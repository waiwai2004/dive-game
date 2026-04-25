extends Area2D
## 伤口节点 — Boss战斗点
## 底部大面积黑色剪影（锯齿状有机形态向上伸展），猩红粒子飘散
## 美术形象远大于判定区域，如概念图所示

# 视觉范围（远大于碰撞判定）
const VISUAL_WIDTH := 1200.0
const VISUAL_HEIGHT := 800.0
# 底部基座高度
const BASE_HEIGHT := 280.0
# 大型指状突起数量
const FINGER_COUNT := 14
# 小型锯齿数量
const JAGGED_COUNT := 30
# 浮动粒子数量
const PARTICLE_COUNT := 40

var _time: float = 0.0
var _finger_data: Array = []
var _jagged_data: Array = []
var _particle_data: Array = []
var _triggered: bool = false


func _ready() -> void:
	monitoring = true
	monitorable = true
	collision_layer = 1
	collision_mask = 1
	_init_fingers()
	_init_jagged_edge()
	_init_particles()
	set_process(true)


func set_triggered(value: bool) -> void:
	_triggered = value
	queue_redraw()


func _process(delta: float) -> void:
	if _triggered:
		return
	_time += delta
	queue_redraw()


func _init_fingers() -> void:
	_finger_data.clear()
	for i in FINGER_COUNT:
		# 手指/触手从底部向上伸出，分布在整个宽度上
		var x_pos := randf_range(-VISUAL_WIDTH * 0.48, VISUAL_WIDTH * 0.48)
		var height := randf_range(VISUAL_HEIGHT * 0.3, VISUAL_HEIGHT * 0.85)
		var width_base := randf_range(25.0, 70.0)
		# 有些特别高特别粗的作为主要形态
		if i < 5:
			height = randf_range(VISUAL_HEIGHT * 0.55, VISUAL_HEIGHT * 0.9)
			width_base = randf_range(45.0, 85.0)

		_finger_data.append({
			"x": x_pos,
			"height": height,
			"width": width_base,
			"phase": randf_range(0.0, TAU),
			"sway_speed": randf_range(0.3, 0.8),
			"sway_amp": randf_range(8.0, 25.0),
			"segments": randi_range(8, 14),
			# 分叉数据
			"branches": randi_range(0, 3),
			"branch_data": [],
		})
		# 生成分叉
		var fd: Dictionary = _finger_data[i]
		for b in range(fd["branches"]):
			fd["branch_data"].append({
				"start_t": randf_range(0.3, 0.7),
				"angle": randf_range(-0.8, 0.8),
				"length": randf_range(40.0, 120.0),
				"width": width_base * randf_range(0.3, 0.6),
				"phase": randf_range(0.0, TAU),
			})


func _init_jagged_edge() -> void:
	_jagged_data.clear()
	for i in JAGGED_COUNT:
		_jagged_data.append({
			"x": randf_range(-VISUAL_WIDTH * 0.52, VISUAL_WIDTH * 0.52),
			"height": randf_range(30.0, 120.0),
			"width": randf_range(15.0, 45.0),
			"phase": randf_range(0.0, TAU),
		})


func _init_particles() -> void:
	_particle_data.clear()
	for i in PARTICLE_COUNT:
		_particle_data.append({
			"base_pos": Vector2(
				randf_range(-VISUAL_WIDTH * 0.55, VISUAL_WIDTH * 0.55),
				randf_range(-VISUAL_HEIGHT * 0.9, BASE_HEIGHT * 0.3)
			),
			"size": randf_range(2.0, 7.0),
			"phase": randf_range(0.0, TAU),
			"float_speed": randf_range(0.2, 0.6),
			"drift_amp": randf_range(5.0, 20.0),
			"rise_speed": randf_range(8.0, 25.0),
			"lifetime_phase": randf_range(0.0, TAU),
		})


func _draw() -> void:
	if _triggered:
		_draw_triggered_state()
		return
	# 绘制顺序：基座 → 锯齿边缘 → 手指突起 → 粒子
	_draw_base_mass()
	_draw_jagged_edge()
	_draw_fingers()
	_draw_particles()


