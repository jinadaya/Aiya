extends Node2D

@onready var slow_down_area : Area2D = $SlowDownArea
@onready var player : Player = $Player
var beach_slow_down : float = 0.0

func _ready() -> void:
	player.on_sand = true
	setup_areas()
	
func setup_areas() -> void:
	slow_down_area.body_entered.connect(_slow_down_player)
	slow_down_area.body_exited.connect(_unslow_player)

func _physics_process(delta: float) -> void:
	if beach_slow_down != 0 and player.velocity.x < 0:
		player.velocity.x += delta * beach_slow_down
		player.velocity.x = min(0, player.velocity.x)

func _slow_down_player(body: Node2D) -> void:
	if body != player: return
	print("slow down")
	beach_slow_down = 1800.0

func _unslow_player(body: Node2D) -> void:
	if body != player: return
	print("speed up")
	beach_slow_down = 0.0
