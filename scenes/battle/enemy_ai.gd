## 敌人 AI
## 职责：
##  - 从 EnemyDatabase 读取敌人与敌方卡牌数据
##  - 基于偏好与当前精神负荷规划本回合要打出的卡
##  - 处理敌方自身 Buff / 状态，并返回需要 battle_scene 结算的结果
class_name BattleEnemyAI
extends Node

signal log_emitted(text: String)
signal hp_changed(hp: int, max_hp: int)

const INNER_DRIVE_EXTRA_TURN_CHANCE := 0.2

var enemy_id: String = ""
var enemy_name: String = "未知敌人"
var hp: int = 1
var max_hp: int = 1
var max_san: int = 1
var weak: int = 0
var energy: int = 0
var energy_max: int = 10
var energy_gain_per_turn: int = 3
var hand_preview: Array[String] = []
var draw_pile: Array[EnemyCardData] = []
var hand: Array[EnemyCardData] = []
var discard_pile: Array[EnemyCardData] = []

var _enemy_data: EnemyData
var _enemy_buff_manager: BuffManager
var _player_buff_manager: BuffManager
var _inner_drive_active: bool = false


func setup(enemy_key: String, enemy_buff_manager: BuffManager = null, player_buff_manager: BuffManager = null) -> void:
	_enemy_buff_manager = enemy_buff_manager
	_player_buff_manager = player_buff_manager
	enemy_id = enemy_key
	_enemy_data = EnemyDatabase.get_enemy_data(enemy_key)

	if _enemy_data == null:
		push_warning("[BattleEnemyAI] enemy data not found: %s, fallback to corpse_shrimp" % enemy_key)
		_enemy_data = EnemyDatabase.get_enemy_data("corpse_shrimp")

	if _enemy_data == null:
		push_error("[BattleEnemyAI] fallback enemy data missing")
		return

	enemy_id = _enemy_data.enemy_id
	enemy_name = _enemy_data.enemy_name
	max_hp = _enemy_data.max_hp
	max_san = _enemy_data.max_san
	energy_max = _enemy_data.energy_max
	energy_gain_per_turn = _enemy_data.energy_gain_per_turn
	hp = max_hp
	energy = 0
	weak = 0
	_inner_drive_active = false
	draw_pile = _enemy_data.get_expanded_cards()
	draw_pile.shuffle()
	hand.clear()
	discard_pile.clear()
	_draw_all_cards_to_hand()
	hp_changed.emit(hp, max_hp)


func get_enemy_data() -> EnemyData:
	return _enemy_data


func get_portrait_path() -> String:
	if _enemy_data == null:
		return ""
	return _enemy_data.portrait_path


func start_turn() -> void:
	energy = mini(energy + energy_gain_per_turn, energy_max)
	if hand.is_empty():
		_refill_hand_from_discard()


func get_current_intent() -> Dictionary:
	var projected_energy := mini(energy + energy_gain_per_turn, energy_max)
	var available_cards: Array[EnemyCardData] = hand.duplicate()
	if available_cards.is_empty():
		available_cards = discard_pile.duplicate()
	var planned_cards := _plan_cards_for_energy(projected_energy, available_cards)
	var names: Array[String] = []
	for card in planned_cards:
		names.append(card.card_name)
	return {
		"energy": projected_energy,
		"cards": names,
		"text": "，".join(names) if not names.is_empty() else "蓄势",
	}


func get_current_intent_display() -> String:
	var intent := get_current_intent()
	var names: Array = intent.get("cards", [])
	if names.is_empty():
		return "蓄势：保留精神负荷"
	return "计划：%s" % " + ".join(names)


func take_damage(damage: int) -> void:
	if damage <= 0:
		return
	_set_hp(hp - damage)


func lose_presence_direct(amount: int) -> void:
	if amount <= 0:
		return
	_set_hp(hp - amount)


func apply_weak(stacks: int) -> void:
	if stacks > 0:
		weak += stacks


func is_dead() -> bool:
	return hp <= 0


