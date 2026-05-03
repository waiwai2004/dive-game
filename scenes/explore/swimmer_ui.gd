extends Node2D

@export var swim_speed: float = 5.0
@export var body_scale: float = 0.82

var _time: float = 0.0


func _ready() -> void:
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta * swim_speed
	queue_redraw()


func _draw() -> void:
	var wave := sin(_time)
	var wave_alt := sin(_time + PI * 0.65)
	var suit := Color(0.92, 0.86, 0.72, 1.0)
	var suit_shadow := Color(0.72, 0.65, 0.53, 1.0)
	var outline := Color(0.05, 0.10, 0.12, 1.0)
	var brass := Color(0.72, 0.42, 0.11, 1.0)
	var glass := Color(0.42, 0.62, 0.68, 0.9)
	var tank := Color(0.58, 0.34, 0.09, 1.0)
	var tube := Color(0.09, 0.13, 0.15, 1.0)

	draw_set_transform(Vector2.ZERO, deg_to_rad(-16.0 + wave * 2.0), Vector2.ONE * body_scale)

	# trailing bubbles
	for bubble_index in range(3):
		var bubble_offset := Vector2(-84.0 - bubble_index * 20.0, -14.0 + sin(_time + bubble_index) * 6.0)
		draw_circle(bubble_offset, 3.0 - bubble_index * 0.4, Color(0.65, 0.9, 1.0, 0.35))

	# rear air tank and hose
	draw_line(Vector2(-12, -28), Vector2(58, -36), tube, 10.0, true)
	draw_line(Vector2(58, -36), Vector2(72, 8), tube, 10.0, true)
	_draw_box(Rect2(Vector2(36, -24), Vector2(22, 70)), tank)
	_draw_box(Rect2(Vector2(36, -24), Vector2(22, 70)), outline, false, 4.0)

	# torso and helmet
	_draw_ellipse_poly(Vector2(-5, 10), Vector2(42, 28), outline)
	_draw_ellipse_poly(Vector2(-5, 10), Vector2(37, 24), suit)
	_draw_ellipse_poly(Vector2(22, -30), Vector2(35, 35), outline)
	_draw_ellipse_poly(Vector2(22, -30), Vector2(30, 30), suit)
	draw_circle(Vector2(43, -45), 7.0, brass)
	draw_circle(Vector2(43, -45), 4.0, Color(0.45, 0.24, 0.06, 1.0))

	# helmet window
	draw_circle(Vector2(21, -28), 18.0, outline)
	draw_circle(Vector2(21, -28), 14.0, glass)
	draw_line(Vector2(14, -36), Vector2(26, -47), Color(0.85, 0.96, 1.0, 0.7), 3.0, true)
	draw_line(Vector2(21, -33), Vector2(31, -43), Color(0.85, 0.96, 1.0, 0.45), 2.0, true)

	# belt and straps
	draw_line(Vector2(-38, 7), Vector2(23, 15), Color(0.33, 0.16, 0.08, 1.0), 8.0, true)
	draw_rect(Rect2(Vector2(-7, 8), Vector2(16, 11)), brass)
	draw_line(Vector2(-25, -14), Vector2(-19, 22), Color(0.32, 0.15, 0.08, 1.0), 7.0, true)
	draw_line(Vector2(14, -4), Vector2(7, 24), Color(0.32, 0.15, 0.08, 1.0), 7.0, true)

	# arms
	var front_hand := Vector2(39.0 + wave * 5.0, 25.0 + wave * 7.0)
	_draw_limb(Vector2(18, 4), front_hand, 9.0, outline, suit)
	var back_hand := Vector2(-54.0, 10.0 + wave_alt * 7.0)
	_draw_limb(Vector2(-32, 0), back_hand, 8.0, outline, suit_shadow)

	# legs and swim kick
	var front_foot := Vector2(-54.0, 52.0 + wave * 12.0)
	var back_foot := Vector2(-80.0, 36.0 + wave_alt * 12.0)
	_draw_limb(Vector2(-18, 28), front_foot, 11.0, outline, suit)
	_draw_limb(Vector2(-38, 23), back_foot, 10.0, outline, suit_shadow)

	# small nose lamp direction cue
	var lamp_start := Vector2(50, -25)
	draw_line(lamp_start, lamp_start + Vector2(22, -2), Color(0.75, 0.93, 1.0, 0.55), 3.0, true)


func _draw_limb(start: Vector2, finish: Vector2, width: float, outline_color: Color, fill_color: Color) -> void:
	draw_line(start, finish, outline_color, width + 4.0, true)
	draw_line(start, finish, fill_color, width, true)
	draw_circle(finish, width * 0.55, outline_color)
	draw_circle(finish, width * 0.38, fill_color)


func _draw_ellipse_poly(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for point_index in range(36):
		var angle := TAU * float(point_index) / 36.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)


func _draw_box(rect: Rect2, color: Color, filled: bool = true, width: float = 1.0) -> void:
	if filled:
		draw_rect(rect, color, true)
	else:
		draw_rect(rect, color, false, width)