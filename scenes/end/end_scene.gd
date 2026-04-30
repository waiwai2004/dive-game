extends Control

@onready var click_catcher: Button = $ClickCatcher


func _ready() -> void:
	if has_node("/root/AudioManager"):
		AudioManager.play_bgm_segment("end")

	if has_node("/root/GlobalUI"):
		GlobalUI.set_mode(GlobalUI.MODE_MENU)
		GlobalUI.clear_hint()
		GlobalUI.clear_energy()
		GlobalUI.refresh_stats()

	click_catcher.pressed.connect(_on_click_catcher_pressed)


func _on_click_catcher_pressed() -> void:
	get_tree().quit()
