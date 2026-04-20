## 卡牌与战斗效果系统
## 职责：
##  - 牌堆三区（抽/手/弃）管理
##  - 精神负荷（能量）+ 玩家 Buff（护盾 / 虚弱）
##  - 卡牌效果应用：伤害/护盾/SAN/虚弱/抽牌/能量/认知……
##  - 对外通过 log_emitted 汇报日志（battle_scene 汇总）
## 依赖：BattleEnemyAI（伤害/施弱）、BattleVisualEffects（受击反馈）
class_name BattleCardSystem
extends Node

signal log_emitted(text: String)

const ENERGY_GAIN_PER_TURN := 3
const ENERGY_MAX := 10
const HAND_DRAW_COUNT := 5
const STARTER_DECK: Array[String] = ["cut", "cut", "guard", "guard", "calm", "break"]

var draw_pile: Array[String] = []
var hand: Array[String] = []
var discard_pile: Array[String] = []

var energy: int = 0
var player_block: int = 0
var player_weak: int = 0

var _enemy_ai: BattleEnemyAI
var _visual_effects: BattleVisualEffects
var _status_manager: StatusManager
var _player_buff_manager: BuffManager
var _enemy_buff_manager: BuffManager


func setup(enemy_ai: BattleEnemyAI, visual_effects: BattleVisualEffects, status_manager: StatusManager = null, player_buff_manager: BuffManager = null, enemy_buff_manager: BuffManager = null) -> void:
	_enemy_ai = enemy_ai
	_visual_effects = visual_effects
	_status_manager = status_manager
	_player_buff_manager = player_buff_manager
	_enemy_buff_manager = enemy_buff_manager


# ====== 对外 API ======

func start_battle() -> void:
	if Game.deck.is_empty():
		Game.reset_run()
	_ensure_playable_deck()

	draw_pile = Game.deck.duplicate()
	draw_pile.shuffle()
	hand.clear()
	discard_pile.clear()

	player_block = 0
	player_weak = 0
	energy = 0
	Game.clear_cognition()

	_draw_all_cards_to_hand()


func _draw_all_cards_to_hand() -> void:
	while not draw_pile.is_empty():
		hand.append(draw_pile.pop_back())
	if not discard_pile.is_empty():
		draw_pile = discard_pile.duplicate()
		discard_pile.clear()
		draw_pile.shuffle()
		while not draw_pile.is_empty():
			hand.append(draw_pile.pop_back())
	log_emitted.emit("获得全部手牌。")


func start_turn() -> void:
	energy = mini(energy + ENERGY_GAIN_PER_TURN, ENERGY_MAX)
	if hand.is_empty():
		if Game.player_cognition > 0:
			Game.clear_cognition()
			log_emitted.emit("手牌打完，认知负荷已清零。")
		_draw_all_cards_to_hand()


func draw_cards(count: int) -> void:
	for _i in range(count):
		if draw_pile.is_empty():
			draw_pile = discard_pile.duplicate()
			discard_pile.clear()
			draw_pile.shuffle()
			if not draw_pile.is_empty():
				log_emitted.emit("弃牌堆洗回抽牌堆。")
		if draw_pile.is_empty():
			break
		hand.append(draw_pile.pop_back())


func discard_hand() -> void:
	for card_id in hand:
		discard_pile.append(card_id)
	hand.clear()


func tick_player_weak() -> void:
	if player_weak > 0:
		player_weak = maxi(player_weak - 1, 0)


func get_effective_cost(card: Dictionary) -> int:
	var cost: int = int(card.get("cost", 0))
	if Game.is_distorted():
		cost += 1
	if _status_manager and _status_manager.is_status_active("癫狂"):
		cost = _status_manager.modify_card_value(cost, "cost")
	return maxi(cost, 0)


## 尝试打出指定手牌。成功 → true，能量不足或越界 → false。
## 所有效果日志通过 log_emitted 信号发出。
func play_card(card_index: int) -> bool:
	if card_index < 0 or card_index >= hand.size():
		return false

	var card_id: String = hand[card_index]
	var card: Dictionary = CardDatabase.get_card(card_id)
	var cost: int = get_effective_cost(card)

	if cost > energy:
		log_emitted.emit("能量不足，无法打出【%s】。" % str(card.get("name", card_id)))
		return false

	energy -= cost
	_apply_card_effect(card)
	_apply_cognition_cost(card)

	discard_pile.append(card_id)
	hand.remove_at(card_index)

	return true


