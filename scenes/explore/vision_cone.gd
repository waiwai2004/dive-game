extends Polygon2D

@export var cone_radius: float = 360.0
@export var cone_angle_deg: float = 120.0
@export var segment_count: int = 24
@export var cone_color: Color = Color(0.85, 0.93, 1.0, 0.20)
@export var player_path: NodePath
@export var camera_path: NodePath

var _player: Node2D = null
var _camera: Camera2D = null


func _ready() -> void:
	_resolve_refs()
	color = cone_color
	set_process(true)


func _process(_delta: float) -> void:
	if not _player or not is_instance_valid(_player):
		_resolve_refs()
	if not _player:
		return
	if not _camera or not is_instance_valid(_camera):
		_resolve_refs()
	if not _camera:
		return

	var head_world: Vector2 = _get_head_world_position(_player)
	var facing: Vector2 = _get_facing_direction(_player)
	_update_polygon_shape()
	global_position = _world_to_screen(head_world)
	rotation = facing.angle()
	color = cone_color


func _update_polygon_shape() -> void:
	var half_angle: float = deg_to_rad(cone_angle_deg * 0.5)
	var points: PackedVector2Array = PackedVector2Array()
	points.append(Vector2.ZERO)

	for i in range(segment_count + 1):
		var t: float = float(i) / float(maxi(segment_count, 1))
		var angle: float = lerpf(-half_angle, half_angle, t)
		var local_point: Vector2 = Vector2.RIGHT.rotated(angle) * cone_radius
		points.append(local_point)

	polygon = points


func _resolve_refs() -> void:
	if not player_path.is_empty():
		var p: Node = get_node_or_null(player_path)
		if p is Node2D:
			_player = p as Node2D
	if not _player:
		var g: Node = get_tree().get_first_node_in_group("player")
		if g is Node2D:
			_player = g as Node2D

	if not camera_path.is_empty():
		var c: Node = get_node_or_null(camera_path)
		if c is Camera2D:
			_camera = c as Camera2D
	if not _camera:
		_camera = get_viewport().get_camera_2d()


func _get_head_world_position(player: Node2D) -> Vector2:
	if player.has_method("get_head_world_position"):
		var value: Variant = player.call("get_head_world_position")
		if value is Vector2:
			return value as Vector2
	return player.global_position


func _get_facing_direction(player: Node2D) -> Vector2:
	if player.has_method("get_facing_direction"):
		var value: Variant = player.call("get_facing_direction")
		if value is Vector2:
			return value as Vector2
	return Vector2.RIGHT


func _world_to_screen(world_pos: Vector2) -> Vector2:
	if not _camera:
		return world_pos

	var screen_center: Vector2 = get_viewport_rect().size * 0.5
	var camera_center_world: Vector2 = _camera.get_screen_center_position()
	var zoom: Vector2 = _camera.zoom
	var safe_zoom: Vector2 = Vector2(
		zoom.x if absf(zoom.x) > 0.0001 else 1.0,
		zoom.y if absf(zoom.y) > 0.0001 else 1.0
	)

	return Vector2(
		(world_pos.x - camera_center_world.x) / safe_zoom.x + screen_center.x,
		(world_pos.y - camera_center_world.y) / safe_zoom.y + screen_center.y
	)
