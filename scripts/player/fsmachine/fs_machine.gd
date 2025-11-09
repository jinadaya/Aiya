extends Node
class_name FSMachine

@export var current_state : PlayerState = null
var states : Dictionary [ StringName , PlayerState ]
var inbetween_state = InbetweenState.new()
var body : CharacterBody2D

func _ready() -> void:
	for child in get_children(false):
		if child is PlayerState:
			if not current_state:
				current_state = child
			states[child.get_state_name()] = child
			child.inbetween_state = inbetween_state
			child.transitioned.connect(_state_changed)
		else:
			push_warning(child.name + " in " + self.name + " node.")
	if not current_state:
		push_error("No initial state set in" + str(self))
	else:
		current_state.enter(null)

func process(delta: float) -> void:
	if current_state:
		current_state.process(delta)

func physics_process(delta: float) -> void:
	inbetween_state.dec_timer(delta)
	if current_state:
		current_state.physics_process(delta)
	body.move_and_slide()

func _state_changed(from : PlayerState, to : StringName):
	if from != current_state:
		return
	if from == states[to]:
		return
	
	var new_state = states[to]
	if not new_state:
		return
	
	if current_state:
		print("Player FSMachine: changing state from ", current_state.name)
		current_state.exit()
	new_state.enter(from)
	current_state = new_state
	print("Player FSMachine: changed state to ", current_state.name)

func set_body(new_body : CharacterBody2D):
	body = new_body
	var c_states : Array[PlayerState] = states.values()
	for state in c_states:
		state.set_body(new_body)
