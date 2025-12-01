extends AnimatableBody2D
class_name Platform

@onready var glow_material : Material = $StoneValidator.material
@onready var validator : Sprite2D = $StoneValidator
@onready var area : Area2D = $InteractionArea

var is_active : bool

signal validate()

func _ready() -> void:
	collision_layer = CollisionMaskStorage.layer_for(CollisionMaskStorage.CollisionLayer.PLATFORM)
	collision_mask = CollisionMaskStorage.get_mask_for_layer(CollisionMaskStorage.CollisionLayer.PLATFORM)
	
	validator.material = null
	area.body_entered.connect(_body_in)
	area.body_exited.connect(_body_out)

func _process(_delta: float) -> void:
	if is_active and Inventory.is_item_collected(Inventory.Item.STONE):
		if InputManager.is_just_pressed(InputManager.Action.STONE):
			validator.material = glow_material
			validate.emit()

func _body_out(body: Node2D) -> void:
	if not body is Player: return
	is_active = false

func _body_in(body: Node2D) -> void:
	is_active = body is Player

func stop_shine():
	validator.material = null
