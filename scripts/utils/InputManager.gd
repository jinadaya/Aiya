extends DebugNode

enum Action {
	MOVE_LEFT,
	MOVE_RIGHT,
	JUMP,
	DOWN,
	VOICE,
	STONE
}

func get_action(act: Action) -> String:
	match act:
		Action.MOVE_LEFT: return "move_left"
		Action.MOVE_RIGHT: return "move_right"
		Action.JUMP: return "jump"
		Action.VOICE: return "voice"
		Action.STONE: return "stone"
		Action.DOWN: return "down"
		_: return ""

func is_just_pressed(act : Action) -> bool:
	return Input.is_action_just_pressed(get_action(act))

func is_just_released(act : Action) -> bool:
	return Input.is_action_just_released(get_action(act))

func is_pressed(act : Action) -> bool:
	return Input.is_action_pressed(get_action(act))

func get_axis(negative: Action, positive: Action) -> float:
	return Input.get_axis(get_action(negative), get_action(positive))

func get_x_axis() -> float:
	return get_axis(Action.MOVE_LEFT, Action.MOVE_RIGHT)

func get_y_axis() -> float:
	return get_axis(Action.JUMP, Action.DOWN)

func is_jumping() -> bool:
	return Input.is_action_pressed("jump")

func is_jumped() -> bool:
	return Input.is_action_just_pressed("jump")

func vibrate(weak: float, strong: float, duration: float) -> void:
	Input.start_joy_vibration(0, weak, strong, duration)
