extends PanelContainer
class_name Menu

@onready var anim : AnimationPlayer = $IntroAnimation
@onready var start_game_button : Button = $VBoxContainer/Button
@onready var blur_layer : ColorRect = $BG/BlurLayer
@onready var bg : TextureRect = $BG/Background
@onready var logo : Sprite2D = $Logo

const logo_sp : float = 2
const btn_sp : float = 3
const btn_sound = preload("res://audio/BTN_CLCK.mp3")
const logo_sound = preload("res://audio/PENCIL_DRAW_LOGO.mp3")

signal game_started

func _ready() -> void:
	if WorldInfo.beach_data.been_before: return
	start_game_button.pressed.connect(_react_to_start_game)
	start_game_button.modulate.a = 0
	_start_aiya_logo_anim()

func _start_aiya_logo_anim() -> void:
	MusicManager.play_sfx(logo_sound)
	anim.play("aiya_logo_intro")
	await anim.animation_finished
	MusicManager.stop_sfx_by_tag(str(logo_sound))
	create_tween().tween_property(start_game_button, "modulate:a", 1.0, 0.5)

func _react_to_start_game() -> void:
	MusicManager.play_sfx(btn_sound, 0.66)
	var tween : Tween = create_tween()
	tween.tween_method(Callable(self, "_set_shader_param_value"), 1.0, 0.0, 3)
	LevelManager.music_level_changed.emit(LevelManager.Location.BEACH)
	await tween.finished
	bg.queue_free()
	logo.queue_free()
	blur_layer.queue_free()
	start_game_button.queue_free()
	
	game_started.emit()

func _set_shader_param_value(value):
	var to : Vector2= Vector2(4200, 2400)
	var from : Vector2 = Vector2(1920, 1080)
	var progress : float = 1 - value
	var currentSize : Vector2 = from + (to - from) * progress
	
	bg.size = currentSize
	bg.modulate.a = value
	
	start_game_button.position.x += btn_sp * 1200 / 1000
	start_game_button.position.y += btn_sp
	start_game_button.modulate.a = value
	start_game_button.scale = Vector2(1 / value, 1 / value)
	
	logo.position.x += logo_sp * 1200 / 1000
	logo.position.y -= btn_sp
	logo.modulate.a = value
	logo.scale = Vector2(1 / value, 1 / value)
	
	if blur_layer and blur_layer.material is ShaderMaterial:
		var blur_material : ShaderMaterial = blur_layer.material
		blur_material.set_shader_parameter("intensity", value)
		blur_layer.material = blur_material
