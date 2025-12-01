extends CanvasLayer
# Generally a class that can make transitions with fade effect and blur effect.

@export var fade_duration: float = 1.0
@export var blur_duration: float = 0.8
@export var text_display_time: float = 2.0
@export var max_blur_amount: float = 5.0

var color_rect: ColorRect
var blur_rect: ColorRect
var label: Label
var is_fading: bool = false
var container: PanelContainer

signal faded_out
signal faded_in
signal blurred_out
signal blurred_in

func _ready() -> void:
	# Create blur rect first (bottom layer)
	if not blur_rect:
		blur_rect = ColorRect.new()
		blur_rect.name = "BlurRect"
		blur_rect.anchor_right = 1.0
		blur_rect.anchor_bottom = 1.0
		blur_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		blur_rect.visible = false
		add_child(blur_rect)
		
		# Create and assign blur shader
		var shader = Shader.new()
		shader.code = """
shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 0.3) = 0.0;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec4 color = vec4(0.0);
	
	// Simple box blur
	float blur = blur_amount / 100.0;
	int samples = 8;
	
	for(int x = -samples; x <= samples; x++) {
		for(int y = -samples; y <= samples; y++) {
			vec2 offset = vec2(float(x), float(y)) * blur;
			color += texture(screen_texture, uv + offset);
		}
	}
	
	int total_samples = (samples * 2 + 1);
	color /= float(total_samples * total_samples);
	
	COLOR = color;
	COLOR.a = 1.0;
}
"""
		var material = ShaderMaterial.new()
		material.shader = shader
		material.set_shader_parameter("blur_amount", 0.0)
		blur_rect.material = material
	
	# Create fade rect (middle layer)
	if not color_rect:
		color_rect = ColorRect.new()
		color_rect.name = "ColorRect"
		color_rect.color = Color(0, 0, 0, 0)
		color_rect.anchor_right = 1.0
		color_rect.anchor_bottom = 1.0
		color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(color_rect)
	
	# Create container with label (top layer)
	if not container:
		container = PanelContainer.new()
		container.name = "TextContainer"
		# Center the container on screen
		container.anchor_left = 0.5
		container.anchor_top = 0.5
		container.anchor_right = 0.5
		container.anchor_bottom = 0.5
		container.grow_horizontal = Control.GROW_DIRECTION_BOTH
		container.grow_vertical = Control.GROW_DIRECTION_BOTH
		# Make container transparent
		container.self_modulate = Color(1, 1, 1, 0)
		container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(container)
		
		# Create label inside container
		label = Label.new()
		label.name = "Label"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.modulate = Color(1, 1, 1, 0)
		# Set custom minimum size for word wrapping
		label.custom_minimum_size = Vector2(860, 0)
		container.add_child(label)
		
		# Apply custom font
		label.add_theme_font_override("font", load("res://theme/fonts/God.ttf"))
		label.add_theme_font_size_override("font_size", 48)
		
		# Make panel background transparent
		var style = StyleBoxEmpty.new()
		container.add_theme_stylebox_override("panel", style)

# Simple fade-out
func fade_out() -> void:
	if is_fading:
		return
	is_fading = true
	
	var tween : Tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, fade_duration)
	await tween.finished
	faded_out.emit()
	
	is_fading = false

# Simple fade-in
func fade_in() -> void:
	if is_fading:
		return
	is_fading = true
	
	var tween : Tween = create_tween()
	tween.tween_property(color_rect, "color:a", 0.0, fade_duration)
	await tween.finished
	faded_in.emit()
	
	is_fading = false

# Blur out (increase blur)
func blur_out() -> void:
	if is_fading:
		return
	is_fading = true
	
	blur_rect.visible = true
	var tween : Tween = create_tween()
	tween.tween_property(blur_rect.material, "shader_parameter/blur_amount", max_blur_amount, blur_duration)
	await tween.finished
	blurred_out.emit()
	
	is_fading = false

# Blur in (decrease blur)
func blur_in() -> void:
	if is_fading:
		return
	is_fading = true
	
	var tween : Tween = create_tween()
	tween.tween_property(blur_rect.material, "shader_parameter/blur_amount", 0.0, blur_duration)
	await tween.finished
	blur_rect.visible = false
	blurred_in.emit()
	
	is_fading = false

# Blur cycle (out then in)
func blur_cycle() -> void:
	await blur_out()
	await blur_in()

# Combined blur and fade out
func blur_fade_out() -> void:
	if is_fading:
		return
	is_fading = true
	
	blur_rect.visible = true
	var tween : Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(blur_rect.material, "shader_parameter/blur_amount", max_blur_amount, blur_duration)
	tween.tween_property(color_rect, "color:a", 1.0, fade_duration)
	await tween.finished
	
	faded_out.emit()
	blurred_out.emit()
	is_fading = false

# Combined blur and fade in
func blur_fade_in() -> void:
	if is_fading:
		return
	is_fading = true
	
	var tween : Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(blur_rect.material, "shader_parameter/blur_amount", 0.0, blur_duration)
	tween.tween_property(color_rect, "color:a", 0.0, fade_duration)
	await tween.finished
	
	blur_rect.visible = false
	faded_in.emit()
	blurred_in.emit()
	is_fading = false

func fade_with_text(text: String) -> void:
	if is_fading:
		return
	is_fading = true
	
	label.text = text
	
	var tween1 : Tween = create_tween()
	tween1.tween_property(color_rect, "color:a", 1.0, fade_duration)
	await tween1.finished
	
	var tween2 : Tween = create_tween()
	tween2.tween_property(label, "modulate:a", 1.0, fade_duration * 0.5)
	await tween2.finished
	
	await get_tree().create_timer(text_display_time).timeout
	
	var tween3 : Tween = create_tween()
	tween3.tween_property(label, "modulate:a", 0.0, fade_duration * 0.5)
	await tween3.finished
	
	is_fading = false
	faded_out.emit()

# Blur with text
func blur_with_text(text: String) -> void:
	if is_fading:
		return
	is_fading = true
	
	label.text = text
	blur_rect.visible = true
	
	var tween1 : Tween = create_tween()
	tween1.tween_property(blur_rect.material, "shader_parameter/blur_amount", max_blur_amount, blur_duration)
	await tween1.finished
	
	var tween2 : Tween = create_tween()
	tween2.tween_property(label, "modulate:a", 1.0, fade_duration * 0.5)
	await tween2.finished
	
	await get_tree().create_timer(text_display_time).timeout
	
	var tween3 : Tween = create_tween()
	tween3.tween_property(label, "modulate:a", 0.0, fade_duration * 0.5)
	await tween3.finished
	
	var tween4 : Tween = create_tween()
	tween4.tween_property(blur_rect.material, "shader_parameter/blur_amount", 0.0, blur_duration)
	await tween4.finished
	
	blur_rect.visible = false
	is_fading = false

func fade_cycle() -> void:
	await fade_out()
	await fade_in()

func set_fade_color(color: Color) -> void:
	color_rect.color = Color(color.r, color.g, color.b, color_rect.color.a)
