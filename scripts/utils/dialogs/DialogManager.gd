extends CanvasLayer

signal dialog_started()
signal dialog_finished()
signal next_dialog_emmited(dialog : DialogStorage.UiDialog)

const DIALOG_PATH: StringName = "dialog_path"
const DIALOG_IS_POPUP: StringName = "is_popup"

enum GameDialogs {
	EnterCave,
	MeetEchoMonster,
	FindStone,
	EnterBeach,
	FoundGate,
	MeetOwl,
	OwlFreed,
	MeetCat,
	CatPassed,
	MeetCrow,
	MeetCreator,
}

# Scene paths
const POPUP_DIALOG_SCENE: String = "res://scripts/utils/dialogs/dialog_popup_window.tscn"
const DEFAULT_DIALOG_SCENE: String = "res://scripts/utils/dialogs/dialog_window.tscn"

var is_dialog_active: bool = false
var current_dialog_windows: Array[Control] = []

# Dialog windows
var dialog_window := preload(DEFAULT_DIALOG_SCENE).instantiate()
var popup_1_dialog_window := preload(POPUP_DIALOG_SCENE).instantiate()
var popup_2_dialog_window := preload(POPUP_DIALOG_SCENE).instantiate()

var current_dialog_path: String

var is_bottom : bool = false

func _ready() -> void:
	self.layer = 999
	DialogStorage.dialog_node_changed.connect(_on_dialog_node_changed)
	DialogStorage.dialog_ended.connect(_on_dialog_ended)
	
	_connect_dialog_signals(popup_1_dialog_window)
	_connect_dialog_signals(popup_2_dialog_window)
	_connect_dialog_signals(dialog_window)
	
	dialog_window.visible = false
	popup_1_dialog_window.visible = false
	popup_2_dialog_window.visible = false
	
	add_child(dialog_window)
	add_child(popup_1_dialog_window)
	add_child(popup_2_dialog_window)
	
	current_dialog_windows.append(dialog_window)

func show_dialog(path: String, bottom: bool = true) -> void:
	is_bottom = bottom
	if is_dialog_active:
		push_warning("DialogManager: Trying to start another dialog, while previous in use.")
		return
	current_dialog_path = path
	
	current_dialog_windows.clear()
	current_dialog_windows.append(dialog_window)

	InputManager.off()
	
	if not DialogStorage.load_dialog_tree(path):
		push_error("DialogManager: Failed to load external dialog: %s" % path)
		return
	
	_create_default_dialog()
	is_dialog_active = true
	
	DialogStorage.start_dialog()

func show_popup_dialog(position_1: Vector2, position_2: Vector2, path: String) -> void:
	if is_dialog_active:
		push_warning("DialogManager: Trying to start another dialog, while previous in use.")
		return
	current_dialog_path = path
	
	current_dialog_windows.append(popup_1_dialog_window)
	current_dialog_windows.append(popup_2_dialog_window)
	
	InputManager.off()
	
	# Load dialog node tree
	if not DialogStorage.load_dialog_tree(path):
		push_error("DialogManager: Failed to load popup external dialog: %s" % path)
		return
	
	_create_popup_dialogs(position_1, position_2)
	is_dialog_active = true
	
	# Start the dialog to emit the first node
	DialogStorage.start_dialog()
	
	dialog_started.emit()

func _create_default_dialog() -> void:
	# Center the dialog or position as needed
	if dialog_window.has_method("center_on_screen"):
		dialog_window.center_on_screen()

func _create_popup_dialogs(position_1: Vector2, position_2: Vector2) -> void:
	var popup_scene: PackedScene = load(POPUP_DIALOG_SCENE)
	if not popup_scene:
		push_error("DialogManager: Failed to load popup dialog scene.")
		return
	
	# Create first popup (for first speaker)
	var popup_1: Control = current_dialog_windows[0]
	popup_1.position = position_1
	
	# Create second popup (for second speaker)
	var popup_2: Control = current_dialog_windows[1]
	popup_2.position = position_2

func _connect_dialog_signals(local_dialog_window: Control) -> void:
	if local_dialog_window.has_signal("next_pressed"):
		local_dialog_window.next_pressed.connect(_on_next_pressed)
	
	if local_dialog_window.has_signal("option_selected"):
		local_dialog_window.option_selected.connect(_on_option_selected)

func _update_dialog_ui(ui_dialog : DialogStorage.UiDialog) -> void:
	# Determine which window should show this dialog based on entity
	var target_window_index: int = _get_window_index_for_entity(ui_dialog.entity)
	
	for i in range(current_dialog_windows.size()):
		var window: Control = current_dialog_windows[i]
		if not is_instance_valid(window):
			continue
		
		if i == target_window_index:
			# This window should display the dialog
			if window.has_method("set_dialog"):
				window.set_dialog(ui_dialog, is_bottom)
			
			# Show this window
			if window.has_method("show_dialog"):
				window.show_dialog()
			else:
				window.show()
		else:
			# Hide other window(s) in popup mode
			if current_dialog_windows.size() > 1:
				if window.has_method("hide_dialog"):
					window.hide_dialog()
				else:
					window.hide()
	
	next_dialog_emmited.emit(ui_dialog)

func _get_window_index_for_entity(entity: String) -> int:
	# For default dialogs (1 window), always use index 0
	if current_dialog_windows.size() == 1:
		return 0
	
	# For popup dialogs (2 windows), alternate based on entity
	# Window 0 (position_1): PLAYER
	# Window 1 (position_2): NPCs (OWL, CAT, CROW) and NARRATOR
	match DialogStorage.ENTITY_NAME_MAP.get(entity):
		DialogStorage.DialogEntities.PLAYER:
			return 0
		DialogStorage.DialogEntities.OWL, \
		DialogStorage.DialogEntities.CAT, \
		DialogStorage.DialogEntities.CROW, \
		DialogStorage.DialogEntities.NARRATOR:
			return 1
		_:
			return 0

func _on_next_pressed() -> void:
	# For nodes without options, this should advance (but DialogStorage handles this via dialog_ended)
	pass

func _on_option_selected(option_num: int) -> void:
	DialogStorage.select_option(option_num)

func _on_dialog_node_changed(ui_dialog: DialogStorage.UiDialog) -> void:
	_update_dialog_ui(ui_dialog)

func _on_dialog_ended(_was_anchor: bool) -> void:
	_cleanup_dialogs()
	is_dialog_active = false
	dialog_finished.emit()
	InputManager.on()

func _cleanup_dialogs() -> void:
	for window in current_dialog_windows:
		window.hide()
	current_dialog_windows.clear()

func force_end_dialog() -> void:
	if is_dialog_active:
		_cleanup_dialogs()
		is_dialog_active = false
