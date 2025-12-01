######################################################
## This script implements the following mechanics:
##  - Movement of player
##  - Coyote jump
##  - Buffer for jumps mid air
##  - Wall slide
##  - Voice action
##  - Stone action
######################################################

extends CharacterBody2D
class_name Player

var sprite : Sprite2D
var body : CharacterBody2D = self
var on_sand : bool = false
var is_echoeing: bool = false
var wall_enabled : bool = false

var step_material : String = ""

@onready var audio_player : AudioStreamPlayer2D = $AudioPlayer

@onready var fsm : FSMachine = $FSMachine

@onready var voice : VoiceAbility = $AbilitiesLayer/Voice

@onready var stone : StoneAbility = $AbilitiesLayer/Stone/Stone
@onready var wall_check_1 : RayCast2D = $WallChecker1
@onready var wall_check_2 : RayCast2D = $WallChecker2
@onready var wall_check_3 : RayCast2D = $WallChecker3
@onready var wall_check_4 : RayCast2D = $WallChecker4

@onready var particles : GPUParticles2D = $SandParticles

@onready var hint : Label = $Container/Hint
@onready var pict_hint : TextureRect = $Container/TextureRect

@onready var atree : AnimationTree = $ATree

signal push_voice()
signal push_stone()

func _ready() -> void:
	step_material = WorldInfo.current_walking_material
	sprite = $PlayerSprite
	hint.modulate.a = 0
	pict_hint.modulate.a = 0
	
	wall_check_1.collision_mask = CollisionMaskStorage.layer_for(CollisionMaskStorage.CollisionLayer.PLATFORM)
	wall_check_2.collision_mask = CollisionMaskStorage.layer_for(CollisionMaskStorage.CollisionLayer.PLATFORM)
	wall_check_3.collision_mask = CollisionMaskStorage.layer_for(CollisionMaskStorage.CollisionLayer.PLATFORM)
	wall_check_4.collision_mask = CollisionMaskStorage.layer_for(CollisionMaskStorage.CollisionLayer.PLATFORM)
	
	collision_layer = CollisionMaskStorage.layer_for(CollisionMaskStorage.CollisionLayer.PLAYER)
	collision_mask = CollisionMaskStorage.get_mask_for_layer(CollisionMaskStorage.CollisionLayer.PLAYER)
	
	particles.emitting = false
	
	fsm.set_atree(atree)
	fsm.set_body(body)

func _process(delta : float) -> void:
	fsm.process(delta)
	particles.emitting = on_sand and fsm.current_state is WalkingState
	if InputManager.is_pressed(InputManager.Action.VOICE) and Inventory.is_item_collected(Inventory.Item.VOICE):
		push_voice.emit()
		voice.start_wave(self.global_position, is_echoeing)
	if InputManager.is_pressed(InputManager.Action.STONE) and Inventory.is_item_collected(Inventory.Item.STONE):
		push_stone.emit()
		stone.start_wave(self.global_position)

func _physics_process(delta: float) -> void:
	fsm.physics_process(delta)

# I use two ray casts 2d to check whether wall is flat enough.
func facing_flat_wall() -> bool:
	return _looks_at_wall(wall_check_1, wall_check_2) or _looks_at_wall(wall_check_3, wall_check_4)

func _looks_at_wall(wall_check_top : RayCast2D, wall_check_bottom : RayCast2D) -> bool:
		# both raycasts must collide
	if not (wall_check_top.is_colliding() and wall_check_bottom.is_colliding()):
		return false

	# they sozuld hit the same collider
	var c1 : Object = wall_check_top.get_collider()
	var c2 : Object  = wall_check_bottom.get_collider()
	if c1 != c2:
		return false

	# normals should both be mostly horizontal and point the same way
	var n1 : Vector2  = wall_check_top.get_collision_normal()
	var n2 : Vector2  = wall_check_bottom.get_collision_normal()
	var same_dir : float = n1.dot(n2) > 0.9
	var horizontal : float = abs(n1.x) > 0.7 and abs(n1.y) < 0.5

	return same_dir and horizontal

func slow_down(direction : int, ) -> void:
	fsm.slow_down_body(direction)

func show_pict_hint(path: String = "") -> void:
	if not path.is_empty():
		var texture: Texture = load(path)
		if not texture: return
		pict_hint.texture = texture
		create_tween().tween_property(pict_hint, "modulate:a", 1, 0.5)
	else:
		var pict_tween = create_tween().tween_property(pict_hint, "modulate:a", 0, 0.5)
		await pict_tween.finished
		pict_hint.texture = null

func show_hint(text: String = "") -> void:
	if not text.is_empty():
		hint.show()
		create_tween().tween_property(hint, "modulate:a", 1, 0.5)
		hint.text = text
	else:
		create_tween().tween_property(hint, "modulate:a", 0, 0.5)

func set_anim(anim: String) -> void:
	fsm.playback.travel(anim)
