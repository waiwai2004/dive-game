extends Control

@onready var result_label = $MainVBox/ResultLabel
@onready var summary_label = $MainVBox/SummaryLabel
@onready var back_to_title_button = $MainVBox/BackToTitleButton

func _ready() -> void:
	back_to_title_button.pressed.connect(_on_back_to_title_button_pressed)
	refresh_ui()

func refresh_ui() -> void:
	if GameManager.battle_result == "victory":
		result_label.text = "Demo 通关"
		summary_label.text = "你成功穿过伤口，完成了本次最小流程验证。"
	else:
		result_label.text = "挑战失败"
		summary_label.text = "你的存在已经消散。"

func _on_back_to_title_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/title/title_scene.tscn")
