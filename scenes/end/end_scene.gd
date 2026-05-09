extends Control

@onready var click_catcher: Button = $ClickCatcher
@onready var hint_label: Label = $EndHint

var _pending_victory: bool = false


func _ready() -> void:
	if has_node("/root/AudioManager"):
		AudioManager.play_bgm_segment("end")

	if has_node("/root/GlobalUI"):
		GlobalUI.set_mode(GlobalUI.MODE_MENU)
		GlobalUI.clear_energy()
		GlobalUI.refresh_stats()

	# 检测是否从 Boss 战胜利跳转过来
	_pending_victory = Game.get_meta("pending_victory_after_end", false)
	if _pending_victory:
		Game.set_meta("pending_victory_after_end", false)
		if hint_label:
			hint_label.text = "点击任意位置继续"
	else:
		if hint_label:
			hint_label.text = "D E M O 结 束"

	click_catcher.pressed.connect(_on_click_catcher_pressed)


func _on_click_catcher_pressed() -> void:
	if _pending_victory:
		get_tree().change_scene_to_file("res://scenes/battle/VictorySettlementUI.tscn")
	else:
		get_tree().quit()
