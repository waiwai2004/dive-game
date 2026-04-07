# 卡牌数据类
# 管理卡牌的定义和实例化
extends RefCounted
class_name CardData

# 获取卡牌数据
static func get_card_data(card_id: String) -> Dictionary:
	return DBManager.get_card(card_id)

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
	var card_ids = []
	# 直接读取 JSON 数据库中存在的所有卡牌 ID
	for id in DBManager.cards_db.keys():
		if id != "resonance": # 排除特定的卡牌（如认知共振）
			card_ids.append(id)
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
