## 内驱力状态
## 激活条件：特定卡牌打出
## 失活条件：无（永久持续直到战斗结束）
## 效果：每轮结束后，有20%的概率给予自己一个额外回合，额外回合也提供精神负荷的恢复
class_name InnerDriveStatus
extends GameStatus

var extra_turn_chance: float = 0.2
var trigger_card_ids: Array[String] = []

signal extra_turn_granted()

func _init():
	super._init("内驱力")


func set_trigger_cards(cards: Array[String]) -> void:
	trigger_card_ids = cards


func check_activation_condition() -> bool:
	return false


func check_deactivation_condition() -> bool:
	return false


func activate_by_card(card_id: String) -> void:
	if not is_active and (trigger_card_ids.is_empty() or card_id in trigger_card_ids):
		on_activate()


func on_turn_end() -> void:
	if is_active:
		var roll = randf()
		if roll < extra_turn_chance:
			extra_turn_granted.emit()


func get_status_description() -> String:
	return "内驱力：每轮结束有20%概率获得额外回合"
