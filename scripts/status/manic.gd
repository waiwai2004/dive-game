## 癫狂状态
## 激活条件：SAN值≤0
## 失活条件：SAN值>0
## 效果：自己所有手牌的所有数值（包括精神负荷、认知负荷、伤害值等）+1。
## Buff / Debuff 层数只读取当前战斗中实际存在的对应 Buff，不读取数据库定义。
class_name ManicStatus
extends GameStatus

const BUFF_STACK_VALUE_TYPES := {
	"apply_weak": {"name": "虚弱", "target": "enemy"},
	"apply_confusion": {"name": "混乱", "target": "enemy"},
	"apply_paralysis": {"name": "麻痹", "target": "enemy"},
	"apply_anger": {"name": "愤怒", "target": "player"},
	"apply_resilience": {"name": "坚韧", "target": "player"},
	"apply_survival": {"name": "残存", "target": "player"},
	"apply_corruption": {"name": "腐化", "target": "enemy"},
	"apply_collapse": {"name": "崩溃", "target": "enemy"},
}

var _player_buff_manager: BuffManager
var _enemy_buff_manager: BuffManager

func _init():
	super._init("癫狂")


func setup(player_buff_manager: BuffManager, enemy_buff_manager: BuffManager) -> void:
	_player_buff_manager = player_buff_manager
	_enemy_buff_manager = enemy_buff_manager


func check_activation_condition() -> bool:
	if typeof(Game) == TYPE_OBJECT and Game.has_method("is_distorted"):
		return Game.is_distorted()
	return false


func check_deactivation_condition() -> bool:
	if typeof(Game) == TYPE_OBJECT:
		var san = Game.get("player_san")
		if san != null:
			return int(san) > 0
	return false


func modify_card_value(base_value: int, value_type: String) -> int:
	if BUFF_STACK_VALUE_TYPES.has(value_type):
		return _modify_buff_stack_value(base_value, value_type)
	return base_value + 1


func _modify_buff_stack_value(base_value: int, value_type: String) -> int:
	var config: Dictionary = BUFF_STACK_VALUE_TYPES[value_type]
	var buff_name := str(config.get("name", ""))
	var target := str(config.get("target", ""))
	var buff_manager: BuffManager = _enemy_buff_manager if target == "enemy" else _player_buff_manager
	if buff_manager == null or not buff_manager.has_buff(buff_name):
		return base_value
	return base_value + 1


func get_status_description() -> String:
	return "癫狂：所有手牌数值+1；Buff层数只按当前战斗已存在的对应Buff加成。"