# ====== 内部效果应用 ======

func _apply_card_effect(card: Dictionary) -> void:
	var card_name := str(card.get("name", "未知卡牌"))
	var fragments: Array[String] = []

	var damage: int = int(card.get("damage", 0))
	if damage > 0:
		if _status_manager and _status_manager.is_status_active("癫狂"):
			damage = _status_manager.modify_card_value(damage, "damage")
		if _enemy_buff_manager:
			damage = _enemy_buff_manager.modify_damage_taken(damage)
		var final_damage := apply_weak_to_damage(damage, player_weak)
		_enemy_ai.take_damage(final_damage)
		_visual_effects.play_enemy_hit_feedback()
		fragments.append("造成%d点伤害" % final_damage)

	var block_gain: int = int(card.get("block", 0))
	if block_gain > 0:
		if _status_manager and _status_manager.is_status_active("癫狂"):
			block_gain = _status_manager.modify_card_value(block_gain, "block")
		player_block += block_gain
		fragments.append("获得%d点护盾" % block_gain)

	var san_heal: int = int(card.get("san_heal", 0))
	if san_heal > 0:
		Game.heal_san(san_heal)
		fragments.append("恢复%d点SAN" % san_heal)

	var weak_on_enemy: int = int(card.get("apply_weak", 0))
	if weak_on_enemy > 0:
		_enemy_ai.apply_weak(weak_on_enemy)
		if _enemy_buff_manager:
			var weakness_debuff = WeaknessDebuff.new()
			weakness_debuff.set_stacks(weak_on_enemy)
			_enemy_buff_manager.add_buff(weakness_debuff)
		fragments.append("施加%d层虚弱" % weak_on_enemy)

	var san_cost: int = int(card.get("san_cost", 0))
	if san_cost > 0:
		Game.player_san = maxi(Game.player_san - san_cost, 0)
		fragments.append("失去%d点SAN" % san_cost)

	var draw_count: int = int(card.get("draw", 0))
	if draw_count > 0:
		draw_cards(draw_count)
		fragments.append("抽%d张牌" % draw_count)

	var gain_energy: int = int(card.get("gain_energy", 0))
	if gain_energy > 0:
		energy = mini(energy + gain_energy, ENERGY_MAX)
		fragments.append("获得%d点精神负荷" % gain_energy)

	var reduce_cog: int = int(card.get("reduce_cognition", 0))
	if reduce_cog > 0:
		Game.player_cognition = maxi(Game.player_cognition - reduce_cog, 0)
		fragments.append("降低%d点认知负荷" % reduce_cog)

	if fragments.is_empty():
		log_emitted.emit("你使用了【%s】。" % card_name)
	else:
		log_emitted.emit("你使用【%s】：%s。" % [card_name, "，".join(fragments)])


func _apply_cognition_cost(card: Dictionary) -> void:
	var cog_gain: int = int(card.get("cognition", 0))
	if cog_gain <= 0:
		return
	Game.add_cognition(cog_gain)
	if Game.player_cognition > Game.max_cognition:
		var hp_before := Game.player_hp
		Game.player_hp = maxi(1, int(round(float(Game.player_hp) / 2.0)))
		Game.clear_cognition()
		log_emitted.emit("认知超载！存在值由%d降至%d。" % [hp_before, Game.player_hp])


func _ensure_playable_deck() -> void:
	if Game.deck.size() >= HAND_DRAW_COUNT:
		return
	Game.deck.clear()
	for card_id in STARTER_DECK:
		Game.deck.append(card_id)


# ====== 静态工具：虚弱减伤公式（供 EnemyAI 复用） ======
static func apply_weak_to_damage(base_damage: int, weak_stack: int) -> int:
	if base_damage <= 0:
		return 0
	if weak_stack <= 0:
		return base_damage
	return maxi(1, base_damage - weak_stack)
