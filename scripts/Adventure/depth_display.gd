extends Label

@export var player_path: NodePath
var player: CharacterBody2D
var surface_y: float = 800  # 水面的Y坐标，根据实际场景调整

func _ready() -> void:
	# 获取玩家节点
	if player_path:
		player = get_node_or_null(player_path)
		# 记录初始位置作为水面位置
		if player:
			surface_y = player.global_position.y
	
	# 设置标签样式
	add_theme_color_override("font_color", Color(1, 1, 1))
	add_theme_font_size_override("font_size", 24)
	
	# 开始每帧更新深度
	set_process(true)

func _process(delta: float) -> void:
	if player:
		# 计算深度：玩家Y坐标减去水面Y坐标，取绝对值
		var depth = abs(player.global_position.y - surface_y)
		# 更新标签文本
		text = "深度: %.1f 米" % depth