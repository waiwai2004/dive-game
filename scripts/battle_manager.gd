# 战斗管理器
# 负责处理战斗逻辑，包括回合管理、卡牌使用、伤害计算等
extends RefCounted

# 预加载脚本
const PlayerDataScript = preload("res://scripts/player_data.gd")
const EnemyDataScript = preload("res://scripts/enemy_data.gd")
const CardDataScript = preload("res://scripts/card_data.gd")

# 信号定义
signal battle_log_added(text)       # 战斗日志添加信号
signal battle_state_changed         # 战斗状态改变信号
signal battle_ended(is_victory)     # 战斗结束信号
signal enemy_damaged(amount)        # 敌人受到伤害信号
signal player_damaged(amount)       # 玩家受到伤害信号

# 战斗实体
var player = null  # 玩家对象
var enemy = null   # 敌人对象

# 卡牌相关
var hand_cards: Array = []  # 手牌数组
var draw_pile: Array = []   # 抽牌堆

# 战斗状态
var next_instance_id: int = 1          # 下一个卡牌实例ID
var selected_card_instance_id: int = -1  # 选中的卡牌实例ID
var battle_finished: bool = false      # 战斗是否结束
var turn_count: int = 0                # 当前回合数
var phase_text: String = "PREPARE"    # 当前战斗阶段

# 设置演示战斗
func setup_demo_battle(is_boss: bool = false) -> void:
	# 创建玩家对象并初始化
	player = PlayerDataScript.new()
	player.setup_demo()

	# 同步游戏管理器中的玩家状态到玩家数据
	player.extra_energy = GameManager.player_summary.get("extra_energy", 0)
	player.max_hp = GameManager.player_summary.get("max_hp", 10)
	player.hp = GameManager.player_summary.get("hp", 10)
	player.max_san = GameManager.player_summary.get("max_san", 10)
	player.san = GameManager.player_summary.get("san", 10)
	player.max_energy = GameManager.player_summary.get("energy_max", 3)
	player.energy = player.max_energy
	player.cognition = GameManager.player_summary.get("cognition", 0)
	player.cognition_max = GameManager.player_summary.get("cognition_max", 10)
	player.cognition_overloaded = GameManager.player_summary.get("cognition_overloaded", false)

	# 创建敌人对象并根据是否为Boss初始化
	enemy = EnemyDataScript.new()
	if is_boss:
		enemy.setup_demo_boss()
	else:
		enemy.setup_demo_normal_enemy()

	# 设置抽牌堆为随机卡组
	draw_pile = CardDataScript.get_random_deck()
	# 清空手牌
	hand_cards.clear()
	# 重置选中的卡牌
	selected_card_instance_id = -1
	# 重置战斗结束状态
	battle_finished = false
	turn_count = 0
	phase_text = "BATTLE START"

	# 发送战斗开始日志
	emit_log("战斗开始！")
	# 开始玩家回合
	start_player_turn()

# 开始玩家回合
func start_player_turn() -> void:
	# 如果战斗已结束，直接返回
	if battle_finished:
		return

	# 重置玩家能量（会自动加上额外能量）
	player.reset_energy()
	turn_count += 1
	phase_text = "PLAYER TURN"
	# 重置选中的卡牌
	selected_card_instance_id = -1
	# 抽取演示手牌
	var drawn_count = draw_demo_hand()
	# 更新敌人意图
	update_enemy_intent()
	# 发送玩家回合开始日志
	emit_log("该你行动了！")
	emit_log("你抽取了%d张牌" % drawn_count)
	# 如果有额外能量，显示信息
	if player.extra_energy > 0:
		emit_log("你获得了%d点额外费用，当前费用上限：%d" % [player.extra_energy, player.max_energy + player.extra_energy])
	# 发送战斗状态改变信号
	battle_state_changed.emit()

