extends Resource
class_name EnemyCardData

@export var card_id: String = ""
@export var card_name: String = ""
@export var category: String = ""
@export var energy_cost: int = 0
@export var copies: int = 1
@export var effect_key: String = ""
@export var effect_value: int = 0
@export var effect_value_2: int = 0
@export var target: String = "player"
@export var note: String = ""


static func from_dict(row: Dictionary) -> EnemyCardData:
	var data := EnemyCardData.new()
	data.card_id = _s(row.get("card_id", ""))
	data.card_name = _s(row.get("card_name", ""))
	data.category = _s(row.get("category", ""))
	data.energy_cost = _i(row.get("energy_cost", 0))
	data.copies = maxi(_i(row.get("copies", 1)), 1)
	data.effect_key = _s(row.get("effect_key", ""))
	data.effect_value = _i(row.get("effect_value", 0))
	data.effect_value_2 = _i(row.get("effect_value_2", 0))
	data.target = _s(row.get("target", "player"))
	data.note = _s(row.get("note", ""))
	return data


func to_dict() -> Dictionary:
	return {
		"card_id": card_id,
		"card_name": card_name,
		"category": category,
		"energy_cost": energy_cost,
		"copies": copies,
		"effect_key": effect_key,
		"effect_value": effect_value,
		"effect_value_2": effect_value_2,
		"target": target,
		"note": note,
	}


static func _s(value: Variant) -> String:
	return str(value).strip_edges()


static func _i(value: Variant) -> int:
	var text := str(value).strip_edges()
	if text.is_empty():
		return 0
	return int(text.to_int())
