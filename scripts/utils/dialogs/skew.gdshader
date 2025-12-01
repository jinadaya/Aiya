shader_type canvas_item; 
uniform float skew_x : hint_range(-2.0, 2.0, 0.01) = 0.0; 
uniform float skew_y : hint_range(-2.0, 2.0, 0.01) = 0.0; 
uniform float animation_speed = 1.0; 
uniform float animation_amplitude_x : hint_range(0.0, 2.0, 0.01) = 0.5; 
uniform float animation_amplitude_y : hint_range(0.0, 2.0, 0.01) = 0.0; 
uniform float wave_frequency : hint_range(0.0, 10.0, 0.1) = 1.0; 
uniform int animation_type : hint_range(0, 4) = 0; 
uniform vec2 pivot = vec2(0.5, 0.5); 
uniform vec2 scale = vec2(1.0, 1.0); 
uniform bool vertical_wave = true; 

void fragment() { 
	float time_factor = TIME * animation_speed; 
	float wave_position = vertical_wave ? UV.y : UV.x; 
	float wave = time_factor + wave_position * wave_frequency; 
	float animated_skew_x = skew_x; 
	float animated_skew_y = skew_y; 
	if (animation_type == 0) { 
		animated_skew_x += sin(wave) * animation_amplitude_x; 
		animated_skew_y += sin(wave) * animation_amplitude_y; 
	} else if (animation_type == 1) { 
		animated_skew_x += cos(wave) * animation_amplitude_x;
		animated_skew_y += cos(wave) * animation_amplitude_y;
	} 
	else if (animation_type == 2) { 
		animated_skew_x += abs(sin(wave)) * animation_amplitude_x;
		animated_skew_y += abs(sin(wave)) * animation_amplitude_y;
	} else if (animation_type == 3) {
		float pendulum = sin(wave) * sin(wave) * sign(sin(wave));
		animated_skew_x += pendulum * animation_amplitude_x;
		animated_skew_y += pendulum * animation_amplitude_y; 
	} else if (animation_type == 4) { float elastic = sin(wave * 2.0) * exp(-abs(sin(wave)) * 2.0); animated_skew_x += elastic * animation_amplitude_x; animated_skew_y += elastic * animation_amplitude_y; } vec2 uv = UV - pivot; vec2 skewed_uv; skewed_uv.x = uv.x + (uv.y * animated_skew_x); skewed_uv.y = uv.y + (uv.x * animated_skew_y); skewed_uv *= scale; skewed_uv += pivot; if (skewed_uv.x >= 0.0 && skewed_uv.x <= 1.0 && skewed_uv.y >= 0.0 && skewed_uv.y <= 1.0) { COLOR = texture(TEXTURE, skewed_uv) * COLOR; } else { COLOR = vec4(0.0); } }