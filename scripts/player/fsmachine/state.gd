extends Node
class_name PlayerState

var body : Player
var inbetween_state : InbetweenState
var playback : AnimationNodeStateMachinePlayback

signal transitioned(from : PlayerState, to : StringName)

func handle_input(_input : InputEvent) -> void:
	pass

func enter(_from : PlayerState) -> void:
	pass

func exit() -> void:
	pass

func process(_delta : float) -> void:
	pass

func physics_process(_delta : float) -> void:
	#var flipped = InputManager.get_x_axis() < 0 if InputManager.get_x_axis() != 0 else body.velocity.x < 0
	body.sprite.flip_h = body.velocity.x < 0

func set_body(new_body : CharacterBody2D) -> void:
	body = new_body

func apply_gravity(delta: float, is_falling: bool = false) -> void:
	var jump_released : bool = not InputManager.is_just_pressed(InputManager.Action.JUMP)
	var current_gravity : float = inbetween_state.get_current_gravity(is_falling, jump_released and body.velocity.y < 0)
	body.velocity.y += current_gravity * delta
	
	# Apply max fall speed
	var max_speed : float = inbetween_state.fast_fall_speed if InputManager.get_y_axis() > 0 else inbetween_state.max_fall_speed
	body.velocity.y = min(body.velocity.y, max_speed)

func apply_horizontal_movement(delta: float) -> void:
	var x_dir : float = InputManager.get_x_axis()
	
	# Select movement parameters based on grounded state
	var speed : float = inbetween_state.ground_speed
	var accel : float = inbetween_state.ground_acceleration
	var decel : float = inbetween_state.ground_deceleration
	
	if x_dir != 0:
		var target_speed : float = speed * x_dir
		body.velocity.x = move_toward(body.velocity.x, target_speed, accel * delta)
	else:
		body.velocity.x = move_toward(body.velocity.x, 0, decel * delta)

func try_transition_on_floor(default_state: StringName = "") -> bool:
	if body.is_on_floor():
		var x_dir : float = InputManager.get_x_axis()
		var to_state : StringName = IdleState.get_state_name() if x_dir == 0 else WalkingState.get_state_name()
		if default_state != "":
			to_state = default_state
		transitioned.emit(self, to_state)
		return true
	return false

func try_transition_on_wall() -> bool:
	if body.is_on_wall() and body.facing_flat_wall() and body.wall_enabled:
		transitioned.emit(self, WallSlideState.get_state_name())
		return true
	return false

func handle_jump_input() -> void:
	if InputManager.is_just_pressed(InputManager.Action.JUMP):
		inbetween_state.set_buffer_jump()
		inbetween_state.is_jump_held = true
	
	if InputManager.is_just_released(InputManager.Action.JUMP):
		inbetween_state.is_jump_held = false

func handle_jump_with_priority() -> void:
	if inbetween_state.can_buffer_jump():
		if inbetween_state.can_wall_jump():
			execute_wall_jump()
			return
		elif inbetween_state.can_coyote_jump():
			execute_jump()
			inbetween_state.coyote_timer = 0
			return
		elif inbetween_state.consume_air_jump():
			execute_jump(inbetween_state.air_jump_force_multiplier)
			return

func execute_jump(force_multiplier: float = 1.0) -> void:
	body.velocity.y = inbetween_state.jump_force * force_multiplier
	inbetween_state.buffer_jump_timer = 0
	inbetween_state.block_jumps()

func execute_wall_jump() -> void:
	if (not body.facing_flat_wall()): return
	var normal : Vector2 = inbetween_state.last_wall_normal
	body.velocity.x = inbetween_state.wall_jump_force.x * normal.x
	body.velocity.y = inbetween_state.wall_jump_force.y
	inbetween_state.wall_jump_timer = 0
	inbetween_state.buffer_jump_timer = 0
	inbetween_state.block_jumps()

func slow_down(extra_velocity: float) -> void:
	body.velocity.x -= extra_velocity * inbetween_state.ground_deceleration

static func get_state_name() -> StringName:
	return &""
