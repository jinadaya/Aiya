extends PlayerState
class_name FallState

func physics_process(delta: float) -> void:
	# Handle jump input
	handle_jump_input()
	
	# Land on ground
	if try_transition_on_floor():
		return
	
	# Hit wall
	if try_transition_on_wall():
		return
	
	# Handle air jump while falling
	handle_jump_with_priority()
	
	# Apply gravity with fall multiplier
	apply_gravity(delta, true)
	
	# Apply horizontal movement with air control
	apply_horizontal_movement(delta)

static func get_state_name() -> StringName:
	return &"Fall"
