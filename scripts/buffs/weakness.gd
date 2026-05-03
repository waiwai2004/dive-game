## 虚弱Debuff
## 标签：Debuff
## 效果：当有X层虚弱时，本轮每次造成伤害时，伤害值-2X（伤害值最少为1）
## 每轮结束阶段移除1层虚弱
class_name WeaknessDebuff
extends BuffBase

func _init():
	super._init("虚弱", BuffType.DEBUFF)
	stack_type = StackType.STACKABLE
	max_stacks = 99


func modify_damage_dealt(base_damage: int) -> int:
	if base_damage <= 0:
		return 0
	return maxi(1, base_damage - stacks * 2)


func on_round_end() -> void:
	if stacks > 0:
		remove_stack(1)


func get_description() -> String:
	return "造成伤害时，伤害值-%d（最少1）" % (stacks * 2)
