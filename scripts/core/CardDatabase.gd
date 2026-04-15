extends Node

@export var cards_csv_path: String = "res://data/cards/cards.csv"
@export var cards_json_path: String = "res://data/cards/cards.json"

var _repo: CardRepository


func _ready() -> void:
	_ensure_repo()
	load_cards()


func _ensure_repo() -> void:
	if _repo != null:
		return
	_repo = CardRepository.new()
	_sync_paths()


func _sync_paths() -> void:
	_ensure_repo()
	_repo.cards_csv_path = cards_csv_path
	_repo.cards_json_path = cards_json_path


func load_cards() -> bool:
	_sync_paths()
	return _repo.load_cards()


func get_card_data(card_id: String) -> CardData:
	_ensure_repo()
	return _repo.get_card_data(card_id)


func get_all_cards() -> Array[CardData]:
	_ensure_repo()
	return _repo.get_all_cards()


func get_enabled_cards() -> Array[CardData]:
	_ensure_repo()
	return _repo.get_enabled_cards()


func has_card(card_id: String) -> bool:
	_ensure_repo()
	return _repo.has_card(card_id)


# 兼容层：现有 BattleScene / RewardUI 仍然读取 Dictionary
func get_card(card_id: String) -> Dictionary:
	_ensure_repo()
	return _repo.get_card_dict(card_id)


func get_type_text(card_type: String) -> String:
	_ensure_repo()
	return _repo.get_type_text(card_type)