# 抽取演示手牌
func draw_demo_hand() -> int:
	# 清空手牌
	hand_cards.clear()

	# 从抽牌堆中抽取最多5张牌
	var draw_count = min(5, draw_pile.size())
	for i in range(draw_count):
		# 从抽牌堆中取出卡牌
		var card_id = draw_pile.pop_back()
		# 创建卡牌实例
		var card = CardDataScript.create_card_instance(card_id, next_instance_id)
		# 增加实例ID
		next_instance_id += 1
		# 将卡牌添加到手牌
		hand_cards.append(card)

	return draw_count

# 获取手牌
func get_hand_cards() -> Array:
	# 返回手牌数组
	return hand_cards

func get_hand_size() -> int:
	return hand_cards.size()

func get_draw_pile_size() -> int:
	return draw_pile.size()

func get_turn_count() -> int:
	return turn_count

func get_phase_text() -> String:
	return phase_text

# 根据实例ID获取卡牌
func get_card_by_instance_id(instance_id: int) -> Dictionary:
	# 遍历手牌
	for card in hand_cards:
		# 找到对应实例ID的卡牌
		if card["instance_id"] == instance_id:
			return card
	# 未找到返回空字典
	return {}

# 从手牌中移除卡牌
func remove_card_from_hand(instance_id: int) -> void:
	# 遍历手牌
	for i in range(hand_cards.size()):
		# 找到对应实例ID的卡牌
		if hand_cards[i]["instance_id"] == instance_id:
			# 移除卡牌
			hand_cards.remove_at(i)
			return

# 检查是否可以使用卡牌
func can_play_card(card: Dictionary) -> bool:
	# 检查玩家能量是否足够
	return player.energy >= card.get("cost", 0)

# 更新敌人意图
func update_enemy_intent() -> void:
	# 设置敌人意图文本为攻击次数
	enemy.intent_text = "攻击 x%d" % enemy.max_energy

# 发送战斗日志
func emit_log(text: String) -> void:
	# 发送战斗日志添加信号
	battle_log_added.emit(text)

# 清除选中的卡牌
func clear_selected_card() -> void:
	# 重置选中的卡牌实例ID
	selected_card_instance_id = -1

# 卡牌点击处理
func on_card_clicked(instance_id: int) -> String:
	# 如果战斗已结束
	if battle_finished:
		return "战斗结束"

	# 获取卡牌
	var card = get_card_by_instance_id(instance_id)
	# 如果卡牌不存在
	if card.is_empty():
		return "卡牌不存在"

	# 如果已经选中同一张卡牌，则取消选择
	if selected_card_instance_id == instance_id:
		selected_card_instance_id = -1
		battle_state_changed.emit()
		return "取消选择%s" % card["name"]

	# 如果能量不足
	if not can_play_card(card):
		return "你没有足够的能量"

	# 获取卡牌ID
	var card_id = card.get("id", "")

	# 处理祝福卡牌
	if card_id == "bless":
		play_bless(card)
		return "你使用了祝福卡牌"

	# 处理治疗卡牌
	if card_id == "heal":
		play_heal(card)
		return "你使用了治疗卡牌"

	# 处理护盾卡牌
	if card_id == "shield":
		play_shield(card)
		return "你使用了护盾卡牌"

	# 处理释怀卡牌
	if card_id == "relief":
		play_relief(card)
		return "你使用了释怀卡牌"

	# 处理能量提升卡牌
	if card_id == "energy_boost":
		play_energy_boost(card)
		return "你使用了能量提升卡牌"

	# 处理抽牌卡牌
	if card_id == "draw":
		play_draw(card)
		return "你使用了抽牌卡牌"

	# 处理认知重置卡牌
	if card_id == "cognition_reset":
		play_cognition_reset(card)
		return "你使用了认知重置卡牌"

	# 处理减速卡牌（减益，需要选择敌人）
	if card_id == "slow":
		selected_card_instance_id = instance_id
		emit_log("你选择了%s" % card["name"])
		battle_state_changed.emit()
		return "你选择了%s。请选择敌人" % card["name"]

	# 处理弱化卡牌（减益，需要选择敌人）
	if card_id == "weaken":
		selected_card_instance_id = instance_id
		emit_log("你选择了%s" % card["name"])
		battle_state_changed.emit()
		return "你选择了%s。请选择敌人" % card["name"]

	# 选中攻击类卡牌
	selected_card_instance_id = instance_id
	# 发送选中卡牌日志
	emit_log("你选择了%s" % card["name"])
	# 发送战斗状态改变信号
	battle_state_changed.emit()
	return "你选择了%s。请选择敌人" % card["name"]

