extends Control

const NORMAL_ENERGY_COLOR := Color(0.2, 0.1, 0.05, 1)
const NORMAL_REC_COLOR := Color(0.2, 0.1, 0.05, 1)
const NORMAL_DESC_COLOR := Color(0.2, 0.12, 0.08, 1)
const MANIC_COLOR := Color(0.95, 0.2, 0.2, 1)
const MANIC_BORDER_COLOR := Color(0.95, 0.25, 0.2, 0.85)

@export var use_imported_frame_art: bool = true

@onready var frame_sprite: TextureRect = get_node_or_null("../FrameSprite")
@onready var illustration_sprite: TextureRect = $IllustrationSprite
@onready var name_label: Label = $NameLabel
@onready var energy_label: Label = $EnergyContainer/EnergyLabel
@onready var rec_label: Label = $RecContainer/RecLabel
@onready var description_label: RichTextLabel = $DescriptionLabel

var _manic_border: PanelContainer = null
var _is_manic: bool = false


func _ready() -> void:
	print("[CardView] node bind frame=%s illustration=%s name=%s energy=%s rec=%s desc=%s" % [
		str(frame_sprite != null),
		str(illustration_sprite != null),
		str(name_label != null),
		str(energy_label != null),
		str(rec_label != null),
		str(description_label != null)
	])


func setup_from_data(card_data: CardData) -> void:
	if card_data == null:
		_clear_view()
		push_warning("[CardView] setup_from_data got null")
		return

	name_label.text = card_data.card_name
	energy_label.text = str(card_data.energy_cost)
	rec_label.text = str(card_data.cognition)
	description_label.text = card_data.description

	_load_texture_to(illustration_sprite, card_data.art_illustration_path, card_data.card_id, "art_illustration_path")


func setup_from_dictionary(card_dict: Dictionary) -> void:
	var card_id: String = str(card_dict.get("id", card_dict.get("card_id", "")))
	var card_name: String = str(card_dict.get("name", card_dict.get("card_name", "")))
	var illustration_path: String = str(card_dict.get("art_illustration_path", ""))

	print("[CardUI] id=%s name=%s illustration=%s" % [card_id, card_name, illustration_path])

	name_label.text = card_name
	energy_label.text = str(int(card_dict.get("cost", card_dict.get("energy_cost", 0))))
	rec_label.text = str(int(card_dict.get("cognition", card_dict.get("cognition_cost", 0))))
	description_label.text = str(card_dict.get("description", card_dict.get("desc", "")))

	_load_texture_to(illustration_sprite, illustration_path, card_id, "art_illustration_path")


func _load_texture_to(target: TextureRect, path: String, card_id: String, field_name: String) -> void:
	if target == null:
		push_warning("[CardView] target node is null for field=%s card=%s" % [field_name, card_id])
		print("[CardUI] %s target null: card=%s" % [field_name, card_id])
		return

	var clean_path: String = path.strip_edges()
	if clean_path.is_empty():
		target.texture = null
		push_warning("[CardView] %s path empty for card '%s'" % [field_name, card_id])
		print("[CardUI] %s path empty: card=%s" % [field_name, card_id])
		return

	if not ResourceLoader.exists(clean_path):
		target.texture = null
		push_warning("[CardView] %s path missing for card '%s': %s" % [field_name, card_id, clean_path])
		print("[CardUI] %s load failed (missing): %s card=%s" % [field_name, clean_path, card_id])
		return

	var res: Resource = load(clean_path)
	if res is Texture2D:
		target.texture = res as Texture2D
		print("[CardUI] %s loaded ok: %s card=%s visible=%s alpha=%.2f size=%s" % [
			field_name,
			clean_path,
			card_id,
			str(target.visible),
			target.modulate.a,
			str(target.size)
		])
	else:
		target.texture = null
		push_warning("[CardView] %s texture load failed for card '%s': %s" % [field_name, card_id, clean_path])
		print("[CardUI] %s load failed (type): %s card=%s" % [field_name, clean_path, card_id])


