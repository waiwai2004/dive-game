## 混乱Debuff
## 当前先作为可追踪的敌方施加状态存在，回合结束移除1层。
class_name ConfusionDebuff
extends BuffBase

func _init():
	super._init("混乱", BuffType.DEBUFF)
	stack_type = StackType.STACKABLE
	max_stacks = 99


func on_turn_end() -> void:
	if stacks > 0:
		remove_stack(1)


func get_description() -> String:
	return "混乱 %d：由敌方施加的异常状态，当前仅用于回合内追踪与展示。" % stacks