func _draw_base_mass() -> void:
	# 底部宽大的不规则基座剪影
	var points: PackedVector2Array = []
	# 从左下开始
	points.append(Vector2(-VISUAL_WIDTH * 0.55, BASE_HEIGHT + 50.0))

	# 上边缘 — 不规则起伏
	var steps := 24
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var x := lerpf(-VISUAL_WIDTH * 0.5, VISUAL_WIDTH * 0.5, t)
		var base_y := 0.0
		# 中间稍高一些
		var center_factor := 1.0 - absf(t - 0.5) * 2.0
		base_y -= center_factor * 40.0
		# 随机起伏
		base_y += sin(t * 8.0 + _time * 0.2) * 20.0
		base_y += sin(t * 13.0 + _time * 0.15 + 1.5) * 12.0
		points.append(Vector2(x, base_y))

	# 右下
	points.append(Vector2(VISUAL_WIDTH * 0.55, BASE_HEIGHT + 50.0))

	draw_colored_polygon(points, Color(0.03, 0.01, 0.01, 0.95))

	# 第二层较浅的层次
	var points2: PackedVector2Array = []
	points2.append(Vector2(-VISUAL_WIDTH * 0.52, BASE_HEIGHT + 50.0))
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var x := lerpf(-VISUAL_WIDTH * 0.48, VISUAL_WIDTH * 0.48, t)
		var y := 30.0 + sin(t * 6.0 + _time * 0.25 + 2.0) * 15.0 + sin(t * 11.0) * 10.0
		points2.append(Vector2(x, y))
	points2.append(Vector2(VISUAL_WIDTH * 0.52, BASE_HEIGHT + 50.0))
	draw_colored_polygon(points2, Color(0.06, 0.02, 0.02, 0.8))


func _draw_jagged_edge() -> void:
	# 基座上的小型锯齿突起
	for data in _jagged_data:
		var x: float = data["x"]
		var h: float = data["height"]
		var w: float = data["width"]
		var phase: float = data["phase"]
		var sway := sin(_time * 0.4 + phase) * 5.0

		var tri: PackedVector2Array = [
			Vector2(x - w * 0.5, 10.0),
			Vector2(x + sway, -h + sin(_time * 0.3 + phase) * 4.0),
			Vector2(x + w * 0.5, 10.0),
		]
		draw_colored_polygon(tri, Color(0.04, 0.01, 0.01, 0.9))


func _draw_fingers() -> void:
	# 大型手指/触手突起 — 概念图中的核心形态
	for data in _finger_data:
		var base_x: float = data["x"]
		var height: float = data["height"]
		var width: float = data["width"]
		var phase: float = data["phase"]
		var sway_speed: float = data["sway_speed"]
		var sway_amp: float = data["sway_amp"]
		var segments: int = data["segments"]

		# 构建手指的脊线
		var spine: PackedVector2Array = []
		for s in range(segments + 1):
			var t := float(s) / float(segments)
			var sway := sin(_time * sway_speed + phase + t * 2.5) * sway_amp * t
			var sway2 := cos(_time * sway_speed * 0.6 + phase + t * 1.8) * sway_amp * 0.4 * t
			var x := base_x + sway + sway2
			var y := lerpf(15.0, -height, t)
			spine.append(Vector2(x, y))

		# 用宽度沿脊线构建多边形轮廓
		var left_side: PackedVector2Array = []
		var right_side: PackedVector2Array = []
		for s in range(spine.size()):
			var t := float(s) / float(spine.size() - 1)
			# 宽度随高度递减，但有有机变化
			var w := width * (1.0 - t * 0.85) * (1.0 + sin(t * 5.0 + phase) * 0.15)
			var p: Vector2 = spine[s]
			# 计算法向方向
			var tangent := Vector2.UP
			if s < spine.size() - 1:
				tangent = (spine[s + 1] - spine[s]).normalized()
			var normal := Vector2(-tangent.y, tangent.x)

			left_side.append(p - normal * w * 0.5)
			right_side.append(p + normal * w * 0.5)

		# 组合成封闭多边形
		var finger_poly: PackedVector2Array = []
		for p in left_side:
			finger_poly.append(p)
		# 顶端
		if spine.size() > 0:
			finger_poly.append(spine[spine.size() - 1])
		# 右侧逆序
		for s in range(right_side.size() - 1, -1, -1):
			finger_poly.append(right_side[s])

		if finger_poly.size() >= 3:
			draw_colored_polygon(finger_poly, Color(0.03, 0.01, 0.01, 0.92))
			# 边缘微弱高光
			var outline: PackedVector2Array = finger_poly.duplicate()
			outline.append(finger_poly[0])
			draw_polyline(outline, Color(0.08, 0.03, 0.03, 0.25), 1.5)

		# 绘制分叉
		var branches: Array = data["branch_data"]
		for bd in branches:
			var start_t: float = bd["start_t"]
			var b_angle: float = bd["angle"]
			var b_length: float = bd["length"]
			var b_width: float = bd["width"]
			var b_phase: float = bd["phase"]
			var start_idx := int(start_t * float(spine.size() - 1))
			if start_idx >= spine.size():
				start_idx = spine.size() - 1
			var start_pos: Vector2 = spine[start_idx]
			var b_sway := sin(_time * 0.5 + b_phase) * 10.0

			var b_end := start_pos + Vector2(
				cos(-PI * 0.5 + b_angle) * b_length + b_sway,
				sin(-PI * 0.5 + b_angle) * b_length
			)
			var b_mid := (start_pos + b_end) * 0.5

			var b_tri: PackedVector2Array = [
				start_pos + Vector2(-b_width * 0.4, 0),
				b_end,
				start_pos + Vector2(b_width * 0.4, 0),
			]
			if b_tri.size() >= 3:
				draw_colored_polygon(b_tri, Color(0.04, 0.01, 0.01, 0.85))


