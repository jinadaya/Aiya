extends Node2D
class_name Validator

@onready var validator_area : Area2D = $Area2D
@onready var glow_material : Material = $Sprite2D.material
@onready var sprite : Sprite2D = $Sprite2D

var is_reachable : bool = false
var is_active : bool = false

signal validate

func _ready() -> void:
	sprite.material = null
	validator_area.body_entered.connect(_activate)
	validator_area.body_exited.connect(_deactivate)

func _process(_delta: float) -> void:
	if InputManager.is_just_pressed(InputManager.Action.STONE) and is_reachable:
		is_active = true
		sprite.material = glow_material
		validate.emit()

func _activate(_body: Node2D) -> void:
	is_reachable = true

func _deactivate(_body: Node2D) -> void:
	is_reachable = false

func off() -> void:
	sprite.material = null
	is_active = false
