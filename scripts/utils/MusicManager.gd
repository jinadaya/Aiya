extends Node

# AudioStreamPlayers for different buses
var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var steps_player: AudioStreamPlayer

# Track current music
var current_music: AudioStream = null
var music_fade_tween: Tween = null

# Audio bus names
const MUSIC_BUS = "Music"
const SFX_BUS = "SFX"
const STEPS_BUS = "Steps"

var sfxs : Dictionary[String, AudioStreamPlayer] = {}

func _ready():
	# Create audio players
	music_player = AudioStreamPlayer.new()
	music_player.bus = MUSIC_BUS
	add_child(music_player)
	
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = SFX_BUS
	add_child(sfx_player)
	
	steps_player = AudioStreamPlayer.new()
	steps_player.bus = STEPS_BUS
	add_child(steps_player)
	
	# Connect level changes to music changes
	LevelManager.music_level_changed.connect(_change_music_according_to_level)
	
	# Ensure audio buses exist
	_setup_audio_buses()

func _process(delta):
	if is_playing_steps:
		step_timer -= delta
		if step_timer <= 0.0:
			_play_next_step()
			step_timer = step_interval

func _change_music_according_to_level(to: LevelManager.Location) -> void:
	var change_to
	match to:
		LevelManager.Location.BEACH:
			change_to = load("res://audio/BEACH_NEW.wav")
		LevelManager.Location.CAVE:
			change_to = load("res://audio/DC_NEW.wav")
		LevelManager.Location.ANCIENT_CITY_1,\
		LevelManager.Location.ANCIENT_CITY_2,\
		LevelManager.Location.ANCIENT_CITY_3:
			change_to = load("res://audio/AC_NEW.wav")
		LevelManager.Location.LIGHTHOUSE:
			change_to = load("res://audio/LH_NEW.wav")
		LevelManager.Location.INIT:
			change_to = load("res://audio/MENU.wav")
	fade_to_music(change_to, 1.3)

func _setup_audio_buses():
	var buses = [MUSIC_BUS, SFX_BUS, STEPS_BUS]
	
	for bus_name in buses:
		var bus_idx = AudioServer.get_bus_index(bus_name)
		if bus_idx == -1:
			AudioServer.add_bus()
			var new_bus_idx = AudioServer.get_bus_count() - 1
			AudioServer.set_bus_name(new_bus_idx, bus_name)

# === MUSIC FUNCTIONS ===

func play_music(stream: AudioStream, fade_in: bool = true, fade_duration: float = 1.0):
	if current_music == stream and music_player.playing:
		return
	
	if music_player.playing and fade_in:
		fade_to_music(stream, fade_duration)
	else:
		music_player.stream = stream
		current_music = stream
		music_player.volume_db = 0.0
		music_player.play()

func fade_to_music(new_stream: AudioStream, duration: float = 1.0):
	if music_fade_tween:
		music_fade_tween.kill()
	
	music_fade_tween = create_tween()
	music_fade_tween.tween_property(music_player, "volume_db", -80.0, duration / 2.0)
	music_fade_tween.tween_callback(func():
		music_player.stream = new_stream
		current_music = new_stream
		music_player.play()
	)
	music_player.finished.connect(react_to_music_stop)
	music_fade_tween.tween_property(music_player, "volume_db", -15.0, duration / 2.0)

func react_to_music_stop() -> void:
	fade_to_music(current_music, 0.1)

func stop_music(fade_out: bool = true, fade_duration: float = 1.0):
	if not music_player.playing:
		return
	
	if fade_out:
		if music_fade_tween:
			music_fade_tween.kill()
		
		music_fade_tween = create_tween()
		music_fade_tween.tween_property(music_player, "volume_db", -80.0, fade_duration)
		music_fade_tween.tween_callback(func():
			music_player.stop()
			current_music = null
			music_player.volume_db = 0.0
		)
	else:
		music_player.stop()
		current_music = null

func pause_music():
	music_player.stream_paused = true

func resume_music():
	music_player.stream_paused = false

# === SFX FUNCTIONS ===

func play_sfx(stream: AudioStream, start_position: float = 0.0, volume_db: float = -8.0, pitch_scale: float = 1.0, tag: String = str(stream)):
	var player = AudioStreamPlayer.new()
	player.bus = SFX_BUS
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	
	sfxs[tag] = player
	
	add_child(player)
	player.play(start_position)
	
	# Auto-cleanup when finished
	player.finished.connect(func():
		player.queue_free()
		sfxs.erase(tag)
	)

func play_sfx_random_pitch(stream: AudioStream, min_pitch: float = 0.9, max_pitch: float = 1.1, volume_db: float = 0.0):
	var pitch = randf_range(min_pitch, max_pitch)
	play_sfx(stream, 0.0, volume_db, pitch)

