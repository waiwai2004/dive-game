extends Label

@export var player_path: NodePath
var player: CharacterBody2D
var surface_y: float = 851  # 水面的Y坐标，根据实际场景调整

func _ready() -> void:
	# 获取玩家节点
	if player_path:
		player = get_node_or_null(player_path)
	
	# 设置标签样式
	add_theme_color_override("font_color", Color(1, 1, 1))
	add_theme_font_size_override("font_size", 24)
	
	# 开始每帧更新深度
	set_process(true)

func _process(delta: float) -> void:
	if player:
		# 计算深度：玩家Y坐标减去水面Y坐标
		var depth = player.global_position.y - surface_y
		# 如果深度为负（玩家在水面上方），显示0米
		if depth < 0:
			depth = 0
		# 添加缩放因子，将游戏单位转换为更合理的深度值
		var depth_scaled = depth * 0.01
		# 更新标签文本
		text = "深度: %.1f 米" % depth_scaled