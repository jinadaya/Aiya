extends Node2D
class_name CameraTransitionScene

@export var transition_camera : Camera2D
@export var character_camera : Camera2D
@export var return_duration : float = 1.0
@export var smooth_follow_speed : float = 5.0

var transition_tween : Tween
var follow_tween : Tween
var camera_free : bool = true
var camera_follow_with_restrictions : bool = false
var camera_return_timer : float = 0
var shake_time : float = 0.0
var noise := FastNoiseLite.new()
var doors_open : bool = false
var is_returning : bool = false
var return_progress : float = 0.0

func _process(delta: float) -> void:
	if is_returning:
		return_progress = min(return_progress + delta / return_duration, 1.0)
		
		var smooth_factor = ease(return_progress, -2.0)
		
		transition_camera.global_position = lerp(
			transition_camera.global_position,
			character_camera.global_position,
			smooth_factor * smooth_follow_speed * delta
		)
		transition_camera.zoom = lerp(
			transition_camera.zoom,
			character_camera.zoom,
			smooth_factor * smooth_follow_speed * delta
		)
		transition_camera.offset = lerp(
			transition_camera.offset,
			character_camera.offset,
			smooth_factor * smooth_follow_speed * delta
		)
		
		# Проверяем, достаточно ли близко камера
		if return_progress >= 1.0 and transition_camera.global_position.distance_to(character_camera.global_position) < 1.0:
			is_returning = false
			camera_free = true
			return_progress = 0.0
	elif camera_follow_with_restrictions:
		_follow_camera(character_camera, delta)
	elif camera_free:
		_change_camera(character_camera, delta)
	if shake_time > 0:
		shake_time -= delta
		character_camera.offset = Vector2(
			noise.get_noise_2d(shake_time, 0) * 20,
			noise.get_noise_2d(0, shake_time) * 20,
		)
	else:
		character_camera.offset = lerp(character_camera.offset, Vector2.ZERO, 10.5 * delta)

func _ready() -> void:
	transition_camera.make_current()
	camera_free = true

func _shake_camera(duration: float) -> void:
	randomize()
	noise.seed = randi()
	noise.frequency = 2.0
	shake_time = duration

func _follow_camera(to: Camera2D, delta: float = 0.5) -> void:
	if follow_tween: 
		follow_tween.kill()
	
	follow_tween = create_tween().set_parallel(true)
	follow_tween.tween_property(transition_camera, "global_position", to.global_position, delta).set_trans(Tween.TRANS_SINE)

func _change_camera(to: Camera2D, delta: float = 0.5) -> void:
	if is_returning and to != transition_camera:
		is_returning = false
	
	if transition_tween: 
		transition_tween.kill()
	
	transition_tween = create_tween().set_parallel(true)
	transition_tween.tween_property(transition_camera, "global_position", to.global_position, delta).set_trans(Tween.TRANS_SINE)
	transition_tween.tween_property(transition_camera, "zoom", to.zoom, delta).set_trans(Tween.TRANS_SINE)
	transition_tween.tween_property(transition_camera, "offset", to.offset, delta).set_trans(Tween.TRANS_SINE)

func change_camera(to: Camera2D, time: float = 1.0) -> void:
	camera_free = false
	_change_camera(to, time)

func return_to_character(duration: float = -1.0) -> void:
	if duration < 0:
		duration = return_duration
	
	if transition_tween:
		transition_tween.kill()
	if follow_tween:
		follow_tween.kill()
	
	is_returning = true
	return_progress = 0.0
	camera_free = false
