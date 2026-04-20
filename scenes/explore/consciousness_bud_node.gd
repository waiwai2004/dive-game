extends Area2D
## 意识花苞节点 — 特殊战斗点
## 灰色调郁金香花苞形态，轻微摇曳动画

const S := 4.0  # 全局缩放倍率

var _time: float = 0.0


func _ready() -> void:
	monitoring = true
	monitorable = true
	collision_layer = 1
	collision_mask = 1
	set_process(true)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var sway := sin(_time * 0.7) * 4.0 * S
	var sway2 := sin(_time * 0.5 + 0.8) * 2.0 * S

	# ── 茎 ──
	var stem_base := Vector2(0.0, 55.0 * S)
	var stem_top := Vector2(sway * 0.2, -25.0 * S)
	var stem_points: PackedVector2Array = []
	for i in range(8):
		var t := float(i) / 7.0
		var x := lerpf(stem_base.x, stem_top.x, t) + sin(t * PI) * sway * 0.3
		var y := lerpf(stem_base.y, stem_top.y, t)
		stem_points.append(Vector2(x, y))
	for i in range(stem_points.size() - 1):
		var t := float(i) / float(stem_points.size() - 1)
		var w := lerpf(4.0 * S, 2.5 * S, t)
		draw_line(stem_points[i], stem_points[i + 1], Color(0.22, 0.28, 0.2, 0.9), w, true)

	# ── 叶片（左侧）──
	var leaf_base := Vector2(-2.0 * S + sway * 0.15, 20.0 * S)
	var leaf_tip := Vector2(-28.0 * S + sway * 0.4, 5.0 * S)
	var leaf_ctrl := Vector2(-20.0 * S + sway * 0.3, 18.0 * S)
	_draw_leaf(leaf_base, leaf_tip, leaf_ctrl, 8.0 * S, Color(0.28, 0.33, 0.25, 0.8))

	# ── 叶片（右侧小叶）──
	var leaf2_base := Vector2(1.0 * S + sway * 0.1, 30.0 * S)
	var leaf2_tip := Vector2(18.0 * S + sway2 * 0.3, 22.0 * S)
	var leaf2_ctrl := Vector2(12.0 * S + sway2 * 0.2, 28.0 * S)
	_draw_leaf(leaf2_base, leaf2_tip, leaf2_ctrl, 5.0 * S, Color(0.25, 0.30, 0.22, 0.7))

	# ── 花苞 ──
	var bud_center := stem_top + Vector2(sway * 0.1, 0.0)
	var bud_scale := 1.0 + sin(_time * 1.0) * 0.04

	# 外层花瓣（左）
	_draw_petal(
		bud_center + Vector2(-10.0 * S * bud_scale, 5.0 * S),
		bud_center + Vector2(-3.0 * S, -42.0 * S * bud_scale),
		12.0 * S * bud_scale,
		Color(0.32, 0.32, 0.32, 0.92)
	)
	# 外层花瓣（右）
	_draw_petal(
		bud_center + Vector2(10.0 * S * bud_scale, 5.0 * S),
		bud_center + Vector2(3.0 * S, -42.0 * S * bud_scale),
		12.0 * S * bud_scale,
		Color(0.36, 0.36, 0.36, 0.92)
	)
	# 中央花瓣
	_draw_petal(
		bud_center + Vector2(0.0, 6.0 * S),
		bud_center + Vector2(0.0, -46.0 * S * bud_scale),
		9.0 * S * bud_scale,
		Color(0.40, 0.40, 0.40, 0.95)
	)

	# 花苞底部环
	draw_arc(bud_center + Vector2(0, 4 * S), 11.0 * S * bud_scale, 0.0, PI, 12, Color(0.2, 0.25, 0.18, 0.6), 2.0 * S)

	# 花苞隐约微光
	var glow_pulse := 0.5 + 0.5 * sin(_time * 1.3)
	draw_circle(bud_center + Vector2(0, -15 * S), 16.0 * S, Color(0.4, 0.5, 0.6, 0.08 + glow_pulse * 0.05))


func _draw_petal(base: Vector2, tip: Vector2, width: float, color: Color) -> void:
	var mid := (base + tip) * 0.5
	var dir := (tip - base).normalized()
	var perp := Vector2(-dir.y, dir.x)
	# 花瓣形状：base → 左鼓起 → tip → 右鼓起
	var ctrl_left := mid + perp * width
	var ctrl_right := mid - perp * width
	var points: PackedVector2Array = [base, ctrl_left, tip, ctrl_right]
	draw_colored_polygon(points, color)
	# 花瓣中线
	draw_line(base, tip, Color(color.r * 0.7, color.g * 0.7, color.b * 0.7, color.a * 0.4), 1.0, true)


func _draw_leaf(base: Vector2, tip: Vector2, ctrl: Vector2, width: float, color: Color) -> void:
	var dir := (tip - base).normalized()
	var perp := Vector2(-dir.y, dir.x)
	var points: PackedVector2Array = [
		base,
		ctrl + perp * width * 0.5,
		tip,
		ctrl - perp * width * 0.5,
	]
	draw_colored_polygon(points, color)
