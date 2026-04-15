extends Control

signal choice_selected(card_id: String)
signal closed

@export_multiline var event_text_value: String = "你触碰到一段模糊的记忆残响。\n\n“不要相信报告上的死亡时间。”\n“我还在下面。”\n\n你听见那个声音再次低语。"
@export var choice_a_text: String = "继续追问真相。"
@export var choice_b_text: String = "先把异常封存起来。"

@onready var dim: ColorRect = $Dim
@onready var panel: PanelContainer = $Panel
@onready var event_text: RichTextLabel = $Panel/MarginContainer/VBoxContainer/EventText
@onready var choice_a: Button = $Panel/MarginContainer/VBoxContainer/ChoiceA
@onready var choice_b: Button = $Panel/MarginContainer/VBoxContainer/ChoiceB


func _ready() -> void:
	hide_ui()

	event_text.text = event_text_value
	choice_a.text = choice_a_text
	choice_b.text = choice_b_text

	if not choice_a.pressed.is_connected(_on_choice_a_pressed):
		choice_a.pressed.connect(_on_choice_a_pressed)
	if not choice_b.pressed.is_connected(_on_choice_b_pressed):
		choice_b.pressed.connect(_on_choice_b_pressed)


func show_event() -> void:
	show()
	dim.show()
	panel.show()

	event_text.text = event_text_value
	choice_a.text = choice_a_text
	choice_b.text = choice_b_text

	choice_a.disabled = false
	choice_b.disabled = false


func hide_ui() -> void:
	hide()
	dim.hide()
	panel.hide()


func _on_choice_a_pressed() -> void:
	choice_selected.emit("pursue")
	_close_event()


func _on_choice_b_pressed() -> void:
	choice_selected.emit("seal")
	_close_event()


func _close_event() -> void:
	hide_ui()
	closed.emit()
