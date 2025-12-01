extends CameraTransitionScene

@onready var go_back_area : Area2D = $ReturnToPreviousLevelArea
@onready var restart_area : Area2D = $RestartArea
@onready var enter_machine_area : Area2D = $BridgeMachine/EnterMachineArea
@onready var trade_area : Area2D = $TradeMachine/TradeArea
@onready var pickup_gear_area : Area2D = $InvPlatforms/P3/PathFollow2D/P3/PickupGearArea
@onready var cat_dialog_area : Area2D = $CatEntry/CatDialogArea
@onready var next_level_area : Area2D = $NextLevelArea

@onready var cloud_gear_4 : Sprite2D = $BridgeMachine/Cloud
@onready var cloud_gear_3 : Sprite2D = $TradeMachine/Cloud

@onready var player : Player = $Player

@onready var platform : Platform = $Platform

@onready var anim : AnimationPlayer = $AnimationPlayer

@onready var trade_monitor_glow_material : Material = $TradeMachine/TradeMachine.material

var cp : Vector2 = Vector2(2575, -135)
var cat_met : bool = false
var can_trade : bool = false
var have_gear : bool = false
var bridge_done : bool = false
var can_enter_machine : bool = false
var in_machine : bool = false
var have_last_gear : bool = false

var cloud_tween : Tween

const cat_dialogs : Array[String] = [
	"res://dialogs/ac2/cat_meetup.json",
	"res://dialogs/ac2/cat_farewell.json",
	"res://dialogs/ac2/cat_help.json"
]
const gear_3_hint_path = "res://sprites/levels/ancient_city/2/gear_3.png"
const gear_4_hint_path = "res://sprites/levels/ancient_city/1/gear_wheel.png"

func _ready() -> void:
	$TradeMachine/TradeMachine.material = null
	_setup_areas()
	_rise_platform()
	_setup_bridge()
	_prepare_world()
	cloud_gear_4.modulate.a = 0
	cloud_gear_3.modulate.a = 0

func _process(_delta: float) -> void:
	super._process(_delta)
	if in_machine:
		player.position = Vector2(2363, -374)
	if InputManager.is_just_pressed(InputManager.Action.STONE):
		if can_trade:
			_trade()
	if InputManager.is_just_pressed(InputManager.Action.INTERACT):
		if can_enter_machine:
			_enter_machine()
		elif in_machine:
			_exit_machine()

func _prepare_world() -> void:
	if WorldInfo.ac_2_data.come_from == WorldInfo.ACData.From.AC_NEXT:
		player.position = Vector2(7730, -505)
		cat_met = true
		bridge_done = true
		_setup_bridge(1)

func _trade() -> void:
	if not have_gear:
		_cycle_cloud(cloud_gear_3)
	else:
		can_trade = false
		var to_shake = $TradeMachine/TradeMachine
		to_shake.material = trade_monitor_glow_material
		
		# Shake trade machine
		var original_position = to_shake.offset
		var tween = create_tween()
		
		for i in range(5):
			var random_offset = Vector2(
				randf_range(-20, 20),
				randf_range(-10, 10)
			)
			tween.tween_property(to_shake, "offset", original_position + random_offset, 0.1)
		tween.tween_property(to_shake, "offset", original_position, 0.2)
		
		player.show_pict_hint(gear_4_hint_path)
		await get_tree().create_timer(2).timeout
		player.show_pict_hint()
		
		have_gear = false
		have_last_gear = true
		can_trade = true

func _enter_machine() -> void:
	InputManager.off()
	player.z_index = 1
	_change_camera($BridgeMachine/BridgeCamera)
	camera_free = false
	anim.play("Enter")
	in_machine = true
	await anim.animation_finished
	InputManager.off([InputManager.Action.INTERACT])
	_handle_actions()

func _handle_actions() -> void:
	if have_last_gear:
		_build_bridge()
	else:
		_cycle_cloud(cloud_gear_4)

func _build_bridge() -> void:
	InputManager.off()
	if bridge_done: return
	anim.play("BiuldBridge")
	await anim.animation_finished
	_setup_bridge(1.0)
	bridge_done = true
	InputManager.off([InputManager.Action.INTERACT])

