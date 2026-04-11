extends Node2D

@onready var title_label: Label = $CanvasLayer/Panel/TitleLabel
@onready var info_label: Label = $CanvasLayer/Panel/InfoLabel
@onready var return_button: Button = $CanvasLayer/Panel/ReturnButton
@onready var attack_button: Button = $CanvasLayer/Panel/AttackButton

func _ready() -> void:
	if not return_button.pressed.is_connected(_on_return_button_pressed):
		return_button.pressed.connect(_on_return_button_pressed)

	if not attack_button.pressed.is_connected(_on_attack_button_pressed):
		attack_button.pressed.connect(_on_attack_button_pressed)

	_setup_enemy_view()

func _setup_enemy_view() -> void:
	match BattleFlow.enemy_id:
		"deep_monster_01":
			title_label.text = "深海异兽"
			info_label.text = "你遭遇了深海异兽。战斗系统正在制作中。"
		_:
			title_label.text = "未知敌人"
			info_label.text = "你进入了战斗页面。"

func _on_attack_button_pressed() -> void:
	info_label.text = "你发动了一次攻击！这里先作为占位演示。"

func _on_return_button_pressed() -> void:
	BattleFlow.prepare_return()
	get_tree().change_scene_to_file(BattleFlow.return_scene_path)
