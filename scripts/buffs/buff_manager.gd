## Buff管理器
## 管理所有Buff/Debuff的添加、移除、层数管理和生命周期
class_name BuffManager
extends Node

signal buff_added(buff_name: String, stacks: int)
signal buff_removed(buff_name: String)
signal buff_stack_changed(buff_name: String, new_stacks: int)

var active_buffs: Dictionary = {}

func _ready() -> void:
	pass


func add_buff(buff: BuffBase) -> void:
	if buff == null:
		return
	var buff_key = _get_buff_key(buff.buff_name, buff.buff_type)
	if active_buffs.has(buff_key):
		var existing: BuffBase = active_buffs[buff_key]
		if existing.stack_type == BuffBase.StackType.STACKABLE:
			existing.add_stack(buff.stacks if buff.stacks > 0 else 1)
		else:
			existing.set_stacks(maxi(existing.stacks, buff.stacks))
	else:
		active_buffs[buff_key] = buff
		buff.buff_expired.connect(_on_buff_expired.bind(buff))
		buff.stack_changed.connect(_on_stack_changed.bind(buff))
		buff_added.emit(buff.buff_name, buff.stacks)


func remove_buff(buff_name: String, buff_type: int = -1) -> void:
	var key_to_remove: String
	if buff_type >= 0:
		key_to_remove = _get_buff_key(buff_name, buff_type)
	else:
		for key in active_buffs:
			if key.begins_with(buff_name + "_"):
				key_to_remove = key
				break
	
	if key_to_remove and active_buffs.has(key_to_remove):
		var buff: BuffBase = active_buffs[key_to_remove]
		buff.clear()
		active_buffs.erase(key_to_remove)
		buff_removed.emit(buff_name)


func get_buff(buff_name: String, buff_type: int = -1) -> BuffBase:
	var key: String
	if buff_type >= 0:
		key = _get_buff_key(buff_name, buff_type)
	else:
		for k in active_buffs:
			if k.begins_with(buff_name + "_"):
				key = k
				break
	return active_buffs.get(key)


func has_buff(buff_name: String) -> bool:
	for key in active_buffs:
		if key.begins_with(buff_name + "_"):
			return true
	return false


func get_buff_stacks(buff_name: String) -> int:
	var buff = get_buff(buff_name)
	if buff:
		return buff.stacks
	return 0


func on_turn_start() -> void:
	for key in active_buffs:
		var buff: BuffBase = active_buffs[key]
		if buff.is_active():
			buff.on_turn_start()


func on_turn_end() -> void:
	var expired_buffs: Array[String] = []
	for key in active_buffs:
		var buff: BuffBase = active_buffs[key]
		if buff.is_active():
			buff.on_turn_end()
	
	var to_erase: Array[String] = []
	for key in active_buffs:
		var buff: BuffBase = active_buffs[key]
		if not buff.is_active():
			to_erase.append(key)
	
	for key in to_erase:
		var buff: BuffBase = active_buffs[key]
		active_buffs.erase(key)
		buff_removed.emit(buff.buff_name)


func modify_damage_dealt(base_damage: int) -> int:
	var modified = base_damage
	var sorted_buffs: Array = []
	for key in active_buffs:
		sorted_buffs.append(active_buffs[key])
	sorted_buffs.sort_custom(func(a, b): return a.priority > b.priority)
	
	for buff in sorted_buffs:
		if buff.is_active():
			modified = buff.modify_damage_dealt(modified)
	return modified


func modify_damage_taken(base_damage: int) -> int:
	var modified = base_damage
	var sorted_buffs: Array = []
	for key in active_buffs:
		sorted_buffs.append(active_buffs[key])
	sorted_buffs.sort_custom(func(a, b): return a.priority > b.priority)
	
	for buff in sorted_buffs:
		if buff.is_active():
			modified = buff.modify_damage_taken(modified)
	return modified


func modify_presence(base_presence: int) -> int:
	var modified = base_presence
	var sorted_buffs: Array = []
	for key in active_buffs:
		sorted_buffs.append(active_buffs[key])
	sorted_buffs.sort_custom(func(a, b): return a.priority > b.priority)
	
	for buff in sorted_buffs:
		if buff.is_active():
			modified = buff.modify_presence(modified)
	return modified


func clear_all_buffs() -> void:
	for key in active_buffs:
		var buff: BuffBase = active_buffs[key]
		buff.clear()
		buff_removed.emit(buff.buff_name)
	active_buffs.clear()


func clear_buffs_by_type(buff_type: int) -> void:
	var to_erase: Array[String] = []
	for key in active_buffs:
		var buff: BuffBase = active_buffs[key]
		if buff.buff_type == buff_type:
			buff.clear()
			to_erase.append(key)
			buff_removed.emit(buff.buff_name)
	
	for key in to_erase:
		active_buffs.erase(key)


func get_all_active_buffs_info() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for key in active_buffs:
		var buff: BuffBase = active_buffs[key]
		if buff.is_active():
			result.append({
				"name": buff.buff_name,
				"type": buff.buff_type,
				"stacks": buff.stacks,
				"description": buff.get_description()
			})
	return result


func _get_buff_key(name: String, type: int) -> String:
	return "%s_%d" % [name, type]


func _on_buff_expired(buff: BuffBase) -> void:
	var key = _get_buff_key(buff.buff_name, buff.buff_type)
	if active_buffs.has(key):
		active_buffs.erase(key)
	buff_removed.emit(buff.buff_name)


func _on_stack_changed(new_stacks: int, buff: BuffBase) -> void:
	buff_stack_changed.emit(buff.buff_name, new_stacks)
