extends Node

var _repo: EnemyRepository


func _ready() -> void:
	_ensure_repo()
	_repo.load_enemies()


func _ensure_repo() -> void:
	if _repo != null:
		return
	_repo = EnemyRepository.new()


func load_enemies() -> bool:
	_ensure_repo()
	return _repo.load_enemies()


func has_enemy(enemy_id: String) -> bool:
	_ensure_repo()
	return _repo.has_enemy(enemy_id)


func get_enemy_data(enemy_id: String) -> EnemyData:
	_ensure_repo()
	return _repo.get_enemy_data(enemy_id)


func get_enemy_id_for_battle_index(battle_index: int) -> String:
	_ensure_repo()
	return _repo.get_enemy_id_for_battle_index(battle_index)


func get_enemy_data_for_battle_index(battle_index: int) -> EnemyData:
	_ensure_repo()
	return _repo.get_enemy_data_for_battle_index(battle_index)
