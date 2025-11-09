extends Resource
class_name InbetweenState

# === TIMERS ===
var coyote_timer: float = 0.0
var buffer_jump_timer: float = 0.0
var wall_jump_timer: float = 0.0

const WALL_JUMP_TIMER_THRESHOLD: float = 0.2
const BUFFER_TIMER_THRESHOLD: float = 0.1
const COYOTE_TIMER_THRESHOLD: float = 0.1
const JUMP_BLOCK_THRESHOLD : float = 0.05

# === MOVEMENT ===
@export_group("Ground Movement")
@export var ground_acceleration: float = 1600.0
@export var ground_deceleration: float = 1800.0
@export var ground_speed: float = 620.0

# === VERTICAL MOVEMENT ===
@export_group("Gravity & Falling")
@export var gravity_scale: float = 1.0
@export var fall_gravity_multiplier: float = 1.2
@export var max_fall_speed: float = 800
@export var fast_fall_speed: float = 900

# === JUMP ===
@export_group("Jump")
@export var jump_force: float = -1000.0
@export var jump_cut_multiplier: float = 0.5
@export var max_air_jumps: int = 1
@export var air_jump_force_multiplier: float = 0.45
@export var jump_lock : float = 0.05

var air_jumps_remaining: int = 1
var is_jump_held: bool = false

# === WALL ===
@export_group("Wall Mechanics")
@export var wall_slide_speed: float = 100.0
@export var wall_jump_force: Vector2 = Vector2(340, -400)

var last_wall_normal: Vector2 = Vector2.ZERO

# === CACHED VALUES ===
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

# === METHODS ===
func dec_timer(delta: float) -> void:
	coyote_timer = max(0, coyote_timer - delta)
	buffer_jump_timer = max(0, buffer_jump_timer - delta)
	wall_jump_timer = max(0, wall_jump_timer - delta)
	jump_lock = max(0, jump_lock - delta)

func reset_air_jumps() -> void:
	air_jumps_remaining = max_air_jumps

func consume_air_jump() -> bool:
	if air_jumps_remaining > 0:
		air_jumps_remaining -= 1
		return true
	return false

func block_jumps():
	jump_lock = JUMP_BLOCK_THRESHOLD

func can_coyote_jump() -> bool:
	return coyote_timer > 0 and jump_lock == 0

func can_buffer_jump() -> bool:
	return buffer_jump_timer > 0 and jump_lock == 0

func can_wall_jump() -> bool:
	return wall_jump_timer > 0 and jump_lock == 0

func set_buffer_jump() -> void:
	buffer_jump_timer = BUFFER_TIMER_THRESHOLD

func reset_coyote() -> void:
	coyote_timer = COYOTE_TIMER_THRESHOLD

func reset_wall_jump() -> void:
	wall_jump_timer = WALL_JUMP_TIMER_THRESHOLD

func get_current_gravity(is_falling: bool = false, is_jump_released: bool = false) -> float:
	var current_gravity = gravity * gravity_scale
	
	if is_falling:
		current_gravity *= fall_gravity_multiplier
	elif is_jump_released and not is_falling:
		current_gravity *= 2.0
	
	return current_gravity
