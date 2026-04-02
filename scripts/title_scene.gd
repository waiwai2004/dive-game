extends Control

@onready var start_button = $CenterContainer/MainVBox/ButtonBar/StartButton
@onready var quit_button = $CenterContainer/MainVBox/ButtonBar/QuitButton

func _ready() -> void:
	start_button.pressed.connect(_on_start_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)

func _on_start_button_pressed() -> void:
	GameManager.reset_demo_progress()
	get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
