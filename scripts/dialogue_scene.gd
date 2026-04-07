# 对话场景脚本
# 处理对话界面的显示和交互逻辑
extends Control

# UI组件引用
@onready var npc_name_label = $UILayer/MarginContainer/MainVBox/PanelContainer/VBoxContainer/NpcNameLabel  # NPC名称标签
@onready var dialogue_text_label = $UILayer/MarginContainer/MainVBox/PanelContainer/VBoxContainer/DialogueTextLabel  # 对话文本标签
@onready var next_button = $UILayer/MarginContainer/MainVBox/PanelContainer/VBoxContainer/HBoxContainer/NextButton  # 下一行按钮
@onready var finish_button = $UILayer/MarginContainer/MainVBox/PanelContainer/VBoxContainer/HBoxContainer/FinishButton  # 结束按钮

# 对话文本数组
var lines := []

# 当前对话索引
var current_index := 0

# 场景准备就绪
func _ready() -> void:
	# 连接下一行按钮的按下信号
	next_button.pressed.connect(_on_next_button_pressed)
	# 连接结束按钮的按下信号
	finish_button.pressed.connect(_on_finish_button_pressed)
	# 从数据库加载剧本，假设本次剧情 ID 为 "dialogue_01"
	var dialogue_data = DBManager.get_event("dialogue_01")
	
	if not dialogue_data.is_empty():
		npc_name_label.text = dialogue_data.get("npc_name", "神秘人")
		lines = dialogue_data.get("lines", ["..."])
	else:
		npc_name_label.text = "读取失败"
		lines = ["未找到剧本数据..."]
		
	refresh_text()

# 刷新文本
func refresh_text() -> void:
	if lines.is_empty(): 
		return
		
	dialogue_text_label.text = lines[current_index]
	
	# 如果是最后一句，就隐藏“下一句”按钮，只留“结束对话”
	if current_index >= lines.size() - 1:
		next_button.hide()
	else:
		next_button.show()

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
