## 愤怒Buff
## 效果：造成伤害时，伤害值增加当前层数；回合结束移除1层。
class_name AngerBuff
extends BuffBase

func _init():
	super._init("愤怒", BuffType.BUFF)
	stack_type = StackType.STACKABLE
	max_stacks = 99


func modify_damage_dealt(base_damage: int) -> int:
	if base_damage <= 0:
		return 0
	return base_damage + stacks


func on_round_end() -> void:
	if stacks > 0:
		remove_stack(1)


func get_description() -> String:
	return "造成伤害时，伤害值+%d" % stacks
