extends PlayerState
class_name WalkingState

var slow_down_decelleration : int = 0

func enter(from: PlayerState) -> void:
	inbetween_state.reset_air_jumps()
	inbetween_state.reset_coyote()
	MusicManager.mute_steps(false)
	MusicManager.play_steps(body.step_material, 0.3, -50)
	if playback:
		if from is FallState:
			playback.travel("landing")
			await playback.state_finished
		if abs(body.velocity.x) == 0:
			playback.travel("start_run")
		else:
			playback.travel("run")

func exit() -> void:
	MusicManager.mute_steps(true)

func physics_process(delta: float) -> void:
	super.physics_process(delta)
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
		var to_state : StringName = FallState.get_state_name()
		transitioned.emit(self, to_state)
		return
	
	# Transition to idle if stopped
	var x_dir : float = InputManager.get_x_axis()
	if x_dir == 0:
		transitioned.emit(self, IdleState.get_state_name())
		return
	
	# Slow donw body
	if slow_down_decelleration != 0:
		slow_down(slow_down_decelleration * delta)
	
	# Apply horizontal movement
	apply_horizontal_movement(delta)

func slow_down_body(axis : int) -> void:
	var walk_dir : int = sign(body.velocity.x)
	if (walk_dir == axis): slow_down_decelleration = axis

static func get_state_name() -> StringName:
	return &"Walking"
