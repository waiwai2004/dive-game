extends RefCounted
class_name EnemyData

var name: String = "Enemy"
var hp: int = 15
var max_hp: int = 15
var san: int = 15
var max_san: int = 15
var energy: int = 2
var max_energy: int = 2
var weak: int = 0
var intent_text: String = "Attack x2"

func setup_demo_normal_enemy() -> void:
	name = "Polluted One"
	hp = 15
	max_hp = 15
	san = 15
	max_san = 15
	energy = 2
	max_energy = 2
	weak = 0
	intent_text = "Attack x2"

func setup_demo_boss() -> void:
	name = "Wound"
	hp = 30
	max_hp = 30
	san = 30
	max_san = 30
	energy = 5
	max_energy = 5
	weak = 0
	intent_text = "Attack x5"

func take_damage(amount: int) -> void:
	hp -= amount
	if hp < 0:
		hp = 0

	san -= amount
	if san < 0:
		san = 0

func is_dead() -> bool:
	return hp <= 0