func execute_turn(player_block: int) -> Dictionary:
	var planned_cards := _plan_cards_for_energy(energy, hand.duplicate())
	var remaining_block := player_block
	var remaining_energy := energy
	var result := {
		"block_consumed": 0,
		"damage_to_player": 0,
		"raw_attack_value": 0,
		"weak_applied_to_player": 0,
		"direct_hp_loss": 0,
		"swap_player_hp_san": false,
		"played_cards": [],
	}

	for card in planned_cards:
		if card == null:
			continue
		if card.energy_cost > remaining_energy:
			continue
		var hand_index := hand.find(card)
		if hand_index < 0:
			continue
		remaining_energy -= card.energy_cost
		result.played_cards.append(card.card_name)
		_apply_card_effect(card, result, remaining_block)
		remaining_block = maxi(player_block - int(result.block_consumed), 0)
		discard_pile.append(card)
		hand.remove_at(hand_index)

	energy = remaining_energy
	_refresh_hand_preview()
	if result.played_cards.is_empty():
		log_emitted.emit("%s 暂时没有合适的牌可出，选择蓄势。" % enemy_name)

	return result


func end_turn_tick() -> bool:
	if weak > 0:
		weak = maxi(weak - 1, 0)
	if _inner_drive_active and randf() < INNER_DRIVE_EXTRA_TURN_CHANCE:
		return true
	return false


func get_active_buffs_info() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if weak > 0:
		result.append({
			"name": "虚弱",
			"stacks": weak,
			"description": "敌人造成伤害时会被虚弱减值。"
		})
	if _inner_drive_active:
		result.append({
			"name": "内驱力",
			"stacks": -1,
			"description": "回合结束后有 20% 概率立刻再行动一次。"
		})
	if _enemy_buff_manager:
		for info in _enemy_buff_manager.get_all_active_buffs_info():
			result.append(info)
	return result


func _plan_cards_for_energy(available_energy: int, source_cards: Array[EnemyCardData]) -> Array[EnemyCardData]:
	if _enemy_data == null:
		return []

	var remaining_energy := available_energy
	var available_cards := source_cards
	var plan: Array[EnemyCardData] = []

	while true:
		var best_index := _pick_best_card_index(available_cards, remaining_energy)
		if best_index < 0:
			break
		var card: EnemyCardData = available_cards[best_index]
		plan.append(card)
		remaining_energy -= card.energy_cost
		available_cards.remove_at(best_index)

	return plan


func _draw_all_cards_to_hand() -> void:
	while not draw_pile.is_empty():
		hand.append(draw_pile.pop_back())
	_refresh_hand_preview()


func _refill_hand_from_discard() -> void:
	if discard_pile.is_empty():
		_refresh_hand_preview()
		return
	draw_pile = discard_pile.duplicate()
	discard_pile.clear()
	draw_pile.shuffle()
	_draw_all_cards_to_hand()
	log_emitted.emit("%s 将弃牌堆洗回并重新获得全部手牌。" % enemy_name)


func _refresh_hand_preview() -> void:
	hand_preview.clear()
	for card in hand:
		if card == null:
			continue
		hand_preview.append(card.card_name)


func _pick_best_card_index(cards: Array[EnemyCardData], available_energy: int) -> int:
	var best_index := -1
	var best_score := -999999
	for i in range(cards.size()):
		var card := cards[i]
		if card == null or card.energy_cost > available_energy:
			continue
		var score := _score_card(card, available_energy)
		if score > best_score:
			best_score = score
			best_index = i
	return best_index


func _score_card(card: EnemyCardData, available_energy: int) -> int:
	var priorities := _get_category_priorities()
	var category_rank := priorities.find(card.category)
	if category_rank < 0:
		category_rank = priorities.size() + 1

	var score := 1000 - category_rank * 100
	score += card.energy_cost * 10
	score -= maxi(available_energy - card.energy_cost, 0)

	match card.effect_key:
		"direct_presence_loss", "swap_player_hp_san":
			score += 25
		"self_state_inner_drive":
			if _inner_drive_active:
				score -= 200
			else:
				score += 20
		"self_buff_survival":
			if hp <= 1:
				score -= 120
			elif _enemy_buff_manager and _enemy_buff_manager.has_buff("残存"):
				score -= 80
			else:
				score += 15
		"self_buff_resilience":
			score += 10
		_:
			pass

	return score


