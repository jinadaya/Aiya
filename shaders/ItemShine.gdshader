shader_type canvas_item;
render_mode blend_premul_alpha;

// Shine effect uniforms
uniform vec4 shine_color : source_color = vec4(1.0);
uniform float shine_angle : hint_range(0.0, 180.0, 0.1) = 45.0;
uniform float shine_speed : hint_range(0.01, 10.0, 0.01) = 0.3;
uniform float shine_delay : hint_range(0.0, 5.0, 0.1) = 0.0;
uniform bool shine_reverse = false;
uniform float Line_Width : hint_range(0.0, 0.2) = 0.09;
uniform float Line_Smoothness : hint_range(0.001, 0.1) = 0.045;
uniform float Brightness : hint_range(0.0, 10.0) = 3.0;
uniform float Distortion : hint_range(1.0, 3.0) = 2.0;
uniform float LensStrength : hint_range(0.0, 0.1) = 0.05;

// Blue glow uniforms
uniform vec3 glow_color : source_color = vec3(0.2, 0.6, 1.0);
uniform float glow_intensity : hint_range(0.0, 5.0) = 2.5;
uniform float glow_spread : hint_range(0.0, 0.1) = 0.03;
uniform float pulse_speed : hint_range(0.1, 10.0) = 2.0;
uniform float pulse_min : hint_range(0.0, 1.0) = 0.4;
uniform float pulse_max : hint_range(0.0, 2.0) = 1.2;
uniform float blue_threshold : hint_range(0.0, 1.0) = 0.3;
uniform float blue_sensitivity : hint_range(1.0, 10.0) = 3.0;

// Toggle effects
uniform bool enable_shine = true;
uniform bool enable_glow = true;

void fragment() {
    vec2 uv = UV;
    vec4 base_color = texture(TEXTURE, uv);
    vec3 final_color = base_color.rgb;
    
    // === SHINE EFFECT ===
    if (enable_shine) {
        float angle_rad = radians(shine_angle);
        vec2 shine_dir = normalize(vec2(cos(angle_rad), -sin(angle_rad)));
        vec2 shine_normal = vec2(-shine_dir.y, shine_dir.x);
        
        vec2 center_uv = uv - vec2(0.5);
        float gradient_to_edge = max(abs(center_uv.x), abs(center_uv.y));
        gradient_to_edge = 1.0 - gradient_to_edge * Distortion;
        gradient_to_edge = clamp(gradient_to_edge, 0.0, 1.0);
        
        float cycle_duration = (1.0 / shine_speed) + shine_delay;
        float time_in_cycle = mod(TIME, cycle_duration);
        float shine_progress = clamp(time_in_cycle * shine_speed, 0.0, 1.0);
        
        if (shine_reverse) {
            shine_progress = 1.0 - shine_progress;
        }
        
        float max_offset = 1.5;
        float offset = mix(-max_offset, max_offset, shine_progress);
        vec2 shine_origin = vec2(0.5) + shine_normal * offset;
        
        float distance = dot(uv - shine_origin, shine_normal);
        float smoothness = clamp(Line_Smoothness, 0.001, 1.0);
        float half_width = Line_Width * 0.5;
        float shine = smoothstep(-half_width - smoothness, -half_width, distance) -
                      smoothstep(half_width, half_width + smoothness, distance);
        
        vec2 lens_offset = shine * LensStrength * shine_normal;
        base_color = texture(TEXTURE, uv + lens_offset);
        
        shine *= base_color.a;
        float final_intensity = shine * gradient_to_edge * Brightness;
        final_intensity = clamp(final_intensity, 0.0, shine_color.a);
        
        final_color = mix(base_color.rgb, shine_color.rgb, final_intensity);
    }
    
    // === BLUE GLOW EFFECT ===
    if (enable_glow) {
        float pulse = pulse_min + (pulse_max - pulse_min) * 
                      (sin(TIME * pulse_speed) * 0.5 + 0.5);
        
        float blue_amount = base_color.b * (1.0 - base_color.r * 0.5) * (1.0 - base_color.g * 0.5);
        blue_amount = smoothstep(blue_threshold, blue_threshold + 0.2, blue_amount);
        blue_amount = pow(blue_amount, 1.0 / blue_sensitivity);
        
        vec4 glow = vec4(0.0);
        float total_weight = 0.0;
        
        for(float layer = 1.0; layer <= 3.0; layer += 1.0) {
            float radius = glow_spread * layer * pulse;
            int samples = int(4.0 + layer * 2.0);
            
            for(int i = 0; i < samples; i++) {
                float angle = float(i) * 6.28318 / float(samples);
                vec2 offset = vec2(cos(angle), sin(angle)) * radius;
                
                vec4 sample_color = texture(TEXTURE, uv + offset);
                float sample_blue = sample_color.b * sample_color.a;
                
                float weight = sample_blue / (layer * layer);
                glow.rgb += glow_color * weight;
                total_weight += weight;
            }
        }
        
        if(total_weight > 0.0) {
            glow.rgb /= total_weight;
        }
        
        vec3 inner_glow = glow.rgb * blue_amount * glow_intensity * pulse * base_color.a;
        final_color += glow_color * blue_amount * 0.3 * pulse;
        final_color += inner_glow;
        
        float edge_detection = 0.0;
        for(int i = 0; i < 8; i++) {
            float angle = float(i) * 6.28318 / 8.0;
            vec2 offset = vec2(cos(angle), sin(angle)) * TEXTURE_PIXEL_SIZE * 2.0;
            edge_detection += (1.0 - texture(TEXTURE, uv + offset).a) * base_color.a;
        }
        edge_detection = min(edge_detection, 1.0);
        final_color += glow_color * edge_detection * blue_amount * pulse * 0.5;
    }
    
    if (base_color.a <= 0.0) {
        discard;
    }
    
    COLOR = vec4(final_color, base_color.a);
}