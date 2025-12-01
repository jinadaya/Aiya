extends DebugNode

var turned_on : bool = true
var m_allowed_actions : Array[Action] = []

enum Action {
	MOVE_LEFT,
	MOVE_RIGHT,
	JUMP,
	DOWN,
	VOICE,
	STONE,
	INTERACT
}

func off(allowed_actions : Array[Action] = []) -> void:
	m_allowed_actions = allowed_actions
	turned_on = false

func on() -> void:
	turned_on = true

func get_action(act: Action) -> String:
	match act:
		Action.MOVE_LEFT: return "move_left"
		Action.MOVE_RIGHT: return "move_right"
		Action.JUMP: return "jump"
		Action.VOICE: return "voice"
		Action.STONE: return "stone"
		Action.DOWN: return "down"
		Action.INTERACT: return "interact"
		_: return ""

func is_just_pressed(act : Action) -> bool:
	if not turned_on and not act in m_allowed_actions: return false
	return Input.is_action_just_pressed(get_action(act))

func is_just_released(act : Action) -> bool:
	if not turned_on and not act in m_allowed_actions: return false
	return Input.is_action_just_released(get_action(act))

func is_pressed(act : Action) -> bool:
	if not turned_on and not act in m_allowed_actions: return false
	return Input.is_action_pressed(get_action(act))

func get_axis(negative: Action, positive: Action) -> float:
	if not turned_on: return false
	return Input.get_axis(get_action(negative), get_action(positive))

func get_x_axis() -> float:
	if not turned_on: return false
	return get_axis(Action.MOVE_LEFT, Action.MOVE_RIGHT)

func get_y_axis() -> float:
	if not turned_on: return false
	return get_axis(Action.JUMP, Action.DOWN)

func is_jumping() -> bool:
	if not turned_on: return false
	return Input.is_action_pressed("jump")

func is_jumped() -> bool:
	if not turned_on: return false
	return Input.is_action_just_pressed("jump")

func vibrate(weak: float, strong: float, duration: float) -> void:
	if not turned_on: return
	Input.start_joy_vibration(0, weak, strong, duration)
