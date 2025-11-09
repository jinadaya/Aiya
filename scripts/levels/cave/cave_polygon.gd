extends Node2D
class_name CavePolygon

@export var texture_path :="res://sprites/levels/cave/bg_4.jpg"

func _ready():
	setup_polygon()

func setup_polygon():
	var polygon = get_node_or_null("Polygon2D")
	
	if polygon == null:
		push_error("No Polygon2D found")
		return
	
	if not polygon is Polygon2D:
		push_error("Node is not Polygon2D")
		return
	
	create_collision(polygon)

func apply_texture(polygon: Polygon2D):
	if texture_path == null or texture_path == "":
		push_warning("No texture path provided")
		return
	
	var img = Image.new()
	var err = img.load(texture_path)
	if err != OK:
		push_error("Failed to load texture: %s" % texture_path)
		return
	
	var img_texture = ImageTexture.create_from_image(img)
	polygon.texture = img_texture
	polygon.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	polygon.texture_offset = Vector2.ZERO
	polygon.texture_scale = Vector2.ONE
	
	if polygon.polygon.size() > 0:
		var rect = get_polygon_rect(polygon.polygon)
		if rect.size.x == 0 or rect.size.y == 0:
			push_warning("Polygon bounds are zero; skipping UV mapping.")
			return
		
		var uvs = PackedVector2Array()
		for point in polygon.polygon:
			var uv = Vector2(
				(point.x - rect.position.x) / rect.size.x,
				(point.y - rect.position.y) / rect.size.y  # Remove the 1.0 - inversion
			)
			uvs.append(uv)
		polygon.uv = uvs


func create_collision(polygon: Polygon2D):
	var static_body = StaticBody2D.new()
	static_body.name = "CollisionBody"
	polygon.add_child(static_body)
	static_body.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self
	
	var collision_polygon = CollisionPolygon2D.new()
	collision_polygon.name = "CollisionPolygon"
	collision_polygon.polygon = polygon.polygon
	static_body.add_child(collision_polygon)
	collision_polygon.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self
	
	print("set collission layers for ", self)
	static_body.collision_layer = CollisionMaskStorage.layer_for(CollisionMaskStorage.CollisionLayer.PLATFORM)
	static_body.collision_mask = CollisionMaskStorage.get_mask_for_layer(CollisionMaskStorage.CollisionLayer.PLATFORM)


func get_polygon_rect(points: PackedVector2Array) -> Rect2:
	if points.size() == 0:
		return Rect2()
	
	var min_x = points[0].x
	var max_x = points[0].x
	var min_y = points[0].y
	var max_y = points[0].y
	
	for point in points:
		min_x = min(min_x, point.x)
		max_x = max(max_x, point.x)
		min_y = min(min_y, point.y)
		max_y = max(max_y, point.y)
	
	return Rect2(min_x, min_y, max_x - min_x, max_y - min_y)
