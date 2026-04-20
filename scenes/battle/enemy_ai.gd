## 敌人 AI
## 职责：
##  - 持有敌人自身数据（名字、HP、虚弱、攻击循环、意图预览）
##  - 接受来自卡牌系统的伤害/虚弱
##  - 按意图执行回合动作，返回结构化结果（不直接操作玩家状态）
## 对外通过 log_emitted 信号发出战斗日志，由 battle_scene 汇总。
class_name BattleEnemyAI
extends Node

signal log_emitted(text: String)
signal hp_changed(hp: int, max_hp: int)

var enemy_name: String = "浅海异常体"
var hp: int = 10
var max_hp: int = 10
var weak: int = 0

var cycle_index: int = 0
var cycle: Array[Dictionary] = []
var hand_preview: Array[String] = []


func setup(is_normal_battle: bool) -> void:
	if is_normal_battle:
		enemy_name = "浅海异常体"
		max_hp = 12
		cycle = [
			{"type": "attack", "value": 2, "text": "撕咬：造成2点伤害"},
			{"type": "attack", "value": 3, "text": "扑袭：造成3点伤害"},
			{"type": "apply_weak", "value": 1, "text": "污染：施加1层虚弱"},
		]
		hand_preview = ["撕咬", "扑袭", "污染"]
	else:
		enemy_name = "深层凝视体"
		max_hp = 18
		cycle = [
			{"type": "attack", "value": 4, "text": "凝视：造成4点伤害"},
			{"type": "apply_weak", "value": 2, "text": "侵蚀：施加2层虚弱"},
			{"type": "attack", "value": 5, "text": "重压：造成5点伤害"},
		]
		hand_preview = ["凝视", "侵蚀", "重压"]
	hp = max_hp
	cycle_index = 0
	weak = 0
	hp_changed.emit(hp, max_hp)


func get_current_intent() -> Dictionary:
	if cycle.is_empty():
		return {"type": "attack", "value": 2, "text": "攻击：造成2点伤害"}
	return cycle[cycle_index % cycle.size()]


## 用于 UI 展示：在"攻击"意图上附加虚弱结算后的实际值
func get_current_intent_display() -> String:
	var intent := get_current_intent()
	var text := str(intent.get("text", "攻击"))
	if String(intent.get("type", "attack")) == "attack":
		var final := BattleCardSystem.apply_weak_to_damage(int(intent.get("value", 0)), weak)
		text += "（实际 %d）" % final
	return text


func take_damage(damage: int) -> void:
	if damage <= 0:
		return
	hp = maxi(0, hp - damage)
	hp_changed.emit(hp, max_hp)


func apply_weak(stacks: int) -> void:
	if stacks > 0:
		weak += stacks


func is_dead() -> bool:
	return hp <= 0


## 执行当前意图。返回：
##   { "block_consumed": int, "damage_to_player": int, "raw_attack_value": int, "weak_applied_to_player": int }
func execute_turn(player_block: int) -> Dictionary:
	var intent := get_current_intent()
	var result := {
		"block_consumed": 0,
		"damage_to_player": 0,
		"raw_attack_value": 0,
		"weak_applied_to_player": 0,
	}

	match String(intent.get("type", "attack")):
		"attack":
			var attack_value := BattleCardSystem.apply_weak_to_damage(int(intent.get("value", 0)), weak)
			var damage_to_hp := maxi(0, attack_value - player_block)
			result.block_consumed = mini(attack_value, player_block)
			result.damage_to_player = damage_to_hp
			result.raw_attack_value = attack_value
			log_emitted.emit("敌人发动【%s】，造成%d点伤害。" % [str(intent.get("text", "攻击")), damage_to_hp])
		"apply_weak":
			var weak_value := int(intent.get("value", 0))
			result.weak_applied_to_player = weak_value
			log_emitted.emit("敌人发动【%s】，你获得%d层虚弱。" % [str(intent.get("text", "侵蚀")), weak_value])

	return result


## 回合末结算：敌人虚弱 -1、意图推进一位
func end_turn_tick() -> void:
	if weak > 0:
		weak = maxi(weak - 1, 0)
	if not cycle.is_empty():
		cycle_index = (cycle_index + 1) % cycle.size()
