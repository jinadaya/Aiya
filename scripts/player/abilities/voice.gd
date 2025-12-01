extends Node2D
class_name VoiceAbility

signal finished

class Ray:
	var position: Vector2
	var direction: Vector2
	var time: float = 0.0
	var stopped: bool = false   # wave stick to collision
	
	func _init(_position: Vector2, _direction: Vector2):
		position = _position
		direction = _direction


var rays: Array[Ray] = []

@export var rays_num: int = 144
@export var angle_step: float = 0.04363323129 # 2.5 degrees

@export var rays_speed: float = 1220.0
@export var lifetime: float = 0.85
@export var time_lock: float = 0.55
@export var cooldown: float = 1.0
@export var bounce_offset: float = 0.5
@export var stick_to_collision: bool = true
@export var min_reflect_dot: float = 0.95

@onready var line: Line2D = $Line2D

var in_progress: float = 0.0
var cooldown_timer: float = 0.0


func _ready():
	line.width = 2.0
	line.default_color = Color.ALICE_BLUE
	line.closed = true


func _physics_process(delta: float):
	if cooldown_timer > 0.0:
		cooldown_timer -= delta

	if in_progress > 0.0:
		_update_wave(delta)
		_draw_wave()


func start_wave(start_position: Vector2, echo: bool = false):
	if cooldown_timer > 0.0:
		return
	if in_progress > 0.0:
		return
	
	if echo: MusicManager.play_sfx(load("res://audio/VOICE_SOUND_ECHO.wav"))
	else: MusicManager.play_sfx(load("res://audio/VOICE_SOUND.mp3"))
	
	in_progress = lifetime + time_lock
	cooldown_timer = cooldown
	rays.clear()

	for i in range(rays_num):
		var direction = Vector2.RIGHT.rotated(angle_step * i)
		var ray = Ray.new(start_position, direction)
		rays.append(ray)


func _update_wave(delta: float):
	in_progress -= delta
	if rays.is_empty():
		return
	
	var space = get_world_2d().direct_space_state
	
	for i in range(rays.size()):
		var ray = rays[i]
		ray.time += delta
		if ray.stopped:
			continue
		
		var new_pos = ray.position + ray.direction * rays_speed * delta
		var ray_query = PhysicsRayQueryParameters2D.create(
			ray.position,
			new_pos,
			CollisionMaskStorage.layer_for(CollisionMaskStorage.CollisionLayer.PLATFORM)
		)
		var result = space.intersect_ray(ray_query)
		
		if result:
			var normal: Vector2 = result["normal"].normalized()
			var hit_pos: Vector2 = result["position"]
			
			if stick_to_collision:
				# Wabe sticks
				ray.position = hit_pos + normal * 0.05
				ray.direction = Vector2.ZERO
				ray.stopped = true
			else:
				# Reflection as is
				var dot = abs(ray.direction.normalized().dot(normal))
				if dot > min_reflect_dot:
					ray.direction = ray.direction.rotated(randf_range(-0.15, 0.15))
				else:
					ray.direction = ray.direction.bounce(normal)
				ray.position = hit_pos + normal * bounce_offset
		else:
			ray.position = new_pos
			
		if ray.time >= lifetime:
			ray.direction = Vector2.ZERO
			ray.stopped = true
			
	if rays.all(func(r): return r.stopped):
		in_progress = 0.0
		finished.emit()


func _draw_wave():
	if rays.is_empty():
		return
		
	line.clear_points()
	
	# Smooth fade out
	var alpha := clampf(1.0 - (rays[0].time / lifetime), 0.0, 1.0)
	var c := line.default_color
	c.a = alpha
	line.default_color = c
	
	for ray in rays:
		line.add_point(to_local(ray.position))
	
	# Add last point
	line.add_point(to_local(rays[0].position))
