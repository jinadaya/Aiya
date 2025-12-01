extends Node2D

@onready var player : Player = $Player
@onready var anim : AnimationPlayer = $AnimationPlayer
@onready var exit : Area2D = $ExitDungeon
@onready var restart_area : Area2D = $Restart
@onready var save_area : Area2D = $SaveArea
@onready var finish_area : Area2D = $FinishArea

var current_save_point : Vector2 = Vector2(72.0, 871.0)

const SAVE_POINT_DISTANCE_THRESHOLD : int = 1000

func _ready() -> void:
	player.particles.hide()
	player.is_echoeing = true
	_setup_interactable_areas()
	_player_enter()

func _player_enter():
	player.wall_enabled = true
	anim.play("enter_anim")

func _on_player_fell(body : Node2D):
	if body != player: return
	await GlobalFader.fade_out()
	player.position = current_save_point
	GlobalFader.fade_in()

func _on_player_exit_cave(body : Node2D):
	if body != player: return
	LevelManager.go(LevelManager.Location.CAVE, LevelManager.Location.BEACH)

func _player_picked_stone_up(body : Node2D):
	if body != player: return
	Inventory.collect_item(Inventory.Item.STONE)
	_on_player_exit_cave(body)

func _save_player_position(body : Node2D):
	if body != player: return
	if player.position.distance_to(current_save_point) < SAVE_POINT_DISTANCE_THRESHOLD : return
	current_save_point = player.position

func _setup_interactable_areas():
	restart_area.collision_layer = CollisionMaskStorage.layer_for(CollisionMaskStorage.CollisionLayer.OBSTACLE)
	exit.collision_layer = CollisionMaskStorage.layer_for(CollisionMaskStorage.CollisionLayer.OBSTACLE)
	save_area.collision_layer = CollisionMaskStorage.layer_for(CollisionMaskStorage.CollisionLayer.OBSTACLE)
	finish_area.collision_layer = CollisionMaskStorage.layer_for(CollisionMaskStorage.CollisionLayer.OBSTACLE)
	
	restart_area.collision_mask = CollisionMaskStorage.get_mask_for_layer(CollisionMaskStorage.CollisionLayer.OBSTACLE)
	exit.collision_mask = CollisionMaskStorage.get_mask_for_layer(CollisionMaskStorage.CollisionLayer.OBSTACLE)
	save_area.collision_mask = CollisionMaskStorage.get_mask_for_layer(CollisionMaskStorage.CollisionLayer.OBSTACLE)
	finish_area.collision_mask = CollisionMaskStorage.get_mask_for_layer(CollisionMaskStorage.CollisionLayer.OBSTACLE)
	
	exit.body_entered.connect(_on_player_exit_cave)
	restart_area.body_entered.connect(_on_player_fell)
	save_area.body_entered.connect(_save_player_position)
	finish_area.body_entered.connect(_player_picked_stone_up)
