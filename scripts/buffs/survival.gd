## 残存Buff
## 标签：Buff
## 效果：buff存在时，自己的存在感值为1（优先级最高）
## 每轮结束阶段，移除1层残存
class_name SurvivalBuff
extends BuffBase

func _init():
	super._init("残存", BuffType.BUFF)
	stack_type = StackType.STACKABLE
	max_stacks = 99
	priority = 100


func modify_presence(base_presence: int) -> int:
	if stacks > 0:
		return 1
	return base_presence


func on_turn_end() -> void:
	if stacks > 0:
		remove_stack(1)


func get_description() -> String:
	return "存在感强制为1（优先级最高）"
