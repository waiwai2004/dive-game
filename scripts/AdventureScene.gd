extends Node2D

const BG_TEX_SIZE := Vector2(1152.0, 2048.0)
const TARGET_WIDTH := 1920.0

@onready var pause_menu = $CanvasLayer/PauseMenu
@onready var interact_tip: Label = $CanvasLayer/InteractTip
@onready var background: Sprite2D = $World/Background
@onready var camera: Camera2D = $World/Player/Camera2D
@onready var player: AdventurePlayer = $World/Player

func _ready() -> void:
	print("AdventureScene ready")
	clear_interact_tip()
	call_deferred("_restore_from_battle")

	background.centered = false

	var scale_factor := TARGET_WIDTH / BG_TEX_SIZE.x
	background.scale = Vector2.ONE * scale_factor

	var world_size := BG_TEX_SIZE * scale_factor

	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(world_size.x)
	camera.limit_bottom = int(world_size.y)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if pause_menu.visible:
			pause_menu.close_menu()
		else:
			pause_menu.open_menu()

func set_interact_tip(text: String) -> void:
	interact_tip.text = text
	interact_tip.visible = true

func clear_interact_tip() -> void:
	interact_tip.visible = false

func _restore_from_battle() -> void:
	if not BattleFlow.returning_from_battle:
		return

	var spawn_node := get_node_or_null(NodePath(BattleFlow.return_spawn_path))
	if spawn_node == null:
		push_warning("找不到返回点: " + BattleFlow.return_spawn_path)
		BattleFlow.clear()
		return

	if spawn_node is Node2D:
		player.return_from_battle(spawn_node.global_position, BattleFlow.return_mode)

	BattleFlow.clear()
