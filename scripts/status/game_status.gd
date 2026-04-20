## 游戏状态基类
## 状态的运行逻辑完全不同于buff，某个单位满足激活条件后，即可进入该状态，直到满足失活条件后，则退出该状态。
class_name GameStatus
extends RefCounted

signal status_activated()
signal status_deactivated()

var status_name: String = ""
var is_active: bool = false

func _init(p_name: String):
	status_name = p_name


func check_activation_condition() -> bool:
	return false


func check_deactivation_condition() -> bool:
	return false


func on_activate() -> void:
	is_active = true
	status_activated.emit()


func on_deactivate() -> void:
	is_active = false
	status_deactivated.emit()


func on_turn_start() -> void:
	pass


func on_turn_end() -> void:
	pass


func modify_card_value(base_value: int, value_type: String) -> int:
	return base_value


func get_status_description() -> String:
	return ""
