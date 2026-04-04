# 卡牌数据类
# 管理卡牌的定义和实例化
extends RefCounted
class_name CardData

# 获取卡牌数据
static func get_card_data(card_id: String) -> Dictionary:
	# 定义所有卡牌数据
	var cards := {
		# 攻击类卡牌
		"strike": {
			"id": "strike",           # 卡牌ID
			"name": "斩击",           # 卡牌名称
			"type": "攻击",           # 卡牌类型
			"cost": 1,                # 卡牌费用
			"cognition": 1,           # 卡牌认知负荷
			"desc": "对一名敌人造成2点伤害。"  # 卡牌描述
		},
		"slash": {
			"id": "slash",           # 卡牌ID
			"name": "挥砍",           # 卡牌名称
			"type": "攻击",           # 卡牌类型
			"cost": 2,                # 卡牌费用
			"cognition": 2,           # 卡牌认知负荷
			"desc": "对一名敌人造成4点伤害。"  # 卡牌描述
		},
		"thrust": {
			"id": "thrust",          # 卡牌ID
			"name": "突刺",           # 卡牌名称
			"type": "攻击",           # 卡牌类型
			"cost": 1,                # 卡牌费用
			"cognition": 1,           # 卡牌认知负荷
			"desc": "对一名敌人造成3点伤害。"  # 卡牌描述
		},
		"cleave": {
			"id": "cleave",          # 卡牌ID
			"name": "劈砍",           # 卡牌名称
			"type": "攻击",           # 卡牌类型
			"cost": 3,                # 卡牌费用
			"cognition": 3,           # 卡牌认知负荷
			"desc": "对一名敌人造成6点伤害。"  # 卡牌描述
		},
		"resonance": {
			"id": "resonance",        # 卡牌ID
			"name": "认知共振",        # 卡牌名称
			"type": "攻击",           # 卡牌类型
			"cost": 2,                # 卡牌费用
			"cognition": 3,           # 卡牌认知负荷
			"desc": "造成等同当前认知负荷值的伤害。"  # 卡牌描述
		},
		
		# 增益类卡牌
		"bless": {
			"id": "bless",           # 卡牌ID
			"name": "祝福",           # 卡牌名称
			"type": "增益",           # 卡牌类型
			"cost": 2,                # 卡牌费用
			"cognition": 3,           # 卡牌认知负荷
			"desc": "恢复5点存在值。"    # 卡牌描述
		},
		"heal": {
			"id": "heal",            # 卡牌ID
			"name": "治疗",           # 卡牌名称
			"type": "增益",           # 卡牌类型
			"cost": 1,                # 卡牌费用
			"cognition": 2,           # 卡牌认知负荷
			"desc": "恢复3点存在值。"    # 卡牌描述
		},
		"shield": {
			"id": "shield",           # 卡牌ID
			"name": "护盾",           # 卡牌名称
			"type": "增益",           # 卡牌类型
			"cost": 2,                # 卡牌费用
			"cognition": 2,           # 卡牌认知负荷
			"desc": "获得2点护盾。"      # 卡牌描述
		},
		
		# 减益类卡牌
		"break": {
			"id": "break",           # 卡牌ID
			"name": "瓦解",           # 卡牌名称
			"type": "减益",           # 卡牌类型
			"cost": 2,                # 卡牌费用
			"cognition": 2,           # 卡牌认知负荷
			"desc": "使敌人获得1层虚弱。"  # 卡牌描述
		},
		"slow": {
			"id": "slow",            # 卡牌ID
			"name": "减速",           # 卡牌名称
			"type": "减益",           # 卡牌类型
			"cost": 1,                # 卡牌费用
			"cognition": 1,           # 卡牌认知负荷
			"desc": "使敌人获得1层虚弱。"  # 卡牌描述
		},
		"weaken": {
			"id": "weaken",          # 卡牌ID
			"name": "弱化",           # 卡牌名称
			"type": "减益",           # 卡牌类型
			"cost": 2,                # 卡牌费用
			"cognition": 2,           # 卡牌认知负荷
			"desc": "使敌人获得2层虚弱。"  # 卡牌描述
		},
		
		# 运营类卡牌
		"relief": {
			"id": "relief",           # 卡牌ID
			"name": "释怀",           # 卡牌名称
			"type": "运营",           # 卡牌类型
			"cost": 0,                # 卡牌费用
			"cognition": 3,           # 卡牌认知负荷
			"desc": "恢复1点费用。"      # 卡牌描述
		},
		"energy_boost": {
			"id": "energy_boost",     # 卡牌ID
			"name": "能量提升",         # 卡牌名称
			"type": "运营",           # 卡牌类型
			"cost": 0,                # 卡牌费用
			"cognition": 2,           # 卡牌认知负荷
			"desc": "本回合获得1点额外费用。"  # 卡牌描述
		},
		"draw": {
			"id": "draw",            # 卡牌ID
			"name": "抽牌",           # 卡牌名称
			"type": "运营",           # 卡牌类型
			"cost": 1,                # 卡牌费用
			"cognition": 2,           # 卡牌认知负荷
			"desc": "抽取2张牌。"       # 卡牌描述
		},
		"cognition_reset": {
			"id": "cognition_reset",  # 卡牌ID
			"name": "认知重置",         # 卡牌名称
			"type": "运营",           # 卡牌类型
			"cost": 1,                # 卡牌费用
			"cognition": 0,           # 卡牌认知负荷
			"desc": "重置认知负荷为0。"    # 卡牌描述
		}
	}

	# 检查卡牌ID是否存在
	if cards.has(card_id):
		# 返回卡牌数据的深拷贝
		return cards[card_id].duplicate(true)

	# 卡牌不存在时返回空字典
	return {}

# 创建卡牌实例
static func create_card_instance(card_id: String, instance_id: int) -> Dictionary:
	# 获取卡牌基础数据
	var card := get_card_data(card_id)
	# 添加实例ID
	card["instance_id"] = instance_id
	# 返回卡牌实例
	return card

# 获取所有卡牌ID（不包含认知共振）
static func get_all_card_ids() -> Array:
	# 定义所有卡牌ID（不包含认知共振）
	var card_ids = [
		"strike",       # 斩击
		"slash",        # 挥砍
		"thrust",       # 突刺
		"cleave",       # 劈砍
		"bless",        # 祝福
		"heal",         # 治疗
		"shield",       # 护盾
		"break",        # 瓦解
		"slow",         # 减速
		"weaken",       # 弱化
		"relief",       # 释怀
		"energy_boost", # 能量提升
		"draw",         # 抽牌
		"cognition_reset" # 认知重置
	]
	return card_ids

# 获取随机卡组
static func get_random_deck() -> Array:
	# 获取所有卡牌ID（不包含认知共振）
	var all_cards = get_all_card_ids()
	# 打乱卡牌顺序
	all_cards.shuffle()
	# 获取前4张卡牌
	var deck = all_cards.slice(0, 4)
	# 添加一张认知共振（确保卡组中只有一张）
	deck.append("resonance")
	# 再次打乱顺序，让认知共振随机出现在卡组中
	deck.shuffle()
	return deck
