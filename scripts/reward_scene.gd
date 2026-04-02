extends Control

const CARD_ITEM_SCENE = preload("res://ui/card_item.tscn")

@onready var card_container = $CenterContainer/MainVBox/CenterContainer
@onready var add_button = $CenterContainer/MainVBox/AddButton

func _ready() -> void:
	add_button.pressed.connect(_on_add_button_pressed)
	build_reward_card()

func build_reward_card() -> void:
	for child in card_container.get_children():
		child.queue_free()

	var card_ui = CARD_ITEM_SCENE.instantiate()
	card_container.add_child(card_ui)
	card_ui.setup(CardData.get_card_data("resonance"))
	card_ui.disabled = true

func _on_add_button_pressed() -> void:
	GameManager.has_resonance_card = true
	GameManager.advance_node()
	get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")
