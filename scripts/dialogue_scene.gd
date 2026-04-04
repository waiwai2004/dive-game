# 对话场景脚本
# 处理对话界面的显示和交互逻辑
extends Control

# UI组件引用
@onready var npc_name_label = $UILayer/MarginContainer/MainVBox/PanelContainer/VBoxContainer/NpcNameLabel  # NPC名称标签
@onready var dialogue_text_label = $UILayer/MarginContainer/MainVBox/PanelContainer/VBoxContainer/DialogueTextLabel  # 对话文本标签
@onready var next_button = $UILayer/MarginContainer/MainVBox/PanelContainer/VBoxContainer/HBoxContainer/NextButton  # 下一行按钮
@onready var finish_button = $UILayer/MarginContainer/MainVBox/PanelContainer/VBoxContainer/HBoxContainer/FinishButton  # 结束按钮

# 对话文本数组
var lines := [
	"你终于来了。",
	"穿过这些残影，找到伤口。",
	"别让自己消失。"
]

# 当前对话索引
var current_index := 0

# 场景准备就绪
func _ready() -> void:
	# 连接下一行按钮的按下信号
	next_button.pressed.connect(_on_next_button_pressed)
	# 连接结束按钮的按下信号
	finish_button.pressed.connect(_on_finish_button_pressed)
	# 刷新文本
	refresh_text()

# 刷新文本
func refresh_text() -> void:
	# 设置NPC名称
	npc_name_label.text = "人格残影"
	# 设置对话文本
	dialogue_text_label.text = lines[current_index]

# 下一行按钮按下处理
func _on_next_button_pressed() -> void:
	# 检查是否还有下一行对话
	if current_index < lines.size() - 1:
		# 增加索引
		current_index += 1
		# 刷新文本
		refresh_text()

# 结束按钮按下处理
func _on_finish_button_pressed() -> void:
	# 前进到下一个节点
	GameManager.advance_node()
	# 切换到地图场景
	get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")
