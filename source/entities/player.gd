class_name Player
extends Character
## 玩家实体类
## 在 Character 的基础上封装玩家独有的能量及费用机制

# @onready var c_card_system: C_CardSystem
# 这里由于 C_CardSystem 还没写，暂时不实际 @onready 调用，用 var 占位代替
var c_card_system: Node

# 信号 - 使用过去分词
signal energy_changed

var current_energy: int:
	get:
		if _model is PlayerModel:
			return (_model as PlayerModel).current_energy
		return 0

var max_energy: int:
	get:
		if _model is PlayerModel:
			return (_model as PlayerModel).max_energy
		return 0

var coin: int:
	get:
		if _model is PlayerModel:
			return (_model as PlayerModel).coin
		return 0

func _ready() -> void:
	super._ready()
	# 确保分配正确的模型
	if not _model:
		_model = PlayerModel.new(StringName("DEFAULT_PLAYER"))

func _begin_combat() -> void:
	super._begin_combat()

func _begin_turn() -> void:
	super._begin_turn()
	reset_energy()

func _end_turn() -> void:
	super._end_turn()

## 使用能量
func use_energy(amount: int) -> void:
	if not _model is PlayerModel: return
	var p_model = _model as PlayerModel
	
	if p_model.current_energy >= amount:
		p_model.current_energy -= amount
		energy_changed.emit()
	else:
		push_warning("Player: Not enough energy!")

## 重置能量回合初始状态
func reset_energy() -> void:
	if not _model is PlayerModel: return
	var p_model = _model as PlayerModel
	
	p_model.current_energy = p_model.max_energy
	energy_changed.emit()
