extends PointLight2D
class_name PlayerLightsource

var img1 : ImageTexture
var img2 : ImageTexture

# Simple impl for 2 states. Don't want to do stuff, sry..
var curr_img_flag : bool = false
var texture_change_timer : float = 0.3 # sec
const MIN_TEXTURE_CHANGE_THRESHOLD : float = 0.15 # sec
const MAX_TEXTURE_CHANGE_THRESHOLD : float = 0.3 # sec

func _ready() -> void:
	var tmp_img1 = Image.new()
	var tmp_img2 = Image.new()
	tmp_img1.load("res://sprites/levels/cave/light/light_1.webp")
	tmp_img2.load("res://sprites/levels/cave/light/light_2.webp")
	img1 = ImageTexture.create_from_image(tmp_img1)
	img2 = ImageTexture.create_from_image(tmp_img2)

# Change texture, since AnimatedTexture2D is deprecated.
func _process(delta: float) -> void:
	if (texture_change_timer <= 0):
		# Renew timer and change texture image
		texture_change_timer = randf_range(MIN_TEXTURE_CHANGE_THRESHOLD, MAX_TEXTURE_CHANGE_THRESHOLD)
		var new_texture = img1 if curr_img_flag else img2
		curr_img_flag = not curr_img_flag
		texture = new_texture
	texture_change_timer -= delta
