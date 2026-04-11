extends Node

var enemy_id: String = ""
var return_scene_path: String = ""
var return_spawn_path: String = ""
var return_mode: String = "underwater"
var returning_from_battle: bool = false

func start_battle(
	p_enemy_id: String,
	p_return_scene_path: String,
	p_return_spawn_path: String,
	p_return_mode: String = "underwater"
) -> void:
	enemy_id = p_enemy_id
	return_scene_path = p_return_scene_path
	return_spawn_path = p_return_spawn_path
	return_mode = p_return_mode
	returning_from_battle = false

func prepare_return() -> void:
	returning_from_battle = true

func clear() -> void:
	enemy_id = ""
	return_scene_path = ""
	return_spawn_path = ""
	return_mode = "underwater"
	returning_from_battle = false
