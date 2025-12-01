extends Node
class_name UiAnimator

@export var animation_type : Tween.TransitionType
@export var target_scale : Vector2 = Vector2(1.02, 1.02)
@export var duration : float = 0.2
@export var rotation_scale = 0.07

@export var anim_rotation : bool = true
@export var anim_bounce : bool = false


var original_scale : Vector2
var target : Control
var is_hovered : bool = false

var rotation_speed : float = randf() * 15
var rotation_acc : float = 0.3
var max_rotation_speed : float = 15
var rotation_dir : int = 1

var y_speed : float = randf() * 15
var y_acc : float = 0.2
var max_y_speed : float = 15
var y_dir : int = 1

func _ready() -> void:
	target = get_parent()
	target.mouse_entered.connect(_on_hovered)
	target.mouse_exited.connect(_on_unhovered)
	target.resized.connect(_change_offset_to_center)
	
	if anim_rotation:
		pass
	
	original_scale = target.scale

func _change_offset_to_center() -> void:
	target.pivot_offset = target.size / 2

func _process(delta: float) -> void:
	if anim_rotation:
		var extra : float = 1.2 if is_hovered else 0.4
		target.rotation_degrees += rotation_speed * delta * extra * rotation_scale
		rotation_speed += rotation_acc * rotation_dir
		if abs(rotation_speed) >= max_rotation_speed:
			rotation_dir *= -1
	
	if anim_bounce:
		var extra : float = 0.0 if is_hovered else 1.0
		target.position.y += y_speed * delta * extra
		y_speed += y_dir * y_acc
		if abs(y_speed) >= max_y_speed:
			y_dir *= -1


func _on_target_scale_changed() -> void:
	original_scale = target.scale


func _on_hovered() -> void:
	is_hovered = true
	var tween : Tween = target.create_tween()
	tween.set_trans(animation_type)
	tween.tween_property(target, "scale", target_scale, duration)


func _on_unhovered() -> void:
	is_hovered = false
	var tween : Tween = target.create_tween()
	tween.set_trans(animation_type)
	tween.tween_property(target, "rotation_degrees", 0, 0.1)
	tween.tween_property(target, "scale", original_scale, duration)
