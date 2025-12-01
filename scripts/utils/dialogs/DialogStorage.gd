extends Node

# Dialog entity types
enum DialogEntities {
	NARRATOR,
	PLAYER,
	OWL,
	CAT,
	CROW,
}

var entities : Dictionary[ DialogEntities, String ] = {
	DialogEntities.NARRATOR : "NARRATOR",
	DialogEntities.PLAYER : "PLAYER",
	DialogEntities.OWL : "OWL",
	DialogEntities.CAT : "CAT",
	DialogEntities.CROW : "CROW",
}

# Entity name to enum mapping
const ENTITY_NAME_MAP = {
	"NARRATOR": DialogEntities.NARRATOR,
	"PLAYER": DialogEntities.PLAYER,
	"OWL": DialogEntities.OWL,
	"CAT": DialogEntities.CAT,
	"CROW": DialogEntities.CROW,
}

# Typed dialog node class
class DialogNode:
	var entity: DialogEntities
	var text: String
	var options: Array[int] = []
	var anchor_reachable: bool = false
	var preview: String = ""
	var metadata: Dictionary = {}  # For custom data like conditions, actions, etc.
	var entity_display_name: String = ""
	var is_last: bool = false
	var font: String = ""
	
	func _init(data: Dictionary) -> void:
		# Parse entity (can be int or string)
		if data.has("entity_name"):
			if typeof(data["entity_name"]) == TYPE_INT:
				entity = data["entity_name"]
			elif typeof(data["entity_name"]) == TYPE_STRING:
				# Convert string to enum using dictionary lookup
				@warning_ignore("unsafe_method_access", "untyped_declaration")
				var entity_str = data["entity_name"].to_upper()
				entity = ENTITY_NAME_MAP.get(entity_str, DialogEntities.NARRATOR)
		else:
			entity = DialogEntities.NARRATOR
		
		text = data.get("text", "")
		preview = data.get("preview", "")
		anchor_reachable = data.get("anchor_reachable", false)
		entity_display_name = data.get("display_name", "Unknown")
		is_last = data.get("last", false)
		font = data.get("font", "")
		
		# Parse options array
		if data.has("options") and data["options"] is Array:
			for opt : int in data["options"]:
				options.append(int(opt))
		
		# Store any extra data
		metadata = data.get("metadata", {})
	
	func has_options() -> bool:
		return not options.is_empty()
	
	func is_valid() -> bool:
		return not text.is_empty()

# UI dialog class for communication with UI
class UiDialog:
	var font: String
	var id: int
	var display_name: String
	var entity: String
	var text: String
	var previews: Array[String]
	
	func _init(m_font: String, m_id: int, m_display_name: String, m_entity_name: String, m_text: String, m_previews: Array[String]) -> void:
		font = m_font
		id = m_id
		display_name = m_display_name
		entity = m_entity_name
		text = m_text
		previews = m_previews


# Dialog tree data
var dialogs: Array[DialogNode] = []
var finish_node: DialogNode = DialogNode.new({
	"entity_name": "",
	"text": "end of dialog",
	"preview": "Continue",
	"options": [],
	"anchor_reachable": true,
	"display_name": "",
})
var dialog_tree_head: int = 0
var current_dialog_node: int = 0
var dialog_history: Array[int] = []

# Signals
signal dialog_node_changed(dialog: UiDialog)
signal dialog_ended(was_anchor: bool)

# Load dialog tree from JSON file
func load_dialog_tree(path: String) -> bool:
	dialog_tree_head = 0
	current_dialog_node = 0
	dialog_history.clear()
	dialogs.clear()
	
	var json_file := FileAccess.open(path, FileAccess.READ)
	if not json_file:
		push_error("DialogTree: Cannot load json: ", path)
		return false
	
	var json_content := json_file.get_as_text()
	json_file.close()
	
	var json_obj : Array = JSON.parse_string(json_content)
	if not json_obj or not json_obj is Array:
		push_error("DialogTree: Cannot parse json or invalid format (expected Array)")
		return false
	
	# Convert JSON dictionaries to DialogNode objects
	for i in range(json_obj.size()):
		var dialog_data : Dictionary = json_obj[i]
		if not dialog_data is Dictionary:
			push_error("DialogTree: Dialog node %d is not a Dictionary" % i)
			return false
		
		var node : DialogNode = DialogNode.new(dialog_data)
		dialogs.append(node)
	
	# Validate dialog tree
	if not validate_dialog_tree():
		return false
	
	print("DialogTree: Loaded %d dialog nodes from %s" % [dialogs.size(), path])
	
	for dialog in dialogs:
		if dialog.is_last:
			dialog.options.append(len(dialogs))
	dialogs.append(finish_node)
	return true

