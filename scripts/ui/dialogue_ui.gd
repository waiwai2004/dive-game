extends Control

signal dialogue_finished
signal choice_selected(result: String)

@onready var dim: CanvasItem = $Dim
@onready var portrait_left: TextureRect = $PortraitLeft
@onready var portrait_right: TextureRect = $PortraitRight
@onready var dialogue_text = $DialogueRoot/DialogueTextContainer/DialogueText
@onready var name_label: Label = $NameBanner/NameLabel
@onready var name_banner: CanvasItem = $NameBanner
@onready var nav_button_continue: CanvasItem = $DialogueRoot/NavButtonContinue
@onready var nav_button_next: CanvasItem = get_node_or_null("DialogueRoot/NavButtonNext")

@onready var choice_area: CanvasItem = $DialogueRoot/ChoiceArea
@onready var choice_1_root: CanvasItem = $DialogueRoot/ChoiceArea/Choice1Root
@onready var choice_1_label: Label = $DialogueRoot/ChoiceArea/Choice1Root/Choice1Label
@onready var choice_1_button: Button = $DialogueRoot/ChoiceArea/Choice1Root/Choice1Button
@onready var choice_2_root: CanvasItem = $DialogueRoot/ChoiceArea/Choice2Root
@onready var choice_2_label: Label = $DialogueRoot/ChoiceArea/Choice2Root/Choice2Label
@onready var choice_2_button: Button = $DialogueRoot/ChoiceArea/Choice2Root/Choice2Button
@onready var choice_3_root: CanvasItem = $DialogueRoot/ChoiceArea/Choice3Root
@onready var choice_3_label: Label = $DialogueRoot/ChoiceArea/Choice3Root/Choice3Label
@onready var choice_3_button: Button = $DialogueRoot/ChoiceArea/Choice3Root/Choice3Button

@export var npc_talk: Texture2D
@export var npc_idle: Texture2D

var dialogue_data: Array = []
var current_index := 0
var active := false
var waiting_choice := false


func _ready() -> void:
	hide_ui()

	var font = load("res://assets/art/霞鹜漫黑.ttf")
	if dialogue_text:
		dialogue_text.add_theme_font_override("normal_font", font)
		dialogue_text.add_theme_font_override("bold_font", font)
		dialogue_text.add_theme_font_override("italics_font", font)
		dialogue_text.add_theme_font_override("bold_italics_font", font)
		dialogue_text.add_theme_font_override("mono_font", font)
		dialogue_text.add_theme_font_size_override("normal_font_size", 32)
		dialogue_text.add_theme_font_size_override("bold_font_size", 32)
		dialogue_text.add_theme_font_size_override("bold_italics_font_size", 32)
		dialogue_text.add_theme_font_size_override("italics_font_size", 32)
		dialogue_text.add_theme_font_size_override("mono_font_size", 32)
		dialogue_text.add_theme_color_override("font_color", Color(1, 1, 1, 1))

	if choice_1_button and not choice_1_button.pressed.is_connected(_on_choice_1_pressed):
		choice_1_button.pressed.connect(_on_choice_1_pressed)
	if choice_2_button and not choice_2_button.pressed.is_connected(_on_choice_2_pressed):
		choice_2_button.pressed.connect(_on_choice_2_pressed)
	if choice_3_button and not choice_3_button.pressed.is_connected(_on_choice_3_pressed):
		choice_3_button.pressed.connect(_on_choice_3_pressed)
	
	if nav_button_continue is BaseButton and not nav_button_continue.pressed.is_connected(_on_nav_button_continue_pressed):
		nav_button_continue.pressed.connect(_on_nav_button_continue_pressed)
	if nav_button_next is BaseButton and not nav_button_next.pressed.is_connected(_on_nav_button_next_pressed):
		nav_button_next.pressed.connect(_on_nav_button_next_pressed)


func start_dialogue(data: Array) -> void:
	dialogue_data = data
	current_index = 0
	active = true
	waiting_choice = false
	Game.in_dialogue = true

	show()
	if dim:
		dim.show()

	show_current_entry()


