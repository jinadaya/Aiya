extends CanvasLayer

# Generally a class that can make transitions with fade effect.

@export var fade_duration: float = 1.0
@export var text_display_time: float = 2.0

var color_rect: ColorRect
var label: Label

var is_fading: bool = false

signal faded_out
signal faded_in

func _ready():
	if not color_rect:
		color_rect = ColorRect.new()
		color_rect.name = "ColorRect"
		color_rect.color = Color(0, 0, 0, 0)
		color_rect.anchor_right = 1.0
		color_rect.anchor_bottom = 1.0
		color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(color_rect)
	
	if not label:
		label = Label.new()
		label.name = "Label"
		label.anchor_left = 0.5
		label.anchor_top = 0.5
		label.anchor_right = 0.5
		label.anchor_bottom = 0.5
		label.pivot_offset = Vector2(0, 0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.modulate = Color(1, 1, 1, 0)
		add_child(label)
		
		label.add_theme_font_size_override("font_size", 48)

# Simple fade-out
func fade_out():
	if is_fading:
		return
	is_fading = true
	
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, fade_duration)
	await tween.finished
	faded_out.emit()
	
	is_fading = false

# Simple fade-in
func fade_in():
	if is_fading:
		return
	is_fading = true
	
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 0.0, fade_duration)
	await tween.finished
	faded_in.emit()
	
	is_fading = false

func fade_with_text(text: String):
	if is_fading:
		return
	is_fading = true
	
	label.text = text
	
	var tween1 = create_tween()
	tween1.tween_property(color_rect, "color:a", 1.0, fade_duration)
	await tween1.finished
	
	var tween2 = create_tween()
	tween2.tween_property(label, "modulate:a", 1.0, fade_duration * 0.5)
	await tween2.finished
	
	await get_tree().create_timer(text_display_time).timeout
	
	var tween3 = create_tween()
	tween3.tween_property(label, "modulate:a", 0.0, fade_duration * 0.5)
	await tween3.finished
	
	var tween4 = create_tween()
	tween4.tween_property(color_rect, "color:a", 0.0, fade_duration)
	await tween4.finished
	
	is_fading = false

func fade_cycle():
	await fade_out()
	await fade_in()

func set_fade_color(color: Color):
	color_rect.color = Color(color.r, color.g, color.b, color_rect.color.a)
