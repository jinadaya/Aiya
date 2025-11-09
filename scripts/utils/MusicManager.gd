extends Node

@export var default_fade_duration: float = 1.0
@export var bus_name: String = "Music"

signal track_changed

var current_player: AudioStreamPlayer
var next_player: AudioStreamPlayer
var is_fading: bool = false
var is_paused: bool = false
var fade_tween: Tween

func _ready() -> void:
	# Create two audio players for crossfading
	current_player = AudioStreamPlayer.new()
	next_player = AudioStreamPlayer.new()
	
	add_child(current_player)
	add_child(next_player)
	
	# Set bus
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		current_player.bus = bus_name
		next_player.bus = bus_name
	
	# Connect finished signals
	current_player.finished.connect(_on_track_finished.bind(current_player))
	next_player.finished.connect(_on_track_finished.bind(next_player))

func change_track(song_id: SongStorage.Song, fade_duration: float = default_fade_duration) -> void:
	# Get the resource from MusicRes class
	var track_resource: Resource = SongStorage.get_song(song_id)
	
	if track_resource == null:
		push_error("MusicManager: Track '%s' not found" % song_id)
		return
	
	if not track_resource is AudioStream:
		push_error("MusicManager: Resource '%s' is not an AudioStream" % song_id)
		return
	
	# If no current track is playing, just start the new one
	if not current_player.playing and not next_player.playing:
		current_player.stream = track_resource
		if fade_duration > 0:
			current_player.volume_db = -80
			current_player.play()
			_fade_volume(current_player, -80, 0, fade_duration)
		else:
			current_player.volume_db = 0
			current_player.play()
		is_paused = false
		return
	
	# Determine which player is currently active
	var active_player = current_player if current_player.playing else next_player
	var inactive_player = next_player if active_player == current_player else current_player
	
	# Stop any existing fade
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
	
	# Set up the new track
	inactive_player.stream = track_resource
	
	if fade_duration > 0:
		is_fading = true
		inactive_player.volume_db = -80
		inactive_player.play()
		
		# Create crossfade
		fade_tween = create_tween()
		fade_tween.set_parallel(true)
		fade_tween.tween_property(active_player, "volume_db", -80, fade_duration)
		fade_tween.tween_property(inactive_player, "volume_db", 0, fade_duration)
		fade_tween.finished.connect(_on_crossfade_finished.bind(active_player))
	else:
		active_player.stop()
		inactive_player.volume_db = 0
		inactive_player.play()
	
	is_paused = false

func pause(fade: bool, fade_duration: float = default_fade_duration) -> void:
	if is_paused:
		return
	
	var active_player = _get_active_player()
	if active_player == null:
		return
	
	if fade and fade_duration > 0:
		is_fading = true
		if fade_tween and fade_tween.is_valid():
			fade_tween.kill()
		
		fade_tween = create_tween()
		fade_tween.tween_property(active_player, "volume_db", -80, fade_duration)
		fade_tween.finished.connect(_on_pause_fade_finished.bind(active_player))
	else:
		active_player.stream_paused = true
	
	is_paused = true

func play(fade: bool, fade_duration: float = default_fade_duration) -> void:
	if not is_paused:
		return
	
	var active_player = _get_active_player()
	if active_player == null:
		return
	
	if fade and fade_duration > 0:
		is_fading = true
		active_player.stream_paused = false
		
		if fade_tween and fade_tween.is_valid():
			fade_tween.kill()
		
		fade_tween = create_tween()
		fade_tween.tween_property(active_player, "volume_db", 0, fade_duration)
		fade_tween.finished.connect(_on_play_fade_finished)
	else:
		active_player.volume_db = 0
		active_player.stream_paused = false
	
	is_paused = false

func stop(fade_duration: float = default_fade_duration) -> void:
	var active_player = _get_active_player()
	if active_player == null:
		return
	
	if fade_duration > 0:
		if fade_tween and fade_tween.is_valid():
			fade_tween.kill()
		
		fade_tween = create_tween()
		fade_tween.tween_property(active_player, "volume_db", -80, fade_duration)
		fade_tween.finished.connect(_on_stop_fade_finished.bind(active_player))
	else:
		active_player.stop()
		active_player.volume_db = 0
	
	is_paused = false

func _get_active_player() -> AudioStreamPlayer:
	if current_player.playing:
		return current_player
	elif next_player.playing:
		return next_player
	return null

func _fade_volume(player: AudioStreamPlayer, from_db: float, to_db: float, duration: float) -> void:
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
	
	is_fading = true
	player.volume_db = from_db
	
	fade_tween = create_tween()
	fade_tween.tween_property(player, "volume_db", to_db, duration)
	fade_tween.finished.connect(_on_fade_finished)

func _on_crossfade_finished(old_player: AudioStreamPlayer) -> void:
	old_player.stop()
	old_player.volume_db = 0
	is_fading = false

func _on_pause_fade_finished(player: AudioStreamPlayer) -> void:
	player.stream_paused = true
	is_fading = false

func _on_play_fade_finished() -> void:
	is_fading = false

func _on_stop_fade_finished(player: AudioStreamPlayer) -> void:
	player.stop()
	player.volume_db = 0
	is_fading = false

func _on_fade_finished() -> void:
	is_fading = false

func _on_track_finished(player: AudioStreamPlayer) -> void:
	if player == current_player:
		track_changed.emit()
