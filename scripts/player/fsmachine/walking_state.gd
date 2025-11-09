extends PlayerState
class_name WalkingState

func enter(_from: PlayerState) -> void:
	inbetween_state.reset_air_jumps()
	inbetween_state.reset_coyote()

func physics_process(delta: float) -> void:
	# Keep coyote timer fresh while grounded
	inbetween_state.reset_coyote()
	
	# Handle jump input
	handle_jump_input()
	
	# Check for buffered or immediate jump
	if inbetween_state.can_buffer_jump() and body.is_on_floor():
		execute_jump()
		transitioned.emit(self, AirState.get_state_name())
		return
	
	# Check if fell off platform
	if not body.is_on_floor():
		var to_state = FallState.get_state_name()
		transitioned.emit(self, to_state)
		return
	
	# Transition to idle if stopped
	var x_dir = InputManager.get_x_axis()
	if x_dir == 0:
		transitioned.emit(self, IdleState.get_state_name())
		return
	
	# Apply horizontal movement
	apply_horizontal_movement(delta)

static func get_state_name() -> StringName:
	return &"Walking"
