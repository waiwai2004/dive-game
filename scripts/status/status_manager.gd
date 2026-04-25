## 状态管理器
## 管理所有游戏状态的激活/失活检测和生命周期
class_name StatusManager
extends Node

signal status_changed(status_name: String, activated: bool)

var active_statuses: Dictionary = {}

func _ready() -> void:
	pass


func register_status(status: GameStatus) -> void:
	if status == null:
		return
	active_statuses[status.status_name] = status
	status.status_activated.connect(_on_status_activated.bind(status))
	status.status_deactivated.connect(_on_status_deactivated.bind(status))


func unregister_status(status_name: String) -> void:
	if active_statuses.has(status_name):
		var status = active_statuses[status_name]
		status.status_activated.disconnect(_on_status_activated)
		status.status_deactivated.disconnect(_on_status_deactivated)
		active_statuses.erase(status_name)


func check_all_statuses() -> void:
	for status_name in active_statuses:
		var status: GameStatus = active_statuses[status_name]
		if not status.is_active:
			if status.check_activation_condition():
				status.on_activate()
		else:
			if status.check_deactivation_condition():
				status.on_deactivate()


func on_turn_start() -> void:
	check_all_statuses()
	for status_name in active_statuses:
		var status: GameStatus = active_statuses[status_name]
		if status.is_active:
			status.on_turn_start()


func on_turn_end() -> void:
	for status_name in active_statuses:
		var status: GameStatus = active_statuses[status_name]
		if status.is_active:
			status.on_turn_end()
	check_all_statuses()


func is_status_active(status_name: String) -> bool:
	if active_statuses.has(status_name):
		return active_statuses[status_name].is_active
	return false


func get_active_status_names() -> Array[String]:
	var result: Array[String] = []
	for status_name in active_statuses:
		if active_statuses[status_name].is_active:
			result.append(status_name)
	return result


func modify_card_value(base_value: int, value_type: String) -> int:
	var modified_value = base_value
	for status_name in active_statuses:
		var status: GameStatus = active_statuses[status_name]
		if status.is_active:
			modified_value = status.modify_card_value(modified_value, value_type)
	return modified_value


func _on_status_activated(status: GameStatus) -> void:
	status_changed.emit(status.status_name, true)


func _on_status_deactivated(status: GameStatus) -> void:
	status_changed.emit(status.status_name, false)
