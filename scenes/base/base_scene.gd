extends Node2D

@onready var interact_tip = $CanvasLayer/InteractTip
@onready var interact_tip_label = $CanvasLayer/InteractTip/PanelContainer/MarginContainer/TipLabel
@onready var dialogue_ui = $CanvasLayer/DialogueUI

var current_interactable: Node = null
var dialogue_data_node := preload("res://data/base_dialogue_data.gd").new()

func _ready():
	add_to_group("base_scene")
	print("[BaseScene] ready")
	if has_node("/root/AudioManager"):
		AudioManager.play_bgm_segment("base")
	_apply_global_ui_mode()
	_update_global_stats()
	_set_global_hint("E 交互", false)

	if interact_tip:
		interact_tip.visible = false

	if dialogue_ui.has_signal("dialogue_finished"):
		dialogue_ui.dialogue_finished.connect(_on_dialogue_finished)

	if dialogue_ui.has_signal("choice_selected"):
		dialogue_ui.choice_selected.connect(_on_dialogue_choice_selected)

func _process(_delta):
	if Game.in_dialogue:
		return

	if Input.is_action_just_pressed("interact"):
		print("[BaseScene] press interact, current=", current_interactable)

	if Input.is_action_just_pressed("interact") and current_interactable:
		current_interactable.interact()

func set_current_interactable(interactable: Node):
	current_interactable = interactable
	print("[BaseScene] set current interactable =", interactable.name)
	show_interact_tip(interactable.hint_text)

func clear_current_interactable(interactable: Node):
	if current_interactable == interactable:
		print("[BaseScene] clear current interactable =", interactable.name)
		current_interactable = null
		clear_interact_tip()

func show_interact_tip(text: String):
	if interact_tip and not has_node("/root/GlobalUI"):
		interact_tip.visible = true
	if interact_tip_label and not has_node("/root/GlobalUI"):
		interact_tip_label.text = text
	_set_global_hint(text, true)

func clear_interact_tip():
	if interact_tip:
		interact_tip.visible = false
	if interact_tip_label:
		interact_tip_label.text = ""
	_set_global_hint("E 交互", false)

func show_npc_dialog():
	clear_interact_tip()

	if not Game.admin_talk_done:
		dialogue_ui.start_dialogue(dialogue_data_node.first_dialogue())
	else:
		dialogue_ui.start_dialogue(dialogue_data_node.repeat_dialogue_after_finish())

func try_enter_dive():
	clear_interact_tip()

	if not Game.admin_talk_done:
		dialogue_ui.start_dialogue(dialogue_data_node.repeat_dialogue_before_finish())
		return

	Game.goto_dive()

func _on_dialogue_choice_selected(result: String):
	match result:
		"aggressive":
			Game.tag_aggressive += 1
		"orderly":
			Game.tag_orderly += 1

func _on_dialogue_finished():
	if not Game.admin_talk_done:
		Game.admin_talk_done = true

	if current_interactable:
		show_interact_tip(current_interactable.hint_text)


func _apply_global_ui_mode() -> void:
	if has_node("/root/GlobalUI"):
		GlobalUI.set_mode(GlobalUI.MODE_BASE)


func _set_global_hint(text: String, visible: bool) -> void:
	if has_node("/root/GlobalUI"):
		if visible:
			GlobalUI.set_hint(text, true)
		else:
			GlobalUI.clear_hint()


func _update_global_stats() -> void:
	if has_node("/root/GlobalUI"):
		GlobalUI.refresh_stats()
