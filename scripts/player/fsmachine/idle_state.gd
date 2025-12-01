extends PlayerState
class_name IdleState

func enter(from: PlayerState) -> void:
	inbetween_state.reset_air_jumps()
	inbetween_state.reset_coyote()
	if playback:
		if from is FallState:
			playback.travel("landing")
			await playback.state_finished
		if abs(body.velocity.x) > 0:
			playback.travel("end_run")
		else:
			playback.travel("idle")

func physics_process(delta: float) -> void:
	# Keep coyote timer fresh
	inbetween_state.reset_coyote()
	
	# Handle jump input
	handle_jump_input()
	
	# Check for buffered jump or immediate jump
	if inbetween_state.can_buffer_jump() and body.is_on_floor():
		execute_jump()
		transitioned.emit(self, AirState.get_state_name())
		return
	
	# Transition to walking if moving
	if InputManager.get_x_axis() != 0:
		transitioned.emit(self, WalkingState.get_state_name())
		return
	
	# Fall off platform
	if not body.is_on_floor():
		var to_state = FallState.get_state_name()
		transitioned.emit(self, to_state)
		return
	
	# Apply deceleration
	apply_horizontal_movement(delta)

static func get_state_name() -> StringName:
	return &"Idle"
