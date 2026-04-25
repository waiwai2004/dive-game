extends Resource
class_name CardData

@export var card_id: String = ""
@export var card_name: String = ""
@export var card_type: String = ""
@export var rarity: String = "普通"
@export var energy_cost: int = 0
@export var target_type: String = "enemy"
@export_multiline var description: String = ""
@export var effect_key: String = ""
@export var effect_value: float = 0.0
@export var effect_value_2: float = 0.0
@export var status: String = "启用"
@export var art_frame_path: String = ""
@export var art_illustration_path: String = ""
@export var card_output_name: String = ""
@export var note: String = ""

# 兼容字段：CSV 可以不填，读取后用仓库默认值补齐。
@export var cognition: int = 0


static func from_row(row: Dictionary) -> CardData:
	var data := CardData.new()
	data.card_id = _s(row.get("card_id", ""))
	data.card_name = _s(row.get("card_name", ""))
	data.card_type = _s(row.get("card_type", ""))
	data.rarity = _s(row.get("rarity", "普通"))
	data.energy_cost = _i(row.get("energy_cost", 0))
	data.target_type = _s(row.get("target_type", "enemy"))
	data.description = _s(row.get("description", ""))
	data.effect_key = _s(row.get("effect_key", ""))
	data.effect_value = _f(row.get("effect_value", 0.0))
	data.effect_value_2 = _f(row.get("effect_value_2", 0.0))
	data.status = _s(row.get("status", "启用"))
	data.art_frame_path = _s(row.get("art_frame_path", ""))
	data.art_illustration_path = _s(row.get("art_illustration_path", ""))
	data.card_output_name = _s(row.get("card_output_name", ""))
	data.note = _s(row.get("note", ""))
	data.cognition = _i(row.get("cognition", row.get("cognition_cost", 0)))
	return data


func is_enabled() -> bool:
	var s := status.strip_edges().to_lower()
	if s in ["废弃", "deprecated", "disabled", "off"]:
		return false
	return s in ["启用", "enabled", "test", "测试", "on", "active"]


func normalized_type() -> String:
	var t := card_type.strip_edges().to_lower()
	match t:
		"攻击", "attack":
			return "attack"
		"防御", "defend", "defense", "buff", "增益":
			return "buff"
		"治疗", "heal":
			return "utility"
		"减益", "debuff":
			return "debuff"
		"运营", "特殊", "utility", "special":
			return "utility"
		_:
			return t if not t.is_empty() else "utility"


func normalized_target_for_battle() -> String:
	var t := target_type.strip_edges().to_lower()
	match t:
		"enemy", "all_enemies":
			return "enemy"
		"self", "player", "none":
			return "player"
		_:
			return "enemy"


func to_battle_dict() -> Dictionary:
	var out: Dictionary = {
		"id": card_id,
		"name": card_name,
		"type": normalized_type(),
		"target": normalized_target_for_battle(),
		"cost": energy_cost,
		"cognition": cognition,
		"description": description,
		"desc": description,
		"card_id": card_id,
		"card_name": card_name,
		"card_type": card_type,
		"rarity": rarity,
		"energy_cost": energy_cost,
		"target_type": target_type,
		"effect_key": effect_key,
		"effect_value": effect_value,
		"effect_value_2": effect_value_2,
		"status": status,
		"art_frame_path": art_frame_path,
		"art_illustration_path": art_illustration_path,
		"card_output_name": card_output_name,
		"note": note
	}

	match effect_key.strip_edges().to_lower():
		"damage":
			out["damage"] = int(round(effect_value))
		"block":
			out["block"] = int(round(effect_value))
		"san_heal", "heal_san", "heal":
			out["san_heal"] = int(round(effect_value))
		"heal_hp", "hp_heal":
			out["heal_hp"] = int(round(effect_value))
		"apply_weak", "weak":
			out["apply_weak"] = int(round(effect_value))
		"gain_energy":
			out["gain_energy"] = int(round(effect_value))
		"damage_and_san_loss":
			out["damage"] = int(round(effect_value))
			out["san_cost"] = int(round(effect_value_2))
		"san_heal_and_draw":
			out["san_heal"] = int(round(effect_value))
			out["draw"] = int(round(effect_value_2))
		"gain_energy_and_draw":
			out["gain_energy"] = int(round(effect_value))
			out["draw"] = int(round(effect_value_2))
		"block_and_reduce_cognition":
			out["block"] = int(round(effect_value))
			out["reduce_cognition"] = int(round(effect_value_2))
		_:
			pass

	return out


static func _s(v: Variant) -> String:
	return str(v).strip_edges()


static func _i(v: Variant) -> int:
	var s := str(v).strip_edges()
	if s.is_empty():
		return 0
	return int(s.to_int())


static func _f(v: Variant) -> float:
	var s := str(v).strip_edges()
	if s.is_empty():
		return 0.0
	return float(s.to_float())
