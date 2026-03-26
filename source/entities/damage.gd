class_name Damage
extends RefCounted
## 伤害包装类
## 用于在战斗系统中传递伤害及其来源或类型数据

var value: float
var source: Node # Character，为避免循环引用这里使用 Node，实际运行会断言为 Character
var damage_type: int

## 构造函数，建立基础伤害实例
func _init(_value: float, _source: Node, _type: int = 0) -> void:
	self.value = _value
	self.source = _source
	self.damage_type = _type