func _exit_machine() -> void:
	anim.play_backwards("Enter")
	await anim.animation_finished
	in_machine = false
	return_to_character(0.5)
	player.z_index = 3
	InputManager.on()

func _rise_platform() -> void:
	InputManager.off()
	var tween := create_tween().set_trans(Tween.TRANS_QUAD)
	tween.tween_property(platform, "position:y", 0, 4)
	await tween.finished
	InputManager.on()

func _try_end_level(body: Node2D) -> void:
	if body != player: return
	if bridge_done:
		LevelManager.go(LevelManager.Location.ANCIENT_CITY_2, LevelManager.Location.ANCIENT_CITY_3)
	else:
		DialogManager.show_dialog(cat_dialogs[2])
		await GlobalFader.fade_out()
		player.position.x -= 200
		GlobalFader.fade_in()

func _setup_areas() -> void:
	restart_area.body_entered.connect(_restart)
	go_back_area.body_entered.connect(_go_back_level)
	
	enter_machine_area.body_entered.connect(_enter_bridge_machine)
	enter_machine_area.body_exited.connect(_exit_bridge_machine)
	
	trade_area.body_entered.connect(_trade_area_entered)
	trade_area.body_exited.connect(_trade_area_exited)
	
	pickup_gear_area.body_entered.connect(_pickup_gear)
	
	cat_dialog_area.body_entered.connect(_start_cat_dialog)
	
	next_level_area.body_entered.connect(_try_end_level)

func _setup_bridge(prgrs: float = 0.0) -> void:
	$InvPlatforms/P1/PathFollow2D/P1/Brick3.modulate.a = prgrs
	$InvPlatforms/P2/PathFollow2D/P2/Brick2.modulate.a = prgrs
	$InvPlatforms/P3/PathFollow2D/P3/Brick1.modulate.a = prgrs
	
	$Bridge/P1/PathFollow2D.progress_ratio = prgrs
	$Bridge/P2/PathFollow2D.progress_ratio = prgrs
	$Bridge/P3/PathFollow2D.progress_ratio = prgrs
	$Bridge/P4/PathFollow2D.progress_ratio = prgrs
	$InvPlatforms/P1/PathFollow2D.progress_ratio = prgrs
	$InvPlatforms/P2/PathFollow2D.progress_ratio = prgrs
	$InvPlatforms/P3/PathFollow2D.progress_ratio = prgrs

func _start_cat_dialog(body : Node2D) -> void:
	if body != player: return
	if bridge_done:
		DialogManager.show_dialog(cat_dialogs[1])
		cat_dialog_area.queue_free()
	elif !cat_met:
		DialogManager.show_dialog(cat_dialogs[0])
	cat_met = true

func _pickup_gear(body : Node2D) -> void:
	if body != player or have_gear: return
	have_gear = true
	$InvPlatforms/P3/PathFollow2D/P3/PickupGearArea.queue_free()
	player.show_pict_hint(gear_3_hint_path)
	await get_tree().create_timer(2).timeout
	player.show_pict_hint()

func _trade_area_exited(body : Node2D) -> void:
	if body != player: return
	can_trade = false

func _trade_area_entered(body : Node2D) -> void:
	if body != player: return
	cp = Vector2(5350, -190)
	can_trade = true

func _exit_bridge_machine(body : Node2D) -> void:
	if body != player: return
	player.show_hint("")
	can_enter_machine = false

func _enter_bridge_machine(body : Node2D) -> void:
	if body != player: return
	cp = Vector2(2575, -135)
	player.show_hint("'F'")
	can_enter_machine = true

func _restart(body : Node2D) -> void:
	if body != player: return
	await GlobalFader.fade_out()
	player.position = cp
	GlobalFader.fade_in()

func _go_back_level(body: Node2D) -> void:
	if body != player: return
	LevelManager.go(LevelManager.Location.ANCIENT_CITY_2, LevelManager.Location.ANCIENT_CITY_1)

func _cycle_cloud(cloud: Sprite2D) -> void:
	if cloud_tween:
		cloud_tween.kill()
	cloud_tween = get_tree().create_tween()
	cloud_tween.tween_interval(0.3)
	cloud_tween.tween_property(cloud, "modulate:a", 1, 0.7)
	cloud_tween.tween_interval(2.0)
	cloud_tween.tween_property(cloud, "modulate:a", 0, 0.7)
