class_name Enemy
extends Character
## 敌方实体类
## 基于 Character，提供意图系统的控制展示挂载点

# @onready var c_intent_system: C_IntentSystem
# @onready var w_tooltip: MarginContainer
#由于组件未建立，先用变量引用
var c_intent_system: Node
var w_tooltip: MarginContainer

func _ready() -> void:
	super._ready()
	# 确保分配对应模型类型
	if not _model:
		_model = EnemyModel.new(StringName("DEFAULT_ENEMY"))

func _begin_turn() -> void:
	super._begin_turn()
	# 唤醒意图计算系统等

func _end_turn() -> void:
	super._end_turn()

## 显示下回合的意图面板提示
func show_tooltip() -> void:
	if w_tooltip:
		w_tooltip.show()
