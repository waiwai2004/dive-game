## 虚弱Debuff
## 标签：Debuff
## 效果：当有此虚脱时，本轮每次造成伤害时，伤害值×2（伤害值最少为1）
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
	var multiplier = 1 + (stacks * 1)
	return maxi(1, base_damage * multiplier)


func on_turn_end() -> void:
	if stacks > 0:
		remove_stack(1)


func get_description() -> String:
	return "造成伤害时，伤害值×%d（最少1）" % (1 + stacks)
