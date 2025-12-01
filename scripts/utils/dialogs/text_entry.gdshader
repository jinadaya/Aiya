shader_type canvas_item;

// Per-character reveal progress (0.0 to text length)
uniform float reveal_position : hint_range(0.0, 1000.0) = 0.0;
uniform float char_transition_width = 3.0; // How many characters transition at once
uniform float slide_distance = 20.0;

void vertex() {
	// Calculate which character this vertex belongs to (approximation based on X position)
	float char_index = UV.x * 100.0; // Approximate character position
	
	// Calculate how revealed this character is
	float char_progress = reveal_position - char_index;
	char_progress = clamp(char_progress / char_transition_width, 0.0, 1.0);
	
	// Smooth step for nicer transitions
	char_progress = smoothstep(0.0, 1.0, char_progress);
	
	// Move vertex down based on progress (starts below, moves up)
	float y_offset = (1.0 - char_progress) * slide_distance;
	VERTEX.y += y_offset;
}

void fragment() {
	// Calculate which character this pixel belongs to
	float char_index = UV.x * 100.0;
	
	// Calculate reveal progress for this character
	float char_progress = reveal_position - char_index;
	char_progress = clamp(char_progress / char_transition_width, 0.0, 1.0);
	char_progress = smoothstep(0.0, 1.0, char_progress);
	
	// Sample texture
	COLOR = texture(TEXTURE, UV) * COLOR;
	
	// Apply fade
	COLOR.a *= char_progress;
}