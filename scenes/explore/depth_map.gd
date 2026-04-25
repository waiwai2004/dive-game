extends Control
## 深度剖面图 — 显示玩家所在深度层级的竖向地形图
## 右上角（雷达右侧）小尺寸，点击可放大至屏幕中心

# ── 地图常量 ──
const MAP_MAX_DEPTH := 4140.0  # Y=0 海面, Y=4140 最深

# ── 层级定义: [名称, Y上界, Y下界] ──
const DEPTH_LAYERS := [
	["海面", 0.0, 200.0],
	["第1层 · 浅海", 200.0, 1000.0],
	["第2层 · 中层", 1000.0, 2200.0],
	["第3层 · 深海", 2200.0, 3400.0],
	["第4层 · 海沟", 3400.0, 4140.0],
]

# ── 布局 ──
const SMALL_WIDTH := 44.0
const SMALL_HEIGHT := 120.0
const LARGE_WIDTH := 300.0
const LARGE_HEIGHT := 600.0
const MARGIN_RIGHT := 24.0
const MARGIN_TOP := 24.0
const RADAR_SMALL_SIZE := 120.0  # 需与雷达尺寸一致
const RADAR_LEFT_OFFSET := 80.0  # 与雷达一致的左偏移
const GAP := 8.0  # 与雷达间距

# ── 颜色 ──
const BG_COLOR := Color(0.02, 0.05, 0.15, 0.92)
const BORDER_COLOR := Color(0.2, 0.5, 0.9, 0.7)
const TERRAIN_LINE_COLOR := Color(0.3, 0.7, 1.0, 0.65)
const TERRAIN_FILL_COLOR := Color(0.08, 0.2, 0.4, 0.5)
const LAYER_LINE_COLOR := Color(0.25, 0.55, 0.85, 0.3)
const LABEL_COLOR := Color(0.5, 0.8, 1.0, 0.7)
const LABEL_COLOR_ACTIVE := Color(0.7, 1.0, 1.0, 1.0)
const PLAYER_MARKER_COLOR := Color(0.6, 1.0, 1.0, 0.95)
const PLAYER_GLOW_COLOR := Color(0.4, 0.85, 1.0, 0.35)
const DEPTH_TEXT_COLOR := Color(0.45, 0.75, 1.0, 0.55)
const OVERLAY_COLOR := Color(0.0, 0.0, 0.0, 0.6)

# ── 地形轮廓（归一化 0~1 坐标，左侧x=0 右侧x=1，上y=0 下y=1） ──
# 每个点是 (x_offset_normalized, y_depth_normalized)
# 模拟海底山峰地形
const TERRAIN_POINTS_LEFT: Array = [
	[0.0, 0.0],
	[0.0, 0.12],
	[0.05, 0.18],
	[0.15, 0.22],
	[0.08, 0.3],
	[0.2, 0.38],
	[0.35, 0.42],
	[0.25, 0.48],
	[0.1, 0.52],
	[0.18, 0.58],
	[0.3, 0.62],
	[0.45, 0.65],
	[0.35, 0.72],
	[0.15, 0.78],
	[0.25, 0.85],
	[0.4, 0.9],
	[0.3, 0.95],
	[0.2, 1.0],
	[0.0, 1.0],
]

const TERRAIN_POINTS_RIGHT: Array = [
	[1.0, 0.0],
	[1.0, 0.1],
	[0.9, 0.15],
	[0.8, 0.2],
	[0.88, 0.28],
	[0.75, 0.35],
	[0.65, 0.4],
	[0.72, 0.46],
	[0.85, 0.52],
	[0.78, 0.58],
	[0.6, 0.63],
	[0.55, 0.68],
	[0.68, 0.74],
	[0.82, 0.8],
	[0.7, 0.86],
	[0.58, 0.92],
	[0.65, 0.97],
	[0.75, 1.0],
	[1.0, 1.0],
]

# ── 状态 ──
var _expanded := false
var _animating := false
var _pulse_time := 0.0
var _overlay: ColorRect = null
var _tween: Tween = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_small_layout()


