extends Node2D

const BATTLE_SCENE_PATH := "res://scenes/battle/BattleScene.tscn"

enum ExplorePhase {
	TO_MEMORY,
	MEMORY_EVENT,
	TO_BATTLE,
	TO_RELAY,
	COMPLETE
}

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
var _phase: int = ExplorePhase.TO_MEMORY
var _event_context: String = ""
var _transitioning: bool = false


func _ready() -> void:
	if has_node("/root/AudioManager"):
		AudioManager.play_bgm_segment("explore")

	_connect_signals()
	_apply_global_ui_mode()
	_update_global_stats()
	_reset_scene_state()
	_resolve_phase_from_game()
	_update_interaction_target()


func _process(_delta: float) -> void:
	if memory_event_open or _transitioning:
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
	_event_context = ""
	_transitioning = false
	Game.in_dialogue = false

	if memory_event_ui.has_method("hide_ui"):
		memory_event_ui.hide_ui()
	else:
		memory_event_ui.hide()

	_set_hint("", false)
	_update_target_highlight()


func _resolve_phase_from_game() -> void:
	if Game.first_battle_reward_done:
		_phase = ExplorePhase.TO_RELAY
	elif Game.memory_event_done:
		_phase = ExplorePhase.TO_BATTLE
	else:
		_phase = ExplorePhase.TO_MEMORY


func _interact_current_target() -> void:
	match current_target:
		"memory":
			_open_memory_event()
		"battle":
			if _phase == ExplorePhase.TO_BATTLE:
				_enter_tutorial_battle()
			elif _phase == ExplorePhase.TO_RELAY:
				_open_relay_report()
			else:
				_set_hint("先调查记忆残响。", true)


func _open_memory_event() -> void:
	if Game.memory_event_done:
		_set_hint("这段残响已经调查过。", true)
		return
	if not _can_interact_memory():
		_set_hint("你还无法锁定这段残响。", true)
		return

	memory_event_open = true
	current_target = ""
	_event_context = "memory"
	Game.in_dialogue = true
	_phase = ExplorePhase.MEMORY_EVENT
	_update_target_highlight()
	_set_hint("", false)

	if "event_text_value" in memory_event_ui:
		memory_event_ui.event_text_value = "你触碰到一段模糊的记忆残响。\n\n“不要相信报告上的死亡时间。”\n“我还在下面。”\n\n海水之下，有什么东西再一次呼唤了你。"
	if "choice_a_text" in memory_event_ui:
		memory_event_ui.choice_a_text = "继续追问那道呼唤。"
	if "choice_b_text" in memory_event_ui:
		memory_event_ui.choice_b_text = "先把异常记下并暂时封存。"

	if memory_event_ui.has_method("show_event"):
		memory_event_ui.show_event()
	else:
		memory_event_ui.show()


func _open_relay_report() -> void:
	memory_event_open = true
	current_target = ""
	_event_context = "relay"
	Game.in_dialogue = true
	_update_target_highlight()
	_set_hint("", false)

	if "event_text_value" in memory_event_ui:
		memory_event_ui.event_text_value = "你清除了盘踞在浅海中继点附近的异常体。\n\n残骸终端还能勉强启动，吐出一段残缺记录：\n\n“若再次收到来自海底的呼叫，切勿回应。”\n“门并未关闭。”\n\n你已经完成了这一次浅海任务，该返航了。"
	if "choice_a_text" in memory_event_ui:
		memory_event_ui.choice_a_text = "回收记录，立即返航。"
	if "choice_b_text" in memory_event_ui:
		memory_event_ui.choice_b_text = "记下警告，先将异常封存。"

	if memory_event_ui.has_method("show_event"):
		memory_event_ui.show_event()
	else:
		memory_event_ui.show()


func _on_memory_choice_selected(choice_id: String) -> void:
	if _event_context == "memory":
		if choice_id == "pursue":
			Game.tag_aggressive += 1
		elif choice_id == "seal":
			Game.tag_orderly += 1

		if Game.has_method("set_memory_choice"):
			Game.set_memory_choice(choice_id)

		# 这里是真正发牌
		if not Game.reward_card_given:
			Game.add_card(choice_id)
			Game.reward_card_given = true

		Game.memory_event_done = true
		_phase = ExplorePhase.TO_BATTLE
		return

	if _event_context == "relay":
		if Game.has_method("set_end_choice"):
			Game.set_end_choice(choice_id)

		_phase = ExplorePhase.COMPLETE
		_transitioning = true
		Game.in_dialogue = false
		call_deferred("_goto_end_scene")

