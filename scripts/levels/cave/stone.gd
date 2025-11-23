extends Sprite2D

@export var max_stone_speed : float = 80.0
@export var acc : float = 1.0
var speed : float = 0.0
var direction : int = 1

func _process(delta: float) -> void:
	speed += acc * direction
	if abs(speed) >= max_stone_speed:
		direction *= -1
	position.y += speed * delta
