# 游戏管理器脚本，负责场景切换和游戏状态管理
extends Node

# 定义场景路径常量
const TITLE_SCENE := "res://scenes/title/TitleScreen.tscn"  # 标题场景路径
const BASE_SCENE := "res://scenes/base/BaseScene.tscn"      # 基地场景路径
const ADVENTURE_SCENE := "res://scenes/adventure/AdventureScene.tscn"  # 冒险场景路径

# 游戏状态变量
var in_adventure: bool = false  # 标记是否在冒险中
var in_dialogue: bool = false   # 标记是否正在对话中

# 战斗相关变量
var player_summary := {
	"hp": 10,
	"max_hp": 10,
	"san": 10,
	"max_san": 10,
	"energy_max": 3,
	"extra_energy": 0,
	"cognition": 0,
	"cognition_max": 10,
	"cognition_overloaded": false
}
var battle_result: String = ""

# 获取当前节点类型
func get_current_node_type() -> String:
	# 这里返回默认值，实际项目中应该根据当前节点类型返回相应的值
	return "battle_normal"

# 跳转到标题场景
func goto_title() -> void:
	in_adventure = false  # 更新游戏状态
	get_tree().paused = false  # 确保游戏树不暂停
	get_tree().change_scene_to_file(TITLE_SCENE)  # 切换到标题场景

# 跳转到基地场景
func goto_base() -> void:
	in_adventure = false  # 更新游戏状态
	get_tree().paused = false  # 确保游戏树不暂停
	get_tree().change_scene_to_file(BASE_SCENE)  # 切换到基地场景

# 开始冒险
func start_adventure() -> void:
	in_adventure = true  # 更新游戏状态
	get_tree().paused = false  # 确保游戏树不暂停
	get_tree().change_scene_to_file(ADVENTURE_SCENE)  # 切换到冒险场景

# 保存并退出游戏
func save_and_exit() -> void:
	# 先做占位，后面再接真正存档逻辑
	goto_title()  # 调用goto_title函数返回标题场景

# 前进到下一个节点
func advance_node() -> void:
	# 这里做占位，实际项目中应该根据当前节点类型前进到下一个节点
	pass
