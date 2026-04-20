extends Node2D
## 伤口猩红光效 — 渲染在暗幕图层之上，无视视野遮蔽
## 必须放在 CanvasLayer(layer>5) 中才能穿透暗幕

var wound_node: Node2D = null
var glow_radius: float = 700.0

var _camera: Camera2D = null
var _time: float = 0.0
# 预生成的蠕动斑块数据
var _splotch_data: Array = []


func _ready() -> void:
	_init_splotches()
	set_process(true)


func _init_splotches() -> void:
	_splotch_data.clear()
	for i in range(18):
		_splotch_data.append({
			"orbit_radius": randf_range(0.15, 0.7),
			"orbit_speed": randf_range(0.08, 0.25) * (1.0 if randi() % 2 == 0 else -1.0),
			"phase": randf_range(0.0, TAU),
			"size": randf_range(10.0, 35.0),
			"pulse_speed": randf_range(0.5, 1.2),
			"pulse_phase": randf_range(0.0, TAU),
		})


func _process(delta: float) -> void:
	_time += delta
	if not wound_node or not is_instance_valid(wound_node):
		return
	if not _camera or not is_instance_valid(_camera):
		_find_camera()
	if not _camera:
		return

	position = _world_to_screen(wound_node.global_position)
	queue_redraw()


func _find_camera() -> void:
	var viewport := get_viewport()
	if viewport:
		_camera = viewport.get_camera_2d()


func _world_to_screen(world_pos: Vector2) -> Vector2:
	if not _camera:
		return world_pos
	var viewport_size := get_viewport_rect().size
	var camera_pos := _camera.global_position
	var zoom := _camera.zoom
	return (world_pos - camera_pos) * zoom + viewport_size * 0.5


func _draw() -> void:
	if not wound_node or not is_instance_valid(wound_node):
		return

	var zoom_scale := 1.0
	if _camera:
		zoom_scale = _camera.zoom.x

	var scaled_radius := glow_radius * zoom_scale

	# 外层弥漫光晕 — 多层叠加
	var pulse := 0.5 + 0.5 * sin(_time * 0.9)
	var pulse2 := 0.5 + 0.5 * sin(_time * 0.6 + 1.8)

	for i in range(10, 0, -1):
		var r := scaled_radius * (0.2 + float(i) * 0.1) * (0.92 + pulse * 0.1)
		var alpha := (0.08 + pulse2 * 0.04) * (1.0 - float(i) / 12.0)
		draw_circle(Vector2.ZERO, r, Color(0.65, 0.04, 0.02, alpha))

	# 核心光斑
	var core_r := scaled_radius * 0.18 * (0.9 + pulse * 0.15)
	draw_circle(Vector2.ZERO, core_r, Color(0.75, 0.08, 0.04, 0.2 + pulse * 0.1))

	# 蠕动的猩红色斑 — 有机运动轨迹
	for data in _splotch_data:
		var orbit_frac: float = data["orbit_radius"]
		var orbit_r: float = orbit_frac * scaled_radius
		var s_speed: float = data["orbit_speed"]
		var s_phase: float = data["phase"]
		var angle: float = _time * s_speed + s_phase
		# 添加径向呼吸
		var p_speed: float = data["pulse_speed"]
		var p_phase: float = data["pulse_phase"]
		var breathe := sin(_time * p_speed + p_phase)
		orbit_r += breathe * scaled_radius * 0.08

		var pos := Vector2(cos(angle), sin(angle)) * orbit_r
		# 额外扰动
		pos.x += sin(_time * 0.7 + s_phase * 2.0) * 8.0 * zoom_scale
		pos.y += cos(_time * 0.5 + s_phase * 3.0) * 6.0 * zoom_scale

		var s_size: float = data["size"]
		var sz: float = s_size * zoom_scale * (0.8 + breathe * 0.25)
		var alpha := 0.12 + 0.06 * (0.5 + 0.5 * breathe)
		draw_circle(pos, sz, Color(0.6, 0.03, 0.01, alpha))

	# 细丝状蔓延
	for i in range(6):
		var angle := float(i) / 6.0 * TAU + _time * 0.12
		var r_start := scaled_radius * 0.15
		var r_end := scaled_radius * (0.5 + 0.2 * sin(_time * 0.4 + float(i)))
		var p1 := Vector2(cos(angle), sin(angle)) * r_start
		var p2 := Vector2(cos(angle + 0.1 * sin(_time * 0.8)), sin(angle + 0.1 * sin(_time * 0.8))) * r_end
		var alpha := 0.08 + 0.04 * sin(_time * 0.6 + float(i))
		draw_line(p1, p2, Color(0.7, 0.05, 0.02, alpha), 3.0 * zoom_scale, true)
