extends RichTextLabel
class_name AnimatedRichText

@export var full_text: String = "Hello World!"
@export var reveal_speed: float = 0.05  # Задержка между буквами в секундах

var current_index: int = 0
var timer: float = 0.0

func _ready() -> void:
	text = ""
	bbcode_enabled = true
	reveal_text(full_text)

func reveal_text(new_text: String):
	full_text = new_text
	current_index = 0
	text = ""
	timer = 0.0

func _process(delta):
	if current_index < full_text.length():
		timer += delta
		
		if timer >= reveal_speed:
			timer = 0.0
			text += full_text[current_index]
			current_index += 1

func set_new_text(new_text: String):
	reveal_text(new_text)

# Функция для мгновенного показа всего текста
func show_all():
	text = full_text
	current_index = full_text.length()
