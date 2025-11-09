extends PlayerState
class_name WallSlideState

func enter(_from: PlayerState) -> void:
	inbetween_state.reset_air_jumps()
	inbetween_state.reset_wall_jump()

func physics_process(delta: float) -> void:
	# Update wall data
	inbetween_state.last_wall_normal = body.get_wall_normal()
	
	# Reset wall jump
	inbetween_state.reset_wall_jump()
	
	# Handle jump input
	handle_jump_input()
	
	# Land on ground
	if try_transition_on_floor():
		return
	
	# Left the wall
	if not body.is_on_wall():
		transitioned.emit(self, FallState.get_state_name())
		return
	
	# Handle wall jump
	if body.velocity.y > 0 and inbetween_state.can_buffer_jump():
		execute_wall_jump()
		transitioned.emit(self, AirState.get_state_name())
		return
	
	# Apply wall slide physics
	var slowing_mlp = 0.4 if inbetween_state.last_wall_normal.x == -InputManager.get_x_axis() else 1.0
	body.velocity.y = min(body.velocity.y + inbetween_state.gravity * delta, inbetween_state.wall_slide_speed * slowing_mlp)
	
	# Handle horizontal movement (allow moving away from wall)
	var x_dir = InputManager.get_x_axis()
	if x_dir != 0:
		# Allow full control when moving away from wall
		if sign(x_dir) == sign(inbetween_state.last_wall_normal.x):
			body.velocity.x = move_toward(body.velocity.x, inbetween_state.ground_speed * x_dir, inbetween_state.ground_acceleration * delta)
		else:
			# Reduced control when trying to push into wall
			body.velocity.x = move_toward(body.velocity.x, 0, inbetween_state.ground_deceleration * delta)
	else:
		body.velocity.x = move_toward(body.velocity.x, 0, inbetween_state.ground_deceleration * delta)

static func get_state_name() -> StringName:
	return &"Wall"
