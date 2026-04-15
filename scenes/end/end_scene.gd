extends Node


func _ready() -> void:
	if has_node("/root/AudioManager"):
		AudioManager.play_bgm_segment("end")
	if has_node("/root/GlobalUI"):
		GlobalUI.set_mode(GlobalUI.MODE_MENU)
		GlobalUI.clear_hint()
		GlobalUI.refresh_stats()
