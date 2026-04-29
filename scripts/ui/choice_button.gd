extends Button

class_name ChoiceButton

var _pressed_state: bool = false
const FONT_PATH = "res://assets/art/霞鹜漫黑.ttf"

func _ready() -> void:
	flat = true
	var font = load(FONT_PATH)
	if font:
		add_theme_font_override("font", font)
		add_theme_font_size_override("font_size", 24)
	add_theme_color_override("font_color", Color(0.2, 0.15, 0.1, 1))
	_toggle_style()
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	autowrap_mode = 3
	add_theme_constant_override("custom_minimum_size", 20)
	add_theme_constant_override("h_separation", 10)

func set_label_text(new_text: String) -> void:
	self.text = new_text

func set_button_pressed_state(pressed: bool) -> void:
	_pressed_state = pressed
	_toggle_style()

func _toggle_style() -> void:
	if _pressed_state:
		var style = StyleBoxTexture.new()
		style.texture = preload("res://assets/art/ui/button/ui_choice_btn_p.PNG")
		style.texture_margin_left = 20
		style.texture_margin_top = 20
		style.texture_margin_right = 20
		style.texture_margin_bottom = 20
		style.content_margin_left = 25
		style.content_margin_right = 25
		style.content_margin_top = 15
		style.content_margin_bottom = 15
		add_theme_stylebox_override("normal", style)
		add_theme_stylebox_override("pressed", style)
		add_theme_stylebox_override("hover", style)
	else:
		var style = StyleBoxTexture.new()
		style.texture = preload("res://assets/art/ui/button/ui_choice_btn_n.PNG")
		style.texture_margin_left = 20
		style.texture_margin_top = 20
		style.texture_margin_right = 20
		style.texture_margin_bottom = 20
		style.content_margin_left = 25
		style.content_margin_right = 25
		style.content_margin_top = 15
		style.content_margin_bottom = 15
		add_theme_stylebox_override("normal", style)
		add_theme_stylebox_override("pressed", style)
		add_theme_stylebox_override("hover", style)