func _process(delta: float) -> void:
	_pulse_time += delta * 2.5
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	var pad_x := w * 0.1
	var pad_top := h * 0.04
	var pad_bottom := h * 0.03
	var draw_w := w - pad_x * 2.0
	var draw_h := h - pad_top - pad_bottom
	var draw_origin := Vector2(pad_x, pad_top)

	# 背景
	var bg_rect := Rect2(Vector2.ZERO, size)
	draw_rect(bg_rect, BG_COLOR)

	# 层级分隔虚线
	_draw_layer_lines(draw_origin, draw_w, draw_h)

	# 地形轮廓
	_draw_terrain(draw_origin, draw_w, draw_h)

	# 层级标注
	_draw_layer_labels(draw_origin, draw_w, draw_h)

	# 玩家深度标记
	_draw_player_marker(draw_origin, draw_w, draw_h)

	# 边框
	draw_rect(bg_rect, BORDER_COLOR, false, 1.5)


func _draw_layer_lines(origin: Vector2, w: float, h: float) -> void:
	for layer_data in DEPTH_LAYERS:
		var y_top: float = layer_data[1]
		var y_norm := y_top / MAP_MAX_DEPTH
		var draw_y := origin.y + y_norm * h
		if y_top <= 0.01:
			continue
		# 虚线
		var dash_len := 6.0
		var gap_len := 4.0
		var x := origin.x
		while x < origin.x + w:
			var x_end := minf(x + dash_len, origin.x + w)
			draw_line(Vector2(x, draw_y), Vector2(x_end, draw_y), LAYER_LINE_COLOR, 1.0)
			x += dash_len + gap_len


func _draw_terrain(origin: Vector2, w: float, h: float) -> void:
	# 左侧地形
	var left_points := PackedVector2Array()
	for pt in TERRAIN_POINTS_LEFT:
		left_points.append(Vector2(origin.x + pt[0] * w, origin.y + pt[1] * h))

	# 右侧地形
	var right_points := PackedVector2Array()
	for pt in TERRAIN_POINTS_RIGHT:
		right_points.append(Vector2(origin.x + pt[0] * w, origin.y + pt[1] * h))

	# 填充左侧地形多边形
	if left_points.size() >= 3:
		var fill_l := PackedVector2Array()
		fill_l.append(Vector2(origin.x, origin.y))
		for p in left_points:
			fill_l.append(p)
		fill_l.append(Vector2(origin.x, origin.y + h))
		var colors_l := PackedColorArray()
		for _i in range(fill_l.size()):
			colors_l.append(TERRAIN_FILL_COLOR)
		draw_polygon(fill_l, colors_l)

	# 填充右侧地形多边形
	if right_points.size() >= 3:
		var fill_r := PackedVector2Array()
		fill_r.append(Vector2(origin.x + w, origin.y))
		for p in right_points:
			fill_r.append(p)
		fill_r.append(Vector2(origin.x + w, origin.y + h))
		var colors_r := PackedColorArray()
		for _i in range(fill_r.size()):
			colors_r.append(TERRAIN_FILL_COLOR)
		draw_polygon(fill_r, colors_r)

	# 地形轮廓线
	if left_points.size() >= 2:
		draw_polyline(left_points, TERRAIN_LINE_COLOR, 1.5, true)
	if right_points.size() >= 2:
		draw_polyline(right_points, TERRAIN_LINE_COLOR, 1.5, true)


func _draw_layer_labels(origin: Vector2, w: float, h: float) -> void:
	var font := ThemeDB.fallback_font
	var font_size_small := 8 if not _expanded else 14
	var font_size_depth := 7 if not _expanded else 12
	var player := _get_player()
	var player_y := 0.0
	if player:
		player_y = player.global_position.y

	for i in range(DEPTH_LAYERS.size()):
		var layer_data: Array = DEPTH_LAYERS[i]
		var layer_name: String = layer_data[0]
		var y_top: float = layer_data[1]
		var y_bot: float = layer_data[2]
		var y_mid := (y_top + y_bot) * 0.5
		var y_norm := y_mid / MAP_MAX_DEPTH
		var draw_y := origin.y + y_norm * h

		# 判断玩家是否在此层
		var is_active := player_y >= y_top and player_y < y_bot
		var col: Color = LABEL_COLOR_ACTIVE if is_active else LABEL_COLOR

		if _expanded:
			# 放大时显示完整名称 + 深度范围
			var label_text := layer_name
			var text_size := font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size_small)
			var text_x := origin.x + (w - text_size.x) * 0.5
			draw_string(font, Vector2(text_x, draw_y + 4.0), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size_small, col)

			# 深度数值
			var depth_text := "%dm ~ %dm" % [int(y_top), int(y_bot)]
			var depth_size := font.get_string_size(depth_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size_depth)
			var depth_x := origin.x + (w - depth_size.x) * 0.5
			draw_string(font, Vector2(depth_x, draw_y + 20.0), depth_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size_depth, DEPTH_TEXT_COLOR)
		else:
			# 小模式只显示层号
			var short_label := "L%d" % (i + 1) if i > 0 else "海面"
			var text_size := font.get_string_size(short_label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size_small)
			var text_x := origin.x + (w - text_size.x) * 0.5
			draw_string(font, Vector2(text_x, draw_y + 3.0), short_label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size_small, col)


