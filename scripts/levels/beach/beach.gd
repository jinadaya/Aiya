extends CameraTransitionScene

@onready var voice_area : Area2D = $VoiceArea
@onready var city_area : Area2D = $TownEntry/CityEnterArea
@onready var cave_area : Area2D = $CaveEntry/CaveArea
@onready var start_fall_area : Area2D = $StartFallArea
@onready var city_view_area : Area2D = $TownEntry/CityViewArea
@onready var city_enter_area : Area2D = $TownEntry/CityEnterArea

@onready var city_camera : Camera2D = $TownEntry/CityCamera
@onready var cave_camera : Camera2D = $CaveEntry/CaveCamera

@onready var door_anim : AnimationPlayer = $TownEntry/DoorAnim
@onready var gates : Sprite2D = $TownEntry/CityEnterArea/Gates
@onready var gates_material : Material = gates.material
@onready var door : Sprite2D = $TownEntry/CityEnterArea/Door
@onready var door_ptc_l : GPUParticles2D = $TownEntry/CityEnterArea/OpenPrtclsLeft
@onready var door_ptc_r : GPUParticles2D = $TownEntry/CityEnterArea/OpenPrtclsRight

@onready var menu : Menu = $Menu

const BEACH_DIALOG_PATH : String = "res://dialogs/beach/enter_beach.json"
const CITY_DIALOG_PATH : String = "res://dialogs/beach/view_city.json"
const VOICE_DIALOG_PATH : String = "res://dialogs/beach/first_voice.json"

@onready var player : Player = $Player

var beach_slow_down : float = 0.0
var level_started : bool = false

func _ready() -> void:
	super._ready()
	if not WorldInfo.beach_data.been_before:
		player.set_physics_process(false)
		$Menu/MenuCamera.make_current()
		change_camera($Menu/MenuCamera)
	
	door_ptc_l.emitting = false
	door_ptc_r.emitting = false
	gates.material = null
	_prepare_scene()
	player.on_sand = true
	DialogManager.next_dialog_emmited.connect(_on_react_to_dialog)
	_setup_areas()
	
	await menu.game_started
	player.set_physics_process(true)
	transition_camera.make_current()
	return_to_character(0.05)


func _prepare_scene() -> void:
	var data = WorldInfo.beach_data
	if data.been_before or data.come_from != WorldInfo.BeachData.From.INIT:
		voice_area.queue_free()
		city_view_area.queue_free()
	match data.come_from:
		WorldInfo.BeachData.From.INIT:
			player.position = Vector2(-1200, -4990)
		WorldInfo.BeachData.From.CAVE:
			player.position = Vector2(7580, 0)
		WorldInfo.BeachData.From.CITY:
			player.position = Vector2(6295, 0)

func _setup_areas() -> void:
	start_fall_area.body_entered.connect(_entered_level)
	start_fall_area.body_exited.connect(_start_level)
	city_view_area.body_entered.connect(_view_city)
	city_view_area.body_exited.connect(_leave_city_view)
	city_enter_area.body_entered.connect(_enter_city)
	cave_area.body_entered.connect(_enter_cave)
	voice_area.body_entered.connect(_get_voice_ability)

func _physics_process(delta: float) -> void:
	if beach_slow_down != 0 and player.velocity.x < 0:
		player.velocity.x += delta * beach_slow_down
		player.velocity.x = min(0, player.velocity.x)

func _enter_cave(body: Node2D) -> void:
	if body != player: return
	LevelManager.go(LevelManager.Location.BEACH, LevelManager.Location.CAVE)

func _leave_city_view(body: Node2D) -> void:
	if body != player: return
	camera_return_timer = 3
	return_to_character(0.75)
	city_view_area.queue_free()

func _view_city(body : Node2D) -> void:
	if body != player: return
	camera_free = false
	_change_camera(city_camera, 3)
	DialogManager.show_dialog(CITY_DIALOG_PATH)

func _enter_city(body: Node2D) -> void:
	if body != player: return
	
	if doors_open:
		LevelManager.go(LevelManager.Location.BEACH, LevelManager.Location.ANCIENT_CITY_1)
	
	if Inventory.is_item_collected(Inventory.Item.STONE):
		player.show_hint("'E'")
		await player.push_stone
		if city_enter_area.get_overlapping_bodies().find(player) == -1: return
		
		gates.material = gates_material
		MusicManager.play_sfx(load("res://audio/GATES_OPENING.mp3"))
		await get_tree().create_timer(0.3).timeout
		door_ptc_l.emitting = true
		door_ptc_r.emitting = true
		_shake_camera(3.5)
		await get_tree().create_timer(0.3).timeout
		door.hide()
		door_anim.play("door_open")
		await door_anim.animation_finished
		door_ptc_l.emitting = false
		door_ptc_r.emitting = false
		doors_open = true
		if city_enter_area.get_overlapping_bodies().find(player) != -1:
			LevelManager.go(LevelManager.Location.BEACH, LevelManager.Location.ANCIENT_CITY_1)

func _unslow_player(body: Node2D) -> void:
	if body != player: return
	beach_slow_down = 0.0

func _get_voice_ability(body: Node2D) -> void:
	if body != player: return
	DialogManager.show_dialog(VOICE_DIALOG_PATH)
	Inventory.collect_item(Inventory.Item.VOICE)
	voice_area.queue_free()

func _entered_level(body : Node2D) -> void:
	if body != player: return
	InputManager.off()

func _start_level(body : Node2D) -> void:
	if body != player: return
	DialogManager.show_dialog(BEACH_DIALOG_PATH)
	start_fall_area.queue_free()

func _on_react_to_dialog(dialog: DialogStorage.UiDialog) -> void:
	if DialogManager.current_dialog_path == CITY_DIALOG_PATH:
		match dialog.id:
			2: _look_at_cave()
			3, 4: _look_at_city()
			_: pass

func _look_at_cave() -> void:
	_change_camera(cave_camera, 1.5)

func _look_at_city() -> void:
	_change_camera(city_camera, 1)
