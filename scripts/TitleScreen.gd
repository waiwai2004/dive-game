# 标题场景脚本，处理标题场景的逻辑和交互
extends Control

# 当节点准备好时，获取UI元素的引用
@onready var game_title: RichTextLabel = $GameTitle  # 游戏标题标签
@onready var start_hint: Label = $StartHint         # 开始游戏提示标签

# 波浪效果参数
var wave_amplitude: float = 10.0  # 波浪振幅
var wave_frequency: float = 2.0   # 波浪频率
var wave_speed: float = 3.0       # 波浪速度

# 当节点准备好时调用的函数
func _ready() -> void:
	game_title.bbcode_enabled = true
	game_title.text = "[center]海底无[color=#ff5555]明日[/color][/center]"
	start_hint.text = "点  击  开  始  游  戏"
	
	# 开始波浪动画
	start_wave_animation()

# 开始波浪动画
func start_wave_animation() -> void:
	# 创建Tween对象
	var tween = create_tween()
	tween.set_loops()  # 循环播放
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	# 动画标题的位置
	var original_position = game_title.position
	var offset = Vector2(0, -wave_amplitude)
	
	tween.tween_property(game_title, "position", original_position + offset, 1.0 / wave_frequency)
	tween.tween_property(game_title, "position", original_position, 1.0 / wave_frequency)

# 当点击捕捉器被按下时调用的函数
func _on_click_catcher_pressed() -> void:
	$ClickCatcher/SfxrStreamPlayer.play_click()
	await get_tree().create_timer(0.2).timeout
	get_tree().change_scene_to_file("res://scenes/base/BaseScene.tscn")



func _on_sfxr_stream_player_finished() -> void:
	pass # Replace with function body.
