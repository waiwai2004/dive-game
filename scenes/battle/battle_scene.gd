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
const STARTER_DECK: Array[String] = ["cut", "cut", "guard", "calm", "break", "release"]
const LEGACY_STARTER_DECK: Array[String] = ["cut", "cut", "guard", "guard", "calm", "break"]

const USE_PURPLE_ENEMY_BAR := true
const SFX_PATHS := {
	"card_hover": "res://assets/audio/sfx/sfx_card_hover.wav",
	"card_play": "res://assets/audio/sfx/sfx_card_play.wav",
	"hit": "res://assets/audio/sfx/sfx_hit.wav",
	"end_turn": "res://assets/audio/sfx/sfx_end_turn.wav"
}

@onready var boss_area: Control = $BossArea
@onready var boss_name_label: Label = $BossArea/BossStatsRoot/BossNameLabel
@onready var boss_hp_bar = $BossArea/BossStatsRoot/BossHpBar
@onready var boss_hp_label: Label = $BossArea/BossStatsRoot/BossHpLabel
@onready var boss_intent_label: Label = $BossArea/BossStatsRoot/BossIntentLabel
@onready var boss_portrait: CanvasItem = $BossArea/BossPortrait

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
var enemy_weak: int = 0
var enemy_pattern: Array[Dictionary] = []
var enemy_pattern_index: int = 0

var battle_state: int = BattleState.PLAYER_TURN
var _hint_request_id: int = 0
var _sfx_players: Dictionary = {}
var _boss_bar_flash_tween: Tween = null
var _boss_hit_tween: Tween = null
var _last_enemy_hp_for_flash: int = -1
var _end_turn_base_scale: Vector2 = Vector2.ONE
var _end_turn_base_modulate: Color = Color(1, 1, 1, 1)


func _ready() -> void:
	if has_node("/root/AudioManager"):
		AudioManager.play_bgm_segment("battle")

	_setup_sfx()
	_apply_boss_bar_visuals()
	_connect_ui_signals()
	_setup_end_turn_feedback()
	_apply_global_ui_mode()
	_hide_reward_story()
	_setup_enemy()
	_start_battle()


func _connect_ui_signals() -> void:
	if not end_turn_button.pressed.is_connected(_on_end_turn_button_pressed):
		end_turn_button.pressed.connect(_on_end_turn_button_pressed)
	if not end_turn_button.mouse_entered.is_connected(_on_end_turn_mouse_entered):
		end_turn_button.mouse_entered.connect(_on_end_turn_mouse_entered)
	if not end_turn_button.mouse_exited.is_connected(_on_end_turn_mouse_exited):
		end_turn_button.mouse_exited.connect(_on_end_turn_mouse_exited)
	if not end_turn_button.button_down.is_connected(_on_end_turn_button_down):
		end_turn_button.button_down.connect(_on_end_turn_button_down)
	if not end_turn_button.button_up.is_connected(_on_end_turn_button_up):
		end_turn_button.button_up.connect(_on_end_turn_button_up)

	var on_reward_selected: Callable = Callable(self, "_on_reward_story_selected")
	if reward_story_ui.has_signal("reward_selected") and not reward_story_ui.is_connected("reward_selected", on_reward_selected):
		reward_story_ui.connect("reward_selected", on_reward_selected)


func _setup_end_turn_feedback() -> void:
	_end_turn_base_scale = end_turn_button.scale
	_end_turn_base_modulate = end_turn_button.modulate
	end_turn_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _setup_sfx() -> void:
	for key in SFX_PATHS.keys():
		var player := AudioStreamPlayer.new()
		player.name = "Sfx_%s" % key
		player.bus = "Master"
		player.volume_db = _get_sfx_volume_db(key)

		var stream: Resource = load(str(SFX_PATHS[key]))
		if stream is AudioStream:
			player.stream = stream

		add_child(player)
		_sfx_players[key] = player


func _get_sfx_volume_db(key: String) -> float:
	match key:
		"card_hover":
			return -12.0
		"card_play":
			return -8.0
		"hit":
			return -7.0
		"end_turn":
			return -8.0
		_:
			return -8.0


func play_ui_sfx(key: String) -> void:
	if not _sfx_players.has(key):
		return
	var player: AudioStreamPlayer = _sfx_players[key]
	if player == null or player.stream == null:
		return
	if player.playing:
		player.stop()
	player.play()


