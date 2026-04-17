extends Control

## 双液饼状体：左半=SAN（粉色），右半=HP（红色），从下往上填充。
## 鼠标悬停在某一半时发出 stat_hovered 信号，battle_scene 据此显示 tooltip。

signal stat_hovered(stat_key: String, is_hovering: bool)

@export var hp_color: Color = Color(0.92, 0.18, 0.24, 1.0)
@export var san_color: Color = Color(0.95, 0.32, 0.76, 1.0)
@export var bg_color: Color = Color(0.08, 0.09, 0.12, 0.94)
@export var border_color: Color = Color(0.82, 0.86, 0.98, 0.88)
@export var border_width: float = 3.0
@export var show_value_labels: bool = true
@export var value_font_size: int = 22

var hp_current: int = 10
var hp_max: int = 10
var san_current: int = 10
var san_max: int = 10

var _current_side: int = 0  # 0 无，1 左(SAN)，2 右(HP)
var _phase: float = 0.0  # 液面轻微波动用


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)


func set_stats(hp: int, hp_max_val: int, san: int, san_max_val: int) -> void:
	hp_current = hp
	hp_max = max(hp_max_val, 1)
	san_current = san
	san_max = max(san_max_val, 1)
	queue_redraw()


func _process(delta: float) -> void:
	_phase += delta
	queue_redraw()

	var mpos: Vector2 = get_local_mouse_position()
	var center: Vector2 = size * 0.5
	var radius: float = minf(size.x, size.y) * 0.5 - border_width

	var new_side: int = 0
	if center.distance_to(mpos) <= radius and Rect2(Vector2.ZERO, size).has_point(mpos):
		new_side = 1 if mpos.x < center.x else 2

	if new_side != _current_side:
		if _current_side != 0:
			stat_hovered.emit(_key_for(_current_side), false)
		if new_side != 0:
			stat_hovered.emit(_key_for(new_side), true)
		_current_side = new_side


func _key_for(side: int) -> String:
	return "san" if side == 1 else "hp"


func _draw() -> void:
	var center: Vector2 = size * 0.5
	var radius: float = minf(size.x, size.y) * 0.5 - border_width

	# 背景整圆
	draw_circle(center, radius, bg_color)

	# 左半 - SAN
	var san_ratio: float = clampf(float(san_current) / float(maxi(san_max, 1)), 0.0, 1.0)
	_draw_half_liquid(center, radius, san_ratio, true, san_color)

	# 右半 - HP
	var hp_ratio: float = clampf(float(hp_current) / float(maxi(hp_max, 1)), 0.0, 1.0)
	_draw_half_liquid(center, radius, hp_ratio, false, hp_color)

	# 外边界
	draw_arc(center, radius, 0.0, TAU, 96, border_color, border_width, true)

	# 中间分隔板
	draw_line(
		Vector2(center.x, center.y - radius),
		Vector2(center.x, center.y + radius),
		border_color,
		border_width,
		true
	)

	# 高光（略微的外圈内边）
	draw_arc(center, radius - 2.0, 0.0, TAU, 64, Color(1, 1, 1, 0.08), 2.0, true)

	if show_value_labels:
		_draw_value_labels(center, radius)


