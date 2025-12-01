extends CameraTransitionScene

@onready var anim : AnimationPlayer = $AnimationPlayer
@onready var last_area : Area2D = $LastTalk
@onready var player: Player = $FallPath/PathFollow2D/Player
@onready var shader_node : ColorRect = $Rays

const last_dialog_path = "res://dialogs/lighthouse/last.json"

var shader_material: ShaderMaterial
var animation_tween: Tween
var is_good_end : bool = true

const good_end = "Aiya's voice was gone. But she wasn't sorry about that. She felt that she remembered that old memories. Memories that used to be very important, but she forgot about them. When Aiya woke up from this wonderful dream, she found out that her throat has no pain no more. Her deadly sentence was not destined to come true. Even thought her voice was gone, some miracle healed cancer she was sick with."
const bad_end = "Aiya tried to light the lighthouse, yet none of her deeds were succesful. She later fell asleep. But when she woke up, the world of Wise Owl, Happy Kitten and mystical Voice from above, was gone. Whe was leying in her bed, dying from throat cancer. And noone was able to help her. Espesially herself."

func _ready():
	super._ready()
	_play_landing()
	_setup_areas()
	DialogManager.next_dialog_emmited.connect(_react_to_dialog)
	DialogManager.dialog_finished.connect(_end)
	# Get the shader material from the node
	if shader_node:
			shader_material = shader_node.material as ShaderMaterial
	
	if not shader_material:
		push_error("RaysAnimation: No shader material found!")
	else:
		# Initialize shader with rays hidden
		shader_material.set_shader_parameter("edge_fade", 1.0)

func _process(delta: float) -> void:
	super._process(delta)

func _play_landing() -> void:
	player.set_physics_process(false)
	player.set_anim("mid_air")
	InputManager.off()
	anim.play("Enter")
	await anim.animation_finished
	InputManager.on()
	player.set_physics_process(true)

func _setup_areas() -> void:
	last_area.body_entered.connect(_start_final_scene)

func _start_final_scene(body: Node2D) -> void:
	if body != player: return
	change_camera($CenterCamera, 2)
	DialogManager.show_dialog(last_dialog_path)

func _react_to_dialog(d: DialogStorage.UiDialog) -> void:
	match d.id:
		2:
			change_camera($GodRaysCamera, 1)
			show_rays(5.0)
		21:
			is_good_end = false
		_: pass

func _end() -> void:
	InputManager.off()
	hide_rays(3.0)
	GlobalFader.fade_duration = 6
	GlobalFader.text_display_time = 15
	var text = good_end if is_good_end else bad_end
	GlobalFader.fade_with_text(text)
	var tween = create_tween()
	tween.tween_property(transition_camera, "position:y", transition_camera.position.y - 800, 8)
	WorldInfo.reset()
	await GlobalFader.faded_out
	LevelManager.go(LevelManager.Location.LIGHTHOUSE, LevelManager.Location.BEACH, false)


func show_rays(duration: float = 1.0):
	if not shader_material:
		return
	
	# Kill any existing tween
	if animation_tween:
		animation_tween.kill()
	
	# Create new tween
	animation_tween = create_tween()
	animation_tween.set_ease(Tween.EASE_OUT)
	animation_tween.set_trans(Tween.TRANS_CUBIC)
	
	animation_tween.tween_method(
		func(value): shader_material.set_shader_parameter("edge_fade", value),
		1.0,
		0.15,
		duration
	)

func hide_rays(duration: float = 1.0):
	if not shader_material:
		return
	
	# Kill any existing tween
	if animation_tween:
		animation_tween.kill()
	
	# Create new tween
	animation_tween = create_tween()
	animation_tween.set_ease(Tween.EASE_OUT)
	animation_tween.set_trans(Tween.TRANS_CUBIC)
	
	animation_tween.tween_method(
		func(value): shader_material.set_shader_parameter("edge_fade", value),
		0.15,
		1.0,
		duration
	)
