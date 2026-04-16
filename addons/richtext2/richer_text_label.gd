extends Control
class_name DialogueUI

signal dialogue_started
signal dialogue_finished
signal choice_selected(index: int, value)

@export var text_speed: float = 0.03
@export var auto_hide_on_finish: bool = true

@onready var dim: ColorRect = $Dim
@onready var portrait_left: TextureRect = $PortraitLeft
@onready var dialogue_panel: PanelContainer = $DialoguePanel
@onready var name_label: Label = $DialoguePanel/NameLabel
@onready var dialogue_text: RichTextLabel = $DialoguePanel/MarginContainer/DialogueText
@onready var choices: VBoxContainer = $DialoguePanel/Choices
@onready var interact_tip: Control = $"../InteractTip"

var _script: Array = []
var _index: int = -1
var _is_typing: bool = false
var _can_advance: bool = false
var _current_line: Dictionary = {}

func _ready() -> void:
	hide()
	_clear_choices()
	dialogue_text.bbcode = ""
	dialogue_text.visible_characters = -1

func start_dialogue(lines: Array) -> void:
	if lines.is_empty():
		return

	_script = lines
	_index = -1
	show()
	if interact_tip:
		interact_tip.hide()

	emit_signal("dialogue_started")
	_next_line()

func end_dialogue() -> void:
	_script.clear()
	_index = -1
	_current_line.clear()
	_is_typing = false
	_can_advance = false
	_clear_choices()

	if auto_hide_on_finish:
		hide()

	if interact_tip:
		interact_tip.show()

	emit_signal("dialogue_finished")

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_accept") or event.is_action_pressed("click"):
		_on_advance_pressed()

func _on_advance_pressed() -> void:
	if _has_choices():
		return

	if _is_typing:
		_finish_current_line()
	elif _can_advance:
		_next_line()

func _next_line() -> void:
	_clear_choices()
	_index += 1

	if _index >= _script.size():
		end_dialogue()
		return

	_current_line = _script[_index]
	_apply_line(_current_line)

func _apply_line(line: Dictionary) -> void:
	name_label.text = str(line.get("name", ""))

	if line.has("portrait"):
		portrait_left.texture = line["portrait"]
		portrait_left.visible = portrait_left.texture != null
	else:
		portrait_left.visible = false

	var text := str(line.get("text", ""))
	dialogue_text.bbcode = text
	dialogue_text.visible_characters = 0

	_can_advance = false

	if line.has("choices") and line["choices"] is Array and not line["choices"].is_empty():
		await _type_text()
		_show_choices(line["choices"])
	else:
		await _type_text()
		_can_advance = true

func _type_text() -> void:
	_is_typing = true

	# 关键：不要切字符串，不要自己解析标签
	# 直接用 RichTextLabel 的可见字符数推进，富文本效果会完整保留
	var total: int = dialogue_text.get_total_character_count()

	while dialogue_text.visible_characters < total:
		if not _is_typing:
			break
		dialogue_text.visible_characters += 1
		await get_tree().create_timer(text_speed).timeout

	dialogue_text.visible_characters = total
	_is_typing = false

func _finish_current_line() -> void:
	_is_typing = false
	dialogue_text.visible_characters = dialogue_text.get_total_character_count()

	if _current_line.has("choices") and _current_line["choices"] is Array and not _current_line["choices"].is_empty():
		_show_choices(_current_line["choices"])
	else:
		_can_advance = true

func _show_choices(choice_list: Array) -> void:
	_clear_choices()

	for i in choice_list.size():
		var item = choice_list[i]
		var btn := Button.new()

		if item is Dictionary:
			btn.text = str(item.get("text", "Option %d" % i))
			btn.pressed.connect(_on_choice_pressed.bind(i, item.get("value", i)))
		else:
			btn.text = str(item)
			btn.pressed.connect(_on_choice_pressed.bind(i, item))

		choices.add_child(btn)

	_can_advance = false

func _on_choice_pressed(index: int, value) -> void:
	_clear_choices()
	emit_signal("choice_selected", index, value)
	_can_advance = true
	_next_line()

func _clear_choices() -> void:
	for child in choices.get_children():
		child.queue_free()

func _has_choices() -> bool:
	return choices.get_child_count() > 0
