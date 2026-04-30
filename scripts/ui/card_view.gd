extends Control

@export var use_imported_frame_art: bool = true

@onready var frame_sprite: TextureRect = get_node_or_null("../FrameSprite")
@onready var illustration_sprite: TextureRect = $IllustrationSprite
@onready var name_label: Label = $NameLabel
@onready var energy_label: Label = $EnergyContainer/EnergyLabel
@onready var rec_label: Label = $RecContainer/RecLabel
@onready var description_label: Label = $DescriptionLabel


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
