extends Control

@onready var title_label: Label = find_child("TitleLabel", true, false)
@onready var status_label: Label = find_child("StatusLabel", true, false)
@onready var header_label: Label = find_child("Header", true, false)
@onready var info_label: Label = find_child("InfoLabel", true, false)
@onready var continue_button: Button = find_child("ContinueButton", true, false)
@onready var reward_plate: TextureRect = find_child("RewardPlate", true, false)
@onready var reward_texture: TextureRect = find_child("RewardTexture", true, false)

var _is_boss: bool = false
var _reward_card_data: Dictionary = {}
var _card_back: Texture2D
var _memory_fragment: Texture2D

func _ready() -> void:
	show()
	
	_is_boss = Game.get_meta("battle_is_boss", false)
	var turns_taken = Game.get_meta("battle_turn_count", 0)
	
	Game.player_san = Game.max_san
	Game.clear_cognition()
	
	_card_back = load("res://assets/art/cards/card_back.PNG") as Texture2D
	_memory_fragment = load("res://assets/art/explore/IMG_3719.PNG") as Texture2D
	
	if status_label: status_label.text = "耗时%d回合" % turns_taken
	
	if _is_boss:
		if title_label: title_label.text = "战斗胜利！"
		if header_label: header_label.text = "奖励"
		if info_label: info_label.text = "获得一张新卡牌"
		if reward_plate: reward_plate.visible = true
		if reward_texture: reward_texture.texture = _card_back
		var db = get_node_or_null("/root/CardDatabase")
		if db and db.has_method("get_card"):
			var first_card_id = Game.get_first_reward_card_id()
			_reward_card_data = db.get_card(first_card_id)
	else:
		if title_label: title_label.text = "战斗胜利！"
		if header_label: header_label.text = "奖励"
		if info_label: info_label.text = "获得记忆碎片"
		if reward_plate: reward_plate.visible = true
		if reward_texture: reward_texture.texture = _memory_fragment
	
	continue_button.text = "放弃并继续"
	continue_button.pressed.connect(_on_continue_pressed)
	
	if reward_texture:
		reward_texture.gui_input.connect(_on_reward_gui_input)
		reward_texture.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _on_reward_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _is_boss:
			if not _reward_card_data.is_empty() and _reward_card_data.has("id"):
				Game.add_card(str(_reward_card_data["id"]))
			var show_card_scene = load("res://scenes/showcard/ShowCard.tscn") as PackedScene
			if show_card_scene:
				var show_card = show_card_scene.instantiate()
				get_tree().root.add_child(show_card)
				get_tree().current_scene = show_card
				show_card.setup(_reward_card_data)
		else:
			var ai_scene = load("res://scenes/ai/AIFeature.tscn") as PackedScene
			if ai_scene:
				var ai_feature = ai_scene.instantiate()
				get_tree().root.add_child(ai_feature)
				get_tree().current_scene = ai_feature


func _on_continue_pressed() -> void:
	Game.goto_explore()