func _draw_value_labels(center: Vector2, radius: float) -> void:
	var font: Font = get_theme_default_font()
	if font == null:
		return
	var san_txt: String = "%d/%d" % [san_current, san_max]
	var hp_txt: String = "%d/%d" % [hp_current, hp_max]

	var half_cx_left: float = center.x - radius * 0.5
	var half_cx_right: float = center.x + radius * 0.5
	var text_y: float = center.y + radius * 0.78

	var san_size: Vector2 = font.get_string_size(san_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, value_font_size)
	var hp_size: Vector2 = font.get_string_size(hp_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, value_font_size)

	draw_string(
		font,
		Vector2(half_cx_left - san_size.x * 0.5, text_y),
		san_txt,
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		value_font_size,
		Color(1, 1, 1, 0.95)
	)
	draw_string(
		font,
		Vector2(half_cx_right - hp_size.x * 0.5, text_y),
		hp_txt,
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		value_font_size,
		Color(1, 1, 1, 0.95)
	)

	# 上方的标题
	var tag_y: float = center.y - radius * 0.55
	var san_tag: String = "SAN"
	var hp_tag: String = "HP"
	var san_tag_size: Vector2 = font.get_string_size(san_tag, HORIZONTAL_ALIGNMENT_CENTER, -1, value_font_size - 4)
	var hp_tag_size: Vector2 = font.get_string_size(hp_tag, HORIZONTAL_ALIGNMENT_CENTER, -1, value_font_size - 4)
	draw_string(
		font,
		Vector2(half_cx_left - san_tag_size.x * 0.5, tag_y),
		san_tag,
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		value_font_size - 4,
		Color(1, 1, 1, 0.82)
	)
	draw_string(
		font,
		Vector2(half_cx_right - hp_tag_size.x * 0.5, tag_y),
		hp_tag,
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		value_font_size - 4,
		Color(1, 1, 1, 0.82)
	)


func _draw_half_liquid(center: Vector2, radius: float, ratio: float, is_left: bool, color: Color) -> void:
	if ratio <= 0.0:
		return

	# 液面 y（从下往上填充）
	var fill_top_y: float = center.y + radius * (1.0 - 2.0 * ratio)
	fill_top_y = clampf(fill_top_y, center.y - radius, center.y + radius)

	var dy: float = fill_top_y - center.y
	var sin_a: float = clampf(dy / radius, -1.0, 1.0)
	var a_fill_right: float = asin(sin_a)      # 范围 [-PI/2, PI/2]
	var a_fill_left: float = PI - a_fill_right # 左半对应角度

	var points: PackedVector2Array = []
	# 从液面与分隔板的交点开始
	points.append(Vector2(center.x, fill_top_y))
	# 沿分隔板下行到最底
	points.append(Vector2(center.x, center.y + radius))

	var steps: int = 48
	if is_left:
		# 左半圆：从底端 (PI/2) 逆时针 -> 左端 (PI) -> 到液面角度 a_fill_left
		for i in range(steps + 1):
			var t: float = float(i) / float(steps)
			var a: float = lerpf(PI * 0.5, a_fill_left, t)
			var x: float = center.x + cos(a) * radius
			var y: float = center.y + sin(a) * radius
			points.append(Vector2(x, y))
	else:
		# 右半圆：从底端 (PI/2) 顺时针 -> 右端 (0) -> 到液面角度 a_fill_right
		for i in range(steps + 1):
			var t: float = float(i) / float(steps)
			var a: float = lerpf(PI * 0.5, a_fill_right, t)
			var x: float = center.x + cos(a) * radius
			var y: float = center.y + sin(a) * radius
			points.append(Vector2(x, y))

	if points.size() >= 3:
		draw_colored_polygon(points, color)

	# 液面顶端的一点波纹（纯装饰）
	if ratio > 0.02 and ratio < 0.98:
		var wave_color: Color = color
		wave_color.a = 0.55
		var half_sign: float = -1.0 if is_left else 1.0
		var surface_half_width: float = sqrt(maxf(0.0, radius * radius - dy * dy))
		var wave_x_start: float = center.x
		var wave_x_end: float = center.x + half_sign * surface_half_width
		var samples: int = 18
		var last_p: Vector2 = Vector2(wave_x_start, fill_top_y)
		for i in range(1, samples + 1):
			var ft: float = float(i) / float(samples)
			var sx: float = lerpf(wave_x_start, wave_x_end, ft)
			var sy: float = fill_top_y + sin(_phase * 2.5 + ft * 6.0 + (0.0 if is_left else PI)) * 1.2
			var p: Vector2 = Vector2(sx, sy)
			draw_line(last_p, p, wave_color, 2.0, true)
			last_p = p