func _on_memory_event_closed() -> void:
	if _transitioning:
		return

	memory_event_open = false
	Game.in_dialogue = false

	if _event_context == "memory":
		if Game.memory_event_done:
			_phase = ExplorePhase.TO_BATTLE
		else:
			_phase = ExplorePhase.TO_MEMORY
	elif _event_context == "relay":
		_phase = ExplorePhase.TO_RELAY

	_event_context = ""
	_update_global_stats()

	var ui := _get_global_ui()
	if ui and ui.has_method("refresh_deck_panel"):
		ui.refresh_deck_panel()

	_update_interaction_target()


func _goto_end_scene() -> void:
	Game.goto_end()


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
	_transitioning = true
	Game.in_dialogue = false
	Game.battle_index = 1
	_set_hint("", false)
	get_tree().change_scene_to_file(BATTLE_SCENE_PATH)


func _update_interaction_target() -> void:
	if memory_event_open or _transitioning:
		return

	var next_target: String = ""

	match _phase:
		ExplorePhase.TO_MEMORY:
			if _can_interact_memory():
				next_target = "memory"
		ExplorePhase.TO_BATTLE:
			if _player_in_battle_zone:
				next_target = "battle"
		ExplorePhase.TO_RELAY:
			if _player_in_battle_zone:
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
		memory_highlight.visible = (_phase == ExplorePhase.TO_MEMORY and _can_interact_memory() and not memory_event_open)

	if battle_highlight:
		battle_highlight.visible = (
			(_phase == ExplorePhase.TO_BATTLE or _phase == ExplorePhase.TO_RELAY)
			and _player_in_battle_zone
			and not memory_event_open
		)


func _update_hint_text() -> void:
	match _phase:
		ExplorePhase.TO_MEMORY:
			if current_target == "memory":
				_set_hint("目标：按 E 调查记忆残响。", true)
				return

			if _player_in_memory_zone and not Game.memory_event_done:
				if _is_memory_discovered():
					_set_hint("你锁定了残响位置，按 E 调查。", true)
				else:
					_set_hint("调整朝向，锁定前方残响。", true)
				return

			_set_hint("目标：先调查前方的记忆残响。", true)
			return

		ExplorePhase.TO_BATTLE:
			if current_target == "battle":
				_set_hint("目标：按 E 接近异常聚集点，进入首战。", true)
				return

			_set_hint("目标：前往异常聚集点。", true)
			return

		ExplorePhase.TO_RELAY:
			if current_target == "battle":
				_set_hint("目标：按 E 调查中继点残骸，完成本章。", true)
				return

			_set_hint("目标：返回中继点残骸，调查记录。", true)
			return

		ExplorePhase.MEMORY_EVENT:
			_set_hint("正在读取记忆残响……", true)
			return

		ExplorePhase.COMPLETE:
			_set_hint("任务完成。", true)
			return

	_set_hint("", false)


func _get_global_ui() -> Node:
	if not is_inside_tree():
		return null
	var tree := get_tree()
	if tree == null:
		return null
	var root := tree.root
	if root == null:
		return null
	return root.get_node_or_null("GlobalUI")


func _apply_global_ui_mode() -> void:
	var ui := _get_global_ui()
	if ui and ui.has_method("set_mode"):
		ui.set_mode(ui.MODE_EXPLORE)


func _set_hint(text: String, visible: bool) -> void:
	var ui := _get_global_ui()
	if ui:
		if visible:
			ui.set_hint(text, true)
		else:
			ui.clear_hint()
	elif is_instance_valid(hint_label):
		hint_label.text = text
		hint_label.visible = visible


func _update_global_stats() -> void:
	var ui := _get_global_ui()
	if ui and ui.has_method("refresh_stats"):
		ui.refresh_stats()
