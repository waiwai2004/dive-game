extends Node
class_name CardRepository

var cards_csv_path: String = "res://data/cards/cards.csv"
var cards_json_path: String = "res://data/cards/cards.json"

var _cards_by_id: Dictionary = {}
var _loaded: bool = false

const _DEFAULT_COGNITION: Dictionary = {
	"cut": 1,
	"guard": 1,
	"calm": 1,
	"break": 1,
	"pursue": 2,
	"seal": 2
}


func load_cards() -> bool:
	_cards_by_id.clear()

	var loaded_ok: bool = false
	if FileAccess.file_exists(cards_csv_path):
		loaded_ok = _load_from_csv(cards_csv_path)
		if not loaded_ok and FileAccess.file_exists(cards_json_path):
			push_warning("[CardRepository] CSV 读取失败，尝试 JSON: %s" % cards_json_path)
			loaded_ok = _load_from_json(cards_json_path)
	elif FileAccess.file_exists(cards_json_path):
		loaded_ok = _load_from_json(cards_json_path)
	else:
		push_error("[CardRepository] cards file not found. csv=%s json=%s" % [cards_csv_path, cards_json_path])

	_loaded = loaded_ok
	if loaded_ok:
		print("[CardRepository] loaded cards: %d" % _cards_by_id.size())
	return loaded_ok


func get_card_data(card_id: String) -> CardData:
	_ensure_loaded()
	if _cards_by_id.has(card_id):
		return _cards_by_id[card_id] as CardData
	return null


func get_all_cards() -> Array[CardData]:
	_ensure_loaded()
	var keys: Array = _cards_by_id.keys()
	keys.sort()
	var all_cards: Array[CardData] = []
	for key in keys:
		all_cards.append(_cards_by_id[key] as CardData)
	return all_cards


func get_enabled_cards() -> Array[CardData]:
	_ensure_loaded()
	var enabled_cards: Array[CardData] = []
	for card in get_all_cards():
		if card and card.is_enabled():
			enabled_cards.append(card)
	return enabled_cards


func has_card(card_id: String) -> bool:
	_ensure_loaded()
	return _cards_by_id.has(card_id)


func get_card_dict(card_id: String) -> Dictionary:
	var c: CardData = get_card_data(card_id)
	if c == null:
		push_warning("[CardRepository] card not found: %s" % card_id)
		return {}
	return c.to_battle_dict()


func get_type_text(card_type: String) -> String:
	var t: String = card_type.strip_edges().to_lower()
	match t:
		"attack", "攻击":
			return "攻击"
		"buff", "defend", "defense", "防御", "增益":
			return "增益"
		"debuff", "减益":
			return "减益"
		"utility", "heal", "治疗", "特殊":
			return "运营"
		_:
			return "未知"


func _ensure_loaded() -> void:
	if not _loaded:
		load_cards()


func _load_from_csv(path: String) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[CardRepository] open csv failed: %s" % path)
		return false

	var header: PackedStringArray = file.get_csv_line()
	if header.is_empty():
		push_error("[CardRepository] csv header empty: %s" % path)
		return false

	var header_names: Array[String] = []
	for i in range(header.size()):
		var header_name: String = str(header[i]).strip_edges()
		if i == 0:
			header_name = header_name.trim_prefix("\ufeff")
		header_names.append(header_name)

	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.is_empty():
			continue

		var is_blank_row: bool = true
		for cell in row:
			if not str(cell).strip_edges().is_empty():
				is_blank_row = false
				break
		if is_blank_row:
			continue

		var row_dict: Dictionary = {}
		for i in range(header_names.size()):
			var key: String = header_names[i]
			var value: String = ""
			if i < row.size():
				value = str(row[i]).strip_edges()
			row_dict[key] = value

		var card: CardData = CardData.from_row(row_dict)
		_finalize_card(card)
		if card.card_id.is_empty():
			push_warning("[CardRepository] skip row with empty card_id")
			continue

		if _cards_by_id.has(card.card_id):
			push_warning("[CardRepository] duplicate card_id '%s', overwrite old data" % card.card_id)
		_cards_by_id[card.card_id] = card

	return _cards_by_id.size() > 0


func _load_from_json(path: String) -> bool:
	var raw := FileAccess.get_file_as_string(path)
	if raw.is_empty():
		push_error("[CardRepository] json empty: %s" % path)
		return false

	var parsed: Variant = JSON.parse_string(raw)
	if parsed == null:
		push_error("[CardRepository] parse json failed: %s" % path)
		return false

	if parsed is Array:
		for item in parsed:
			if item is Dictionary:
				var card: CardData = CardData.from_row(item)
				_finalize_card(card)
				if card.card_id.is_empty():
					continue
				_cards_by_id[card.card_id] = card
	elif parsed is Dictionary and parsed.has("cards") and parsed["cards"] is Array:
		for item in parsed["cards"]:
			if item is Dictionary:
				var card2: CardData = CardData.from_row(item)
				_finalize_card(card2)
				if card2.card_id.is_empty():
					continue
				_cards_by_id[card2.card_id] = card2
	else:
		push_error("[CardRepository] json format invalid: %s" % path)
		return false

	return _cards_by_id.size() > 0


func _finalize_card(card: CardData) -> void:
	if card.description.is_empty():
		card.description = card.note

	if card.target_type.is_empty():
		if card.normalized_type() in ["buff", "utility"]:
			card.target_type = "self"
		else:
			card.target_type = "enemy"

	if card.cognition <= 0 and _DEFAULT_COGNITION.has(card.card_id):
		card.cognition = int(_DEFAULT_COGNITION[card.card_id])
