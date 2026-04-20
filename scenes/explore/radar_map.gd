extends Control
## 雷达地图 — 圆形扫描雷达，显示玩家在探索地图中的位置
## 右上角小尺寸显示，点击可放大至屏幕中心

# ── 地图常量 ──
const MAP_CENTER := Vector2(2880.0, 2160.0)
const MAP_HALF_SIZE := Vector2(2880.0, 2160.0)

# ── 布局 ──
const SMALL_SIZE := 120.0
const LARGE_SIZE := 500.0
const MARGIN_RIGHT := 24.0
const MARGIN_LEFT_OFFSET := 80.0  # 向左偏移
const MARGIN_TOP := 24.0

# ── 扫描周期 ──
const SCAN_INTERVAL := 10.0   # 每 10 秒扫描一次
const SCAN_DURATION := 2.0    # 扫描线旋转 360° 用时
const DOT_SHOW_DURATION := 5.0 # 红点显示持续时间
const DOT_FADE_DURATION := 1.0 # 红点淡出时间

# ── 颜色 ──
const BG_COLOR := Color(0.02, 0.04, 0.02, 0.92)
const RING_COLOR := Color(0.15, 0.55, 0.15, 0.6)
const BORDER_COLOR := Color(0.2, 0.7, 0.2, 0.85)
const CROSSHAIR_COLOR := Color(0.12, 0.4, 0.12, 0.35)
const TICK_COLOR := Color(0.18, 0.6, 0.18, 0.5)
const SWEEP_COLOR := Color(0.3, 1.0, 0.3, 0.7)
const TRAIL_COLOR := Color(0.15, 0.6, 0.15, 0.25)
const CENTER_DOT_COLOR := Color(0.6, 1.0, 0.6, 0.9)
const PLAYER_DOT_COLOR := Color(1.0, 0.15, 0.15, 1.0)
const OVERLAY_COLOR := Color(0.0, 0.0, 0.0, 0.6)

# ── 状态 ──
var _radar_radius := SMALL_SIZE * 0.5
var _expanded := false
var _animating := false

# 扫描状态
var _scan_timer := 0.0
var _scanning := false
var _scan_angle := 0.0  # 弧度, 0 = 12点钟方向

# 红点状态
var _show_dot := false
var _dot_timer := 0.0
var _dot_alpha := 1.0
var _player_radar_pos := Vector2.ZERO

# 遮罩
var _overlay: ColorRect = null

# 缓存
var _tween: Tween = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_small_layout()
	# 开始第一次扫描倒计时
	_scan_timer = SCAN_INTERVAL


func _process(delta: float) -> void:
	_update_scan(delta)
	_update_dot(delta)

	if _scanning:
		queue_redraw()
	elif _show_dot:
		queue_redraw()


func _update_scan(delta: float) -> void:
	if _scanning:
		_scan_angle += (TAU / SCAN_DURATION) * delta
		if _scan_angle >= TAU:
			_scan_angle = 0.0
			_scanning = false
			_trigger_dot_display()
		return

	_scan_timer -= delta
	if _scan_timer <= 0.0:
		_scanning = true
		_scan_angle = 0.0
		_scan_timer = SCAN_INTERVAL


func _update_dot(delta: float) -> void:
	if not _show_dot:
		return

	# 实时更新玩家位置映射
	_update_player_radar_pos()

	_dot_timer -= delta
	if _dot_timer <= 0.0:
		_show_dot = false
		_dot_alpha = 0.0
		queue_redraw()
		return

	# 淡出
	if _dot_timer < DOT_FADE_DURATION:
		_dot_alpha = _dot_timer / DOT_FADE_DURATION
	else:
		_dot_alpha = 1.0


func _trigger_dot_display() -> void:
	_show_dot = true
	_dot_timer = DOT_SHOW_DURATION
	_dot_alpha = 1.0
	_update_player_radar_pos()
	queue_redraw()


func _update_player_radar_pos() -> void:
	var player := _get_player()
	if not player:
		_player_radar_pos = Vector2.ZERO
		return

	var offset := player.global_position - MAP_CENTER
	var mapped := Vector2(
		offset.x / MAP_HALF_SIZE.x,
		offset.y / MAP_HALF_SIZE.y
	) * (_radar_radius * 0.85)

	# 限制在雷达圆内
	if mapped.length() > _radar_radius * 0.9:
		mapped = mapped.normalized() * _radar_radius * 0.9

	_player_radar_pos = mapped


func _get_player() -> CharacterBody2D:
	var p = get_tree().get_first_node_in_group("player")
	if p is CharacterBody2D:
		return p
	return null


# ── 绘制 ──

