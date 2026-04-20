## Buff/Debuff基类
## Buff为临时效果，不同于状态系统
class_name BuffBase
extends RefCounted

enum BuffType { BUFF, DEBUFF }
enum StackType { STACKABLE, UNIQUE }

signal stack_changed(new_stacks: int)
signal buff_expired()

var buff_name: String = ""
var buff_type: int = BuffType.BUFF
var stack_type: int = StackType.STACKABLE
var stacks: int = 0
var max_stacks: int = -1
var is_permanent: bool = false
var priority: int = 0

func _init(p_name: String, p_type: int = BuffType.BUFF):
	buff_name = p_name
	buff_type = p_type


func add_stack(amount: int = 1) -> bool:
	if max_stacks > 0 and stacks >= max_stacks:
		return false
	stacks += amount
	if max_stacks > 0:
		stacks = mini(stacks, max_stacks)
	stack_changed.emit(stacks)
	return true


func remove_stack(amount: int = 1) -> void:
	stacks = maxi(stacks - amount, 0)
	stack_changed.emit(stacks)
	if stacks <= 0 and not is_permanent:
		buff_expired.emit()


func set_stacks(value: int) -> void:
	if max_stacks > 0:
		value = mini(value, max_stacks)
	stacks = maxi(value, 0)
	stack_changed.emit(stacks)


func clear() -> void:
	stacks = 0
	stack_changed.emit(0)
	buff_expired.emit()


func is_active() -> bool:
	return stacks > 0


func on_turn_start() -> void:
	pass


func on_turn_end() -> void:
	pass


func modify_damage_dealt(base_damage: int) -> int:
	return base_damage


func modify_damage_taken(base_damage: int) -> int:
	return base_damage


func modify_presence(base_presence: int) -> int:
	return base_presence


func get_description() -> String:
	return ""


func get_tooltip() -> String:
	var type_str = "Buff" if buff_type == BuffType.BUFF else "Debuff"
	return "[%s] %s x%d" % [type_str, buff_name, stacks]