# 敌人目标点击处理
func on_enemy_target_clicked() -> String:
	# 如果战斗已结束
	if battle_finished:
		return "战斗结束"

	# 如果没有选中卡牌
	if selected_card_instance_id == -1:
		return "请选择先选择卡牌"

	# 获取选中的卡牌
	var card = get_card_by_instance_id(selected_card_instance_id)
	# 如果卡牌不存在
	if card.is_empty():
		selected_card_instance_id = -1
		return "卡牌不存在"

	# 如果能量不足
	if not can_play_card(card):
		selected_card_instance_id = -1
		return "你没有足够的能量"

	# 获取卡牌ID
	var card_id = card.get("id", "")
	var result_message = ""

	# 处理不同类型的卡牌
	if card_id == "strike":
		play_strike(card)
		result_message = "你使用了斩击卡牌"
	elif card_id == "slash":
		play_slash(card)
		result_message = "你使用了挥砍卡牌"
	elif card_id == "thrust":
		play_thrust(card)
		result_message = "你使用了突刺卡牌"
	elif card_id == "cleave":
		play_cleave(card)
		result_message = "你使用了劈砍卡牌"
	elif card_id == "break":
		play_break(card)
		result_message = "你使用了瓦解卡牌"
	elif card_id == "slow":
		play_slow(card)
		result_message = "你使用了减速卡牌"
	elif card_id == "weaken":
		play_weaken(card)
		result_message = "你使用了弱化卡牌"
	elif card_id == "resonance":
		play_resonance(card)
		result_message = "你使用了认知共振卡牌"
	else:
		return "该卡牌不能攻击敌人"

	# 重置选中的卡牌
	selected_card_instance_id = -1
	# 检查手牌是否为空
	check_hand_empty()
	# 检查战斗是否结束
	check_battle_end()
	# 发送战斗状态改变信号
	battle_state_changed.emit()
	return result_message

# 结束玩家回合
func end_player_turn() -> String:
	# 如果战斗已结束
	if battle_finished:
		return "战斗结束"

	# 清除选中的卡牌
	clear_selected_card()
	phase_text = "ENDING TURN"
	# 发送结束回合日志
	emit_log("玩家结束回合")
	# 执行敌人回合
	enemy_turn()

	# 如果战斗已结束
	if battle_finished:
		return "战斗结束"

	# 结束回合清理
	end_round_cleanup()
	# 开始新的玩家回合
	start_player_turn()
	return "敌人回合..."

# 敌人回合
func enemy_turn() -> void:
	phase_text = "ENEMY TURN"
	# 发送敌人回合开始日志
	emit_log("敌人回合开始")

	# 获取敌人能量
	var actions = enemy.max_energy
	# 执行攻击
	while actions > 0:
		# 对玩家造成伤害
		damage_player(2)
		# 发送敌人使用攻击日志
		emit_log("敌人使用了攻击卡牌")
		# 减少剩余行动次数
		actions -= 1

		# 检查玩家是否死亡
		if player.is_dead():
			# 检查战斗是否结束
			check_battle_end()
			return

# 结束回合清理
func end_round_cleanup() -> void:
	# 回收手牌到抽牌堆
	for card in hand_cards:
		draw_pile.append(card["id"])
	# 清空手牌
	hand_cards.clear()
	# 打乱抽牌堆
	draw_pile.shuffle()

	# 减少玩家虚弱层数
	if player.weak > 0:
		player.weak -= 1

	# 减少敌人虚弱层数
	if enemy.weak > 0:
		enemy.weak -= 1

	# 发送回合结束日志
	emit_log("回合结束。")
	# 发送战斗状态改变信号
	battle_state_changed.emit()

