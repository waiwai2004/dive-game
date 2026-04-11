# 玩家数据类
# 管理玩家的属性和状态
extends RefCounted
class_name PlayerData

# 玩家名称
var name: String = "Player"
# 当前生命值
var hp: int = 10
# 最大生命值
var max_hp: int = 10
# 当前理智值
var san: int = 10
# 最大理智值
var max_san: int = 10
# 当前能量值
var energy: int = 3
# 最大能量值
var max_energy: int = 3
# 额外能量（每回合额外获得）
var extra_energy: int = 0
# 当前认知负荷
var cognition: int = 0
# 最大认知负荷
var cognition_max: int = 10
# 虚弱层数
var weak: int = 0
# 是否已经发生过认知过载
var cognition_overloaded: bool = false

# 初始化演示数据
func setup_demo() -> void:
	# 设置玩家名称
	name = "Player"
	# 设置初始生命值
	hp = 10
	max_hp = 10
	# 设置初始理智值
	san = 10
	max_san = 10
	# 设置初始能量值
	energy = 3
	max_energy = 3
	# 设置初始额外能量
	extra_energy = 0
	# 设置初始认知负荷
	cognition = 0
	cognition_max = 10
	# 设置初始虚弱层数
	weak = 0
	# 重置认知过载标志
	cognition_overloaded = false

# 重置能量值
func reset_energy() -> void:
	# 将能量恢复到最大值加上额外能量
	energy = max_energy + extra_energy

# 恢复生命值
func heal_hp(amount: int) -> void:
	# 增加生命值
	hp += amount
	# 确保生命值不超过最大值
	if hp > max_hp:
		hp = max_hp

# 受到伤害
func take_damage(amount: int) -> void:
	# 减少生命值
	hp -= amount
	# 确保生命值不小于0
	if hp < 0:
		hp = 0

	# 减少理智值
	san -= amount
	# 确保理智值不小于0
	if san < 0:
		san = 0

# 增加认知负荷
func add_cognition(amount: int) -> bool:
	# 如果已经发生过认知过载，不再增加认知负荷
	if cognition_overloaded:
		return false
	
	# 增加认知负荷
	cognition += amount
	
	# 检查是否超过认知负荷上限
	if cognition > cognition_max:
		# 标记已经发生过认知过载
		cognition_overloaded = true
		return true
	
	return false

# 清除认知负荷
func clear_cognition() -> void:
	# 将认知负荷重置为0
	cognition = 0
	# 重置认知过载标志
	cognition_overloaded = false

# 检查玩家是否死亡
func is_dead() -> bool:
	# 当生命值小于等于0时，玩家死亡
	return hp <= 0

# 检查玩家是否发疯
func is_mad() -> bool:
	# 当理智值小于等于0时，玩家发疯
	return san <= 0