func _draw_player_marker(origin: Vector2, w: float, h: float) -> void:
	var player := _get_player()
	if not player:
		return

	var depth_norm := clampf(player.global_position.y / MAP_MAX_DEPTH, 0.0, 1.0)
	var marker_y := origin.y + depth_norm * h
	var marker_x := origin.x + w * 0.5

	var pulse := (sin(_pulse_time) + 1.0) * 0.5  # 0~1
	var glow_r := 8.0 + pulse * 4.0
	var marker_r := 3.5 if not _expanded else 5.0

	# 发光
	draw_circle(Vector2(marker_x, marker_y), glow_r, PLAYER_GLOW_COLOR)

	# 小三角（朝右）
	var tri_size := marker_r * 2.0
	var tri := PackedVector2Array([
		Vector2(marker_x + tri_size, marker_y),
		Vector2(marker_x - tri_size * 0.5, marker_y - tri_size * 0.7),
		Vector2(marker_x - tri_size * 0.5, marker_y + tri_size * 0.7),
	])
	draw_polygon(tri, PackedColorArray([PLAYER_MARKER_COLOR, PLAYER_MARKER_COLOR, PLAYER_MARKER_COLOR]))

	# 放大模式：显示精确深度
	if _expanded:
		var font := ThemeDB.fallback_font
		var depth_val := int(player.global_position.y)
		var text := "深度: %dm" % depth_val
		draw_string(font, Vector2(marker_x + tri_size + 6.0, marker_y + 5.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, PLAYER_MARKER_COLOR)


func _get_player() -> CharacterBody2D:
	var p = get_tree().get_first_node_in_group("player")
	if p is CharacterBody2D:
		return p
	return null


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

	if has_node("/root/Game"):
		Game.in_dialogue = true

	# 遮罩
	_overlay = ColorRect.new()
	_overlay.color = OVERLAY_COLOR
	_overlay.anchor_right = 1.0
	_overlay.anchor_bottom = 1.0
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.z_index = z_index - 1
	get_parent().add_child(_overlay)
	get_parent().move_child(_overlay, get_index())
	_overlay.gui_input.connect(_on_overlay_input)

	var target_size := Vector2(LARGE_WIDTH, LARGE_HEIGHT)
	var screen_center := Vector2(1920.0 * 0.5, 1080.0 * 0.5)
	var target_pos := screen_center - target_size * 0.5

	z_index = 50

	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(self, "position", target_pos, 0.35)
	_tween.tween_property(self, "size", target_size, 0.35)
	_tween.chain().tween_callback(_on_expand_done)


func _on_expand_done() -> void:
	_animating = false
	queue_redraw()


func _collapse() -> void:
	if not _expanded or _animating:
		return
	_animating = true
	_expanded = false

	if _overlay:
		_overlay.queue_free()
		_overlay = null

	var target_size := Vector2(SMALL_WIDTH, SMALL_HEIGHT)
	var target_pos := _get_small_position()

	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(self, "position", target_pos, 0.3)
	_tween.tween_property(self, "size", target_size, 0.3)
	_tween.chain().tween_callback(_on_collapse_done)


func _on_collapse_done() -> void:
	z_index = 0
	_animating = false

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
	size = Vector2(SMALL_WIDTH, SMALL_HEIGHT)
	queue_redraw()


func _get_small_position() -> Vector2:
	# 雷达右侧
	var radar_right := 1920.0 - RADAR_SMALL_SIZE - MARGIN_RIGHT - RADAR_LEFT_OFFSET + RADAR_SMALL_SIZE + GAP
	return Vector2(radar_right, MARGIN_TOP)
