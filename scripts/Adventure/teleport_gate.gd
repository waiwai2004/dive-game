extends Area2D

@export var player_path: NodePath
@export var underwater_spawn_path: NodePath
@export var prompt_text := "【E】进入下潜"
@export var enable_mouse_click := true

@onready var player = get_node_or_null(player_path)
@onready var underwater_spawn = get_node_or_null(underwater_spawn_path)
@onready var gate_sprite: Sprite2D = $Sprite2D

var player_inside := false
var base_scale := Vector2.ONE

func _ready() -> void:
	monitoring = true
	monitorable = true
	input_pickable = true

	if gate_sprite != null:
		base_scale = gate_sprite.scale

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if player_inside and Input.is_action_just_pressed("interact"):
		_enter_gate()

func _on_body_entered(body: Node) -> void:
	if body != player:
		return

	player_inside = true
	_show_tip()
	_set_highlight(true)

func _on_body_exited(body: Node) -> void:
	if body != player:
		return

	player_inside = false
	_hide_tip()
	_set_highlight(false)

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if not enable_mouse_click:
		return

	if not player_inside:
		return

	if event is InputEventMouseButton \
	and event.pressed \
	and event.button_index == MOUSE_BUTTON_LEFT:
		_enter_gate()

func _enter_gate() -> void:
	if player == null or underwater_spawn == null:
		return

	_hide_tip()
	player.enter_underwater(underwater_spawn.global_position)

func _show_tip() -> void:
	var scene = get_tree().current_scene
	if scene != null and scene.has_method("set_interact_tip"):
		scene.set_interact_tip(prompt_text)

func _hide_tip() -> void:
	var scene = get_tree().current_scene
	if scene != null and scene.has_method("clear_interact_tip"):
		scene.clear_interact_tip()

func _set_highlight(active: bool) -> void:
	if gate_sprite == null:
		return

	var tween := create_tween()
	if active:
		tween.tween_property(gate_sprite, "scale", base_scale * 1.08, 0.12)
	else:
		tween.tween_property(gate_sprite, "scale", base_scale, 0.12)
