extends Control

@export var use_imported_frame_art: bool = false

@onready var frame_sprite: TextureRect = $FrameSprite
@onready var illustration_sprite: TextureRect = $IllustrationSprite
@onready var name_label: Label = $NameLabel
@onready var cost_label: Label = $CostLabel
@onready var description_label: Label = $DescriptionLabel


func _ready() -> void:
	print("[CardView] node bind frame=%s illustration=%s name=%s cost=%s desc=%s use_imported_frame_art=%s" % [
		str(frame_sprite != null),
		str(illustration_sprite != null),
		str(name_label != null),
		str(cost_label != null),
		str(description_label != null),
		str(use_imported_frame_art)
	])


func setup_from_data(card_data: CardData) -> void:
	if card_data == null:
		_clear_view()
		push_warning("[CardView] setup_from_data got null")
		return

	name_label.text = card_data.card_name
	cost_label.text = str(card_data.energy_cost)
	description_label.text = card_data.description

	_apply_imported_frame_art(card_data.art_frame_path, card_data.card_id)
	_load_texture_to(illustration_sprite, card_data.art_illustration_path, card_data.card_id, "art_illustration_path")


func setup_from_dictionary(card_dict: Dictionary) -> void:
	var card_id: String = str(card_dict.get("id", card_dict.get("card_id", "")))
	var card_name: String = str(card_dict.get("name", card_dict.get("card_name", "")))
	var frame_path: String = str(card_dict.get("art_frame_path", ""))
	var illustration_path: String = str(card_dict.get("art_illustration_path", ""))

	print("[CardUI] id=%s name=%s frame=%s illustration=%s" % [card_id, card_name, frame_path, illustration_path])

	name_label.text = card_name
	cost_label.text = str(int(card_dict.get("cost", card_dict.get("energy_cost", 0))))
	description_label.text = str(card_dict.get("description", card_dict.get("desc", "")))

	_apply_imported_frame_art(frame_path, card_id)
	_load_texture_to(illustration_sprite, illustration_path, card_id, "art_illustration_path")


func _apply_imported_frame_art(frame_path: String, card_id: String) -> void:
	if frame_sprite == null:
		return

	if not use_imported_frame_art:
		frame_sprite.visible = false
		frame_sprite.texture = null
		print("[CardUI] imported frame disabled: card=%s" % card_id)
		return

	frame_sprite.visible = true
	_load_texture_to(frame_sprite, frame_path, card_id, "art_frame_path")


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
	frame_sprite.texture = null
	illustration_sprite.texture = null
	name_label.text = ""
	cost_label.text = ""
	description_label.text = ""
