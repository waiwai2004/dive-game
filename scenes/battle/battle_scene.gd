extends Control

enum BattleState {
	PLAYER_TURN,
	ENEMY_TURN,
	REWARD,
	FINISHED
}

const CARD_SCENE := preload("res://scenes/battle/CardUI.tscn")
const ENERGY_PER_TURN := 3
const HAND_DRAW_COUNT := 5
const STARTER_DECK: Array[String] = ["cut", "cut", "guard", "guard", "calm", "break"]

@onready var boss_name_label: Label = $BossArea/BossStatsRoot/BossNameLabel
@onready var boss_hp_bar: ProgressBar = $BossArea/BossStatsRoot/BossHpBar
@onready var boss_hp_label: Label = $BossArea/BossStatsRoot/BossHpLabel
@onready var boss_intent_label: Label = $BossArea/BossStatsRoot/BossIntentLabel

@onready var left_hand_area: HBoxContainer = $HandUI/LeftHandArea
@onready var right_hand_area: HBoxContainer = $HandUI/RightHandArea
@onready var hand_ui: CanvasLayer = $HandUI
@onready var end_turn_button: Button = $EndTurnButton

@onready var battle_hint_root: Control = $BattleHintRoot
@onready var hint_label: Label = $BattleHintRoot/HintBg/HintLabel

@onready var reward_story_ui: Node = $RewardStoryUI

var draw_pile: Array[String] = []
var hand: Array[String] = []
var discard_pile: Array[String] = []

var energy: int = ENERGY_PER_TURN
var player_block: int = 0
var player_weak: int = 0

var enemy_name: String = "异常体"
var enemy_hp: int = 8
var enemy_max_hp: int = 8
var enemy_attack: int = 2
var enemy_weak: int = 0

var battle_state: int = BattleState.PLAYER_TURN
var _hint_request_id: int = 0


func _ready() -> void:
	if has_node("/root/AudioManager"):
		AudioManager.play_bgm_segment("battle")

	_apply_global_ui_mode()
	_connect_ui_signals()
	_hide_reward_story()
	_setup_enemy()
	_start_battle()


func _connect_ui_signals() -> void:
	if not end_turn_button.pressed.is_connected(_on_end_turn_button_pressed):
		end_turn_button.pressed.connect(_on_end_turn_button_pressed)

	var on_reward_selected: Callable = Callable(self, "_on_reward_story_selected")
	if reward_story_ui.has_signal("reward_selected") and not reward_story_ui.is_connected("reward_selected", on_reward_selected):
		reward_story_ui.connect("reward_selected", on_reward_selected)


func _setup_enemy() -> void:
	if _is_normal_battle():
		enemy_name = "浅海异常体"
		enemy_max_hp = 10
		enemy_hp = enemy_max_hp
		enemy_attack = 2
	else:
		enemy_name = "深层凝视体"
		enemy_max_hp = 18
		enemy_hp = enemy_max_hp
		enemy_attack = 4

	_refresh_boss_ui()
	_show_battle_hint("%s 逼近。" % enemy_name)


func _start_battle() -> void:
	if Game.deck.is_empty():
		Game.reset_run()
	_ensure_playable_deck()

	draw_pile = Game.deck.duplicate()
	draw_pile.shuffle()
	hand.clear()
	discard_pile.clear()

	player_block = 0
	player_weak = 0
	enemy_weak = 0
	Game.clear_cognition()
	show_hand_ui()
	set_hand_interactable(false)

	_start_player_turn()


func _start_player_turn() -> void:
	battle_state = BattleState.PLAYER_TURN
	energy = ENERGY_PER_TURN
	draw_cards(HAND_DRAW_COUNT)
	show_hand_ui()
	set_hand_interactable(true)
	_refresh_ui()
	_show_battle_hint("你的回合：点击卡牌出牌，或结束回合。")


func draw_cards(count: int) -> void:
	for _i in range(count):
		if draw_pile.is_empty():
			draw_pile = discard_pile.duplicate()
			discard_pile.clear()
			draw_pile.shuffle()

		if draw_pile.is_empty():
			break

		hand.append(draw_pile.pop_back())


