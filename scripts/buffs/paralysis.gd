## 麻痹Debuff
## 存在时，每打出一张牌后有50%概率强制结束回合；每轮结算移除1层。
class_name ParalysisDebuff
extends BuffBase

func _init():
	super._init("麻痹", BuffType.DEBUFF)
	stack_type = StackType.STACKABLE
	max_stacks = 99


func should_force_end_turn_after_card() -> bool:
	return stacks > 0 and randf() < 0.5


func on_round_end() -> void:
	if stacks > 0:
		remove_stack(1)


func get_description() -> String:
	return "打出牌后有50%%概率强制结束回合；每轮结算移除1层。"
