extends AnimatableBody2D
class_name FloatingPlatform

@export var max_speed : float = 100.0
@export var acc : float = 1.0
var speed : float = randf_range(-max_speed, max_speed)
var direction : int = 1

@onready var collision := $Collision

func _ready() -> void:
	collision_layer = CollisionMaskStorage.layer_for(CollisionMaskStorage.CollisionLayer.PLATFORM)
	collision_mask = CollisionMaskStorage.get_mask_for_layer(CollisionMaskStorage.CollisionLayer.PLATFORM)

func _process(delta: float) -> void:
	speed += acc * direction
	if abs(speed) >= max_speed:
		direction *= -1
	position.y += speed * delta
