extends Node

var current_node_index: int = 0

var map_nodes: Array[String] = [
	"start",
	"dialogue",
	"reward",
	"battle_normal",
	"event",
	"rest",
	"battle_boss"
]

var player_summary := {
	"hp": 10,
	"max_hp": 10,
	"san": 10,
	"max_san": 10,
	"cognition_max": 10
}

var battle_result: String = ""
var has_resonance_card: bool = false

func reset_demo_progress() -> void:
	current_node_index = 0
	player_summary = {
		"hp": 10,
		"max_hp": 10,
		"san": 10,
		"max_san": 10,
		"cognition_max": 10
	}
	battle_result = ""
	has_resonance_card = false

func get_current_node_type() -> String:
	if current_node_index >= 0 and current_node_index < map_nodes.size():
		return map_nodes[current_node_index]
	return "end"

func advance_node() -> void:
	current_node_index += 1

func is_demo_finished() -> bool:
	return current_node_index >= map_nodes.size()
