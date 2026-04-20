## 癫狂状态
## 激活条件：SAN值≤0
## 失活条件：SAN值>0
## 效果：自己所有手牌的所有数值（包括精神负荷、认知负荷、伤害值、buff层数等等）+1
class_name ManicStatus
extends GameStatus

func _init():
	super._init("癫狂")


func check_activation_condition() -> bool:
	if typeof(Game) == TYPE_OBJECT and Game.has_method("is_distorted"):
		return Game.is_distorted()
	return false


func check_deactivation_condition() -> bool:
	if typeof(Game) == TYPE_OBJECT:
		var san = Game.get("player_san")
		if san != null:
			return int(san) > 0
	return false


func modify_card_value(base_value: int, value_type: String) -> int:
	return base_value + 1


func get_status_description() -> String:
	return "癫狂：所有手牌数值+1"