# Validate the entire dialog tree
func validate_dialog_tree() -> bool:
	if dialogs.is_empty():
		push_error("DialogTree: Dialog tree is empty")
		return false
	
	for i in range(dialogs.size()):
		var node := dialogs[i]
		
		# Check if node is valid
		if not node.is_valid():
			push_error("DialogTree: Node %d has empty text" % i)
			return false
		
		# Validate option indices
		for opt_idx in node.options:
			if opt_idx < 0 or opt_idx >= dialogs.size():
				push_error("DialogTree: Node %d has invalid option index: %d" % [i, opt_idx])
				return false
			
			# Check if target node has preview text
			if dialogs[opt_idx].preview.is_empty():
				push_warning("DialogTree: Node %d (option from %d) missing preview text" % [opt_idx, i])
	
	return true

# Start the dialog from the head
func start_dialog() -> void:
	current_dialog_node = dialog_tree_head
	dialog_history.clear()
	emit_current_dialog()

# Emit current dialog to UI
func emit_current_dialog() -> void:
	if current_dialog_node >= dialogs.size():
		push_error("DialogTree: Invalid current_dialog_node: %d" % current_dialog_node)
		return
	
	var current := dialogs[current_dialog_node]
	var entity_name : String = entities.get(current.entity, "Unknown")
	var display_name : String = dialogs[current_dialog_node].entity_display_name
	var font : String = dialogs[current_dialog_node].font
	
	# Collect previews for options
	var previews: Array[String] = []
	for opt_idx in current.options:
		if opt_idx < dialogs.size():
			previews.append(dialogs[opt_idx].preview)
	
	var ui_dialog := UiDialog.new(font, current_dialog_node, display_name, entity_name, current.text, previews)
	dialog_node_changed.emit(ui_dialog)
	
	# Check if dialog ended
	if not current.has_options():
		var is_anchor := current.anchor_reachable
		if is_anchor:
			dialog_tree_head = current_dialog_node
		dialog_ended.emit(is_anchor)

# Handle user selecting an option (0-based index into current options)
func select_option(option_index: int) -> bool:
	if current_dialog_node >= dialogs.size():
		push_error("DialogTree: Invalid current_dialog_node")
		return false
	
	var current := dialogs[current_dialog_node]
	
	if option_index < 0 or option_index >= current.options.size():
		push_error("DialogTree: Invalid option index %d (available: %d)" % [option_index, current.options.size()])
		return false
	
	# Save to history for potential back navigation
	dialog_history.append(current_dialog_node)
	
	# Move to selected dialog node
	current_dialog_node = current.options[option_index]
	
	# Emit the new dialog
	emit_current_dialog()
	return true

# Go back to previous dialog (if history exists)
func go_back() -> bool:
	if dialog_history.is_empty():
		return false
	
	current_dialog_node = dialog_history.pop_back()
	emit_current_dialog()
	return true

# Get current dialog node
func get_current_node() -> DialogNode:
	if current_dialog_node >= 0 and current_dialog_node < dialogs.size():
		return dialogs[current_dialog_node]
	return null

# Get current dialog node options
func get_options_for_current() -> Array[String]:
	if current_dialog_node >= dialogs.size():
		return []
	var node := dialogs[current_dialog_node]
	var options_texts : Array = []
	for opt in node.options:
		options_texts.append(dialogs[opt].preview)
	return options_texts

# Check if can go back
func can_go_back() -> bool:
	return not dialog_history.is_empty()

# Reset to beginning
func reset() -> void:
	current_dialog_node = dialog_tree_head
	dialog_history.clear()
