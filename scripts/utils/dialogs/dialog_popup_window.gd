extends Control

signal next_pressed
signal option_selected(num: int)
signal dialog_started
signal dialog_completed

@onready var next_btn: Button = $MarginContainer/HBoxContainer/BtnContainer/BtnNext
@onready var options_container: VBoxContainer = $MarginContainer/HBoxContainer/VBoxContainer/OptionsContainer
@onready var entity_label: Label = $MarginContainer/HBoxContainer/VBoxContainer/EntityName
@onready var dialog_text: RicherTextLabel = $MarginContainer/HBoxContainer/VBoxContainer/DialogText

var is_showing: bool = false
var current_options: Array[Button] = []
var font_helper : FontHelper = FontHelper.new()

func _ready() -> void:
	z_index = 999
	next_btn.pressed.connect(_on_next_pressed)
	if dialog_text.has_signal("animation_finished"):
		dialog_text.animation_finished.connect(_on_dialog_animation_finished)

func set_dialog(dialog: DialogStorage.UiDialog) -> void:
	_clear_previous_dialog()
	
	next_btn.hide()
	
	# Set dialog text
	dialog_text.set_bbcode(dialog.text)
	dialog_text.font = dialog.font
	
	# Set entity name
	entity_label.text = dialog.display_name
	
	# Set options
	_create_options(dialog.previews)
	
	is_showing = true
	dialog_started.emit()

func _clear_previous_dialog() -> void:
	"""Clears the previous dialog content.""" 
	if is_showing:
		dialog_text.clear()
		_remove_all_options()

func _create_options(previews: Array) -> void:
	"""Creates button options from preview text array."""
	current_options.clear()
	
	for i in len(previews):
		var preview: String = previews[i]
		var option: Button = _create_option_button(preview, i)
		options_container.add_child(option)
		current_options.append(option)

func _create_option_button(text: String, index: int) -> Button:
	"""Creates a single option button with animator."""
	var option: Button = Button.new()
	option.add_child(UiAnimator.new())
	option.text = text
	option.pressed.connect(_option_pressed.bind(index))
	return option

func _remove_all_options() -> void:
	"""Removes all option buttons from the container."""
	for option in current_options:
		if is_instance_valid(option):
			option.queue_free()
	current_options.clear()
	
	# Fallback to ensure container is empty
	for child in options_container.get_children():
		options_container.remove_child(child)
		child.queue_free()

func _option_pressed(num: int) -> void:
	"""Handles option button press."""
	# Optionally disable buttons after selection to prevent double-clicks
	_disable_all_options()
	option_selected.emit(num)

func _on_next_pressed() -> void:
	"""Handles next button press."""
	next_pressed.emit()

func _on_dialog_animation_finished() -> void:
	"""Called when dialog text animation completes."""
	# Show next button or enable options after text finishes
	if current_options.is_empty():
		next_btn.show()
	dialog_completed.emit()

func _disable_all_options() -> void:
	"""Disables all option buttons."""
	for option in current_options:
		if is_instance_valid(option):
			option.disabled = true

func _enable_all_options() -> void:
	"""Enables all option buttons."""
	for option in current_options:
		if is_instance_valid(option):
			option.disabled = false

func hide_dialog() -> void:
	"""Hides the dialog system."""
	is_showing = false
	hide()

func show_dialog() -> void:
	"""Shows the dialog system."""
	show()

func skip_text_animation() -> void:
	"""Skips the text reveal animation if supported."""
	if dialog_text.has_method("skip_animation"):
		dialog_text.skip_animation()
