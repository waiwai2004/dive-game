extends Control

var card_ui: Node = null
var title_label: Label = null
var description_text: RichTextLabel = null
var collect_button: TextureButton = null

var card_data: Dictionary = {}
var _pending_setup: Dictionary = {}
var _add_card_on_collect: bool = true

func _ready() -> void:
	card_ui = get_node_or_null("Control/CardContainer/CardUI")
	title_label = get_node_or_null("RightPanel/TitleBox/TitleLabel")
	description_text = get_node_or_null("RightPanel/DescriptionText")
	collect_button = get_node_or_null("RightPanel/CollectButton")
	
	if collect_button:
		collect_button.pressed.connect(_on_collect_pressed)
	
	if not _pending_setup.is_empty():
		_apply_setup(_pending_setup)
		_pending_setup = {}

func setup(data: Dictionary, add_card_on_collect: bool = true) -> void:
	card_data = data
	_add_card_on_collect = add_card_on_collect
	
	if is_inside_tree():
		_apply_setup(data)
	else:
		_pending_setup = data

func _apply_setup(data: Dictionary) -> void:
	var card_name = str(data.get("name", data.get("card_name", "未知卡牌")))
	if title_label:
		title_label.text = card_name
	
	var desc = str(data.get("description", data.get("desc", "")))
	if description_text:
		description_text.text = desc
	
	if card_ui and card_ui.has_method("setup"):
		card_ui.setup(data, 0, self)
		if card_ui.has_method("_refresh_text"):
			card_ui.call("_refresh_text")

func _on_collect_pressed() -> void:
	if _add_card_on_collect and card_data.has("id"):
		var card_id = str(card_data["id"])
		if typeof(Game) == TYPE_OBJECT and Game.has_method("add_card"):
			Game.add_card(card_id)
			print("已收下卡牌:", card_id)
	
	get_tree().change_scene_to_file("res://scenes/explore/ExploreScene.tscn")
