extends Control

signal dialogue_finished

@onready var dim: ColorRect = $Dim
@onready var portrait_left: TextureRect = $PortraitLeft
@onready var dialogue_panel: PanelContainer = $DialoguePanel
@onready var dialogue_text: RichTextLabel = $DialoguePanel/MarginContainer/DialogueText
@onready var name_label: Label = $NameLabel
@onready var choices_box: VBoxContainer = $Choices

@export var choice_button_theme: Theme
@export var choice_button_min_height: float = 80.0

@export var text_speed: float = 0.03
@export var fast_forward_multiplier: float = 3.0
@export var auto_advance_delay: float = 0.08
@export var instant_finish_on_fast_forward: bool = true

var dialogue_data: Array = []
var current_index: int = 0
var is_active: bool = false
var waiting_choice: bool = false

var full_text: String = ""
var visible_char_count: int = 0
var char_timer: float = 0.0
var auto_advance_timer: float = 0.0
var is_typing: bool = false

var butler_portrait: Texture2D
var receiver_portrait: Texture2D
var machine_portrait: Texture2D

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	choices_box.visible = false

	dialogue_text.bbcode_enabled = true
	dialogue_text.visible_characters = 0

	butler_portrait = load("res://art/assets/characters/NPC.PNG")
	receiver_portrait = load("res://art/placeholder/receiver.png")
	# machine_portrait = load("res://art/placeholder/machine.png")

func _process(delta: float) -> void:
	if not is_active:
		return

	var fast_forwarding := Input.is_action_pressed("fast_forward")

	if is_typing:
		if fast_forwarding and instant_finish_on_fast_forward:
			_finish_current_line_instantly()
			return

		var speed_multiplier: float = 1.0
		if fast_forwarding:
			speed_multiplier = fast_forward_multiplier

		char_timer += delta * speed_multiplier

		while char_timer >= text_speed and is_typing:
			char_timer -= text_speed
			visible_char_count += 1
			dialogue_text.visible_characters = visible_char_count

			if visible_char_count >= dialogue_text.get_total_character_count():
				is_typing = false
				_on_line_typing_finished()
		return

	if waiting_choice:
		return

	if fast_forwarding:
		auto_advance_timer += delta
		if auto_advance_timer >= auto_advance_delay:
			auto_advance_timer = 0.0
			_next_line()
	else:
		auto_advance_timer = 0.0

func start_dialogue(data: Array) -> void:
	GameManager.in_dialogue = true
	dialogue_data = data
	current_index = 0
	is_active = true
	waiting_choice = false
	is_typing = false

	visible = true
	choices_box.visible = false
	_clear_choices()
	_show_current_line()

func _input(event: InputEvent) -> void:
	if not is_active:
		return

	if waiting_choice:
		return

	if event is InputEventMouseButton \
	and event.pressed \
	and event.button_index == MOUSE_BUTTON_LEFT:
		if is_typing:
			_finish_current_line_instantly()
		else:
			_next_line()

func _next_line() -> void:
	current_index += 1

	if current_index >= dialogue_data.size():
		_finish_dialogue()
		return

	_show_current_line()

func _show_current_line() -> void:
	_clear_choices()
	choices_box.visible = false
	waiting_choice = false

	var line: Dictionary = dialogue_data[current_index]

	var speaker: String = str(line.get("speaker", ""))
	var text: String = str(line.get("text", ""))
	var portrait_key: String = str(line.get("portrait", ""))

	name_label.text = speaker
	full_text = _convert_legacy_tags(text)

	dialogue_text.clear()
	dialogue_text.append_text(full_text)
	dialogue_text.visible_characters = 0

	visible_char_count = 0
	char_timer = 0.0
	auto_advance_timer = 0.0
	is_typing = true

	_set_portrait(portrait_key)

func _finish_current_line_instantly() -> void:
	dialogue_text.visible_characters = dialogue_text.get_total_character_count()
	visible_char_count = dialogue_text.get_total_character_count()
	char_timer = 0.0
	is_typing = false
	_on_line_typing_finished()

func _on_line_typing_finished() -> void:
	var line: Dictionary = dialogue_data[current_index]

	if line.has("choices"):
		waiting_choice = true
		choices_box.visible = true
		_build_choices(line["choices"])

func _set_portrait(key: String) -> void:
	match key:
		"butler":
			portrait_left.texture = butler_portrait
		"receiver":
			portrait_left.texture = receiver_portrait
		"machine":
			portrait_left.texture = machine_portrait
		_:
			portrait_left.texture = null

func _build_choices(choice_list: Array) -> void:
	_clear_choices()

	for choice_data in choice_list:
		var btn := Button.new()
		btn.text = str(choice_data.get("text", ""))
		btn.custom_minimum_size = Vector2(0, choice_button_min_height)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.focus_mode = Control.FOCUS_NONE
		btn.clip_text = true

		if btn.has_method("set_autowrap_mode"):
			btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		if choice_button_theme:
			btn.theme = choice_button_theme

		btn.pressed.connect(_on_choice_selected.bind(choice_data))
		choices_box.add_child(btn)

func _on_choice_selected(choice_data: Dictionary) -> void:
	waiting_choice = false

	var jump_to: int = int(choice_data.get("next_index", current_index + 1))
	if jump_to >= dialogue_data.size():
		_finish_dialogue()
		return

	current_index = jump_to
	_show_current_line()

func _clear_choices() -> void:
	for child in choices_box.get_children():
		child.queue_free()

func _finish_dialogue() -> void:
	GameManager.in_dialogue = false
	is_active = false
	waiting_choice = false
	is_typing = false
	visible = false
	emit_signal("dialogue_finished")

func _convert_legacy_tags(text: String) -> String:
	text = text.replace("[red]", "[color=red]")
	text = text.replace("[/red]", "[/color]")
	text = text.replace("[blue]", "[color=blue]")
	text = text.replace("[/blue]", "[/color]")
	text = text.replace("[green]", "[color=green]")
	text = text.replace("[/green]", "[/color]")
	text = text.replace("[yellow]", "[color=yellow]")
	text = text.replace("[/yellow]", "[/color]")
	text = text.replace("[orange]", "[color=orange]")
	text = text.replace("[/orange]", "[/color]")
	text = text.replace("[purple]", "[color=purple]")
	text = text.replace("[/purple]", "[/color]")
	return text