func _apply_boss_bar_visuals() -> void:
	var fill := StyleBoxFlat.new()
	fill.corner_radius_top_left = 8
	fill.corner_radius_top_right = 8
	fill.corner_radius_bottom_left = 8
	fill.corner_radius_bottom_right = 8

	var background := StyleBoxFlat.new()
	background.corner_radius_top_left = 8
	background.corner_radius_top_right = 8
	background.corner_radius_bottom_left = 8
	background.corner_radius_bottom_right = 8
	background.bg_color = Color(0.08, 0.05, 0.12, 0.92)

	if USE_PURPLE_ENEMY_BAR:
		fill.bg_color = Color(0.58, 0.12, 0.75, 0.96)
		fill.border_width_left = 2
		fill.border_width_top = 2
		fill.border_width_right = 2
		fill.border_width_bottom = 2
		fill.border_color = Color(0.84, 0.52, 1.0, 0.92)
	else:
		fill.bg_color = Color(0.78, 0.12, 0.2, 0.96)
		fill.border_width_left = 2
		fill.border_width_top = 2
		fill.border_width_right = 2
		fill.border_width_bottom = 2
		fill.border_color = Color(1.0, 0.58, 0.62, 0.9)

	if boss_hp_bar is ProgressBar:
		boss_hp_bar.add_theme_stylebox_override("fill", fill)
		boss_hp_bar.add_theme_stylebox_override("background", background)

	boss_hp_bar.self_modulate = Color(1, 1, 1, 1)


func _setup_enemy() -> void:
	if _is_normal_battle():
		enemy_name = "浅海异常体"
		enemy_max_hp = 12
		enemy_hp = enemy_max_hp
		enemy_pattern = [
			{"type": "attack", "value": 2, "text": "撕咬：造成2点伤害"},
			{"type": "apply_weak", "value": 1, "text": "污染：施加1层虚弱"},
			{"type": "attack", "value": 4, "text": "扑袭：造成4点伤害"}
		]
	else:
		enemy_name = "深层凝视体"
		enemy_max_hp = 18
		enemy_hp = enemy_max_hp
		enemy_pattern = [
			{"type": "attack", "value": 3, "text": "凝视：造成3点伤害"},
			{"type": "apply_weak", "value": 2, "text": "侵蚀：施加2层虚弱"},
			{"type": "attack", "value": 5, "text": "重压：造成5点伤害"}
		]

	enemy_pattern_index = 0
	_last_enemy_hp_for_flash = enemy_hp
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

	_start_player_turn()


func set_battle_state(new_state: int) -> void:
	battle_state = new_state

	match battle_state:
		BattleState.PLAYER_TURN:
			show_hand_ui()
			set_hand_interactable(true)
			end_turn_button.disabled = false
			_hide_reward_story()
		BattleState.ENEMY_TURN:
			show_hand_ui()
			set_hand_interactable(false)
			end_turn_button.disabled = true
			_hide_reward_story()
		BattleState.REWARD:
			hide_hand_ui()
			set_hand_interactable(false)
			end_turn_button.disabled = true
			_open_reward_story()
		BattleState.FINISHED:
			hide_hand_ui()
			set_hand_interactable(false)
			end_turn_button.disabled = true
			_hide_reward_story()

	_refresh_ui()


func _start_player_turn() -> void:
	energy = ENERGY_PER_TURN
	draw_cards(HAND_DRAW_COUNT)
	set_battle_state(BattleState.PLAYER_TURN)
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
	_refresh_boss_ui()
	_refresh_hand_cards()
	_update_global_ui()


func _refresh_boss_ui() -> void:
	boss_name_label.text = enemy_name

	if "max_value" in boss_hp_bar:
		boss_hp_bar.max_value = float(maxi(enemy_max_hp, 1))
	if "value" in boss_hp_bar:
		boss_hp_bar.value = clamp(float(enemy_hp), 0.0, float(maxi(enemy_max_hp, 1)))

	boss_hp_label.text = "HP %d / %d" % [enemy_hp, enemy_max_hp]
	boss_intent_label.text = "意图：%s" % _get_enemy_intent_label_text()

	if _last_enemy_hp_for_flash > enemy_hp:
		_flash_boss_bar()
		_play_enemy_hit_feedback()
	_last_enemy_hp_for_flash = enemy_hp


func _flash_boss_bar() -> void:
	if _boss_bar_flash_tween and is_instance_valid(_boss_bar_flash_tween):
		_boss_bar_flash_tween.kill()
	boss_hp_bar.self_modulate = Color(1.35, 1.35, 1.35, 1.0)
	_boss_bar_flash_tween = create_tween()
	_boss_bar_flash_tween.tween_property(boss_hp_bar, "self_modulate", Color(1, 1, 1, 1), 0.18)


