extends RefCounted
class_name CardData

static func get_card_data(card_id: String) -> Dictionary:
	var cards := {
		"strike": {
			"id": "strike",
			"name": "斩击",
			"type": "攻击",
			"cost": 1,
			"cognition": 1,
			"desc": "对一名敌人造成2点伤害。"
		},
		"bless": {
			"id": "bless",
			"name": "祝福",
			"type": "增益",
			"cost": 2,
			"cognition": 3,
			"desc": "恢复5点存在值。"
		},
		"break": {
			"id": "break",
			"name": "瓦解",
			"type": "减益",
			"cost": 2,
			"cognition": 2,
			"desc": "使敌人获得1层虚弱。"
		},
		"relief": {
			"id": "relief",
			"name": "释怀",
			"type": "运营",
			"cost": 0,
			"cognition": 3,
			"desc": "恢复1点费用。"
		},
		"resonance": {
			"id": "resonance",
			"name": "认知共振",
			"type": "攻击",
			"cost": 2,
			"cognition": 3,
			"desc": "造成等同当前认知负荷值的伤害。"
		}
	}

	if cards.has(card_id):
		return cards[card_id].duplicate(true)

	return {}

static func create_card_instance(card_id: String, instance_id: int) -> Dictionary:
	var card := get_card_data(card_id)
	card["instance_id"] = instance_id
	return card

static func get_demo_starting_deck() -> Array:
	var deck = [
		"strike",
		"strike",
		"bless",
		"break",
		"relief"
	]
	if GameManager.has_resonance_card:
		deck.append("resonance")
	return deck
