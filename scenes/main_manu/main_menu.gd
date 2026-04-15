extends Control

@onready var start_hint: Label = $StartHint


func _ready() -> void:
	Game.reset_run()
	if has_node("/root/AudioManager"):
		AudioManager.play_bgm_segment("menu")
	if has_node("/root/GlobalUI"):
		GlobalUI.set_mode(GlobalUI.MODE_MENU)
		GlobalUI.clear_hint()
		GlobalUI.refresh_stats()

	if start_hint:
		start_hint.text = "点 击 任 意 位 置 开 始 游 戏"


func _on_click_catcher_pressed() -> void:
	await get_tree().create_timer(0.2).timeout
	get_tree().change_scene_to_file("res://scenes/story/StoryScene.tscn")
