extends Node
class_name DebugNode

var debug_settings : Dictionary[String, bool] = {}

func _init() -> void:
	_init_debug_settings()
	if debug_settings.get("_init", false):
		print(_get_node_debug_name() + " is created")

func _ready() -> void:
	if debug_settings.get("_ready", false):
		print(_get_node_debug_name() + "'s ready is called")

func _process(delta: float) -> void:
	if debug_settings.get("_process", false):
		print(_get_node_debug_name() + "'s process is called. Delta = " + str(delta))

func _get_node_debug_name() -> String:
	return "DebugNode"

func _init_debug_settings() -> void:
	pass
