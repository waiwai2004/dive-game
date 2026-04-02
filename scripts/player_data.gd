extends RefCounted
class_name PlayerData

var name: String = "Player"
var hp: int = 10
var max_hp: int = 10
var san: int = 10
var max_san: int = 10
var energy: int = 3
var max_energy: int = 3
var cognition: int = 0
var cognition_max: int = 10
var weak: int = 0

func setup_demo() -> void:
	name = "Player"
	hp = 10
	max_hp = 10
	san = 10
	max_san = 10
	energy = 3
	max_energy = 3
	cognition = 0
	cognition_max = 10
	weak = 0

func reset_energy() -> void:
	energy = max_energy

func heal_hp(amount: int) -> void:
	hp += amount
	if hp > max_hp:
		hp = max_hp

func take_damage(amount: int) -> void:
	hp -= amount
	if hp < 0:
		hp = 0

	san -= amount
	if san < 0:
		san = 0

func add_cognition(amount: int) -> bool:
	cognition += amount
	return cognition > cognition_max

func clear_cognition() -> void:
	cognition = 0

func is_dead() -> bool:
	return hp <= 0

func is_mad() -> bool:
	return san <= 0