func hide_ui() -> void:
	hide()

	if dim:
		dim.hide()
	if portrait_left:
		portrait_left.hide()
	if portrait_right:
		portrait_right.hide()
	if name_banner:
		name_banner.hide()
	if choice_area:
		choice_area.hide()
	if choice_1_root:
		choice_1_root.hide()
	if choice_2_root:
		choice_2_root.hide()
	if choice_3_root:
		choice_3_root.hide()
	if nav_button_continue:
		nav_button_continue.hide()
	if nav_button_next:
		nav_button_next.hide()


func show_current_entry() -> void:
	if current_index >= dialogue_data.size():
		finish_dialogue()
		return

	var entry: Dictionary = dialogue_data[current_index]

	if name_label:
		name_label.show()
		name_label.text = String(entry.get("name", ""))

	if name_banner:
		name_banner.show()

	var text_container = get_node_or_null("DialogueRoot/DialogueTextContainer")

	if dialogue_text:
		dialogue_text.set("bbcode", String(entry.get("text", "")))

	_update_left_portrait(entry)

	var is_choice := String(entry.get("type", "line")) == "choice"
	if is_choice:
		_show_choices(entry)
		if dialogue_text:
			dialogue_text.hide()
		if text_container:
			text_container.hide()
	else:
		waiting_choice = false
		if choice_area:
			choice_area.hide()
		if text_container:
			text_container.show()
		if dialogue_text:
			dialogue_text.show()
		if nav_button_next:
			nav_button_next.show()
		if nav_button_continue:
			nav_button_continue.show()


func _show_choices(entry: Dictionary) -> void:
	waiting_choice = true

	if nav_button_continue:
		nav_button_continue.hide()
	if nav_button_next:
		nav_button_next.hide()
	if choice_area:
		choice_area.show()
	
	if portrait_left:
		portrait_left.hide()
	
	var right_tex: Texture2D = entry.get("right_portrait", null)
	if right_tex != null and portrait_right:
		portrait_right.texture = right_tex
		portrait_right.show()

	var choice_data: Array = entry.get("choices", [])

	if choice_data.size() > 0:
		choice_1_root.show()
		choice_1_label.text = String(choice_data[0].get("text", "选项1"))
		choice_1_button.disabled = false
	else:
		choice_1_root.hide()

	if choice_data.size() > 1:
		choice_2_root.show()
		choice_2_label.text = String(choice_data[1].get("text", "选项2"))
		choice_2_button.disabled = false
	else:
		choice_2_root.hide()

	if choice_data.size() > 2:
		choice_3_root.show()
		choice_3_label.text = String(choice_data[2].get("text", "选项3"))
		choice_3_button.disabled = false
	else:
		choice_3_root.hide()


func _update_left_portrait(entry: Dictionary) -> void:
	if not portrait_left:
		return

	var tex: Texture2D = entry.get("left_portrait", null)
	if tex != null:
		portrait_left.texture = tex
		portrait_left.show()
	else:
		portrait_left.show()
	
	var right_tex: Texture2D = entry.get("right_portrait", null)
	if right_tex != null and portrait_right:
		portrait_right.texture = right_tex
		portrait_right.show()
	elif portrait_right:
		portrait_right.hide()


func _on_choice_1_pressed() -> void:
	_emit_choice(0)


func _on_choice_2_pressed() -> void:
	_emit_choice(1)


func _on_choice_3_pressed() -> void:
	_emit_choice(2)


func _emit_choice(index: int) -> void:
	if current_index >= dialogue_data.size():
		return

	var entry: Dictionary = dialogue_data[current_index]
	var choice_data: Array = entry.get("choices", [])
	if index >= choice_data.size():
		return

	var result := String(choice_data[index].get("result", ""))
	choice_selected.emit(result)

	waiting_choice = false
	current_index += 1
	show_current_entry()


func advance() -> void:
	if not active or waiting_choice:
		return

	current_index += 1
	show_current_entry()


func go_back() -> void:
	if not active or waiting_choice:
		return
	
	if current_index > 0:
		current_index -= 1
		show_current_entry()


func finish_dialogue() -> void:
	active = false
	waiting_choice = false
	Game.in_dialogue = false
	hide_ui()
	dialogue_finished.emit()


func _on_nav_button_continue_pressed() -> void:
	advance()


func _on_nav_button_next_pressed() -> void:
	advance()


func _input(event: InputEvent) -> void:
	if not active or waiting_choice:
		return

	if event.is_action_pressed("advance"):
		advance()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance()
		get_viewport().set_input_as_handled()
