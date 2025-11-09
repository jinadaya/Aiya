extends ColorRect
class_name StoneAbility

## Компонент для создания эффекта силовой волны вокруг игрока
## Использует полноэкранный шейдер для создания искажающего эффекта

# Параметры анимации волны
@export_group("Wave Animation")
@export var max_radius: float = 0.25  ## Максимальный радиус в UV координатах (0-1)
@export var expansion_speed: float = 0.4  ## Скорость расширения волны
@export var fade_start_percent: float = 0.17  ## С какого процента начинается затухание (0-1)

# Параметры визуального стиля
@export_group("Visual Style")
@export var ring_width: float = 0.08  ## Толщина кольца волны
@export var distortion_strength: float = 0.02  ## Сила искажения экрана
@export var ring_color: Color = Color(0.3, 0.6, 1.0, 1.0)  ## Цвет свечения кольца
@export var ring_intensity: float = 0.8  ## Интенсивность свечения
@export var wave_frequency: float = 25.0  ## Частота волнового паттерна

# Параметры магических искр
@export_group("Magic Sparks")
@export var spark_color: Color = Color(0.4, 0.8, 1.0, 0.7)  ## Цвет искр
@export var spark_density: float = 20.0  ## Плотность искр (1-50)
@export var spark_speed: float = 1.9  ## Скорость движения искр
@export var spark_intensity: float = 0.7  ## Яркость искр

# Внутренние переменные
var _is_active: bool = false
var _current_radius: float = 0.0
var _shader_material: ShaderMaterial

func _ready():
	# Настраиваем ColorRect на весь экран
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Создаем материал с шейдером
	_shader_material = material as ShaderMaterial
	
	if _shader_material:
		_initialize_shader_parameters()
	
	# Изначально скрываем
	visible = false

func _initialize_shader_parameters():
	"""Инициализирует параметры шейдера"""
	_shader_material.set_shader_parameter("radius", 0.0)
	_shader_material.set_shader_parameter("ring_width", ring_width)
	_shader_material.set_shader_parameter("distortion_strength", distortion_strength)
	_shader_material.set_shader_parameter("fade_alpha", 1.0)
	_shader_material.set_shader_parameter("ring_color", ring_color)
	_shader_material.set_shader_parameter("ring_intensity", ring_intensity)
	_shader_material.set_shader_parameter("wave_frequency", wave_frequency)
	_shader_material.set_shader_parameter("spark_color", spark_color)
	_shader_material.set_shader_parameter("spark_density", spark_density)
	_shader_material.set_shader_parameter("spark_speed", spark_speed)
	_shader_material.set_shader_parameter("spark_intensity", spark_intensity)

func _process(delta: float):
	if not _is_active:
		return
	
	_update_wave(delta)

func _update_wave(delta: float):
	"""Обновляет анимацию волны"""
	# Расширяем волну
	_current_radius += expansion_speed * delta
	
	# Вычисляем прогресс (0.0 - 1.0)
	var progress = _current_radius / max_radius
	
	# Обновляем радиус в шейдере
	_shader_material.set_shader_parameter("radius", _current_radius)
	
	# Плавное затухание в конце
	if progress >= fade_start_percent:
		var fade_progress = (progress - fade_start_percent) / (1.0 - fade_start_percent)
		var fade_value = 1.0 - ease(fade_progress, -2.0)  # Ease out
		_shader_material.set_shader_parameter("fade_alpha", fade_value)
	
	# Завершаем волну
	if progress >= 1.0:
		_stop_wave()

func start_wave(world_position: Vector2):
	"""
	Запускает волну от указанной мировой позиции
	
	Args:
		world_position: Позиция в мировых координатах (обычно global_position игрока)
	"""
	if _is_active:
		return
	
	# Конвертируем мировую позицию в UV координаты экрана СРАЗУ
	# и сохраняем их - они НЕ будут обновляться во время анимации
	var uv_center = _world_to_uv(world_position)
	
	# Запускаем волну
	_is_active = true
	_current_radius = 0.0
	visible = true
	
	# Устанавливаем центр волны - он останется фиксированным
	_shader_material.set_shader_parameter("wave_center", uv_center)
	_shader_material.set_shader_parameter("radius", 0.0)
	_shader_material.set_shader_parameter("fade_alpha", 1.0)

func _stop_wave():
	"""Останавливает волну"""
	_is_active = false
	visible = false
	_current_radius = 0.0
	_shader_material.set_shader_parameter("radius", 0.0)
	_shader_material.set_shader_parameter("fade_alpha", 0.0)

func _world_to_uv(world_pos: Vector2) -> Vector2:
	"""
	Конвертирует мировую позицию в UV координаты (0-1)
	
	Args:
		world_pos: Позиция в мировых координатах
		
	Returns:
		UV координаты (0.0 - 1.0)
	"""
	var viewport = get_viewport()
	var camera = viewport.get_camera_2d()
	
	if not camera:
		# Если нет камеры, возвращаем центр экрана
		return Vector2(0.5, 0.5)
	
	var viewport_size = viewport.get_visible_rect().size
	var camera_pos = camera.get_screen_center_position()
	var zoom = camera.zoom
	
	# Размер видимой области в мировых координатах
	var visible_size = viewport_size / zoom
	
	# Верхний левый угол видимой области
	var top_left = camera_pos - visible_size * 0.5
	
	# Относительная позиция от верхнего левого угла
	var relative_pos = world_pos - top_left
	
	# Конвертируем в UV (0.0 - 1.0)
	var uv = relative_pos / visible_size
	
	return uv

## Вспомогательные функции для внешнего использования

func is_wave_active() -> bool:
	"""Проверяет, активна ли волна в данный момент"""
	return _is_active

func stop_immediately():
	"""Немедленно останавливает волну без анимации"""
	_stop_wave()