# 应用认知负荷
func apply_cognition(amount: int) -> void:
	# 如果已经发生过认知过载，不再增加认知负荷
	if player.cognition_overloaded:
		emit_log("认知系统已崩溃，无法继续增加认知负荷")
		return
	
	# 增加认知负荷并检查是否过载
	var overload = player.add_cognition(amount)
	# 发送认知负荷增加日志
	emit_log("认知负荷增加：%d" % amount)

	# 如果认知负荷过载
	if overload:
		# 生命值减半
		var old_hp = player.hp
		player.hp = int(round(player.hp / 2.0))
		# 确保生命值不小于0
		if player.hp < 0:
			player.hp = 0
		# 发送认知过载日志
		emit_log("认知突破上限！生命值从%d减半至%d" % [old_hp, player.hp])
		emit_log("认知系统已崩溃，后续卡牌不再增加认知负荷")

# 检查手牌是否为空
func check_hand_empty() -> void:
	# 如果手牌为空
	if hand_cards.is_empty():
		# 清除认知负荷
		player.clear_cognition()
		# 发送手牌为空日志
		emit_log("手牌为空。认知负荷重置为0。")

# 检查战斗是否结束
func check_battle_end() -> void:
	# 如果战斗已结束
	if battle_finished:
		return

	# 如果敌人死亡
	if enemy.is_dead():
		# 设置战斗结束
		battle_finished = true
		phase_text = "VICTORY"
		# 发送敌人被击败日志
		emit_log("敌人被击败！")
		# 发送战斗结束信号（胜利）
		battle_ended.emit(true)
		return

	# 如果玩家死亡
	if player.is_dead():
		# 设置战斗结束
		battle_finished = true
		phase_text = "DEFEAT"
		# 发送玩家被击败日志
		emit_log("玩家被击败！")
		# 发送战斗结束信号（失败）
		battle_ended.emit(false)

# 获取修改后的伤害值
func get_modified_damage(base_damage: int, weak_stacks: int) -> int:
	# 计算最终伤害（基础伤害减去虚弱层数*2）
	var result = base_damage - weak_stacks * 2
	# 如果有虚弱buff，伤害减半
	if weak_stacks > 0:
		result = int(float(result) / 2.0)
	# 确保伤害至少为1
	if result < 1:
		result = 1
	return result

# 对敌人造成伤害
func damage_enemy(base_damage: int) -> void:
	# 计算最终伤害
	var final_damage = get_modified_damage(base_damage, player.weak)
	# 敌人受到伤害
	enemy.take_damage(final_damage)
	# 发送敌人受到伤害日志
	emit_log("敌人受到：%d点伤害" % final_damage)
	# 发出伤害信号让UI显示数字与特效
	enemy_damaged.emit(final_damage)

# 对玩家造成伤害
func damage_player(base_damage: int) -> void:
	# 计算最终伤害
	var final_damage = get_modified_damage(base_damage, enemy.weak)
	# 玩家受到伤害
	player.take_damage(final_damage)
	# 发送玩家受到伤害日志
	emit_log("玩家受到：%d点伤害" % final_damage)
	# 发出伤害信号让UI显示数字与特效
	player_damaged.emit(final_damage)

# 使用斩击卡牌
func play_strike(card: Dictionary) -> void:
	# 消耗能量
	player.energy -= card["cost"]
	# 对敌人造成2点伤害
	damage_enemy(2)
	# 发送使用斩击日志
	emit_log("你使用了斩击卡牌")
	# 应用认知负荷
	apply_cognition(card["cognition"])
	# 从手牌中移除卡牌
	remove_card_from_hand(card["instance_id"])

