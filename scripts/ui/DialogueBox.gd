extends Control

signal dialogue_finished
signal choice_selected(result: String)

@onready var dim = $Dim
@onready var portrait_left = $PortraitLeft
@onready var portrait_right = $PortraitRight
@onready var dialogue_panel = $DialoguePanel
@onready var dialogue_text = $DialoguePanel/MarginContainer/DialogueText
@onready var next_hint = $Label
@onready var name_label = $NameLabel
@onready var choices_box = $VBoxContainer
@onready var choice_1 = $VBoxContainer/Choice1
@onready var choice_2 = $VBoxContainer/Choice2

var dialogue_data: Array = []
var current_index: int = 0
var active: bool = false
var waiting_choice: bool = false

func _ready():
	hide_ui()

	if choice_1.has_signal("pressed"):
		choice_1.pressed.connect(_on_choice_1_pressed)
	if choice_2.has_signal("pressed"):
		choice_2.pressed.connect(_on_choice_2_pressed)

	if choice_1.has_signal("choice_pressed"):
		choice_1.choice_pressed.connect(_on_choice_1_pressed)
	if choice_2.has_signal("choice_pressed"):
		choice_2.choice_pressed.connect(_on_choice_2_pressed)

func start_dialogue(data: Array):
	dialogue_data = data
	current_index = 0
	active = true
	waiting_choice = false
	Game.in_dialogue = true

	show()

	if dim:
		dim.show()
	if dialogue_panel:
		dialogue_panel.show()

	show_current_entry()

func hide_ui():
	hide()

	if dim:
		dim.hide()
	if portrait_left:
		portrait_left.hide()
	if portrait_right:
		portrait_right.hide()
	if dialogue_panel:
		dialogue_panel.hide()
	if next_hint:
		next_hint.hide()
	if name_label:
		name_label.hide()
	if choices_box:
		choices_box.hide()

func show_current_entry():
	if current_index >= dialogue_data.size():
		finish_dialogue()
		return

	var entry = dialogue_data[current_index]

	if name_label:
		name_label.show()
		name_label.text = entry.get("name", "")

	if dialogue_text:
		dialogue_text.text = entry.get("text", "")

	_update_left_portrait(entry)
	_update_right_portrait(entry)

	var is_choice: bool = entry.get("type", "line") == "choice"

	if is_choice:
		waiting_choice = true

		if next_hint:
			next_hint.hide()

		if choices_box:
			choices_box.show()

		var choice_data = entry.get("choices", [])

		if choice_data.size() > 0:
			choice_1.visible = true
			_set_choice_text(choice_1, choice_data[0].get("text", "选项1"))
			_set_choice_disabled(choice_1, false)
		else:
			choice_1.visible = false

		if choice_data.size() > 1:
			choice_2.visible = true
			_set_choice_text(choice_2, choice_data[1].get("text", "选项2"))
			_set_choice_disabled(choice_2, false)
		else:
			choice_2.visible = false
	else:
		waiting_choice = false

		if choices_box:
			choices_box.hide()

		if next_hint:
			next_hint.show()

func _update_left_portrait(entry: Dictionary):
	if not portrait_left:
		return

	var tex: Texture2D = entry.get("left_portrait", null)
	if tex != null:
		portrait_left.texture = tex
		portrait_left.show()
	else:
		portrait_left.texture = null
		portrait_left.hide()

func _update_right_portrait(entry: Dictionary):
	if not portrait_right:
		return

	var tex: Texture2D = entry.get("right_portrait", null)
	var is_choice: bool = entry.get("type", "line") == "choice"

	if tex != null and is_choice:
		portrait_right.texture = tex
		portrait_right.show()
	else:
		portrait_right.texture = null
		portrait_right.hide()

func _set_choice_text(choice_node: Node, value: String):
	if choice_node == null:
		return

	if "text" in choice_node:
		choice_node.text = value
		return

	if choice_node.has_method("set_choice_text"):
		choice_node.set_choice_text(value)

func _set_choice_disabled(choice_node: Node, value: bool):
	if choice_node == null:
		return

	if "disabled" in choice_node:
		choice_node.disabled = value
		return

	if choice_node.has_method("set_disabled_state"):
		choice_node.set_disabled_state(value)

func _on_choice_1_pressed(_arg = null):
	_emit_choice(0)

func _on_choice_2_pressed(_arg = null):
	_emit_choice(1)

func _emit_choice(index: int):
	if current_index >= dialogue_data.size():
		return

	var entry = dialogue_data[current_index]
	var choice_data = entry.get("choices", [])

	if index >= choice_data.size():
		return

	var result = choice_data[index].get("result", "")
	choice_selected.emit(result)

	waiting_choice = false
	current_index += 1
	show_current_entry()

func advance():
	if not active:
		return
	if waiting_choice:
		return

	current_index += 1
	show_current_entry()

func finish_dialogue():
	active = false
	waiting_choice = false
	Game.in_dialogue = false
	hide_ui()
	dialogue_finished.emit()

func _input(event):
	if not active:
		return
	if waiting_choice:
		return

	if event.is_action_pressed("advance"):
		advance()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance()
		get_viewport().set_input_as_handled()