func _play_enemy_hit_feedback() -> void:
	if _boss_hit_tween and is_instance_valid(_boss_hit_tween):
		_boss_hit_tween.kill()

	var start_pos: Vector2 = boss_area.position
	var start_modulate: Color = boss_portrait.modulate
	boss_portrait.modulate = Color(1.25, 1.15, 1.15, 1.0)

	_boss_hit_tween = create_tween()
	_boss_hit_tween.set_trans(Tween.TRANS_QUAD)
	_boss_hit_tween.set_ease(Tween.EASE_OUT)
	_boss_hit_tween.tween_property(boss_area, "position", start_pos + Vector2(-8, 2), 0.03)
	_boss_hit_tween.tween_property(boss_area, "position", start_pos + Vector2(8, -2), 0.03)
	_boss_hit_tween.tween_property(boss_area, "position", start_pos + Vector2(-4, 1), 0.03)
	_boss_hit_tween.tween_property(boss_area, "position", start_pos, 0.04)
	_boss_hit_tween.parallel().tween_property(boss_portrait, "modulate", start_modulate, 0.16)


func _get_enemy_intent_label_text() -> String:
	var intent: Dictionary = _get_current_enemy_intent()
	var intent_type: String = str(intent.get("type", "attack"))
	var value: int = int(intent.get("value", 0))
	var text: String = str(intent.get("text", "攻击"))

	if intent_type == "attack":
		var final_damage: int = _apply_weak_to_damage(value, enemy_weak)
		if enemy_weak > 0:
			return "%s（实际 %d，虚弱%d）" % [text, final_damage, enemy_weak]
		return "%s" % text

	if intent_type == "apply_weak":
		return "%s" % text

	return text


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

	if hand.is_empty() and Game.player_cognition > 0:
		Game.clear_cognition()
		_show_battle_hint("你打空了手牌，认知负荷清零。", 0.8)

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
	var explicit_target: String = str(card.get("target", "enemy"))
	if explicit_target == "enemy" or explicit_target == "player":
		return explicit_target
	return "enemy"


func _apply_card_effect(card: Dictionary, target: String) -> void:
	var card_name: String = str(card.get("name", "未知卡牌"))
	var damage: int = int(card.get("damage", 0))
	var block_gain: int = int(card.get("block", 0))
	var san_heal: int = int(card.get("san_heal", 0))
	var apply_weak: int = int(card.get("apply_weak", 0))
	var san_cost: int = int(card.get("san_cost", 0))
	var draw_count: int = int(card.get("draw", 0))
	var gain_energy: int = int(card.get("gain_energy", 0))
	var reduce_cognition: int = int(card.get("reduce_cognition", 0))

	var messages: Array[String] = []
	var dealt_damage := false

	if damage > 0:
		if target == "enemy":
			var final_damage: int = _apply_weak_to_damage(damage, player_weak)
			enemy_hp = maxi(0, enemy_hp - final_damage)
			messages.append("造成 %d 点伤害" % final_damage)
			if final_damage > 0:
				dealt_damage = true
		else:
			var damage_to_hp: int = maxi(0, damage - player_block)
			player_block = maxi(player_block - damage, 0)
			Game.damage_player(damage_to_hp, damage)
			messages.append("承受 %d 点伤害" % damage)

	if block_gain > 0:
		player_block += block_gain
		messages.append("获得 %d 护盾" % block_gain)

	if san_heal > 0:
		Game.heal_san(san_heal)
		messages.append("恢复 %d SAN" % san_heal)

	if apply_weak > 0:
		if target == "enemy":
			enemy_weak += apply_weak
			messages.append("施加 %d 层虚弱" % apply_weak)
		else:
			player_weak += apply_weak
			messages.append("你获得 %d 层虚弱" % apply_weak)

	if san_cost > 0:
		Game.player_san = maxi(Game.player_san - san_cost, 0)
		messages.append("失去 %d SAN" % san_cost)

	if gain_energy > 0:
		energy += gain_energy
		messages.append("获得 %d 点能量" % gain_energy)

	if draw_count > 0:
		draw_cards(draw_count)
		messages.append("抽 %d 张牌" % draw_count)

	if reduce_cognition > 0:
		Game.reduce_cognition(reduce_cognition)
		messages.append("降低 %d 点认知" % reduce_cognition)

	if dealt_damage:
		play_ui_sfx("hit")

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


func _on_end_turn_mouse_entered() -> void:
	if end_turn_button.disabled:
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(end_turn_button, "scale", _end_turn_base_scale * 1.05, 0.10)
	tween.parallel().tween_property(end_turn_button, "modulate", Color(1.08, 1.08, 1.12, 1.0), 0.10)


func _on_end_turn_mouse_exited() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(end_turn_button, "scale", _end_turn_base_scale, 0.10)
	tween.parallel().tween_property(end_turn_button, "modulate", _end_turn_base_modulate, 0.10)


