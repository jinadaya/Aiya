extends Control

signal next_pressed
signal option_selected(num: int)
signal dialog_started
signal dialog_completed

@onready var next_btn: Button = $MarginContainer/HBoxContainer/BtnContainer/BtnNext
@onready var options_container: VBoxContainer = $MarginContainer/HBoxContainer/VBoxContainer/OptionsContainer
@onready var entity_label: Label = $MarginContainer/HBoxContainer/VBoxContainer/EntityName
@onready var dialog_text : RichTextAnimation = $MarginContainer/HBoxContainer/VBoxContainer/DialogText

var is_showing: bool = false
var current_options: Array[Button] = []

func _ready() -> void:
	next_btn.pressed.connect(_on_next_pressed)
	if dialog_text.has_signal("animation_finished"):
		dialog_text.animation_finished.connect(_on_dialog_animation_finished)

func set_dialog(dialog: DialogStorage.UiDialog, bottom: bool = true) -> void:
	if not bottom: position.y = get_viewport_rect().size.y * 0.05
	else: position.y = get_viewport_rect().size.y * 0.85
	var font: Font = load("res://theme/fonts/God.ttf")
	_clear_previous_dialog()
	next_btn.hide()
	# Set dialog text
	dialog_text.set_bbcode(dialog.text)
	dialog_text.font = dialog.font
	# Set entity name
	entity_label.text = dialog.display_name
	await dialog_text.anim_finished
	# Set options
	_create_options(dialog.previews)
	is_showing = true
	dialog_started.emit()

func _clear_previous_dialog() -> void:
	if is_showing:
		dialog_text.clear()
		_remove_all_options()

func _create_options(previews: Array) -> void:
	current_options.clear()
	var tween : Tween = create_tween().set_parallel(true)
	
	for i in len(previews):
		var preview: String = previews[i]
		var option: Button = _create_option_button(preview, i)
		option.self_modulate = Color(option.self_modulate.r, option.self_modulate.g, option.self_modulate.b, 0)
		options_container.add_child(option)
		current_options.append(option)
		tween.tween_property(option, "self_modulate:a", 1.0, 0.35)

func _create_option_button(text: String, index: int) -> Button:
	var option: Button = Button.new()
	var animator: UiAnimator = UiAnimator.new()
	animator.anim_rotation = true
	option.add_child(UiAnimator.new())
	option.text = text
	option.pressed.connect(_option_pressed.bind(index))
	return option

func _remove_all_options() -> void:
	for option in current_options:
		if is_instance_valid(option):
			option.queue_free()
	current_options.clear()
	
	for child in options_container.get_children():
		options_container.remove_child(child)
		child.queue_free()

func _option_pressed(num: int) -> void:
	_disable_all_options()
	option_selected.emit(num)

func _on_next_pressed() -> void:
	next_pressed.emit()

func _on_dialog_animation_finished() -> void:
	if current_options.is_empty():
		next_btn.show()
	dialog_completed.emit()

func _disable_all_options() -> void:
	for option in current_options:
		if is_instance_valid(option):
			option.disabled = true

func _enable_all_options() -> void:
	for option in current_options:
		if is_instance_valid(option):
			option.disabled = false

func hide_dialog() -> void:
	is_showing = false
	hide()

func show_dialog() -> void:
	show()

func skip_text_animation() -> void:
	if dialog_text.has_method("skip_animation"):
		dialog_text.skip_animation()
