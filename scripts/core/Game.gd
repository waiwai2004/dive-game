extends Node

var player_hp: int = 12
var max_hp: int = 12

var player_san: int = 10
var max_san: int = 10
var player_cognition: int = 0
var max_cognition: int = 6
var cognition_current: int:
	get:
		return player_cognition
	set(value):
		player_cognition = maxi(value, 0)
var cognition_max: int:
	get:
		return max_cognition
	set(value):
		max_cognition = maxi(value, 1)

var deck: Array[String] = []

var tag_aggressive: int = 0
var tag_orderly: int = 0

var battle_index: int = 0
var first_battle_reward_done: bool = false
var admin_talk_done: bool = false
var memory_event_done: bool = false
var reward_card_given: bool = false
var in_dialogue: bool = false

func reset_run():
	player_hp = 12
	max_hp = 12
	player_san = 10
	max_san = 10
	player_cognition = 0
	max_cognition = 6

	tag_aggressive = 0
	tag_orderly = 0

	battle_index = 0
	first_battle_reward_done = false
	admin_talk_done = false
	memory_event_done = false
	reward_card_given = false
	in_dialogue = false

	deck = [
		"cut",
		"cut",
		"guard",
		"guard",
		"calm",
		"break"
	]

func add_card(card_id: String):
	deck.append(card_id)

func damage_player(amount: int):
	player_hp = max(player_hp - amount, 0)
	player_san = max(player_san - amount, 0)

func heal_player(amount: int):
	player_hp = min(player_hp + amount, max_hp)

func heal_san(amount: int):
	player_san = min(player_san + amount, max_san)

func is_distorted() -> bool:
	return player_san <= 0


func add_cognition(amount: int) -> void:
	player_cognition = maxi(player_cognition + amount, 0)


func clear_cognition() -> void:
	player_cognition = 0

func goto_title():
	get_tree().change_scene_to_file("res://scenes/main_manu/MainMenu.tscn")

func goto_dive():
	get_tree().change_scene_to_file("res://scenes/dive/DiveScene.tscn")

func goto_explore():
	get_tree().change_scene_to_file("res://scenes/explore/ExploreScene.tscn")

func goto_end():
	get_tree().change_scene_to_file("res://scenes/end/EndScene.tscn")