func _draw() -> void:
	var cx := size.x * 0.5
	var cy := size.y * 0.5
	var c := Vector2(cx, cy)
	var r := _radar_radius

	# 背景圆
	draw_circle(c, r, BG_COLOR)

	# 同心圆环 (5 圈)
	for i in range(1, 6):
		var ring_r := r * (float(i) / 5.0)
		_draw_circle_arc(c, ring_r, 0, TAU, RING_COLOR, 2.0)

	# 十字准线
	draw_line(Vector2(cx - r, cy), Vector2(cx + r, cy), CROSSHAIR_COLOR, 1.5)
	draw_line(Vector2(cx, cy - r), Vector2(cx, cy + r), CROSSHAIR_COLOR, 1.5)

	# 边缘刻度 (每 30°)
	for i in range(12):
		var angle := float(i) * (TAU / 12.0) - PI * 0.5
		var inner := c + Vector2(cos(angle), sin(angle)) * (r * 0.9)
		var outer := c + Vector2(cos(angle), sin(angle)) * r
		draw_line(inner, outer, TICK_COLOR, 2.5)

	# 扫描扇形
	if _scanning:
		_draw_sweep(c, r)

	# 边框环
	_draw_circle_arc(c, r, 0, TAU, BORDER_COLOR, 3.0)

	# 中心点
	draw_circle(c, 2.5, CENTER_DOT_COLOR)

	# 玩家红点
	if _show_dot and _dot_alpha > 0.01:
		var dot_pos := c + _player_radar_pos
		var dot_color := Color(PLAYER_DOT_COLOR.r, PLAYER_DOT_COLOR.g, PLAYER_DOT_COLOR.b, _dot_alpha)
		var dot_r := 4.0 if _expanded else 3.0
		draw_circle(dot_pos, dot_r + 2.0, Color(dot_color.r, dot_color.g, dot_color.b, dot_color.a * 0.3))
		draw_circle(dot_pos, dot_r, dot_color)

		# 坐标文字 (放大模式下)
		if _expanded:
			var player := _get_player()
			if player:
				var px := int(player.global_position.x)
				var py := int(player.global_position.y)
				var text := "(%d, %d)" % [px, py]
				var font := ThemeDB.fallback_font
				var font_size := 14
				var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
				var text_pos := dot_pos + Vector2(-text_size.x * 0.5, -dot_r - 6.0)
				draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, dot_color)


func _draw_sweep(center: Vector2, radius: float) -> void:
	# 扫描角度（从 12 点钟开始，顺时针）
	var sweep_angle := _scan_angle - PI * 0.5
	var trail_arc := PI * 0.25  # 拖影弧度

	# 绘制扇形拖影 (多个三角形)
	var segments := 24
	for i in range(segments):
		var t := float(i) / float(segments)
		var a0 := sweep_angle - trail_arc * t
		var a1 := sweep_angle - trail_arc * (t + 1.0 / float(segments))
		var alpha := (1.0 - t) * TRAIL_COLOR.a
		var col := Color(TRAIL_COLOR.r, TRAIL_COLOR.g, TRAIL_COLOR.b, alpha)
		var p0 := center
		var p1 := center + Vector2(cos(a0), sin(a0)) * radius
		var p2 := center + Vector2(cos(a1), sin(a1)) * radius
		draw_polygon(PackedVector2Array([p0, p1, p2]), PackedColorArray([col, col, col]))

	# 扫描线
	var line_end := center + Vector2(cos(sweep_angle), sin(sweep_angle)) * radius
	draw_line(center, line_end, SWEEP_COLOR, 3.0)


func _draw_circle_arc(center: Vector2, radius: float, angle_from: float, angle_to: float, color: Color, width: float) -> void:
	var nb_points := 64
	var points := PackedVector2Array()
	for i in range(nb_points + 1):
		var angle := angle_from + float(i) * (angle_to - angle_from) / float(nb_points)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	for i in range(nb_points):
		draw_line(points[i], points[i + 1], color, width)


# ── 交互 ──

func _gui_input(event: InputEvent) -> void:
	if _animating:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not _expanded:
			_expand()
			get_viewport().set_input_as_handled()


func _expand() -> void:
	if _expanded or _animating:
		return
	_animating = true
	_expanded = true

	# 锁定玩家移动
	if has_node("/root/Game"):
		Game.in_dialogue = true

	# 创建遮罩
	_overlay = ColorRect.new()
	_overlay.color = OVERLAY_COLOR
	_overlay.anchor_right = 1.0
	_overlay.anchor_bottom = 1.0
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.z_index = z_index - 1
	get_parent().add_child(_overlay)
	get_parent().move_child(_overlay, get_index())
	_overlay.gui_input.connect(_on_overlay_input)

	# 保存原始位置
	var target_size := Vector2(LARGE_SIZE, LARGE_SIZE)
	var screen_center := Vector2(1920.0 * 0.5, 1080.0 * 0.5)
	var target_pos := screen_center - target_size * 0.5

	# 提升 z_index
	z_index = 50

	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(self, "position", target_pos, 0.35)
	_tween.tween_property(self, "size", target_size, 0.35)
	_tween.chain().tween_callback(_on_expand_done)


func _on_expand_done() -> void:
	_radar_radius = LARGE_SIZE * 0.5
	_animating = false
	queue_redraw()


func _collapse() -> void:
	if not _expanded or _animating:
		return
	_animating = true
	_expanded = false

	# 移除遮罩
	if _overlay:
		_overlay.queue_free()
		_overlay = null

	var target_size := Vector2(SMALL_SIZE, SMALL_SIZE)
	var target_pos := _get_small_position()

	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(self, "position", target_pos, 0.3)
	_tween.tween_property(self, "size", target_size, 0.3)
	_tween.chain().tween_callback(_on_collapse_done)


func _on_collapse_done() -> void:
	_radar_radius = SMALL_SIZE * 0.5
	z_index = 0
	_animating = false

	# 恢复玩家移动
	if has_node("/root/Game"):
		Game.in_dialogue = false

	queue_redraw()


func _on_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_collapse()
		get_viewport().set_input_as_handled()


# ── 布局 ──

func _apply_small_layout() -> void:
	var pos := _get_small_position()
	position = pos
	size = Vector2(SMALL_SIZE, SMALL_SIZE)
	_radar_radius = SMALL_SIZE * 0.5
	queue_redraw()


func _get_small_position() -> Vector2:
	return Vector2(1920.0 - SMALL_SIZE - MARGIN_RIGHT - MARGIN_LEFT_OFFSET, MARGIN_TOP)
