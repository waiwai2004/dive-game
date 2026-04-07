# 地图场景脚本
# 处理地图界面的显示和交互逻辑
extends Control

# UI组件引用
@onready var chapter_label = $MarginContainer/MainVBox/ChapterLabel  # 当前节点标签
@onready var player_summary_label = $MarginContainer/MainVBox/PlayerSummaryLabel  # 玩家状态标签
@onready var node_line = $MarginContainer/MainVBox/CenterContainer/NodeLine  # 节点连线容器
@onready var enter_node_button = $MarginContainer/MainVBox/EnterNodeButton  # 进入节点按钮

# 节点名称映射
var node_name_map := {
	"start": "起点",          # 起点节点
	"dialogue": "人格残影",    # 对话节点
	"reward": "记忆残影",     # 奖励节点
	"battle_normal": "污染点",  # 普通战斗节点
	"event": "认知废墟",      # 事件节点
	"rest": "自我锚点",       # 休息节点
	"battle_boss": "伤口"      # Boss战斗节点
}

# 场景准备就绪
func _ready() -> void:
	# 连接进入节点按钮的按下信号
	enter_node_button.pressed.connect(_on_enter_node_button_pressed)
	# 刷新UI
	refresh_ui()

# 刷新UI
func refresh_ui() -> void:
	# 获取当前节点类型
	var current_type = GameManager.get_current_node_type()
	# 获取当前节点的显示名称
	var current_name_text = node_name_map.get(current_type, "未知节点")

	# 设置当前节点标签文本
	chapter_label.text = "当前节点：%s" % current_name_text

	# 获取玩家状态
	var p = GameManager.player_summary
	# 设置玩家状态标签文本
	player_summary_label.text = "存在值 %d/%d | 理智 %d/%d | 认知上限 %d" % [
		p["hp"], p["max_hp"],  # 生命值
		p["san"], p["max_san"],  # 理智值
		p["cognition_max"]       # 认知上限
	]

	# 构建节点连线
	build_nodes()

# 构建节点连线
func build_nodes() -> void:
	# 清除现有节点
	for child in node_line.get_children():
		child.queue_free()

	# 遍历所有节点
	for i in range(GameManager.map_nodes.size()):
		# 获取节点类型
		var node_type = GameManager.map_nodes[i]
		# 获取节点显示名称
		var display_name = node_name_map.get(node_type, node_type)

		# 创建按钮
		var btn = Button.new()
		btn.text = display_name
		btn.custom_minimum_size = Vector2(120, 60)

		# 根据节点状态设置按钮样式
		if i < GameManager.current_node_index:
			# 已通过的节点
			btn.disabled = true
			btn.modulate = Color(0.6, 0.6, 0.6)  # 灰色
		elif i == GameManager.current_node_index:
			# 当前节点
			btn.disabled = false
			btn.modulate = Color(1.0, 1.0, 1.0)  # 白色
		else:
			# 未到达的节点
			btn.disabled = true
			btn.modulate = Color(0.35, 0.35, 0.35)  # 深灰色

		# 添加按钮到节点连线容器
		node_line.add_child(btn)

		# 添加箭头
		if i < GameManager.map_nodes.size() - 1:
			var arrow = Label.new()
			arrow.text = "→"
			node_line.add_child(arrow)

# 进入节点按钮按下处理
func _on_enter_node_button_pressed() -> void:
	# 获取当前节点类型
	var node_type = GameManager.get_current_node_type()

	# 根据节点类型切换场景
	match node_type:
		"start":
			# 前进到下一个节点
			GameManager.advance_node()
			# 刷新UI
			refresh_ui()
		"dialogue":
			# 切换到对话场景
			get_tree().change_scene_to_file("res://scenes/dialogue/dialogue_scene.tscn")
		"reward":
			# 切换到奖励场景
			get_tree().change_scene_to_file("res://scenes/reward/reward_scene.tscn")
		"battle_normal", "battle_boss":
			# 切换到战斗场景
			get_tree().change_scene_to_file("res://scenes/battle/battle_scene.tscn")
		"event":
			# 切换到事件场景
			get_tree().change_scene_to_file("res://scenes/event/event_scene.tscn")
		"rest":
			# 切换到休息场景
			get_tree().change_scene_to_file("res://scenes/rest/rest_scene.tscn")
		_:
			# 切换到结果场景
			get_tree().change_scene_to_file("res://scenes/result/result_scene.tscn")
