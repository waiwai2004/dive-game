extends ColorRect

@export var player_path: NodePath
@export var camera_path: NodePath

@export var darkness_alpha: float = 0.95
@export var cone_radius: float = 360.0
@export var cone_angle_deg: float = 118.0
@export var edge_feather: float = 140.0
@export var angle_feather_deg: float = 18.0

@export var peripheral_radius: float = 130.0
@export var peripheral_feather: float = 110.0
@export var origin_forward_offset: float = 24.0

var _player: Node2D = null
var _camera: Camera2D = null
var _shader_material: ShaderMaterial = null


func _ready() -> void:
	_resolve_refs()
	_ensure_material()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func _process(_delta: float) -> void:
	if not _player or not is_instance_valid(_player):
		_resolve_refs()
	if not _camera or not is_instance_valid(_camera):
		_resolve_refs()
	if not _player or not _camera or not _shader_material:
		return

	var facing: Vector2 = _get_facing_direction(_player)
	var head_world: Vector2 = _get_head_world_position(_player)
	var origin_world: Vector2 = head_world + facing * origin_forward_offset
	var origin_screen: Vector2 = _world_to_screen(origin_world)
	var screen_size: Vector2 = get_viewport_rect().size

	_shader_material.set_shader_parameter("screen_size", screen_size)
	_shader_material.set_shader_parameter("cone_center", origin_screen)
	_shader_material.set_shader_parameter("cone_dir", facing.normalized())
	_shader_material.set_shader_parameter("cone_radius", cone_radius)
	_shader_material.set_shader_parameter("cone_angle", deg_to_rad(cone_angle_deg))
	_shader_material.set_shader_parameter("edge_feather", edge_feather)
	_shader_material.set_shader_parameter("angle_feather", deg_to_rad(angle_feather_deg))
	_shader_material.set_shader_parameter("peripheral_radius", peripheral_radius)
	_shader_material.set_shader_parameter("peripheral_feather", peripheral_feather)
	_shader_material.set_shader_parameter("darkness_alpha", darkness_alpha)


func _ensure_material() -> void:
	if material is ShaderMaterial:
		_shader_material = material as ShaderMaterial
	else:
		_shader_material = ShaderMaterial.new()
		material = _shader_material

	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform vec2 screen_size = vec2(1920.0, 1080.0);
uniform vec2 cone_center = vec2(960.0, 540.0);
uniform vec2 cone_dir = vec2(1.0, 0.0);

uniform float cone_radius = 360.0;
uniform float cone_angle = 2.0594885;
uniform float edge_feather = 140.0;
uniform float angle_feather = 0.31415927;

uniform float peripheral_radius = 130.0;
uniform float peripheral_feather = 110.0;
uniform float darkness_alpha = 0.95;

float angle_diff(float a, float b) {
	float d = a - b;
	d = mod(d + PI, TAU) - PI;
	return d;
}

void fragment() {
	vec2 p = SCREEN_UV * screen_size;
	vec2 to_p = p - cone_center;
	float dist = length(to_p);

	vec2 forward = normalize(cone_dir);
	vec2 dir = dist > 0.0001 ? (to_p / dist) : forward;

	float ang = abs(angle_diff(atan(dir.y, dir.x), atan(forward.y, forward.x)));
	float half_angle = cone_angle * 0.5;

	float cone_angular = 1.0 - smoothstep(half_angle - angle_feather, half_angle, ang);
	float cone_radial = 1.0 - smoothstep(cone_radius - edge_feather, cone_radius, dist);
	float cone_visibility = clamp(cone_angular * cone_radial, 0.0, 1.0);

	float peripheral_visibility = 1.0 - smoothstep(
		peripheral_radius - peripheral_feather,
		peripheral_radius,
		dist
	);

	float visibility = max(cone_visibility, peripheral_visibility);
	float alpha = darkness_alpha * (1.0 - visibility);

	COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
"""
	_shader_material.shader = shader


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
	if player.has_method("get_character_state"):
		var state: Variant = player.call("get_character_state")
		if state is Dictionary and "head_position" in state:
			var value: Variant = state["head_position"]
			if value is Vector2:
				return value

	if player.has_method("get_head_world_position"):
		var value2: Variant = player.call("get_head_world_position")
		if value2 is Vector2:
			return value2

	return player.global_position


func _get_facing_direction(player: Node2D) -> Vector2:
	if player.has_method("get_character_state"):
		var state: Variant = player.call("get_character_state")
		if state is Dictionary and "facing_direction" in state:
			var value: Variant = state["facing_direction"]
			if value is Vector2 and value.length_squared() > 0.0001:
				return value.normalized()

	if player.has_method("get_facing_direction"):
		var value2: Variant = player.call("get_facing_direction")
		if value2 is Vector2 and value2.length_squared() > 0.0001:
			return value2.normalized()

	return Vector2.RIGHT


func _world_to_screen(world_pos: Vector2) -> Vector2:
	if not _camera:
		return world_pos

	var screen_center: Vector2 = get_viewport_rect().size * 0.5
	var camera_center_world: Vector2 = _camera.get_screen_center_position()
	var zoom: Vector2 = _camera.zoom

	var safe_zoom := Vector2(
		zoom.x if absf(zoom.x) > 0.0001 else 1.0,
		zoom.y if absf(zoom.y) > 0.0001 else 1.0
	)

	return Vector2(
		(world_pos.x - camera_center_world.x) / safe_zoom.x + screen_center.x,
		(world_pos.y - camera_center_world.y) / safe_zoom.y + screen_center.y
	)
