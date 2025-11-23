shader_type canvas_item;

// Основные параметры цвета песка
uniform vec3 sand_color_light : source_color = vec3(0.96, 0.89, 0.73);
uniform vec3 sand_color_mid : source_color = vec3(0.88, 0.79, 0.62);
uniform vec3 sand_color_dark : source_color = vec3(0.72, 0.61, 0.45);

// Параметры акварели
uniform float brush_stroke_size : hint_range(1.0, 10.0) = 3.5;
uniform float paper_texture : hint_range(0.0, 1.0) = 0.4;
uniform float pigment_granulation : hint_range(0.0, 1.0) = 0.6;
uniform float edge_darkening : hint_range(0.0, 1.0) = 0.5;

// Затемнение
uniform float gradient_strength : hint_range(0.0, 1.0) = 0.6;
uniform float gradient_start : hint_range(0.0, 1.0) = 0.3;
uniform vec3 shadow_color : source_color = vec3(0.45, 0.38, 0.28);

// Анимация
uniform float time_scale : hint_range(0.0, 0.5) = 0.0;

// Хеш функция
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

// Улучшенный шум
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    
    // Кубическая интерполяция для более гладких переходов
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// Воксельный шум (Voronoi) для имитации гранул пигмента
float voronoi(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    
    float min_dist = 1.0;
    
    for(int y = -1; y <= 1; y++) {
        for(int x = -1; x <= 1; x++) {
            vec2 neighbor = vec2(float(x), float(y));
            vec2 point = hash(i + neighbor) * vec2(1.0, 1.0);
            vec2 diff = neighbor + point - f;
            float dist = length(diff);
            min_dist = min(min_dist, dist);
        }
    }
    
    return min_dist;
}

// Многослойный шум
float fbm(vec2 p, int octaves) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    for(int i = 0; i < octaves; i++) {
        value += amplitude * noise(p * frequency);
        frequency *= 2.0;
        amplitude *= 0.5;
    }
    
    return value;
}

// Имитация мазков кисти
float brush_strokes(vec2 uv, float time) {
    vec2 p = uv * brush_stroke_size;
    
    // Горизонтальные штрихи
    float strokes = fbm(vec2(p.x, p.y * 0.3) + time * 0.1, 3);
    
    // Добавляем случайные завихрения
    float swirls = fbm(p + vec2(noise(p * 0.5) * 2.0, time * 0.05), 2);
    
    return mix(strokes, swirls, 0.4);
}

// Эффект растекания краски (bloom)
float watercolor_bloom(vec2 uv, float time) {
    vec2 p = uv * 2.0;
    
    // Крупные пятна
    float bloom = fbm(p + time * 0.08, 2);
    bloom = smoothstep(0.3, 0.8, bloom);
    
    // Неровные края
    float edges = noise(p * 6.0 + time * 0.15);
    edges = pow(edges, 2.0);
    
    return bloom * (0.7 + edges * 0.3);
}

// Текстура бумаги
float paper_grain(vec2 uv) {
    vec2 p = uv * 50.0;
    float grain = noise(p) * 0.5 + noise(p * 2.0) * 0.3 + noise(p * 4.0) * 0.2;
    return grain;
}

void fragment() {
    // UV масштабируются в зависимости от размера объекта
    vec2 resolution = 1.0 / SCREEN_PIXEL_SIZE;
    vec2 uv = UV * resolution / 100.0; // Делим на 100 для базового масштаба
    
    float time = TIME * time_scale;
    
    // Базовые мазки кисти
    float strokes = brush_strokes(uv, time);
    
    // Эффект растекания
    float bloom = watercolor_bloom(uv, time);
    
    // Гранулы пигмента (характерная особенность акварели)
    float granulation = voronoi(uv * 15.0 + time * 0.1);
    granulation = smoothstep(0.2, 0.8, granulation);
    
    // Вариации цвета
    float color_var1 = fbm(uv * 3.0 + time * 0.05, 4);
    float color_var2 = fbm(uv * 5.0 - time * 0.03, 3);
    
    // Смешиваем цвета песка
    vec3 sand = mix(sand_color_dark, sand_color_mid, strokes);
    sand = mix(sand, sand_color_light, bloom);
    sand = mix(sand, sand_color_mid, color_var1 * 0.3);
    
    // Применяем гранулы пигмента
    sand = mix(sand * 0.85, sand, granulation * (1.0 - pigment_granulation) + pigment_granulation);
    
    // Эффект неровных краев (характерно для акварели)
    float edge_noise = fbm(uv * 8.0, 3);
    sand *= 1.0 - edge_noise * edge_darkening * 0.2;
    
    // Текстура бумаги
    float paper = paper_grain(uv);
    sand += (paper - 0.5) * paper_texture * 0.1;
    
    // ЗАТЕМНЕНИЕ ВНИЗ (используем исходный UV для градиента)
    float gradient = smoothstep(gradient_start, 1.0, UV.y);
    gradient = pow(gradient, 1.5); // Более плавный переход
    
    // Добавляем вариативность в градиент (акварельная неровность)
    float gradient_noise = noise(uv * 4.0 + time * 0.05) * 0.15;
    gradient += gradient_noise;
    gradient = clamp(gradient, 0.0, 1.0);
    
    // Применяем затемнение
    sand = mix(sand, shadow_color, gradient * gradient_strength);
    
    // Небольшая десатурация внизу (как в акварели)
    float desaturate = gradient * 0.3;
    float luminance = dot(sand, vec3(0.299, 0.587, 0.114));
    sand = mix(sand, vec3(luminance), desaturate);
    
    COLOR = vec4(sand, 1.0);
}