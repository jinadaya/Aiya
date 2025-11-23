shader_type canvas_item;

// Параметры дюн
uniform float scale : hint_range(0.1, 10.0) = 2.0;
uniform float height : hint_range(0.1, 2.0) = 1.0;
uniform float detail : hint_range(1.0, 10.0) = 3.0;
uniform float wind_direction : hint_range(0.0, 6.28318) = 0.785;
uniform float time_speed : hint_range(0.0, 1.0) = 0.05;

// Параметры акварельного эффекта
uniform float watercolor_bleeding : hint_range(0.0, 0.5) = 0.15; // Растекание краски
uniform float paper_texture_strength : hint_range(0.0, 1.0) = 0.3;
uniform float color_variation : hint_range(0.0, 0.5) = 0.2;
uniform float edge_irregularity : hint_range(0.0, 1.0) = 0.4;

// Параметры волнистых краёв
uniform float edge_wave_amplitude : hint_range(0.0, 0.5) = 0.15;
uniform float edge_wave_frequency : hint_range(0.1, 10.0) = 4.0;
uniform float edge_softness : hint_range(0.0, 0.5) = 0.2;

// Акварельная палитра песка
uniform vec3 sand_light : source_color = vec3(0.98, 0.92, 0.78);
uniform vec3 sand_mid : source_color = vec3(0.90, 0.82, 0.65);
uniform vec3 sand_dark : source_color = vec3(0.75, 0.65, 0.50);
uniform vec3 sand_shadow : source_color = vec3(0.55, 0.48, 0.40);

// Функция хеша
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

// Улучшенный шум
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Фрактальный шум
float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    for(int i = 0; i < 5; i++) {
        value += amplitude * noise(p * frequency);
        frequency *= 2.0;
        amplitude *= 0.5;
    }
    
    return value;
}

// Турбулентность для акварельного эффекта
float turbulence(vec2 p) {
    float t = 0.0;
    float f = 1.0;
    for(int i = 0; i < 4; i++) {
        t += abs(noise(p * f)) / f;
        f *= 2.0;
    }
    return t;
}

// Текстура бумаги
float paper_texture(vec2 uv) {
    float paper = fbm(uv * 50.0);
    paper += noise(uv * 200.0) * 0.3;
    return paper;
}

// Генерация формы дюны
float dune_shape(vec2 uv) {
    vec2 wind_vec = vec2(cos(wind_direction), sin(wind_direction));
    
    // Добавляем органическое искажение для акварельного вида
    vec2 distorted_uv = uv + vec2(
        turbulence(uv * 3.0 + TIME * time_speed) * watercolor_bleeding,
        turbulence(uv * 3.0 + vec2(5.2, 1.3) + TIME * time_speed) * watercolor_bleeding
    );
    
    float dune_noise = fbm(distorted_uv * scale + wind_vec * TIME * time_speed * 0.5);
    float detail_noise = fbm(distorted_uv * scale * detail * 0.5);
    
    float asymmetry = smoothstep(0.3, 0.7, dune_noise) * 0.3;
    
    float dune = dune_noise * height;
    dune += detail_noise * 0.2 * height;
    dune *= (1.0 + asymmetry);
    
    return dune;
}

// Вычисление нормали
vec3 calculate_normal(vec2 uv, float epsilon) {
    float h = dune_shape(uv);
    float hx = dune_shape(uv + vec2(epsilon, 0.0));
    float hy = dune_shape(uv + vec2(0.0, epsilon));
    
    vec2 gradient = vec2(hx - h, hy - h) / epsilon;
    return normalize(vec3(-gradient.x, -gradient.y, 1.0));
}

// Волнистые неровные края (акварельные)
float wavy_edge(vec2 uv) {
    vec2 edge_dist = min(uv, 1.0 - uv);
    float dist_to_edge = min(edge_dist.x, edge_dist.y);
    
    // Органические волны с неровностями
    float angle = atan(uv.y - 0.5, uv.x - 0.5);
    float perimeter = length(uv - 0.5) * 6.28318;
    
    float wave = sin(angle * edge_wave_frequency + TIME * time_speed * 2.0) * 0.5 + 0.5;
    wave += turbulence(vec2(perimeter, angle) * 3.0) * edge_irregularity;
    wave *= edge_wave_amplitude;
    
    // Добавляем неровности характерные для акварели
    float irregularity = turbulence(uv * 10.0 + TIME * time_speed) * 0.1 * edge_irregularity;
    
    float edge_threshold = wave + irregularity;
    
    // Мягкий размытый край как у акварели
    float alpha = smoothstep(edge_threshold - edge_softness * 2.0, edge_threshold + edge_softness, dist_to_edge);
    
    // Дополнительная неравномерность прозрачности на краях
    alpha *= 0.85 + noise(uv * 20.0) * 0.15;
    
    return alpha;
}

void fragment() {
    vec2 uv = UV;
    
    // Волнистая маска краёв
    float edge_alpha = wavy_edge(uv);
    
    // Генерируем высоту дюны
    float dune_height = dune_shape(uv);
    
    // Вычисляем нормаль для мягкого освещения
    vec3 normal = calculate_normal(uv, 0.01);
    
    // Мягкое рассеянное освещение (как у акварели)
    vec3 light_dir = normalize(vec3(0.4, 0.6, 1.0));
    float light = max(dot(normal, light_dir), 0.0);
    light = pow(light, 0.7); // Смягчаем контраст
    
    // Ambient occlusion
    float ao = smoothstep(0.0, 0.6, dune_height);
    
    // Цветовые вариации как у акварели
    float color_noise = fbm(uv * 8.0 + TIME * time_speed * 0.3);
    vec3 color_shift = vec3(
        color_noise * color_variation,
        color_noise * color_variation * 0.8,
        color_noise * color_variation * 0.6
    );
    
    // Выбираем цвет с плавными переходами
    vec3 color;
    float light_smooth = smoothstep(0.3, 0.9, light);
    
    if (light_smooth > 0.66) {
        color = mix(sand_mid, sand_light, (light_smooth - 0.66) / 0.34);
    } else if (light_smooth > 0.33) {
        color = mix(sand_dark, sand_mid, (light_smooth - 0.33) / 0.33);
    } else {
        color = mix(sand_shadow, sand_dark, light_smooth / 0.33);
    }
    
    // Применяем цветовые вариации
    color += color_shift;
    
    // Ambient occlusion
    color *= 0.6 + 0.4 * ao;
    
    // Текстура бумаги
    float paper = paper_texture(uv);
    color = mix(color, color * paper, paper_texture_strength);
    
    // Эффект растекания краски (больше пигмента в тенях)
    float pigment_density = 1.0 - light_smooth * 0.3;
    color *= pigment_density;
    
    // Небольшие пятна как у акварели
    float spots = smoothstep(0.7, 0.9, noise(uv * 30.0));
    color = mix(color, color * 0.85, spots * 0.2);
    
    // Финальная прозрачность с градиентом на краях
    float final_alpha = edge_alpha;
    
    // Неравномерная прозрачность как у акварели
    final_alpha *= 0.75 + turbulence(uv * 5.0) * 0.25;
    
    COLOR = vec4(color, final_alpha);
}