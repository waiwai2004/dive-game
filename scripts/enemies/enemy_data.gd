extends Resource
class_name EnemyData

@export var enemy_id: String = ""
@export var enemy_name: String = ""
@export var max_hp: int = 1
@export var max_san: int = 1
@export var energy_max: int = 10
@export var energy_gain_per_turn: int = 3
@export var portrait_path: String = ""
@export var ai_profile: String = ""
@export var ai_threshold_hp: int = 0
@export var notes: String = ""
@export var cards: Array[EnemyCardData] = []
@export var drop_table: Array[Dictionary] = []


static func from_dict(row: Dictionary) -> EnemyData:
	var data := EnemyData.new()
	data.enemy_id = _s(row.get("enemy_id", ""))
	data.enemy_name = _s(row.get("enemy_name", ""))
	data.max_hp = maxi(_i(row.get("max_hp", 1)), 1)
	data.max_san = maxi(_i(row.get("max_san", 1)), 1)
	data.energy_max = maxi(_i(row.get("energy_max", 10)), 1)
	data.energy_gain_per_turn = maxi(_i(row.get("energy_gain_per_turn", 3)), 0)
	data.portrait_path = _s(row.get("portrait_path", ""))
	data.ai_profile = _s(row.get("ai_profile", ""))
	data.ai_threshold_hp = maxi(_i(row.get("ai_threshold_hp", 0)), 0)
	data.notes = _s(row.get("notes", ""))

	var card_rows: Variant = row.get("cards", [])
	if card_rows is Array:
		for item in card_rows:
			if item is Dictionary:
				data.cards.append(EnemyCardData.from_dict(item))

	var drop_rows: Variant = row.get("drop_table", [])
	if drop_rows is Array:
		for item2 in drop_rows:
			if item2 is Dictionary:
				data.drop_table.append(item2.duplicate(true))

	return data


func get_card_pool_preview() -> Array[String]:
	var preview: Array[String] = []
	for card in cards:
		if card == null:
			continue
		if card.copies > 1:
			preview.append("%s x%d" % [card.card_name, card.copies])
		else:
			preview.append(card.card_name)
	return preview


func get_expanded_cards() -> Array[EnemyCardData]:
	var expanded: Array[EnemyCardData] = []
	for card in cards:
		if card == null:
			continue
		for _i in range(maxi(card.copies, 1)):
			expanded.append(card)
	return expanded


static func _s(value: Variant) -> String:
	return str(value).strip_edges()


static func _i(value: Variant) -> int:
	var text := str(value).strip_edges()
	if text.is_empty():
		return 0
	return int(text.to_int())
