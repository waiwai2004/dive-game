extends Node

# 兼容旧路径：转到新表格驱动实现。
var _repo: CardRepository


func _ready() -> void:
	_ensure_repo()
	_repo.load_cards()


func _ensure_repo() -> void:
	if _repo != null:
		return
	_repo = CardRepository.new()


func load_cards() -> bool:
	_ensure_repo()
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


func get_card(card_id: String) -> Dictionary:
	_ensure_repo()
	return _repo.get_card_dict(card_id)


func get_type_text(card_type: String) -> String:
	_ensure_repo()
	return _repo.get_type_text(card_type)
