shader_type canvas_item;

// Blur intensity control
uniform float blur_amount : hint_range(0.0, 10.0) = 1.0;

void fragment() {
    // Get the texture pixel size
    vec2 pixel_size = TEXTURE_PIXEL_SIZE * blur_amount;
    
    // Sample the texture multiple times with offsets for blur effect
    vec4 color = vec4(0.0);
    
    // 9-tap Gaussian blur kernel
    // Center
    color += texture(TEXTURE, UV) * 0.2;
    
    // Adjacent pixels
    color += texture(TEXTURE, UV + vec2(-pixel_size.x, 0.0)) * 0.12;
    color += texture(TEXTURE, UV + vec2(pixel_size.x, 0.0)) * 0.12;
    color += texture(TEXTURE, UV + vec2(0.0, -pixel_size.y)) * 0.12;
    color += texture(TEXTURE, UV + vec2(0.0, pixel_size.y)) * 0.12;
    
    // Diagonal pixels
    color += texture(TEXTURE, UV + vec2(-pixel_size.x, -pixel_size.y)) * 0.08;
    color += texture(TEXTURE, UV + vec2(pixel_size.x, -pixel_size.y)) * 0.08;
    color += texture(TEXTURE, UV + vec2(-pixel_size.x, pixel_size.y)) * 0.08;
    color += texture(TEXTURE, UV + vec2(pixel_size.x, pixel_size.y)) * 0.08;
    
    // Apply modulate color to preserve self_modulate control
    COLOR = color * COLOR;
}