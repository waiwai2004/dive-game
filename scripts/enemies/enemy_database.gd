extends Node
class_name EnemyRepository

var enemies_json_path: String = "res://data/enemies/enemies.json"

var _enemies_by_id: Dictionary = {}
var _battle_order: Array[String] = []
var _loaded: bool = false


func load_enemies() -> bool:
	_enemies_by_id.clear()
	_battle_order.clear()

	if not FileAccess.file_exists(enemies_json_path):
		push_error("[EnemyRepository] enemy json not found: %s" % enemies_json_path)
		return false

	var raw := FileAccess.get_file_as_string(enemies_json_path)
	if raw.is_empty():
		push_error("[EnemyRepository] enemy json empty: %s" % enemies_json_path)
		return false

	var parsed: Variant = JSON.parse_string(raw)
	if parsed == null or not (parsed is Dictionary):
		push_error("[EnemyRepository] parse enemy json failed: %s" % enemies_json_path)
		return false

	var battle_order_raw: Variant = parsed.get("battle_order", [])
	if battle_order_raw is Array:
		for enemy_id in battle_order_raw:
			_battle_order.append(str(enemy_id))

	var enemies_raw: Variant = parsed.get("enemies", [])
	if enemies_raw is Array:
		for item in enemies_raw:
			if item is Dictionary:
				var enemy := EnemyData.from_dict(item)
				if enemy.enemy_id.is_empty():
					continue
				_enemies_by_id[enemy.enemy_id] = enemy

	_loaded = not _enemies_by_id.is_empty()
	if _loaded:
		print("[EnemyRepository] loaded enemies: %d" % _enemies_by_id.size())
	return _loaded


func get_enemy_data(enemy_id: String) -> EnemyData:
	_ensure_loaded()
	if _enemies_by_id.has(enemy_id):
		return _enemies_by_id[enemy_id] as EnemyData
	return null


func has_enemy(enemy_id: String) -> bool:
	_ensure_loaded()
	return _enemies_by_id.has(enemy_id)


func get_enemy_id_for_battle_index(battle_index: int) -> String:
	_ensure_loaded()
	if _battle_order.is_empty():
		return ""
	var index := maxi(battle_index, 1) - 1
	index = clampi(index, 0, _battle_order.size() - 1)
	return _battle_order[index]


func get_enemy_data_for_battle_index(battle_index: int) -> EnemyData:
	return get_enemy_data(get_enemy_id_for_battle_index(battle_index))


func _ensure_loaded() -> void:
	if not _loaded:
		load_enemies()