# === STEPS FUNCTIONS ===

func play_step(stream: AudioStream, volume_db: float = -12.0):
	if not steps_player.playing:
		steps_player.stream = stream
		steps_player.volume_db = volume_db
		steps_player.play()

func play_step_random(streams: Array[AudioStream], volume_db: float = 0.0):
	if streams.is_empty():
		return
	
	var random_stream = streams[randi() % streams.size()]
	play_step(random_stream, volume_db)

func play_step_random_pitch(stream: AudioStream, min_pitch: float = 0.95, max_pitch: float = 1.05, volume_db: float = 0.0):
	if not steps_player.playing:
		steps_player.stream = stream
		steps_player.volume_db = volume_db
		steps_player.pitch_scale = randf_range(min_pitch, max_pitch)
		steps_player.play()

# === VOLUME CONTROL ===

func set_music_volume(volume_db: float):
	var bus_idx = AudioServer.get_bus_index(MUSIC_BUS)
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, volume_db)

func set_sfx_volume(volume_db: float):
	var bus_idx = AudioServer.get_bus_index(SFX_BUS)
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, volume_db)

func set_steps_volume(volume_db: float):
	var bus_idx = AudioServer.get_bus_index(STEPS_BUS)
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, volume_db)

func get_music_volume() -> float:
	var bus_idx = AudioServer.get_bus_index(MUSIC_BUS)
	return AudioServer.get_bus_volume_db(bus_idx) if bus_idx != -1 else 0.0

func get_sfx_volume() -> float:
	var bus_idx = AudioServer.get_bus_index(SFX_BUS)
	return AudioServer.get_bus_volume_db(bus_idx) if bus_idx != -1 else 0.0

func get_steps_volume() -> float:
	var bus_idx = AudioServer.get_bus_index(STEPS_BUS)
	return AudioServer.get_bus_volume_db(bus_idx) if bus_idx != -1 else 0.0

# === STEPS FUNCTIONS ===

# Step sound libraries - preload your step sounds here
var step_sounds = {
	"sand": [
		preload("res://sprites/player/step_on_sand1.mp3"),
		preload("res://sprites/player/step_on_sand2.mp3")
	],
	"stone": [
		preload("res://sprites/player/step_on_stone1.mp3"),
		preload("res://sprites/player/step_on_stone2.mp3")
	],
}

# Step playback state
var is_playing_steps: bool = false
var current_step_surface: String = ""
var step_interval: float = 0.5  # Time between steps in seconds
var step_timer: float = 0.0
var step_volume: float = 0.0
var step_pitch_min: float = 0.95
var step_pitch_max: float = 1.05

func play_steps(surface: String, interval: float = 0.5, volume_db: float = 0.0, min_pitch: float = 0.95, max_pitch: float = 1.05):
	if not step_sounds.has(surface):
		push_error("AudioManager: Unknown step surface '%s'" % surface)
		return
	
	if step_sounds[surface].is_empty():
		push_warning("AudioManager: No step sounds loaded for surface '%s'" % surface)
		return
	
	current_step_surface = surface
	step_interval = interval
	step_volume = volume_db
	step_pitch_min = min_pitch
	step_pitch_max = max_pitch
	is_playing_steps = true
	step_timer = 0.0  # Play first step immediately

func stop_steps():
	is_playing_steps = false
	current_step_surface = ""
	steps_player.stop()

func set_step_interval(interval: float):
	step_interval = interval

func _play_next_step():
	if current_step_surface.is_empty() or not step_sounds.has(current_step_surface):
		return
	
	var sounds = step_sounds[current_step_surface]
	if sounds.is_empty():
		return
	
	var random_sound = sounds[randi() % sounds.size()]
	steps_player.stream = random_sound
	steps_player.volume_db = step_volume
	steps_player.pitch_scale = randf_range(step_pitch_min, step_pitch_max)
	steps_player.play()

# === MUTE CONTROL ===

func stop_sfx_by_tag(tag: String) -> void:
	var sfx : AudioStreamPlayer = sfxs.get(tag)
	if sfx: sfx.stop()

func mute_music(muted: bool):
	var bus_idx = AudioServer.get_bus_index(MUSIC_BUS)
	if bus_idx != -1:
		AudioServer.set_bus_mute(bus_idx, muted)

func mute_sfx(muted: bool):
	var bus_idx = AudioServer.get_bus_index(SFX_BUS)
	if bus_idx != -1:
		AudioServer.set_bus_mute(bus_idx, muted)

func mute_steps(muted: bool):
	var bus_idx = AudioServer.get_bus_index(STEPS_BUS)
	if bus_idx != -1:
		AudioServer.set_bus_mute(bus_idx, muted)

func mute_all(muted: bool):
	mute_music(muted)
	mute_sfx(muted)
	mute_steps(muted)
