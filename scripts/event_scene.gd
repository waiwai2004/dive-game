extends Control

@onready var option_a_button = $CenterContainer/MainVBox/ChoiceRow/OptionACard
@onready var option_b_button = $CenterContainer/MainVBox/ChoiceRow/OptionBCard

func _ready() -> void:
	option_a_button.pressed.connect(_on_option_a_button_pressed)
	option_b_button.pressed.connect(_on_option_b_button_pressed)

func _on_option_a_button_pressed() -> void:
	GameManager.player_summary["max_hp"] += 5
	GameManager.player_summary["hp"] = GameManager.player_summary["max_hp"]
	GameManager.player_summary["cognition_max"] -= 1
	GameManager.advance_node()
	get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")

func _on_option_b_button_pressed() -> void:
	GameManager.player_summary["max_hp"] -= 3
	if GameManager.player_summary["hp"] > GameManager.player_summary["max_hp"]:
		GameManager.player_summary["hp"] = GameManager.player_summary["max_hp"]
	# 每回合额外提供1点费用
	GameManager.player_summary["extra_energy"] += 1
	GameManager.advance_node()
	get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")
