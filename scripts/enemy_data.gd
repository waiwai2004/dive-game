# 敌人数据类
# 管理敌人的属性和状态
extends RefCounted
class_name EnemyData

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
func setup_from_db(enemy_id: String) -> void:
	var data = DBManager.get_enemy(enemy_id)
	if data.is_empty():
		print("报错：数据库中找不到敌人ID：", enemy_id)
		return # 提前结束，防止崩溃
		
	name = data.get("name", "未知敌人") # 使用 .get() 更安全
	max_hp = int(data.get("max_hp", 10))
	hp = max_hp
	max_san = int(data.get("max_san", 10))
	san = max_san
	max_energy = int(data.get("max_energy", 2))
	energy = max_energy
	intent_text = data.get("intent_text", "...")
	weak = 0

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
