class_name CharacterModel
extends RefCounted
## 角色数据模型基类
## 存储角色健康与护盾等状态及基础属性，不依赖 Node 层级

var cha_id: StringName
var cha_name: String
var max_health: float
var current_health: float
var shielded: int

## 构造函数，需要传入强类型的角色 ID
func _init(id: StringName) -> void:
	cha_id = id
	shielded = 0
	# 实际应用中可以调用 DatatableManager 获取配置初始化以下属性
	cha_name = ""
	max_health = 0.0
	current_health = 0.0
