extends Area2D

const BATTLE_SCENE := "res://scenes/battle/BattleScene.tscn"
const ADVENTURE_SCENE := "res://scenes/adventure/AdventureScene.tscn"

@export var enemy_id := "deep_monster_01"
@export var prompt_text := "【E】遭遇敌人"
@export var return_spawn_path: NodePath = ^"World/Enemy/BattleReturnSpawn"
@export_enum("surface", "underwater") var return_mode := "underwater"

@onready var sprite: Sprite2D = $Sprite2D

var player_inside := false
var base_scale := Vector2.ONE

func _ready() -> void:
	monitoring = true
	monitorable = true

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	if sprite != null:
		base_scale = sprite.scale

func _process(_delta: float) -> void:
	if player_inside and Input.is_action_just_pressed("interact"):
		_enter_battle()

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	player_inside = true
	_show_tip()
	_set_highlight(true)

func _on_body_exited(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	player_inside = false
	_hide_tip()
	_set_highlight(false)

func _enter_battle() -> void:
	player_inside = false
	_hide_tip()

	var spawn_node := get_node_or_null(return_spawn_path)
	if spawn_node == null:
		push_error("Enemy 返回点无效: " + str(return_spawn_path))
		return

	var scene_root := get_tree().current_scene
	var scene_relative_path := str(scene_root.get_path_to(spawn_node))

	print("进入战斗，记录返回点路径: ", scene_relative_path)

	BattleFlow.start_battle(
		enemy_id,
		ADVENTURE_SCENE,
		scene_relative_path,
		return_mode
	)

	get_tree().change_scene_to_file(BATTLE_SCENE)


func _show_tip() -> void:
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("set_interact_tip"):
		scene.set_interact_tip(prompt_text)

func _hide_tip() -> void:
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("clear_interact_tip"):
		scene.clear_interact_tip()

func _set_highlight(active: bool) -> void:
	if sprite == null:
		return

	var tween := create_tween()
	if active:
		tween.tween_property(sprite, "scale", base_scale * 1.05, 0.12)
	else:
		tween.tween_property(sprite, "scale", base_scale, 0.12)