func _draw_particles() -> void:
	# 猩红色漂浮粒子
	for data in _particle_data:
		var base_pos: Vector2 = data["base_pos"]
		var sz: float = data["size"]
		var phase: float = data["phase"]
		var f_speed: float = data["float_speed"]
		var d_amp: float = data["drift_amp"]
		var r_speed: float = data["rise_speed"]
		var l_phase: float = data["lifetime_phase"]

		# 粒子缓慢上升 + 水平飘荡
		var drift_x := sin(_time * f_speed + phase) * d_amp
		var drift_y := -fmod((_time * r_speed + l_phase * 100.0), VISUAL_HEIGHT * 1.2)
		var pos := base_pos + Vector2(drift_x, drift_y)

		# 循环（超出顶部后回到底部）
		if pos.y < -VISUAL_HEIGHT:
			pos.y += VISUAL_HEIGHT * 1.3

		# 脉动大小和透明度
		var pulse := 0.5 + 0.5 * sin(_time * 1.5 + phase)
		var particle_size := sz * (0.7 + pulse * 0.5)
		var alpha := 0.35 + pulse * 0.3

		draw_circle(pos, particle_size, Color(0.7, 0.08, 0.03, alpha))
		# 微弱光晕
		draw_circle(pos, particle_size * 2.5, Color(0.6, 0.04, 0.02, alpha * 0.15))


func _draw_triggered_state() -> void:
	var gray := Color(0.25, 0.25, 0.25, 0.5)
	var dark_gray := Color(0.15, 0.15, 0.15, 0.5)
	
	var points: PackedVector2Array = []
	points.append(Vector2(-VISUAL_WIDTH * 0.55, BASE_HEIGHT + 50.0))
	for i in range(25):
		var t := float(i) / 24.0
		var x := lerpf(-VISUAL_WIDTH * 0.55, VISUAL_WIDTH * 0.55, t)
		var y := BASE_HEIGHT + randf_range(-20.0, 20.0)
		points.append(Vector2(x, y))
	points.append(Vector2(VISUAL_WIDTH * 0.55, BASE_HEIGHT + 50.0))
	draw_colored_polygon(points, dark_gray)
	
	for data in _finger_data:
		var base_x: float = data["x"]
		var height: float = data["height"] * 0.7
		var width: float = data["width"] * 0.8
		var finger_points: PackedVector2Array = [
			Vector2(base_x - width * 0.5, 10.0),
			Vector2(base_x, 10.0 - height),
			Vector2(base_x + width * 0.5, 10.0),
		]
		draw_colored_polygon(finger_points, gray)
