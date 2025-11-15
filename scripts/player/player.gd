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

var body : CharacterBody2D = self
var on_sand : bool = false
@onready var sprite : Sprite2D = $Sprite

@onready var a_tree : AnimationTree = $ATree
@onready var anim_player : AnimationPlayer = $APlayer
@onready var audio_player : AudioStreamPlayer2D = $AudioPlayer

@onready var fsm : FSMachine = $FSMachine

@onready var voice : VoiceAbility = $AbilitiesLayer/Voice
@onready var stone : StoneAbility = $AbilitiesLayer/Stone/Stone

@onready var wall_check_1 : RayCast2D = $WallChecker1
@onready var wall_check_2 : RayCast2D = $WallChecker2
@onready var wall_check_3 : RayCast2D = $WallChecker3
@onready var wall_check_4 : RayCast2D = $WallChecker4

@onready var particles : GPUParticles2D = $SandParticles

func _ready() -> void:
	wall_check_1.collision_mask = CollisionMaskStorage.layer_for(CollisionMaskStorage.CollisionLayer.PLATFORM)
	wall_check_2.collision_mask = CollisionMaskStorage.layer_for(CollisionMaskStorage.CollisionLayer.PLATFORM)
	wall_check_3.collision_mask = CollisionMaskStorage.layer_for(CollisionMaskStorage.CollisionLayer.PLATFORM)
	wall_check_4.collision_mask = CollisionMaskStorage.layer_for(CollisionMaskStorage.CollisionLayer.PLATFORM)
	collision_layer = CollisionMaskStorage.layer_for(CollisionMaskStorage.CollisionLayer.PLAYER)
	collision_mask = CollisionMaskStorage.get_mask_for_layer(CollisionMaskStorage.CollisionLayer.PLAYER)
	particles.emitting = false
	fsm.set_body(body)
	a_tree.active = true

func _process(delta : float) -> void:
	fsm.process(delta)
	particles.emitting = on_sand and fsm.current_state is WalkingState
	if InputManager.is_pressed(InputManager.Action.VOICE) and Inventory.is_item_collected(Inventory.Item.VOICE):
		voice.start_wave(self.global_position)
	if InputManager.is_pressed(InputManager.Action.STONE) and Inventory.is_item_collected(Inventory.Item.STONE):
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
	print("slow down with", direction)
	fsm.slow_down_body(direction)
