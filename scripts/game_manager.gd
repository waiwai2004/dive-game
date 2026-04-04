# 游戏管理器
# 负责控制游戏流程，跟踪当前节点位置，管理玩家状态
extends Node

# 当前节点索引
var current_node_index: int = 0

# 游戏节点列表，定义游戏流程顺序
var map_nodes: Array[String] = [
	"start",      # 游戏开始
	"dialogue",   # 对话场景
	"reward",     # 奖励场景
	"battle_normal", # 普通战斗
	"event",      # 事件场景
	"rest",       # 休息场景
	"battle_boss"  # Boss战斗
]

# 玩家状态摘要
var player_summary := {
	"hp": 10,           # 当前生命值
	"max_hp": 10,       # 最大生命值
	"san": 10,           # 当前理智值
	"max_san": 10,       # 最大理智值
	"cognition_max": 10, # 最大认知负荷
	"energy_max": 3,     # 最大能量
	"extra_energy": 0    # 每回合额外能量
}

# 战斗结果
var battle_result: String = ""
# 是否拥有共鸣卡牌
var has_resonance_card: bool = false

# 重置游戏进度
func reset_demo_progress() -> void:
	# 重置节点索引到开始位置
	current_node_index = 0
	# 重置玩家状态
	player_summary = {
		"hp": 10,
		"max_hp": 10,
		"san": 10,
		"max_san": 10,
		"cognition_max": 10,
		"energy_max": 3,
		"extra_energy": 0
	}
	# 重置战斗结果
	battle_result = ""
	# 重置共鸣卡牌状态
	has_resonance_card = false

# 获取当前节点类型
func get_current_node_type() -> String:
	# 检查索引是否在有效范围内
	if current_node_index >= 0 and current_node_index < map_nodes.size():
		# 返回当前节点类型
		return map_nodes[current_node_index]
	# 超出范围返回结束
	return "end"

# 前进到下一个节点
func advance_node() -> void:
	# 节点索引加1
	current_node_index += 1

# 检查游戏是否结束
func is_demo_finished() -> bool:
	# 当节点索引超出节点列表大小时，游戏结束
	return current_node_index >= map_nodes.size()
