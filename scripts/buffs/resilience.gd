## 坚韧Buff
## 标签：Buff
## 效果：每次受到伤害时，伤害值-1（伤害值最少为1）
class_name ResilienceBuff
extends BuffBase

func _init():
	super._init("坚韧", BuffType.BUFF)
	stack_type = StackType.STACKABLE
	max_stacks = 99


func modify_damage_taken(base_damage: int) -> int:
	if base_damage <= 0:
		return 0
	var reduction = stacks
	return maxi(1, base_damage - reduction)


func on_turn_end() -> void:
	if stacks > 0:
		remove_stack(1)


func get_description() -> String:
	return "受到伤害时，伤害值-%d（最少1）" % stacks