func _on_end_turn_button_down() -> void:
	if end_turn_button.disabled:
		return
	var tween := create_tween()
	tween.tween_property(end_turn_button, "scale", _end_turn_base_scale * 0.97, 0.05)


func _on_end_turn_button_up() -> void:
	if end_turn_button.disabled:
		return
	var tween := create_tween()
	tween.tween_property(end_turn_button, "scale", _end_turn_base_scale * 1.05, 0.06)


func _on_end_turn_button_pressed() -> void:
	if battle_state != BattleState.PLAYER_TURN:
		return

	play_ui_sfx("end_turn")

	if player_weak > 0:
		player_weak = maxi(player_weak - 1, 0)

	await _enemy_turn()


func _enemy_turn() -> void:
	set_battle_state(BattleState.ENEMY_TURN)
	_discard_hand_to_discard_pile()

	var intent: Dictionary = _get_current_enemy_intent()
	var intent_type: String = str(intent.get("type", "attack"))
	var value: int = int(intent.get("value", 0))

	match intent_type:
		"attack":
			var final_attack: int = _apply_weak_to_damage(value, enemy_weak)
			var damage_to_hp: int = maxi(0, final_attack - player_block)
			player_block = maxi(player_block - final_attack, 0)
			Game.damage_player(damage_to_hp, final_attack)
			play_ui_sfx("hit")
			_show_battle_hint("敌人发动【%s】，你受到 %d 点存在伤害，并损失 %d SAN。" % [str(intent.get("text", "攻击")), damage_to_hp, final_attack], 1.0)
		"apply_weak":
			player_weak += value
			_show_battle_hint("敌人发动【%s】，你获得 %d 层虚弱。" % [str(intent.get("text", "侵蚀")), value], 1.0)
		_:
			_show_battle_hint("敌人正在蠢动。", 0.8)

	if enemy_weak > 0:
		enemy_weak = maxi(enemy_weak - 1, 0)

	_update_global_ui()
	_refresh_boss_ui()

	if Game.player_hp <= 0:
		await _on_battle_lose()
		return

	_advance_enemy_intent()
	await get_tree().create_timer(0.35).timeout
	_start_player_turn()


func _discard_hand_to_discard_pile() -> void:
	for card_id in hand:
		discard_pile.append(card_id)
	hand.clear()


func _on_battle_win() -> void:
	_clear_battle_runtime()
	_show_battle_hint("战斗胜利。", 1.0)
	_update_global_ui()

	if _is_normal_battle():
		if Game.first_battle_reward_done:
			set_battle_state(BattleState.FINISHED)
			await get_tree().create_timer(0.6).timeout
			Game.goto_explore()
			return

		set_battle_state(BattleState.REWARD)
		_show_battle_hint("战斗胜利，做出你的选择。")
		return

	set_battle_state(BattleState.FINISHED)
	if has_node("/root/GlobalUI"):
		GlobalUI.clear_energy()
	await get_tree().create_timer(1.0).timeout
	Game.goto_end()


func _on_battle_lose() -> void:
	set_battle_state(BattleState.FINISHED)
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
	set_battle_state(BattleState.FINISHED)

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
	return Game.battle_index <= 1


func _ensure_playable_deck() -> void:
	if Game.deck == LEGACY_STARTER_DECK:
		Game.deck = STARTER_DECK.duplicate()
		return

	if Game.deck.size() >= HAND_DRAW_COUNT:
		return

	Game.deck.clear()
	for card_id in STARTER_DECK:
		Game.deck.append(card_id)


func _get_current_enemy_intent() -> Dictionary:
	if enemy_pattern.is_empty():
		return {"type": "attack", "value": 2, "text": "攻击：造成2点伤害"}
	return enemy_pattern[enemy_pattern_index % enemy_pattern.size()]


func _advance_enemy_intent() -> void:
	if enemy_pattern.is_empty():
		return
	enemy_pattern_index = (enemy_pattern_index + 1) % enemy_pattern.size()


func show_hand_ui() -> void:
	hand_ui.visible = true


func hide_hand_ui() -> void:
	hand_ui.visible = false


func _set_container_interactable(container: Container, enabled: bool, filter_value: int) -> void:
	container.mouse_filter = filter_value
	for node in container.get_children():
		if node is Control:
			(node as Control).mouse_filter = filter_value
		if node is Button:
			(node as Button).disabled = not enabled


func set_hand_interactable(enabled: bool) -> void:
	var filter_value: int = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	_set_container_interactable(left_hand_area, enabled, filter_value)
	_set_container_interactable(right_hand_area, enabled, filter_value)
