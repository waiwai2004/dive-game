extends Area2D
## 认知废墟节点 — 特殊战斗点
## 漂浮碎片群 + 微弱能量丝线，带有幽灵鱼/水母般的引导体

var _time: float = 0.0
var _debris_data: Array = []
var _wisp_data: Array = []


func _ready() -> void:
	monitoring = true
	monitorable = true
	collision_layer = 1
	collision_mask = 1
	_init_debris()
	_init_wisps()
	set_process(true)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _init_debris() -> void:
	_debris_data.clear()
	# 生成随机漂浮碎片
	for i in range(10):
		_debris_data.append({
			"pos": Vector2(randf_range(-120.0, 120.0), randf_range(-90.0, 90.0)),
			"size": Vector2(randf_range(16.0, 44.0), randf_range(10.0, 32.0)),
			"rotation": randf_range(0.0, TAU),
			"phase": randf_range(0.0, TAU),
			"float_speed": randf_range(0.25, 0.7),
			"float_amp": randf_range(6.0, 20.0),
			"rot_speed": randf_range(-0.3, 0.3),
			"color_val": randf_range(0.25, 0.42),
		})


func _init_wisps() -> void:
	_wisp_data.clear()
	# 生成引导体（幽灵鱼形态）
	for i in range(4):
		_wisp_data.append({
			"orbit_center": Vector2(randf_range(-60.0, 60.0), randf_range(-40.0, 40.0)),
			"orbit_radius": randf_range(80.0, 180.0),
			"orbit_speed": randf_range(0.15, 0.35) * (1.0 if randi() % 2 == 0 else -1.0),
			"phase": randf_range(0.0, TAU),
			"body_length": randf_range(36.0, 64.0),
			"body_width": randf_range(10.0, 20.0),
			"tail_segments": randi_range(3, 6),
		})


func _draw() -> void:
	_draw_debris()
	_draw_energy_lines()
	_draw_wisps()
	_draw_center_glow()


func _draw_debris() -> void:
	for data in _debris_data:
		var f_speed: float = data["float_speed"]
		var f_phase: float = data["phase"]
		var f_amp: float = data["float_amp"]
		var float_y: float = sin(_time * f_speed + f_phase) * f_amp
		var float_x: float = cos(_time * f_speed * 0.7 + f_phase) * f_amp * 0.3
		var pos: Vector2 = data["pos"] + Vector2(float_x, float_y)
		var sz: Vector2 = data["size"]
		var rot: float = data["rotation"] + _time * float(data["rot_speed"])
		var val: float = data["color_val"]

		var points := _rotated_rect(pos, sz, rot)
		draw_colored_polygon(points, Color(val, val * 0.9, val * 0.85, 0.7))
		# 边缘高光
		var edge_color := Color(val + 0.15, val + 0.12, val + 0.1, 0.4)
		var outline := points.duplicate()
		outline.append(points[0])
		draw_polyline(outline, edge_color, 1.2)


func _draw_energy_lines() -> void:
	# 碎片间的微弱能量丝线
	for i in range(_debris_data.size() - 1):
		var d1: Dictionary = _debris_data[i]
		var d2: Dictionary = _debris_data[i + 1]
		var d1_speed: float = d1["float_speed"]
		var d1_phase: float = d1["phase"]
		var d1_amp: float = d1["float_amp"]
		var d2_speed: float = d2["float_speed"]
		var d2_phase: float = d2["phase"]
		var d2_amp: float = d2["float_amp"]
		var fy1: float = sin(_time * d1_speed + d1_phase) * d1_amp
		var fx1: float = cos(_time * d1_speed * 0.7 + d1_phase) * d1_amp * 0.3
		var fy2: float = sin(_time * d2_speed + d2_phase) * d2_amp
		var fx2: float = cos(_time * d2_speed * 0.7 + d2_phase) * d2_amp * 0.3

		var p1: Vector2 = d1["pos"] + Vector2(fx1, fy1)
		var p2: Vector2 = d2["pos"] + Vector2(fx2, fy2)

		# 只在距离较近时显示
		if p1.distance_to(p2) < 100.0:
			var alpha := 0.06 + 0.04 * sin(_time * 0.7 + float(i))
			draw_line(p1, p2, Color(0.5, 0.7, 0.85, alpha), 1.0, true)


func _draw_wisps() -> void:
	# 幽灵鱼/引导体
	for data in _wisp_data:
		var center: Vector2 = data["orbit_center"]
		var orbit_r: float = data["orbit_radius"]
		var o_speed: float = data["orbit_speed"]
		var o_phase: float = data["phase"]
		var angle: float = _time * o_speed + o_phase
		var head_pos: Vector2 = center + Vector2(cos(angle), sin(angle)) * orbit_r

		# 运动方向
		var move_dir: Vector2 = Vector2(-sin(angle), cos(angle)) * signf(o_speed)
		move_dir = move_dir.normalized()
		var perp: Vector2 = Vector2(-move_dir.y, move_dir.x)

		var body_len: float = data["body_length"]
		var body_w: float = data["body_width"]

		# 身体 — 流线型
		var body_points: PackedVector2Array = []
		body_points.append(head_pos + move_dir * body_len * 0.3)  # 头部尖端
		body_points.append(head_pos + perp * body_w * 0.5)
		body_points.append(head_pos - move_dir * body_len * 0.4)
		body_points.append(head_pos - perp * body_w * 0.5)
		draw_colored_polygon(body_points, Color(0.55, 0.6, 0.55, 0.25))

		# 尾巴 — 蠕动
		var tail_start: Vector2 = head_pos - move_dir * body_len * 0.4
		var seg_len: float = body_len * 0.25
		var prev: Vector2 = tail_start
		var tail_segs: int = data["tail_segments"]
		for s in range(tail_segs):
			var t := float(s + 1) / float(tail_segs)
			var wave := sin(_time * 2.5 + o_phase + t * 3.0) * 8.0 * t
			var next_pos: Vector2 = prev - move_dir * seg_len + perp * wave
			var alpha := 0.2 * (1.0 - t * 0.7)
			var w := body_w * 0.4 * (1.0 - t * 0.6)
			draw_line(prev, next_pos, Color(0.5, 0.55, 0.5, alpha), maxf(w, 0.5), true)
			prev = next_pos

		# 头部小眼睛
		var eye_pos: Vector2 = head_pos + move_dir * body_len * 0.15
		draw_circle(eye_pos, 1.8, Color(0.7, 0.8, 0.7, 0.4))


func _draw_center_glow() -> void:
	var pulse := 0.5 + 0.5 * sin(_time * 0.8)
	draw_circle(Vector2.ZERO, 50.0, Color(0.45, 0.55, 0.65, 0.06 + pulse * 0.04))
	draw_circle(Vector2.ZERO, 24.0, Color(0.5, 0.6, 0.7, 0.1 + pulse * 0.05))


func _rotated_rect(center: Vector2, sz: Vector2, angle: float) -> PackedVector2Array:
	var half := sz / 2.0
	var corners := [
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	]
	var result: PackedVector2Array = []
	for c in corners:
		result.append(c.rotated(angle) + center)
	return result