func _get_category_priorities() -> Array[String]:
	if _enemy_data == null:
		return []

	match _enemy_data.ai_profile:
		"corpse_shrimp":
			if hp >= maxi(_enemy_data.ai_threshold_hp, 1):
				return ["理解", "共情", "机制", "重构"]
			return ["共情", "理解", "机制", "重构"]
		"motor_jellyfish":
			return ["机制", "理解", "共情", "重构"]
		"black_bubble":
			return ["共情", "重构", "理解", "机制"]
		_:
			return ["理解", "共情", "机制", "重构"]


func _apply_card_effect(card: EnemyCardData, result: Dictionary, remaining_block: int) -> void:
	match card.effect_key:
		"damage", "damage_all":
			var attack_value := BattleCardSystem.apply_weak_to_damage(card.effect_value, weak)
			var damage_to_hp := maxi(0, attack_value - remaining_block)
			var block_used := mini(attack_value, remaining_block)
			result.block_consumed += block_used
			result.damage_to_player += damage_to_hp
			result.raw_attack_value += attack_value
			log_emitted.emit("%s 使用【%s】，造成%d点伤害。" % [enemy_name, card.card_name, damage_to_hp])
		"self_buff_resilience":
			_add_enemy_buff("坚韧", card.effect_value)
			log_emitted.emit("%s 使用【%s】，获得%d层坚韧。" % [enemy_name, card.card_name, card.effect_value])
		"self_buff_survival":
			_add_enemy_buff("残存", card.effect_value)
			log_emitted.emit("%s 使用【%s】，获得%d层残存。" % [enemy_name, card.card_name, card.effect_value])
		"apply_player_paralysis":
			_add_player_debuff("麻痹", card.effect_value)
			log_emitted.emit("%s 使用【%s】，你获得%d层麻痹。" % [enemy_name, card.card_name, card.effect_value])
		"apply_player_confusion":
			_add_player_debuff("混乱", card.effect_value)
			log_emitted.emit("%s 使用【%s】，你获得%d层混乱。" % [enemy_name, card.card_name, card.effect_value])
		"self_state_inner_drive":
			_inner_drive_active = true
			log_emitted.emit("%s 使用【%s】，进入内驱力状态。" % [enemy_name, card.card_name])
		"direct_presence_loss":
			result.direct_hp_loss += card.effect_value
			log_emitted.emit("%s 使用【%s】，直接削减你%d点存在值。" % [enemy_name, card.card_name, card.effect_value])
		"swap_player_hp_san":
			result.swap_player_hp_san = true
			log_emitted.emit("%s 使用【%s】，扭曲了你的存在值与 SAN 值。" % [enemy_name, card.card_name])
		_:
			log_emitted.emit("%s 使用了【%s】。" % [enemy_name, card.card_name])


func _add_enemy_buff(buff_name: String, stacks: int) -> void:
	if _enemy_buff_manager == null or stacks <= 0:
		return
	match buff_name:
		"坚韧":
			var resilience := ResilienceBuff.new()
			resilience.set_stacks(stacks)
			_enemy_buff_manager.add_buff(resilience)
		"残存":
			var survival := SurvivalBuff.new()
			survival.set_stacks(stacks)
			_enemy_buff_manager.add_buff(survival)


func _add_player_debuff(buff_name: String, stacks: int) -> void:
	if _player_buff_manager == null or stacks <= 0:
		return
	match buff_name:
		"麻痹":
			var paralysis := ParalysisDebuff.new()
			paralysis.set_stacks(stacks)
			_player_buff_manager.add_buff(paralysis)
		"混乱":
			var confusion := ConfusionDebuff.new()
			confusion.set_stacks(stacks)
			_player_buff_manager.add_buff(confusion)


func _set_hp(next_hp: int) -> void:
	var final_hp := clampi(next_hp, 0, max_hp)
	if _enemy_buff_manager:
		final_hp = clampi(_enemy_buff_manager.modify_presence(final_hp), 0, max_hp)
	hp = final_hp
	hp_changed.emit(hp, max_hp)
