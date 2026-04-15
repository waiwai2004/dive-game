extends Control

signal dialogue_finished
signal choice_selected(result: String)

@onready var dim: CanvasItem = $Dim
@onready var portrait_left: TextureRect = $PortraitLeft
@onready var portrait_right: TextureRect = $PortraitRight
@onready var dialogue_panel: CanvasItem = $DialoguePanel
@onready var dialogue_text: RichTextLabel = $DialoguePanel/MarginContainer/DialogueText
@onready var name_label: Label = $NameLabel
@onready var next_hint: Label = get_node_or_null("Label")

@onready var choice_area: CanvasItem = $ChoiceArea
@onready var choice_1_root: CanvasItem = $ChoiceArea/Choice1Root
@onready var choice_1_label: Label = $ChoiceArea/Choice1Root/Choice1Label
@onready var choice_1_button: Button = $ChoiceArea/Choice1Root/Choice1Button
@onready var choice_2_root: CanvasItem = $ChoiceArea/Choice2Root
@onready var choice_2_label: Label = $ChoiceArea/Choice2Root/Choice2Label
@onready var choice_2_button: Button = $ChoiceArea/Choice2Root/Choice2Button

var dialogue_data: Array = []
var current_index := 0
var active := false
var waiting_choice := false


func _ready() -> void:
	hide_ui()

	if choice_1_button and not choice_1_button.pressed.is_connected(_on_choice_1_pressed):
		choice_1_button.pressed.connect(_on_choice_1_pressed)
	if choice_2_button and not choice_2_button.pressed.is_connected(_on_choice_2_pressed):
		choice_2_button.pressed.connect(_on_choice_2_pressed)


func start_dialogue(data: Array) -> void:
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


func hide_ui() -> void:
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
	if choice_area:
		choice_area.hide()
	if choice_1_root:
		choice_1_root.hide()
	if choice_2_root:
		choice_2_root.hide()


func show_current_entry() -> void:
	if current_index >= dialogue_data.size():
		finish_dialogue()
		return

	var entry: Dictionary = dialogue_data[current_index]

	if name_label:
		name_label.show()
		name_label.text = String(entry.get("name", ""))

	if dialogue_text:
		dialogue_text.text = String(entry.get("text", ""))

	_update_left_portrait(entry)
	_update_right_portrait(entry)

	var is_choice := String(entry.get("type", "line")) == "choice"
	if is_choice:
		_show_choices(entry)
	else:
		waiting_choice = false
		if choice_area:
			choice_area.hide()
		if next_hint:
			next_hint.show()


func _show_choices(entry: Dictionary) -> void:
	waiting_choice = true

	if next_hint:
		next_hint.hide()
	if choice_area:
		choice_area.show()

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


func _update_left_portrait(entry: Dictionary) -> void:
	if not portrait_left:
		return

	var tex: Texture2D = entry.get("left_portrait", null)
	if tex != null:
		portrait_left.texture = tex
		portrait_left.show()
	else:
		portrait_left.texture = null
		portrait_left.hide()


func _update_right_portrait(entry: Dictionary) -> void:
	if not portrait_right:
		return

	var tex: Texture2D = entry.get("right_portrait", null)
	var is_choice := String(entry.get("type", "line")) == "choice"
	if tex != null and is_choice:
		portrait_right.texture = tex
		portrait_right.show()
	else:
		portrait_right.texture = null
		portrait_right.hide()


func _on_choice_1_pressed() -> void:
	_emit_choice(0)


func _on_choice_2_pressed() -> void:
	_emit_choice(1)


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


func finish_dialogue() -> void:
	active = false
	waiting_choice = false
	Game.in_dialogue = false
	hide_ui()
	dialogue_finished.emit()


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
