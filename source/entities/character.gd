class_name Character
extends Node2D
## 角色实体基类
## 处理角色所有逻辑生命周期，更新数据交由只发射 Signal 与表现解耦。

@export var cha_type: String = ""

var cha_id: StringName
var _model: CharacterModel
var _is_selected: bool = false

# 信号 - 使用过去分词
signal turn_begined
signal turn_completed
signal damaged
signal shielded_changed
signal died

# 只读属性
var current_health: float:
	get: return _model.current_health if _model else 0.0

var max_health: float:
	get: return _model.max_health if _model else 1.0

var shielded: int:
	get: return _model.shielded if _model else 0

var is_death: bool:
	get: return _model.current_health <= 0.0 if _model else true

func _ready() -> void:
	pass

## 开始整局战斗初始化
func _begin_combat() -> void:
	pass

## 结束整局战斗收尾
func _end_combat() -> void:
	pass

## 回合开始时调用，处理周期性特效、重置状态等
func _begin_turn() -> void:
	# 复杂的护盾和buff清算
	turn_begined.emit()

## 回合结束时调用
func _end_turn() -> void:
	turn_completed.emit()

## 添加护盾
func add_shielded(value: int) -> void:
	if not _model:
		return
	_model.shielded += value
	shielded_changed.emit()

## 核心受伤结算
func damage(dmg: Damage) -> void:
	if not _model or is_death:
		return
		
	var final_damage = int(dmg.value)
	
	# 优先扣除护盾
	if _model.shielded > 0:
		if final_damage >= _model.shielded:
			final_damage -= _model.shielded
			_model.shielded = 0
		else:
			_model.shielded -= final_damage
			final_damage = 0
		shielded_changed.emit()
			
	# 如果还有剩余伤害扣除血量
	if final_damage > 0:
		_model.current_health -= final_damage
		damaged.emit()
		
		# 状态机：如果血量归零，触发死亡逻辑
		if _model.current_health <= 0:
			_model.current_health = 0
			death()

## 处理角色死亡
func death() -> void:
	died.emit()
	queue_free()

## 动画系统挂载（通用动作播放）
func play_animation_with_reset(anim: StringName) -> void:
	pass # 需要搭配具体的 AnimationPlayer 使用，骨架预留

## 角色被光标/技能选中
func selected() -> void:
	_is_selected = true

## 角色取消选中
func unselected() -> void:
	_is_selected = false
