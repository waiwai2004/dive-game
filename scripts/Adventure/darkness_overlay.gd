extends ColorRect

@export var player_path: NodePath
@export var camera_path: NodePath

@export_range(0.01, 1.0, 0.01) var radius := 0.18
@export_range(0.01, 1.0, 0.01) var softness := 0.22
@export_range(0.0, 1.0, 0.01) var darkness := 0.90

var shader_mat: ShaderMaterial
var player: Node
var camera: Camera2D

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	player = get_node_or_null(player_path)
	camera = get_node_or_null(camera_path)

	if material == null:
		push_error("DarknessOverlay 缺少 ShaderMaterial")
		return

	shader_mat = material.duplicate() as ShaderMaterial
	material = shader_mat

	if shader_mat != null:
		shader_mat.set_shader_parameter("radius", radius)
		shader_mat.set_shader_parameter("softness", softness)
		shader_mat.set_shader_parameter("darkness", darkness)

func _process(_delta: float) -> void:
	if player == null or camera == null or shader_mat == null:
		return

	if not player.has_method("get_light_world_position"):
		return

	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	var target_world: Vector2 = player.get_light_world_position()
	var screen_center_world: Vector2 = camera.get_screen_center_position()

	# 世界坐标 -> 屏幕像素坐标
	var screen_pos := (target_world - screen_center_world) * camera.zoom + viewport_size * 0.5

	var uv := Vector2(
		clamp(screen_pos.x / viewport_size.x, 0.0, 1.0),
		clamp(screen_pos.y / viewport_size.y, 0.0, 1.0)
	)

	shader_mat.set_shader_parameter("light_pos", uv)
