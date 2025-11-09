shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// Параметры волны
uniform float radius : hint_range(0.0, 1.0) = 0.0;
uniform float ring_width : hint_range(0.01, 0.2) = 0.08;
uniform float distortion_strength : hint_range(0.0, 0.05) = 0.02;
uniform float fade_alpha : hint_range(0.0, 1.0) = 1.0;
uniform vec2 wave_center = vec2(0.5, 0.5);

// Параметры визуальных эффектов
uniform vec4 ring_color : source_color = vec4(0.3, 0.6, 1.0, 1.0);
uniform float ring_intensity : hint_range(0.0, 2.0) = 0.8;
uniform float wave_frequency : hint_range(1.0, 50.0) = 20.0;

// Параметры магических искр
uniform vec4 spark_color : source_color = vec4(0.4, 0.8, 1.0, 1.0);
uniform float spark_density : hint_range(1.0, 50.0) = 15.0;
uniform float spark_speed : hint_range(0.0, 5.0) = 2.0;
uniform float spark_intensity : hint_range(0.0, 3.0) = 1.5;

void fragment() {
	vec2 uv = SCREEN_UV;
	
	// Корректируем соотношение сторон для круглого кольца
	vec2 aspect_corrected_uv = uv;
	float aspect = 1.0 / SCREEN_PIXEL_SIZE.x * SCREEN_PIXEL_SIZE.y;
	aspect_corrected_uv.x *= aspect;
	
	vec2 corrected_center = wave_center;
	corrected_center.x *= aspect;
	
	vec2 to_center = aspect_corrected_uv - corrected_center;
	float dist = length(to_center);
	
	// Для искажения используем оригинальное направление
	vec2 original_to_center = uv - wave_center;
	
	// Создаем кольцевую маску
	float inner_edge = radius - ring_width * 0.5;
	float outer_edge = radius + ring_width * 0.5;
	
	float ring = smoothstep(inner_edge - 0.02, inner_edge, dist) * 
	             smoothstep(outer_edge + 0.02, outer_edge, dist);
	
	// Применяем затухание
	ring *= fade_alpha;
	
	// Волновое искажение
	float wave_pattern = sin(dist * wave_frequency - radius * 10.0);
	float distortion = wave_pattern * distortion_strength * ring;
	
	vec2 distorted_uv = uv + normalize(original_to_center) * distortion;
	
	// Получаем цвет с экрана
	vec3 screen_col = texture(SCREEN_TEXTURE, distorted_uv).rgb;
	
	// Создаем магические искры (прожилки)
	float angle = atan(original_to_center.y, original_to_center.x);
	
	// Несколько слоев искр с разными параметрами
	float spark1 = sin(angle * spark_density + TIME * spark_speed) * 
	               sin(dist * spark_density * 2.0 - TIME * spark_speed * 1.5);
	float spark2 = sin(angle * spark_density * 1.3 - TIME * spark_speed * 0.8) * 
	               cos(dist * spark_density * 1.7 + TIME * spark_speed);
	float spark3 = cos(angle * spark_density * 0.7 + TIME * spark_speed * 1.2) * 
	               sin(dist * spark_density * 2.5 - TIME * spark_speed * 0.5);
	
	// Комбинируем искры
	float sparks = (spark1 + spark2 * 0.7 + spark3 * 0.5) * 0.4;
	
	// Применяем искры только в области кольца
	sparks = max(0.0, sparks) * ring * spark_intensity;
	
	// Добавляем голубое свечение искр
	vec3 spark_glow = spark_color.rgb * sparks;
	
	// Только искажение и искры, без видимого кольца
	COLOR = vec4(screen_col + spark_glow, 1.0);
}