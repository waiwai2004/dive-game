extends Control

@onready var npc_name_label = $UILayer/MarginContainer/MainVBox/PanelContainer/VBoxContainer/NpcNameLabel
@onready var dialogue_text_label = $UILayer/MarginContainer/MainVBox/PanelContainer/VBoxContainer/DialogueTextLabel
@onready var next_button = $UILayer/MarginContainer/MainVBox/PanelContainer/VBoxContainer/HBoxContainer/NextButton
@onready var finish_button = $UILayer/MarginContainer/MainVBox/PanelContainer/VBoxContainer/HBoxContainer/FinishButton

var lines := [
	"你终于来了。",
	"穿过这些残影，找到伤口。",
	"别让自己消失。"
]

var current_index := 0

func _ready() -> void:
	next_button.pressed.connect(_on_next_button_pressed)
	finish_button.pressed.connect(_on_finish_button_pressed)
	refresh_text()

func refresh_text() -> void:
	npc_name_label.text = "人格残影"
	dialogue_text_label.text = lines[current_index]

func _on_next_button_pressed() -> void:
	if current_index < lines.size() - 1:
		current_index += 1
		refresh_text()

func _on_finish_button_pressed() -> void:
	GameManager.advance_node()
	get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")
