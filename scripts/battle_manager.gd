extends RefCounted
class_name BattleManager

const PlayerDataScript = preload("res://scripts/player_data.gd")
const EnemyDataScript = preload("res://scripts/enemy_data.gd")
const CardDataScript = preload("res://scripts/card_data.gd")

signal battle_log_added(text)
signal battle_state_changed
signal battle_ended(is_victory)

var player = null
var enemy = null

var hand_cards: Array = []
var draw_pile: Array = []

var next_instance_id: int = 1
var selected_card_instance_id: int = -1
var battle_finished: bool = false

func setup_demo_battle(is_boss: bool = false) -> void:
	player = PlayerDataScript.new()
	player.setup_demo()

	enemy = EnemyDataScript.new()
	if is_boss:
		enemy.setup_demo_boss()
	else:
		enemy.setup_demo_normal_enemy()

	draw_pile = CardDataScript.get_demo_starting_deck()
	hand_cards.clear()
	selected_card_instance_id = -1
	battle_finished = false

	emit_log("Battle Start")
	start_player_turn()

func start_player_turn() -> void:
	if battle_finished:
		return

	player.reset_energy()
	selected_card_instance_id = -1
	draw_demo_hand()
	update_enemy_intent()
	emit_log("Player Turn Start")
	emit_log("Draw 5 cards")
	battle_state_changed.emit()

func draw_demo_hand() -> void:
	hand_cards.clear()

	for card_id in draw_pile:
		var card = CardDataScript.create_card_instance(card_id, next_instance_id)
		next_instance_id += 1
		hand_cards.append(card)

func get_hand_cards() -> Array:
	return hand_cards

func get_card_by_instance_id(instance_id: int) -> Dictionary:
	for card in hand_cards:
		if card["instance_id"] == instance_id:
			return card
	return {}

func remove_card_from_hand(instance_id: int) -> void:
	for i in range(hand_cards.size()):
		if hand_cards[i]["instance_id"] == instance_id:
			hand_cards.remove_at(i)
			return

func can_play_card(card: Dictionary) -> bool:
	return player.energy >= card.get("cost", 0)

func update_enemy_intent() -> void:
	enemy.intent_text = "Attack x%d" % enemy.max_energy

func emit_log(text: String) -> void:
	battle_log_added.emit(text)

func clear_selected_card() -> void:
	selected_card_instance_id = -1

func on_card_clicked(instance_id: int) -> String:
	if battle_finished:
		return "Battle finished."

	var card = get_card_by_instance_id(instance_id)
	if card.is_empty():
		return "Card not found."

	if not can_play_card(card):
		return "Not enough Energy."

	var card_id = card.get("id", "")

	if card_id == "bless":
		play_bless(card)
		return "Card played."

	if card_id == "relief":
		play_relief(card)
		return "Card played."

	selected_card_instance_id = instance_id
	emit_log("Selected card: %s" % card["name"])
	battle_state_changed.emit()
	return "Selected %s. Click Select Enemy." % card["name"]

func on_enemy_target_clicked() -> String:
	if battle_finished:
		return "Battle finished."

	if selected_card_instance_id == -1:
		return "Select a card first."

	var card = get_card_by_instance_id(selected_card_instance_id)
	if card.is_empty():
		selected_card_instance_id = -1
		return "Card not found."

	if not can_play_card(card):
		selected_card_instance_id = -1
		return "Not enough Energy."

	var card_id = card.get("id", "")

	if card_id == "strike":
		play_strike(card)
	elif card_id == "break":
		play_break(card)
	elif card_id == "resonance":
		play_resonance(card)
	else:
		return "This card cannot target enemy."

	selected_card_instance_id = -1
	check_hand_empty()
	check_battle_end()
	battle_state_changed.emit()
	return "Card played."

func end_player_turn() -> String:
	if battle_finished:
		return "Battle finished."

	clear_selected_card()
	emit_log("Player ends the turn.")
	enemy_turn()

	if battle_finished:
		return "Battle Ended."

	end_round_cleanup()
	start_player_turn()
	return "Enemy Turn..."

func enemy_turn() -> void:
	emit_log("Enemy Turn Start")

	var actions = enemy.max_energy
	while actions > 0:
		damage_player(2)
		emit_log("Enemy uses Strike.")
		actions -= 1

		if player.is_dead():
			check_battle_end()
			return

func end_round_cleanup() -> void:
	if player.weak > 0:
		player.weak -= 1

	if enemy.weak > 0:
		enemy.weak -= 1

	emit_log("Round End. Weak stacks reduced by 1.")
	battle_state_changed.emit()

func apply_cognition(amount: int) -> void:
	var overload = player.add_cognition(amount)
	emit_log("Cognition +%d" % amount)

	if overload:
		player.hp = int(round(player.hp / 2.0))
		if player.hp < 0:
			player.hp = 0
		emit_log("Cognition Overload! HP is halved.")

func check_hand_empty() -> void:
	if hand_cards.is_empty():
		player.clear_cognition()
		emit_log("Hand is empty. Cognition reset to 0.")

func check_battle_end() -> void:
	if battle_finished:
		return

	if enemy.is_dead():
		battle_finished = true
		emit_log("Enemy Defeated!")
		battle_ended.emit(true)
		return

	if player.is_dead():
		battle_finished = true
		emit_log("Player Defeated!")
		battle_ended.emit(false)

func get_modified_damage(base_damage: int, weak_stacks: int) -> int:
	var result = base_damage - weak_stacks * 2
	if result < 1:
		result = 1
	return result

func damage_enemy(base_damage: int) -> void:
	var final_damage = get_modified_damage(base_damage, player.weak)
	enemy.take_damage(final_damage)
	emit_log("Enemy takes %d damage." % final_damage)

func damage_player(base_damage: int) -> void:
	var final_damage = get_modified_damage(base_damage, enemy.weak)
	player.take_damage(final_damage)
	emit_log("Player takes %d damage." % final_damage)

func play_strike(card: Dictionary) -> void:
	player.energy -= card["cost"]
	damage_enemy(2)
	emit_log("Played Strike.")
	apply_cognition(card["cognition"])
	remove_card_from_hand(card["instance_id"])

func play_bless(card: Dictionary) -> void:
	player.energy -= card["cost"]
	player.heal_hp(5)
	emit_log("Played Bless. Restore 5 HP.")
	apply_cognition(card["cognition"])
	remove_card_from_hand(card["instance_id"])
	check_hand_empty()
	check_battle_end()
	battle_state_changed.emit()

func play_break(card: Dictionary) -> void:
	player.energy -= card["cost"]
	enemy.weak += 1
	emit_log("Played Debuff. Enemy gains Weak x1.")
	apply_cognition(card["cognition"])
	remove_card_from_hand(card["instance_id"])

func play_relief(card: Dictionary) -> void:
	player.energy -= card["cost"]
	player.energy += 1
	emit_log("Played Relief. Gain 1 Energy.")
	apply_cognition(card["cognition"])
	remove_card_from_hand(card["instance_id"])
	check_hand_empty()
	check_battle_end()
	battle_state_changed.emit()

func play_resonance(card: Dictionary) -> void:
	player.energy -= card["cost"]
	var damage = player.cognition
	damage_enemy(damage)
	emit_log("Played Cognitive Resonance.")
	apply_cognition(card["cognition"])
	remove_card_from_hand(card["instance_id"])