# 使用祝福卡牌
func play_bless(card: Dictionary) -> void:
	# 消耗能量
	player.energy -= card["cost"]
	# 恢复5点生命值
	player.heal_hp(5)
	# 发送使用祝福日志
	emit_log("你恢复了5点生命值")
	# 应用认知负荷
	apply_cognition(card["cognition"])
	# 从手牌中移除卡牌
	remove_card_from_hand(card["instance_id"])
	# 检查手牌是否为空
	check_hand_empty()
	# 检查战斗是否结束
	check_battle_end()
	# 发送战斗状态改变信号
	battle_state_changed.emit()

# 使用瓦解卡牌
func play_break(card: Dictionary) -> void:
	# 消耗能量
	player.energy -= card["cost"]
	# 敌人获得1层虚弱
	enemy.weak += 1
	# 发送使用瓦解日志
	emit_log("你使用了瓦解卡牌，敌人获得1层虚弱")
	# 应用认知负荷
	apply_cognition(card["cognition"])
	# 从手牌中移除卡牌
	remove_card_from_hand(card["instance_id"])

# 使用释怀卡牌
func play_relief(card: Dictionary) -> void:
	# 消耗能量
	player.energy -= card["cost"]
	# 恢复1点能量
	player.energy += 1
	# 发送使用释怀日志
	emit_log("你恢复了1点能量")
	# 应用认知负荷
	apply_cognition(card["cognition"])
	# 从手牌中移除卡牌
	remove_card_from_hand(card["instance_id"])
	# 检查手牌是否为空
	check_hand_empty()
	# 检查战斗是否结束
	check_battle_end()
	# 发送战斗状态改变信号
	battle_state_changed.emit()

# 使用认知共振卡牌
func play_resonance(card: Dictionary) -> void:
	# 消耗能量
	player.energy -= card["cost"]
	# 伤害等于当前认知负荷
	var damage = player.cognition
	# 对敌人造成伤害
	damage_enemy(damage)
	# 发送使用认知共振日志
	emit_log("你使用了认知共振卡牌")
	# 应用认知负荷
	apply_cognition(card["cognition"])
	# 从手牌中移除卡牌
	remove_card_from_hand(card["instance_id"])

# 使用挥砍卡牌
func play_slash(card: Dictionary) -> void:
	# 消耗能量
	player.energy -= card["cost"]
	# 对敌人造成4点伤害
	damage_enemy(4)
	# 发送使用挥砍日志
	emit_log("你使用了挥砍卡牌")
	# 应用认知负荷
	apply_cognition(card["cognition"])
	# 从手牌中移除卡牌
	remove_card_from_hand(card["instance_id"])

# 使用突刺卡牌
func play_thrust(card: Dictionary) -> void:
	# 消耗能量
	player.energy -= card["cost"]
	# 对敌人造成3点伤害
	damage_enemy(3)
	# 发送使用突刺日志
	emit_log("你使用了突刺卡牌")
	# 应用认知负荷
	apply_cognition(card["cognition"])
	# 从手牌中移除卡牌
	remove_card_from_hand(card["instance_id"])

# 使用劈砍卡牌
func play_cleave(card: Dictionary) -> void:
	# 消耗能量
	player.energy -= card["cost"]
	# 对敌人造成6点伤害
	damage_enemy(6)
	# 发送使用劈砍日志
	emit_log("你使用了劈砍卡牌")
	# 应用认知负荷
	apply_cognition(card["cognition"])
	# 从手牌中移除卡牌
	remove_card_from_hand(card["instance_id"])

# 使用治疗卡牌
func play_heal(card: Dictionary) -> void:
	# 消耗能量
	player.energy -= card["cost"]
	# 恢复3点生命值
	player.heal_hp(3)
	# 发送使用治疗日志
	emit_log("你使用了治疗卡牌，恢复3点生命值")
	# 应用认知负荷
	apply_cognition(card["cognition"])
	# 从手牌中移除卡牌
	remove_card_from_hand(card["instance_id"])
	# 检查手牌是否为空
	check_hand_empty()
	# 检查战斗是否结束
	check_battle_end()
	# 发送战斗状态改变信号
	battle_state_changed.emit()

