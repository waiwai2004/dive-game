extends Node2D

@onready var interact_tip: Control = $CanvasLayer/InteractTip
@onready var tip_label: Label = $CanvasLayer/InteractTip/PanelContainer/MarginContainer/TipLabel
@onready var dialogue_ui: Control = $CanvasLayer/DialogueUI

@export var ui_theme: Theme

var active_interact_zones: int = 0
var has_finished_first_npc_dialogue: bool = false
var can_enter_adventure: bool = false

func _ready() -> void:
	add_to_group("base_scene")
	interact_tip.visible = false
	tip_label.text = ""

	if ui_theme:
		dialogue_ui.theme = ui_theme

	if dialogue_ui.has_signal("dialogue_finished"):
		dialogue_ui.dialogue_finished.connect(_on_dialogue_finished)

func show_interact_tip(text: String) -> void:
	active_interact_zones += 1
	tip_label.text = text
	interact_tip.visible = true

func clear_interact_tip() -> void:
	active_interact_zones = max(0, active_interact_zones - 1)
	if active_interact_zones == 0:
		interact_tip.visible = false
		tip_label.text = ""

func set_click_tip(text: String) -> void:
	show_interact_tip(text)

func set_hint_label(text: String) -> void:
	show_interact_tip(text)

func clear_click_tip() -> void:
	clear_interact_tip()

func clear_hint_label() -> void:
	clear_interact_tip()

func show_npc_dialog() -> void:
	active_interact_zones = 0
	interact_tip.visible = false
	tip_label.text = ""

	var data: Array
	if has_finished_first_npc_dialogue:
		data = BaseDialogueData.final_only_dialogue()
	else:
		data = BaseDialogueData.first_dialogue()

	dialogue_ui.start_dialogue(data)

func _on_dialogue_finished() -> void:
	if not has_finished_first_npc_dialogue:
		has_finished_first_npc_dialogue = true
		can_enter_adventure = true

func enter_adventure() -> void:
	if not can_enter_adventure:
		show_interact_tip("[左键] 先与基地管家交谈")
		return

	interact_tip.visible = false
	tip_label.text = ""

	# 使用GameManager的start_adventure()函数进入冒险场景
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		game_manager.start_adventure()