func _clear_view() -> void:
	illustration_sprite.texture = null
	name_label.text = ""
	energy_label.text = ""
	rec_label.text = ""
	description_label.text = ""


func apply_manic_visual(card_dict: Dictionary) -> void:
	if _is_manic:
		return
	_is_manic = true

	var raw_cost := int(card_dict.get("cost", card_dict.get("energy_cost", 0)))
	var raw_cognition := int(card_dict.get("cognition", card_dict.get("cognition_cost", 0)))
	var modified_cost := raw_cost + 1
	var modified_cognition := raw_cognition + 1

	print("[Manic] 卡牌:%s 原始费用=%s→%s 原始认知=%s→%s" % [
		card_dict.get("name", "?"), raw_cost, modified_cost, raw_cognition, modified_cognition
	])

	energy_label.text = str(modified_cost)
	energy_label.add_theme_color_override("font_color", MANIC_COLOR)

	rec_label.text = str(modified_cognition)
	rec_label.add_theme_color_override("font_color", MANIC_COLOR)

	var raw_desc := str(card_dict.get("description", card_dict.get("desc", "")))
	_set_description_with_highlighted_numbers(raw_desc, 1)

	_ensure_manic_border()


func clear_manic_visual(card_dict: Dictionary) -> void:
	if not _is_manic:
		return
	_is_manic = false

	var base_cost := int(card_dict.get("cost", card_dict.get("energy_cost", 0)))
	var base_cognition := int(card_dict.get("cognition", card_dict.get("cognition_cost", 0)))

	energy_label.text = str(base_cost)
	energy_label.remove_theme_color_override("font_color")

	rec_label.text = str(base_cognition)
	rec_label.remove_theme_color_override("font_color")

	description_label.clear()
	description_label.push_normal()
	description_label.add_text(str(card_dict.get("description", card_dict.get("desc", ""))))
	description_label.pop()

	if _manic_border and is_instance_valid(_manic_border):
		_manic_border.queue_free()
		_manic_border = null


func _set_description_with_highlighted_numbers(raw_text: String, add_amount: int) -> void:
	description_label.clear()
	description_label.push_normal()

	var regex := RegEx.new()
	regex.compile("(\\d+)")
	var found := regex.search_all(raw_text)
	if found.is_empty():
		description_label.add_text(raw_text)
		description_label.pop()
		return

	var last_end := 0
	for m in found:
		var start := m.get_start()
		var end := m.get_end()
		if start > last_end:
			description_label.add_text(raw_text.substr(last_end, start - last_end))
		var num_str := m.get_string(1)
		var new_num := int(num_str) + add_amount
		description_label.push_color(MANIC_COLOR)
		description_label.add_text(str(new_num))
		description_label.pop()
		last_end = end
	if last_end < raw_text.length():
		description_label.add_text(raw_text.substr(last_end))
	description_label.pop()


func _ensure_manic_border() -> void:
	if _manic_border and is_instance_valid(_manic_border):
		return
	var parent := get_parent()
	if parent == null:
		return
	_manic_border = PanelContainer.new()
	_manic_border.name = "ManicBorder"
	_manic_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_width_left = 4
	sb.border_width_top = 4
	sb.border_width_right = 4
	sb.border_width_bottom = 4
	sb.border_color = MANIC_BORDER_COLOR
	sb.corner_radius_top_left = 14
	sb.corner_radius_top_right = 14
	sb.corner_radius_bottom_right = 14
	sb.corner_radius_bottom_left = 14
	sb.shadow_color = Color(0.95, 0.25, 0.15, 0.45)
	sb.shadow_size = 8
	_manic_border.add_theme_stylebox_override("panel", sb)
	_manic_border.anchors_preset = Control.PRESET_FULL_RECT
	_manic_border.offset_left = -3
	_manic_border.offset_top = -3
	_manic_border.offset_right = 3
	_manic_border.offset_bottom = 3
	parent.add_child(_manic_border)
