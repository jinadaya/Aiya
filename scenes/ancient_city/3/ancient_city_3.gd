extends Node2D

@onready var player : Player = $Player

@onready var bird_dialog_area : Area2D = $Bird/BirdDialogArea

@onready var platform_1 : Platform = $Platform1
@onready var platform_2 : Platform = $Platform2

@onready var next_level_area : Area2D = $GoToNextLevel
@onready var restart_area : Area2D = $RestartArea
@onready var prev_level_area : Area2D = $GoPrevLevel

var tween_p1 : Tween
var tween_p2 : Tween

@onready var anim : AnimationPlayer = $Bird/AnimationPlayer

const bird_dialog_path = "res://dialogs/ac3/bird.json"

func _ready() -> void:
	_setup_areas()
	_setup_validators()

func _setup_validators() -> void:
	platform_1.validate.connect(_move_p_1)
	platform_2.validate.connect(_move_p_2)

func _move_p_1() -> void:
	if tween_p1 and tween_p1.is_running(): return
	
	tween_p1 = create_tween().set_trans(Tween.TRANS_CUBIC)
	tween_p1.tween_property(platform_1, "position:y", platform_1.position.y - 700, 2)
	tween_p1.tween_interval(2)
	tween_p1.tween_property(platform_1, "position:y", platform_1.position.y, 2)
	
	await tween_p1.finished
	platform_1.stop_shine()
	tween_p1.kill()

func _move_p_2() -> void:
	if tween_p2 and tween_p2.is_running(): return
	
	tween_p2 = create_tween().set_trans(Tween.TransitionType.TRANS_SINE)
	tween_p2.tween_property(platform_2, "position:y", platform_2.position.y + 160, 1)
	tween_p2.tween_interval(0.7)
	tween_p2.tween_property(platform_2, "position:x", platform_2.position.x + 3140, 7)
	tween_p2.tween_interval(0.7)
	tween_p2.tween_property(platform_2, "position:y", platform_2.position.y - 1360, 3)
	tween_p2.tween_interval(0.7)
	tween_p2.tween_property(platform_2, "position:y", platform_2.position.y + 160, 3)
	tween_p2.tween_interval(0.7)
	tween_p2.tween_property(platform_2, "position:x", platform_2.position.x, 5)
	tween_p2.tween_interval(0.7)
	tween_p2.tween_property(platform_2, "position:y", platform_2.position.y, 1)
	
	await tween_p2.finished
	platform_2.stop_shine()
	
	tween_p2.kill()

func _setup_areas() -> void:
	prev_level_area.body_entered.connect(_go_back_level)
	restart_area.body_entered.connect(_restart)
	next_level_area.body_entered.connect(_go_to_next_level)
	bird_dialog_area.body_entered.connect(_show_bird_dialog)

func _go_back_level(body: Node2D) -> void:
	if body != player: return
	LevelManager.go(LevelManager.Location.ANCIENT_CITY_3, LevelManager.Location.ANCIENT_CITY_2)

func _restart(body: Node2D) -> void:
	await GlobalFader.fade_out()
	body.position = Vector2(-3330, 30)
	GlobalFader.fade_in()

func _show_bird_dialog(body: Node2D) -> void:
	if body != player: return
	anim.play("bird_look")
	DialogManager.show_dialog(bird_dialog_path)
	bird_dialog_area.queue_free()

func _go_to_next_level(body: Node2D) -> void:
	if body != player: return
	LevelManager.go(LevelManager.Location.ANCIENT_CITY_3, LevelManager.Location.LIGHTHOUSE)
