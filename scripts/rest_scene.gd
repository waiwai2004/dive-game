extends Control

@onready var rest_button = $CenterContainer/MainVBox/ButtonRow/RestButton

func _ready() -> void:
	rest_button.pressed.connect(_on_rest_button_pressed)

func _on_rest_button_pressed() -> void:
	GameManager.player_summary["hp"] = GameManager.player_summary["max_hp"]
	GameManager.advance_node()
	get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")
