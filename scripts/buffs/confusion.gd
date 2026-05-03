## 混乱Debuff
## 存在时，打出的牌在效果结算前有33%概率失效；每轮结算移除1层。
class_name ConfusionDebuff
extends BuffBase

func _init():
	super._init("混乱", BuffType.DEBUFF)
	stack_type = StackType.STACKABLE
	max_stacks = 99


func should_cancel_card() -> bool:
	return stacks > 0 and randf() < 0.33


func on_round_end() -> void:
	if stacks > 0:
		remove_stack(1)


func get_description() -> String:
	return "打出的牌有33%%概率失效；每轮结算移除1层。"
