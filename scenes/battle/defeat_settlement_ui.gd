extends Control

@onready var title_label: Label = find_child("TitleLabel", true, false)
@onready var status_label: Label = find_child("StatusLabel", true, false)
@onready var return_button: Button = find_child("ReturnButton", true, false)

func _ready() -> void:
	show()
	if return_button:
		return_button.pressed.connect(_on_return_button_pressed)
		
	# 从全局读取是哪个怪物杀死了玩家
	var enemy_name = Game.get_meta("battle_enemy_name", "深海梦魇")

	if title_label: title_label.text = "挑战失败"
	if status_label: status_label.text = "你的存在被 %s 抹除" % enemy_name

func _on_return_button_pressed() -> void:
	Game.goto_title()
