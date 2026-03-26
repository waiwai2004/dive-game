class_name PlayerModel
extends CharacterModel
## 玩家数据模型
## 继承自普通角色数据模型，增加能量和货币

var max_energy: int
var current_energy: int
var coin: int

func _init(id: StringName) -> void:
	super._init(id)
	max_energy = 3
	current_energy = 3
	coin = 0
