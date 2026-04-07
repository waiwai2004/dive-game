# 标题场景脚本
# 处理标题界面的交互逻辑
extends Control

# 按钮引用
@onready var start_button = $CenterContainer/MainVBox/ButtonBar/StartButton  # 开始按钮
@onready var quit_button = $CenterContainer/MainVBox/ButtonBar/QuitButton  # 退出按钮

# 场景准备就绪
func _ready() -> void:
	# 连接开始按钮的按下信号
	start_button.pressed.connect(_on_start_button_pressed)
	# 连接退出按钮的按下信号
	quit_button.pressed.connect(_on_quit_button_pressed)

# 开始按钮按下处理
func _on_start_button_pressed() -> void:
	# 重置游戏进度
	GameManager.reset_demo_progress()
	# 切换到地图场景
	get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")

# 退出按钮按下处理
func _on_quit_button_pressed() -> void:
	# 退出游戏
	get_tree().quit()
