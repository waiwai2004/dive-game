extends Area2D

@export var detect_radius: float = 520.0
@export var visible_angle_deg: float = 120.0
@export var fade_speed: float = 4.5
@export var hidden_alpha: float = 0.16
@export var visible_alpha: float = 1.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var highlight: CanvasItem = get_node_or_null("Highlight")

var _player: Node2D = null
var _is_visible_to_player: bool = false
var _current_alpha: float = 0.0


func _ready() -> void:
	_find_player()
	_current_alpha = hidden_alpha
	_apply_alpha(_current_alpha)
	set_process(true)


func _process(delta: float) -> void:
	if not _player or not is_instance_valid(_player):
		_find_player()
		if not _player:
			return

	_is_visible_to_player = is_discovered_by_player(_player)
	var target_alpha: float = visible_alpha if _is_visible_to_player else hidden_alpha
	_current_alpha = move_toward(_current_alpha, target_alpha, fade_speed * delta)
	_apply_alpha(_current_alpha)


func is_discovered_by_player(player: Node2D) -> bool:
	if not player:
		return false

	var head_pos: Vector2 = _get_head_position(player)
	var to_target: Vector2 = global_position - head_pos
	var distance: float = to_target.length()

	if distance > detect_radius:
		return false
	if distance <= 0.001:
		return true

	var facing: Vector2 = _get_facing(player)
	if facing.length_squared() <= 0.0001:
		facing = Vector2.RIGHT
	facing = facing.normalized()

	var target_dir: Vector2 = to_target.normalized()
	var half_angle_rad: float = deg_to_rad(visible_angle_deg * 0.5)
	var threshold: float = cos(half_angle_rad)

	return facing.dot(target_dir) >= threshold


func is_currently_visible() -> bool:
	return _is_visible_to_player


func _find_player() -> void:
	var node: Node = get_tree().get_first_node_in_group("player")
	if node is Node2D:
		_player = node as Node2D
	else:
		_player = null


func _get_head_position(player: Node2D) -> Vector2:
	if player.has_method("get_head_world_position"):
		var value: Variant = player.call("get_head_world_position")
		if value is Vector2:
			return value as Vector2
	return player.global_position


func _get_facing(player: Node2D) -> Vector2:
	if player.has_method("get_facing_direction"):
		var value: Variant = player.call("get_facing_direction")
		if value is Vector2:
			return value as Vector2
	return Vector2.RIGHT


func _apply_alpha(alpha_value: float) -> void:
	var clamped_alpha: float = clampf(alpha_value, 0.0, 1.0)
	sprite.modulate.a = clamped_alpha
	if highlight:
		highlight.visible = _is_visible_to_player
		highlight.modulate.a = clampf(clamped_alpha * 0.9, 0.0, 1.0)
