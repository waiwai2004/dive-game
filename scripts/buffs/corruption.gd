## 腐化Debuff
## 效果：回合结束时直接失去1点存在值与2点SAN；每轮结算移除1层。
class_name CorruptionDebuff
extends BuffBase

func _init():
	super._init("腐化", BuffType.DEBUFF)
	stack_type = StackType.STACKABLE
	max_stacks = 99


func on_turn_end() -> void:
	if stacks > 0 and typeof(Game) == TYPE_OBJECT and Game.has_method("damage_player"):
		Game.damage_player(1, 2)


func on_round_end() -> void:
	if stacks > 0:
		remove_stack(1)


func get_description() -> String:
	return "回合结束时直接失去1点存在值与2点SAN；每轮结算移除1层。"
