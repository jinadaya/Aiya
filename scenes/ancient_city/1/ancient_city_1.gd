extends CameraTransitionScene

@onready var platform : Platform = $Platform
@onready var free_validator : Validator = $UpperRoom/FloatPlatform3/ValidatorFree
@onready var fODArea : Area2D = $CageGeneral/OwlBlockedDialogAera
@onready var sODArea : Area2D = $CageGeneral/OwlFreeDialogArea
@onready var player : Player = $Player
@onready var cage_b : Node2D = $CageGeneral/CageBroken
@onready var cage_f : Node2D = $CageGeneral/CageInit

@onready var elev_anim : AnimationPlayer = $Elevator/AnimationPlayer
@onready var elev_validator : Validator = $Elevator/Validator
@onready var elev_platform : Platform = $Elevator/Platform

@onready var platforms_camera : Camera2D = $PlatformsCamera
@onready var entry_camera : Camera2D = $EnterCamera

@onready var next_level_are : Area2D = $NextLevel

@onready var owl_anim : AnimationPlayer = $CageGeneral/OwlAnim

const fod_path = "res://dialogs/ac1/fod.json"
const sod_path = "res://dialogs/ac1/sod.json"
const sod2_path = "res://dialogs/ac1/sod2.json"

const gear_hint = "res://sprites/levels/ancient_city/1/gear_wheel.png"

var cage_opened : bool = false
var can_go_past_wall : bool = false
var platform_up : bool = false
var timer_down_started : SceneTreeTimer = null
var tween : Tween
var elev_tween : Tween

func _ready() -> void:
	super._ready()
	_start_owl_blinking()
	DialogManager.dialog_started.connect(_stop_owl_blinking)
	DialogManager.next_dialog_emmited.connect(_react_to_dialog)
	DialogManager.dialog_finished.connect(_start_owl_blinking)
	_setup_areas()
	cage_b.hide()
	$Elevator/GearWheel3.hide()
	_setup_validators()
	_preapare_world()

func _preapare_world() -> void:
	if WorldInfo.ac_1_data.come_from == WorldInfo.ACData.From.AC_NEXT:
		player.position = Vector2(-6500, -1500)
		cage_b.show()
		cage_f.hide()
		$Elevator/GearWheel3.show()
		can_go_past_wall = true
		cage_opened = true
		fODArea.queue_free()
		sODArea.queue_free()

func _setup_validators() -> void:
	platform.validate.connect(_move_platform)
	elev_platform.validate.connect(_rise_up)
	free_validator.validate.connect(_free_owl)
	elev_validator.validate.connect(_get_elevator)

func _rise_up() -> void:
	var n_tween = create_tween()
	n_tween.tween_property(elev_platform, "position:y", -2000, 8)

func _get_elevator() -> void:
	if can_go_past_wall:
		$Elevator/GearWheel3.show()
		if elev_tween: elev_tween.kill()
		elev_tween = create_tween()
		elev_anim.play("gear_spin_full")
		elev_tween.tween_property(elev_platform, "position:y", 470, 8)
		await elev_tween.finished
	else:
		elev_anim.play("gear_lost")

func _free_owl() -> void:
	MusicManager.play_sfx(load("res://audio/CAGE_OPEN.mp3"))
	cage_opened = true
	cage_f.hide()
	cage_b.show()
	$CageGeneral/OwlSprite.position.x -= 100
	$CageGeneral/OwlSprite.texture = load("res://sprites/levels/ancient_city/1/stand.png")

func _move_platform() -> void:
	if tween: return
	tween = create_tween()
	if platform_up:
		tween.tween_property(platform, "position:y", platform.position.y + 1200, 5).set_trans(Tween.TransitionType.TRANS_CUBIC)
		await tween.finished
		platform_up = !platform_up
	else:
		tween.tween_property(platform, "position:y", platform.position.y - 1200, 6).set_trans(Tween.TransitionType.TRANS_CUBIC)
		await tween.finished
		platform_up = !platform_up
	platform.stop_shine()
	tween = null
	if platform_up:
		timer_down_started = null
		timer_down_started = get_tree().create_timer(5)
		await timer_down_started.timeout
		_move_platform()

func _setup_areas() -> void:
	fODArea.body_entered.connect(_setup_fod)
	sODArea.body_entered.connect(_setup_sod)
	
	$EntryCameraChange.body_entered.connect(_show_enter)
	$EntryCameraChange.body_exited.connect(_follow_player)
	
	$UpperRoom/EnterPlatformsArea.body_entered.connect(_show_platforms)
	$UpperRoom/EnterPlatformsArea.body_exited.connect(_follow_player)
	
	$NextLevel.body_entered.connect(_go_next_level)

func _go_next_level(body : Node2D) -> void:
	if body != player: return
	LevelManager.go(LevelManager.Location.ANCIENT_CITY_1, LevelManager.Location.ANCIENT_CITY_2)

func _show_platforms(body : Node2D) -> void:
	if body != player: return
	camera_free = false
	_change_camera(platforms_camera)

func _show_enter(body : Node2D) -> void:
	if body != player: return
	camera_follow_with_restrictions = true
	_change_camera(entry_camera)

func _follow_player(body : Node2D) -> void:
	if body != player: return
	camera_follow_with_restrictions = false
	return_to_character(0.2)
	_change_camera(transition_camera)

func _setup_fod(body: Node2D) -> void:
	if body != player: return
	DialogManager.show_dialog(fod_path, false)
	fODArea.queue_free()

func _setup_sod(body: Node2D) -> void:
	if body != player or not cage_opened: return
	if can_go_past_wall:
		DialogManager.show_dialog(sod2_path, false)
	can_go_past_wall = true
	DialogManager.show_dialog(sod_path, false)

func _react_to_dialog(dialog : DialogStorage.UiDialog) -> void:
	_owl_say()
	if dialog.id == 4 and cage_opened:
		player.show_pict_hint(gear_hint)
		await get_tree().create_timer(2).timeout
		player.show_pict_hint()

func _owl_say() -> void:
	owl_anim.play("speak")
	await get_tree().create_timer(1).timeout
	owl_anim.stop()

func _stop_owl_blinking() -> void:
	owl_anim.stop()

func _start_owl_blinking() -> void:
	if cage_opened: $CageGeneral/OwlSprite.texture = load("res://sprites/levels/ancient_city/1/stand.png")
	else: owl_anim.play("blink")