func _refresh_ui() -> void:
	_sync_hand_ui_state()
	_refresh_boss_ui()
	_refresh_hand_cards()
	end_turn_button.disabled = battle_state != BattleState.PLAYER_TURN
	_update_global_ui()


func _refresh_boss_ui() -> void:
	boss_name_label.text = enemy_name
	boss_hp_bar.max_value = float(maxi(enemy_max_hp, 1))
	boss_hp_bar.value = clamp(float(enemy_hp), 0.0, float(maxi(enemy_max_hp, 1)))
	boss_hp_label.text = "HP %d / %d" % [enemy_hp, enemy_max_hp]

	var intent_attack: int = _apply_weak_to_damage(enemy_attack, enemy_weak)
	var weak_note: String = ""
	if enemy_weak > 0:
		weak_note = "（虚弱%d）" % enemy_weak
	boss_intent_label.text = "意图：下回合攻击 %d %s" % [intent_attack, weak_note]


func _refresh_hand_cards() -> void:
	_clear_container_cards(left_hand_area)
	_clear_container_cards(right_hand_area)

	var hand_count: int = hand.size()
	if hand_count <= 0:
		return

	var left_count: int = int(ceil(float(hand_count) / 2.0))
	for i in range(hand_count):
		var card_id: String = hand[i]
		var card_data: Dictionary = CardDatabase.get_card(card_id)
		var card_ui: Node = CARD_SCENE.instantiate()
		card_ui.call("setup", card_data, i, self)
		card_ui.set("disabled", battle_state != BattleState.PLAYER_TURN or _get_effective_cost(card_data) > energy)

		if i < left_count:
			left_hand_area.add_child(card_ui)
		else:
			right_hand_area.add_child(card_ui)


