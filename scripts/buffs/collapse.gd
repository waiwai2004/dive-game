## 崩溃Debuff
## 回合开始时扣除自身X点SAN；每轮结算叠加1层。可被「绝望蚀割」吞噬。
class_name CollapseDebuff
extends BuffBase

func _init():
	super._init("崩溃", BuffType.DEBUFF)
	stack_type = StackType.STACKABLE
	max_stacks = 99


func on_round_end() -> void:
	add_stack(1)


func get_description() -> String:
	return "回合开始时扣除自身%d点SAN；每轮结算叠加1层。" % stacks
