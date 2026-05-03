## 疯狂为乐状态
## 激活条件：特定卡牌打出
## 失活条件：无（永久持续直到战斗结束）
## 效果：回合开始时，若处于癫狂，额外恢复5点精神负荷并增加3点认知负荷。
class_name MadnessForFunStatus
extends GameStatus

var status_manager: StatusManager = null
var card_system: BattleCardSystem = null

func _init():
	super._init("疯狂为乐")


func setup(p_status_manager: StatusManager, p_card_system: BattleCardSystem) -> void:
	status_manager = p_status_manager
	card_system = p_card_system


func check_activation_condition() -> bool:
	return false


func check_deactivation_condition() -> bool:
	return false


func on_turn_start() -> void:
	if status_manager == null or card_system == null:
		return
	if not status_manager.is_status_active("癫狂"):
		return
	card_system.energy = mini(card_system.energy + 5, BattleCardSystem.ENERGY_MAX)
	Game.add_cognition(3)


func get_status_description() -> String:
	return "疯狂为乐：癫狂时回合开始额外恢复5点精神负荷，并增加3点认知负荷。"