func _clear_container_cards(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func play_card(card_index: int) -> void:
	if battle_state != BattleState.PLAYER_TURN:
		return
	if card_index < 0 or card_index >= hand.size():
		return

	var card_id: String = hand[card_index]
	var card: Dictionary = CardDatabase.get_card(card_id)
	var cost: int = _get_effective_cost(card)
	if cost > energy:
		_show_battle_hint("能量不足。", 0.8)
		_refresh_ui()
		return

	energy -= cost
	_apply_card_effect(card, _resolve_target(card))
	_apply_cognition_cost(card)

	discard_pile.append(card_id)
	hand.remove_at(card_index)

	if Game.player_hp <= 0:
		await _on_battle_lose()
		return

	if enemy_hp <= 0:
		await _on_battle_win()
		return

	_refresh_ui()


func _get_effective_cost(card: Dictionary) -> int:
	var cost: int = int(card.get("cost", 0))
	if Game.is_distorted():
		cost += 1
	return maxi(cost, 0)


func _resolve_target(card: Dictionary) -> String:
	var explicit_target: String = str(card.get("target", ""))
	if explicit_target == "enemy" or explicit_target == "player":
		return explicit_target

	var card_type: String = str(card.get("type", ""))
	match card_type:
		"attack", "debuff":
			return "enemy"
		"buff", "utility":
			return "player"
		_:
			return "enemy"


func _apply_card_effect(card: Dictionary, target: String) -> void:
	var card_name: String = str(card.get("name", "未知卡牌"))
	var damage: int = int(card.get("damage", 0))
	var block_gain: int = int(card.get("block", 0))
	var san_heal: int = int(card.get("san_heal", 0))
	var apply_weak: int = int(card.get("apply_weak", 0))
	var san_cost: int = int(card.get("san_cost", 0))

	var messages: Array[String] = []

	if damage > 0:
		if target == "enemy":
			var final_damage: int = _apply_weak_to_damage(damage, player_weak)
			enemy_hp = maxi(0, enemy_hp - final_damage)
			messages.append("造成 %d 点伤害" % final_damage)
		else:
			Game.damage_player(damage)
			messages.append("承受 %d 点伤害" % damage)

	if block_gain > 0:
		player_block += block_gain
		messages.append("鑾峰緱 %d 鎶ょ浘" % block_gain)

	if san_heal > 0:
		Game.heal_san(san_heal)
		messages.append("鎭㈠ %d SAN" % san_heal)

	if apply_weak > 0:
		if target == "enemy":
			enemy_weak += apply_weak
			messages.append("施加 %d 层虚弱" % apply_weak)
		else:
			player_weak += apply_weak
			messages.append("你获得 %d 层虚弱" % apply_weak)

	if san_cost > 0:
		Game.player_san = maxi(Game.player_san - san_cost, 0)
		messages.append("澶卞幓 %d SAN" % san_cost)

	if messages.is_empty():
		_show_battle_hint("你使用了【%s】。" % card_name, 0.9)
	else:
		_show_battle_hint("你使用【%s】：%s。" % [card_name, _join_messages(messages)], 1.0)

	_refresh_boss_ui()
	_update_global_ui()


func _apply_cognition_cost(card: Dictionary) -> void:
	var cognition_gain: int = int(card.get("cognition", 0))
	if cognition_gain <= 0:
		return

	Game.add_cognition(cognition_gain)
	var cognition_max: int = maxi(Game.max_cognition, 1)

	if Game.player_cognition > cognition_max:
		var hp_before: int = Game.player_hp
		var hp_after: int = int(round(float(hp_before) / 2.0))
		if hp_before > 0:
			hp_after = maxi(hp_after, 1)

		Game.player_hp = clampi(hp_after, 0, Game.max_hp)
		Game.clear_cognition()
		_show_battle_hint("认知超载！存在值由 %d 变为 %d。" % [hp_before, Game.player_hp], 1.2)

	_update_global_ui()


func _on_end_turn_button_pressed() -> void:
	if battle_state != BattleState.PLAYER_TURN:
		return
	await _enemy_turn()


func _enemy_turn() -> void:
	battle_state = BattleState.ENEMY_TURN
	set_hand_interactable(false)
	end_turn_button.disabled = true

	var final_attack: int = _apply_weak_to_damage(enemy_attack, enemy_weak)
	var damage_to_hp: int = maxi(0, final_attack - player_block)
	player_block = 0
	Game.damage_player(damage_to_hp)

	if enemy_weak > 0:
		enemy_weak = maxi(enemy_weak - 1, 0)

	if player_weak > 0:
		player_weak = maxi(player_weak - 1, 0)

	_show_battle_hint("敌人攻击，造成 %d 点伤害。" % damage_to_hp, 1.0)
	_update_global_ui()

	if Game.player_hp <= 0:
		await _on_battle_lose()
		return

	hand.clear()
	await get_tree().create_timer(0.35).timeout
	_start_player_turn()


func _on_battle_win() -> void:
	battle_state = BattleState.FINISHED
	hide_hand_ui()
	set_hand_interactable(false)
	_clear_battle_runtime()
	_show_battle_hint("战斗胜利。", 1.0)
	_update_global_ui()

	if _is_normal_battle():
		if Game.first_battle_reward_done:
			await get_tree().create_timer(0.6).timeout
			Game.goto_explore()
			return

		await get_tree().create_timer(0.45).timeout
		_open_reward_story()
		return

	if has_node("/root/GlobalUI"):
		GlobalUI.clear_energy()
	await get_tree().create_timer(1.0).timeout
	Game.goto_end()


func _on_battle_lose() -> void:
	battle_state = BattleState.FINISHED
	hide_hand_ui()
	set_hand_interactable(false)
	_clear_battle_runtime()
	_show_battle_hint("你的意识溃散了。", 1.0)
	_update_global_ui()

	if has_node("/root/GlobalUI"):
		GlobalUI.clear_energy()
	await get_tree().create_timer(1.0).timeout
	Game.goto_title()


func _clear_battle_runtime() -> void:
	energy = 0
	player_block = 0
	player_weak = 0
	enemy_weak = 0
	Game.clear_cognition()


func _open_reward_story() -> void:
	battle_state = BattleState.REWARD
	hide_hand_ui()
	set_hand_interactable(false)
	end_turn_button.disabled = true

	if reward_story_ui.has_method("show_ui"):
		reward_story_ui.call("show_ui")
	else:
		reward_story_ui.show()

	_show_battle_hint("做出你的选择。")


func _on_reward_story_selected(card_id: String) -> void:
	if battle_state != BattleState.REWARD:
		return
	if card_id != "pursue" and card_id != "seal":
		return

	Game.add_card(card_id)
	Game.first_battle_reward_done = true
	battle_state = BattleState.FINISHED
	_hide_reward_story()

	var reward_name: String = str(CardDatabase.get_card(card_id).get("name", card_id))
	_show_battle_hint("你获得了【%s】。" % reward_name, 0.8)

	await get_tree().create_timer(0.6).timeout
	Game.goto_explore()


func _hide_reward_story() -> void:
	if reward_story_ui.has_method("hide_ui"):
		reward_story_ui.call("hide_ui")
	else:
		reward_story_ui.hide()


func _show_battle_hint(text: String, auto_hide_seconds: float = 0.0) -> void:
	_hint_request_id += 1
	var request_id: int = _hint_request_id

	hint_label.text = text
	battle_hint_root.show()
	_set_global_hint(text)

	if auto_hide_seconds <= 0.0:
		return

	await get_tree().create_timer(auto_hide_seconds).timeout
	if request_id != _hint_request_id:
		return

	battle_hint_root.hide()


func _apply_global_ui_mode() -> void:
	if has_node("/root/GlobalUI"):
		GlobalUI.set_mode(GlobalUI.MODE_BATTLE)


func _set_global_hint(text: String) -> void:
	if has_node("/root/GlobalUI"):
		GlobalUI.set_hint(text, true)


func _update_global_ui() -> void:
	if has_node("/root/GlobalUI"):
		GlobalUI.refresh_stats()
		GlobalUI.set_energy(
			maxi(energy, 0),
			ENERGY_PER_TURN,
			true,
			maxi(player_block, 0),
			Game.player_cognition,
			maxi(Game.max_cognition, 1)
		)


func _apply_weak_to_damage(base_damage: int, weak_stack: int) -> int:
	if base_damage <= 0:
		return 0
	if weak_stack <= 0:
		return base_damage
	return maxi(1, base_damage - weak_stack)


func _join_messages(messages: Array[String]) -> String:
	if messages.is_empty():
		return ""
	var text: String = messages[0]
	for i in range(1, messages.size()):
		text += "，" + messages[i]
	return text


func _is_normal_battle() -> bool:
	# battle_index 在旧流程里可能是 0 或 1，都视为首场普通战
	return Game.battle_index <= 1


func _ensure_playable_deck() -> void:
	if Game.deck.size() >= HAND_DRAW_COUNT:
		return
	Game.deck.clear()
	for card_id in STARTER_DECK:
		Game.deck.append(card_id)


func show_hand_ui() -> void:
	hand_ui.visible = true


func hide_hand_ui() -> void:
	hand_ui.visible = false


func set_hand_interactable(enabled: bool) -> void:
	var filter_value: int = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	left_hand_area.mouse_filter = filter_value
	right_hand_area.mouse_filter = filter_value

	for node in left_hand_area.get_children():
		if node is Control:
			(node as Control).mouse_filter = filter_value
		if node is Button:
			(node as Button).disabled = not enabled

	for node in right_hand_area.get_children():
		if node is Control:
			(node as Control).mouse_filter = filter_value
		if node is Button:
			(node as Button).disabled = not enabled


func _sync_hand_ui_state() -> void:
	match battle_state:
		BattleState.PLAYER_TURN:
			show_hand_ui()
			set_hand_interactable(true)
		BattleState.REWARD, BattleState.FINISHED:
			hide_hand_ui()
			set_hand_interactable(false)
		_:
			show_hand_ui()
			set_hand_interactable(false)