# 使用护盾卡牌
func play_shield(card: Dictionary) -> void:
	# 消耗能量
	player.energy -= card["cost"]
	# 获得2点护盾（这里简化处理，直接恢复2点生命值）
	player.heal_hp(2)
	# 发送使用护盾日志
	emit_log("你使用了护盾卡牌，获得2点护盾")
	# 应用认知负荷
	apply_cognition(card["cognition"])
	# 从手牌中移除卡牌
	remove_card_from_hand(card["instance_id"])
	# 检查手牌是否为空
	check_hand_empty()
	# 检查战斗是否结束
	check_battle_end()
	# 发送战斗状态改变信号
	battle_state_changed.emit()

# 使用减速卡牌
func play_slow(card: Dictionary) -> void:
	# 消耗能量
	player.energy -= card["cost"]
	# 敌人获得1层虚弱
	enemy.weak += 1
	# 发送使用减速日志
	emit_log("你使用了减速卡牌，敌人获得1层虚弱")
	# 应用认知负荷
	apply_cognition(card["cognition"])
	# 从手牌中移除卡牌
	remove_card_from_hand(card["instance_id"])

# 使用弱化卡牌
func play_weaken(card: Dictionary) -> void:
	# 消耗能量
	player.energy -= card["cost"]
	# 敌人获得2层虚弱
	enemy.weak += 2
	# 发送使用弱化日志
	emit_log("你使用了弱化卡牌，敌人获得2层虚弱")
	# 应用认知负荷
	apply_cognition(card["cognition"])
	# 从手牌中移除卡牌
	remove_card_from_hand(card["instance_id"])

# 使用能量提升卡牌
func play_energy_boost(card: Dictionary) -> void:
	# 消耗能量
	player.energy -= card["cost"]
	# 获得1点额外能量
	player.energy += 1
	# 发送使用能量提升日志
	emit_log("你使用了能量提升卡牌，获得1点额外能量")
	# 应用认知负荷
	apply_cognition(card["cognition"])
	# 从手牌中移除卡牌
	remove_card_from_hand(card["instance_id"])
	# 检查手牌是否为空
	check_hand_empty()
	# 检查战斗是否结束
	check_battle_end()
	# 发送战斗状态改变信号
	battle_state_changed.emit()

# 使用抽牌卡牌
func play_draw(card: Dictionary) -> void:
	# 消耗能量
	player.energy -= card["cost"]
	# 发送使用抽牌日志
	emit_log("你使用了抽牌卡牌")
	# 应用认知负荷
	apply_cognition(card["cognition"])
	# 从手牌中移除卡牌
	remove_card_from_hand(card["instance_id"])
	# 抽取2张牌（从抽牌堆中取出）
	for i in range(2):
		if draw_pile.size() > 0:
			var card_id = draw_pile.pop_back()
			var new_card = CardDataScript.create_card_instance(card_id, next_instance_id)
			next_instance_id += 1
			hand_cards.append(new_card)
			emit_log("你抽取了%s" % new_card["name"])
		else:
			emit_log("抽牌堆已空，无法抽牌")
	# 检查手牌是否为空
	check_hand_empty()
	# 检查战斗是否结束
	check_battle_end()
	# 发送战斗状态改变信号
	battle_state_changed.emit()

# 使用认知重置卡牌
func play_cognition_reset(card: Dictionary) -> void:
	# 消耗能量
	player.energy -= card["cost"]
	# 重置认知负荷为0
	player.clear_cognition()
	# 发送使用认知重置日志
	emit_log("你使用了认知重置卡牌，认知负荷重置为0")
	# 应用认知负荷（这里为0）
	apply_cognition(card["cognition"])
	# 从手牌中移除卡牌
	remove_card_from_hand(card["instance_id"])
	# 检查手牌是否为空
	check_hand_empty()
	# 检查战斗是否结束
	check_battle_end()
	# 发送战斗状态改变信号
	battle_state_changed.emit()
