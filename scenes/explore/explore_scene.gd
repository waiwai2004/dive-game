extends Node2D

const BATTLE_SCENE_PATH := "res://scenes/battle/BattleScene.tscn"

@onready var player: CharacterBody2D = $World/Player
@onready var memory_zone: Area2D = $World/MemoryEchoZone
@onready var memory_highlight: CanvasItem = get_node_or_null("World/MemoryEchoZone/Highlight")
@onready var battle_zone: Area2D = $World/BattleZone
@onready var battle_highlight: CanvasItem = $World/BattleZone/Highlight
@onready var hint_label: Label = $CanvasLayer/HintLabel
@onready var memory_event_ui: Control = $CanvasLayer/MemoryEventUI

var current_target: String = ""
var memory_event_open: bool = false
var _player_in_memory_zone: bool = false
var _player_in_battle_zone: bool = false


func _ready() -> void:
	if has_node("/root/AudioManager"):
		AudioManager.play_bgm_segment("explore")

	_connect_signals()
	_apply_global_ui_mode()
	_update_global_stats()
	_reset_scene_state()


func _process(_delta: float) -> void:
	if memory_event_open:
		return

	_update_interaction_target()

	if Input.is_action_just_pressed("interact"):
		_interact_current_target()


func _connect_signals() -> void:
	var on_memory_choice: Callable = Callable(self, "_on_memory_choice_selected")
	var on_memory_closed: Callable = Callable(self, "_on_memory_event_closed")

	if not memory_zone.body_entered.is_connected(_on_memory_zone_body_entered):
		memory_zone.body_entered.connect(_on_memory_zone_body_entered)
	if not memory_zone.body_exited.is_connected(_on_memory_zone_body_exited):
		memory_zone.body_exited.connect(_on_memory_zone_body_exited)

	if not battle_zone.body_entered.is_connected(_on_battle_zone_body_entered):
		battle_zone.body_entered.connect(_on_battle_zone_body_entered)
	if not battle_zone.body_exited.is_connected(_on_battle_zone_body_exited):
		battle_zone.body_exited.connect(_on_battle_zone_body_exited)

	if memory_event_ui.has_signal("choice_selected") and not memory_event_ui.is_connected("choice_selected", on_memory_choice):
		memory_event_ui.connect("choice_selected", on_memory_choice)
	if memory_event_ui.has_signal("closed") and not memory_event_ui.is_connected("closed", on_memory_closed):
		memory_event_ui.connect("closed", on_memory_closed)


func _reset_scene_state() -> void:
	current_target = ""
	memory_event_open = false
	_player_in_memory_zone = false
	_player_in_battle_zone = false
	Game.in_dialogue = false

	if memory_event_ui.has_method("hide_ui"):
		memory_event_ui.hide_ui()
	else:
		memory_event_ui.hide()

	_set_hint("", false)
	_update_target_highlight()


func _interact_current_target() -> void:
	match current_target:
		"memory":
			_open_memory_event()
		"battle":
			if not Game.memory_event_done:
				_set_hint("先调查记忆残响。", true)
				return
			_enter_tutorial_battle()


func _open_memory_event() -> void:
	if Game.memory_event_done:
		_set_hint("这段残响已经调查过。", true)
		return
	if not _can_interact_memory():
		_set_hint("你还无法锁定这段残响。", true)
		return

	memory_event_open = true
	current_target = ""
	Game.in_dialogue = true
	_update_target_highlight()
	_set_hint("", false)

	if memory_event_ui.has_method("show_event"):
		memory_event_ui.show_event()
	else:
		memory_event_ui.show()


func _on_memory_choice_selected(card_id: String) -> void:
	if card_id == "pursue":
		Game.tag_aggressive += 1
	elif card_id == "seal":
		Game.tag_orderly += 1

	if not Game.reward_card_given:
		Game.add_card(card_id)
		Game.reward_card_given = true

	Game.memory_event_done = true


func _on_memory_event_closed() -> void:
	memory_event_open = false
	Game.in_dialogue = false
	_update_global_stats()
	_update_interaction_target()


func _on_memory_zone_body_entered(body: Node) -> void:
	if body != player or memory_event_open:
		return
	_player_in_memory_zone = true
	_update_interaction_target()


func _on_memory_zone_body_exited(body: Node) -> void:
	if body != player:
		return
	_player_in_memory_zone = false
	_update_interaction_target()


func _on_battle_zone_body_entered(body: Node) -> void:
	if body != player or memory_event_open:
		return
	_player_in_battle_zone = true
	_update_interaction_target()


func _on_battle_zone_body_exited(body: Node) -> void:
	if body != player:
		return
	_player_in_battle_zone = false
	_update_interaction_target()


func _enter_tutorial_battle() -> void:
	Game.in_dialogue = false
	Game.battle_index = 1
	_set_hint("", false)
	get_tree().change_scene_to_file(BATTLE_SCENE_PATH)


func _update_interaction_target() -> void:
	if memory_event_open:
		return

	var next_target: String = ""
	if _can_interact_memory():
		next_target = "memory"
	elif _player_in_battle_zone:
		next_target = "battle"

	current_target = next_target
	_update_target_highlight()
	_update_hint_text()


func _can_interact_memory() -> bool:
	if Game.memory_event_done:
		return false
	if not _player_in_memory_zone:
		return false
	return _is_memory_discovered()


func _is_memory_discovered() -> bool:
	if memory_zone.has_method("is_discovered_by_player"):
		var result: Variant = memory_zone.call("is_discovered_by_player", player)
		if result is bool:
			return bool(result)
	return _player_in_memory_zone


func _update_target_highlight() -> void:
	if memory_highlight:
		memory_highlight.visible = _can_interact_memory() and not memory_event_open
	if battle_highlight:
		battle_highlight.visible = current_target == "battle" and not memory_event_open


func _update_hint_text() -> void:
	if current_target == "memory":
		_set_hint("按 E 调查记忆残响", true)
		return

	if current_target == "battle":
		if Game.memory_event_done:
			_set_hint("按 E 进入教学战", true)
		else:
			_set_hint("先调查记忆残响。", true)
		return

	if _player_in_memory_zone and not Game.memory_event_done:
		if _is_memory_discovered():
			_set_hint("你锁定了残响位置，按 E 调查。", true)
		else:
			_set_hint("调整朝向，锁定前方残响。", true)
		return

	_set_hint("", false)


func _apply_global_ui_mode() -> void:
	if has_node("/root/GlobalUI"):
		GlobalUI.set_mode(GlobalUI.MODE_EXPLORE)


func _set_hint(text: String, visible: bool) -> void:
	if hint_label and not has_node("/root/GlobalUI"):
		hint_label.text = text
		hint_label.visible = visible

	if has_node("/root/GlobalUI"):
		if visible:
			GlobalUI.set_hint(text, true)
		else:
			GlobalUI.clear_hint()


func _update_global_stats() -> void:
	if has_node("/root/GlobalUI"):
		GlobalUI.refresh_stats()
