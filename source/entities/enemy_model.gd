class_name EnemyModel
extends CharacterModel
## 敌方数据模型
## 包含敌人意图池等专用数据

var intent_pool: PackedStringArray

func _init(id: StringName) -> void:
	super._init(id)
	intent_pool = []
