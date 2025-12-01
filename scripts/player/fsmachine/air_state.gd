extends PlayerState
class_name AirState

func enter(from: PlayerState) -> void:
	if body.velocity.y > 0:
		playback.travel("mid_air")
	elif body.velocity.y < 0:
		playback.travel("jump_start")
		
	# Only set buffer if coming from non-grounded state
	if from and (from is IdleState or from is WalkingState):
		inbetween_state.buffer_jump_timer = 0

func physics_process(delta: float) -> void:
	super.physics_process(delta)
	# Handle jump input for air jumps
	handle_jump_input()
	
	# Transition to fall when velocity turns downward
	if body.velocity.y > 0:
		transitioned.emit(self, FallState.get_state_name())
		return
	
	# Land on ground
	if try_transition_on_floor():
		return
	
	# Hit wall
	if try_transition_on_wall():
		return
	
	# Handle jumps (priority: wall > coyote > air)
	handle_jump_with_priority()
	
	# Apply variable jump height (cut jump short if button released early)
	if not inbetween_state.is_jump_held and body.velocity.y < 0:
		body.velocity.y *= inbetween_state.jump_cut_multiplier
		inbetween_state.is_jump_held = false  # Prevent multiple cuts
	
	# Apply gravity and horizontal movement
	apply_gravity(delta, false)
	apply_horizontal_movement(delta)

static func get_state_name() -> StringName:
	return &"Air"
