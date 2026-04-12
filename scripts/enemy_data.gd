# 敌人数据类
# 管理敌人的属性和状态
extends RefCounted


# 敌人名称
var name: String = "Enemy"
# 当前生命值
var hp: int = 15
# 最大生命值
var max_hp: int = 15
# 当前理智值
var san: int = 15
# 最大理智值
var max_san: int = 15
# 当前能量值
var energy: int = 2
# 最大能量值
var max_energy: int = 2
# 虚弱层数
var weak: int = 0
# 敌人意图文本
var intent_text: String = "Attack x2"

# 初始化普通敌人数据
func setup_demo_normal_enemy() -> void:
	# 设置敌人名称
	name = "Polluted One"
	# 设置生命值
	hp = 15
	max_hp = 15
	# 设置理智值
	san = 15
	max_san = 15
	# 设置能量值
	energy = 2
	max_energy = 2
	# 设置虚弱层数
	weak = 0
	# 设置意图文本
	intent_text = "Attack x2"

# 初始化Boss敌人数据
func setup_demo_boss() -> void:
	# 设置敌人名称
	name = "Wound"
	# 设置生命值
	hp = 30
	max_hp = 30
	# 设置理智值
	san = 30
	max_san = 30
	# 设置能量值
	energy = 5
	max_energy = 5
	# 设置虚弱层数
	weak = 0
	# 设置意图文本
	intent_text = "Attack x5"

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

# 检查敌人是否死亡
func is_dead() -> bool:
	# 当生命值小于等于0时，敌人死亡
	return hp <= 0
