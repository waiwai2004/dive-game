# 标题场景脚本，处理标题场景的逻辑和交互
extends Control

# 当节点准备好时，获取UI元素的引用
@onready var game_title: RichTextLabel = $GameTitle  # 游戏标题标签
@onready var start_hint: Label = $StartHint         # 开始游戏提示标签

# 当节点准备好时调用的函数
func _ready() -> void:
	game_title.bbcode_enabled = true
	game_title.text = "[center]海底无[color=#ff5555]明日[/color][/center]"
	start_hint.text = "点  击  开  始  游  戏"


# 当点击捕捉器被按下时调用的函数
func _on_click_catcher_pressed() -> void:
	$ClickCatcher/SfxrStreamPlayer.play_click()
	await get_tree().create_timer(0.2).timeout
	get_tree().change_scene_to_file("res://scenes/base/BaseScene.tscn")



func _on_sfxr_stream_player_finished() -> void:
	pass # Replace with function body.
