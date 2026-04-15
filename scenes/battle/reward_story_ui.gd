extends Control

signal reward_selected(card_id: String)

@export var title_text: String = "记忆残响"
@export_multiline var body_text_value: String = "那片异变海域安静下来后，你听见某段不属于此处的回声。\n它像一段被海水反复浸泡过的记忆，残破，却仍在等待被理解。"
@export var hint_text_value: String = "请选择一种处理方式。"
@export var choice_1_text: String = "继续追问那段回声。"
@export var choice_2_text: String = "先把它封存起来。"

@onready var dim: ColorRect = $Dim
@onready var story_panel: PanelContainer = $StoryPanel
@onready var title_label: Label = $StoryPanel/MarginContainer/VBoxContainer/TitleLabel
@onready var body_text: Label = $StoryPanel/MarginContainer/VBoxContainer/BodyText
@onready var hint_label: Label = $StoryPanel/MarginContainer/VBoxContainer/HintLabel
@onready var choice_area: Control = $ChoiceArea
@onready var choice_1_button: Button = $ChoiceArea/Choice1Button
@onready var choice_2_button: Button = $ChoiceArea/Choice2Button
@onready var collect_area: Control = $CollectArea
@onready var collect_button: Button = $CollectArea/CollectButton

var _pending_card_id: String = ""


func _ready() -> void:
	_show_choice_stage()
	hide_ui()

	if not choice_1_button.pressed.is_connected(_on_choice_1_pressed):
		choice_1_button.pressed.connect(_on_choice_1_pressed)
	if not choice_2_button.pressed.is_connected(_on_choice_2_pressed):
		choice_2_button.pressed.connect(_on_choice_2_pressed)
	if not collect_button.pressed.is_connected(_on_collect_button_pressed):
		collect_button.pressed.connect(_on_collect_button_pressed)


func show_ui() -> void:
	_show_choice_stage()
	show()
	dim.show()
	story_panel.show()


func hide_ui() -> void:
	hide()
	dim.hide()
	story_panel.hide()
	choice_area.hide()
	collect_area.hide()


func _show_choice_stage() -> void:
	_pending_card_id = ""
	title_label.text = title_text
	body_text.text = body_text_value
	hint_label.text = _build_choice_hint_text()
	choice_1_button.text = choice_1_text
	choice_2_button.text = choice_2_text
	choice_1_button.disabled = false
	choice_2_button.disabled = false
	choice_area.show()
	collect_area.hide()


func _on_choice_1_pressed() -> void:
	_show_collect_stage("pursue")


func _on_choice_2_pressed() -> void:
	_show_collect_stage("seal")


func _show_collect_stage(card_id: String) -> void:
	_pending_card_id = card_id
	var card: Dictionary = CardDatabase.get_card(card_id)

	title_label.text = "获得卡牌"
	body_text.text = _build_reward_preview(card)
	hint_label.text = "点击“收下”将其加入牌组。"

	choice_area.hide()
	collect_area.show()
	collect_button.disabled = false
	collect_button.text = "收下"


func _on_collect_button_pressed() -> void:
	if _pending_card_id.is_empty():
		return

	collect_button.disabled = true
	reward_selected.emit(_pending_card_id)


func _build_choice_hint_text() -> String:
	var pursue_text: String = _build_card_info("pursue")
	var seal_text: String = _build_card_info("seal")
	return "%s\n\nA: %s\nB: %s" % [hint_text_value, pursue_text, seal_text]


func _build_card_info(card_id: String) -> String:
	var card: Dictionary = CardDatabase.get_card(card_id)
	var name_text: String = str(card.get("name", card_id))
	var type_text: String = CardDatabase.get_type_text(str(card.get("type", "")))
	var cost: int = int(card.get("cost", 0))
	var cognition: int = int(card.get("cognition", 0))
	var desc: String = _get_card_description(card)
	return "【%s】%s  %d费  认知%d | %s" % [name_text, type_text, cost, cognition, desc]


func _build_reward_preview(card: Dictionary) -> String:
	var name_text: String = str(card.get("name", "未知卡牌"))
	var type_text: String = CardDatabase.get_type_text(str(card.get("type", "")))
	var cost: int = int(card.get("cost", 0))
	var cognition: int = int(card.get("cognition", 0))
	var desc: String = _get_card_description(card)

	return "【%s】\n类型：%s\n费用：%d\n认知负荷：%d\n效果：%s" % [name_text, type_text, cost, cognition, desc]


func _get_card_description(card: Dictionary) -> String:
	var description: String = str(card.get("description", ""))
	if not description.is_empty():
		return description
	return str(card.get("desc", ""))
