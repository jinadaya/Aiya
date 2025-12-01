// Save as: olive_green_inner_glow.gdshader
// For 2D sprites - makes olive green pixels glow from inside with pulsing
shader_type canvas_item;

// Glow settings
uniform vec3 glow_color : source_color = vec3(0.447, 0.565, 0.200); // Olive green #729033
uniform float glow_intensity : hint_range(0.0, 5.0) = 2.5;
uniform float glow_spread : hint_range(0.0, 0.1) = 0.03;

// Pulse animation
uniform float pulse_speed : hint_range(0.1, 10.0) = 2.0;
uniform float pulse_min : hint_range(0.0, 1.0) = 0.4;
uniform float pulse_max : hint_range(0.0, 2.0) = 1.2;

// Green detection
uniform float green_threshold : hint_range(0.0, 1.0) = 0.3;
uniform float green_sensitivity : hint_range(1.0, 10.0) = 3.0;

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    
    // Calculate pulsing intensity
    float pulse = pulse_min + (pulse_max - pulse_min) * 
                  (sin(TIME * pulse_speed) * 0.5 + 0.5);
    
    // Detect olive green pixels (#729033 characteristics)
    // Green is dominant, red is moderate (~80% of green), blue is very low
    float green_amount = color.g * (0.3 + color.r * 0.7) * (1.0 - color.b * 0.9);
    green_amount = smoothstep(green_threshold, green_threshold + 0.2, green_amount);
    green_amount = pow(green_amount, 1.0 / green_sensitivity);
    
    // Create inner glow by sampling nearby pixels
    vec4 glow = vec4(0.0);
    float total_weight = 0.0;
    
    // Multi-layer glow for depth
    for(float layer = 1.0; layer <= 3.0; layer += 1.0) {
        float radius = glow_spread * layer * pulse;
        int samples = int(4.0 + layer * 2.0);
        
        for(int i = 0; i < samples; i++) {
            float angle = float(i) * 6.28318 / float(samples);
            vec2 offset = vec2(cos(angle), sin(angle)) * radius;
            
            vec4 sample_color = texture(TEXTURE, UV + offset);
            float sample_green = sample_color.g * sample_color.a;
            
            float weight = sample_green / (layer * layer);
            glow.rgb += glow_color * weight;
            total_weight += weight;
        }
    }
    
    if(total_weight > 0.0) {
        glow.rgb /= total_weight;
    }
    
    // Apply glow to green areas
    vec3 inner_glow = glow.rgb * green_amount * glow_intensity * pulse * color.a;
    
    // Brighten the original green
    color.rgb += glow_color * green_amount * 0.3 * pulse;
    
    // Add the inner glow
    COLOR.rgb = color.rgb + inner_glow;
    COLOR.a = color.a;
    
    // Extra rim light on edges for "from inside" effect
    float edge_detection = 0.0;
    for(int i = 0; i < 8; i++) {
        float angle = float(i) * 6.28318 / 8.0;
        vec2 offset = vec2(cos(angle), sin(angle)) * TEXTURE_PIXEL_SIZE * 2.0;
        edge_detection += (1.0 - texture(TEXTURE, UV + offset).a) * color.a;
    }
    edge_detection = min(edge_detection, 1.0);
    COLOR.rgb += glow_color * edge_detection * green_amount * pulse * 0.5;
}