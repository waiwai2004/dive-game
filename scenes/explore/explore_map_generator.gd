## 探索地图生成器
## 负责程序化生成所有探索区域节点（记忆回声、战斗区域、伤口Boss、意识花苞、认知废墟）。
class_name ExploreMapGenerator

const MAP_WIDTH := 2880.0
const MAP_HEIGHT := 1880.0
const GROUND_Y := 1700.0
const SPAWN_MARGIN := 150.0
const MIN_ENTITY_DISTANCE := 200.0
const PLAYER_SAFE_RADIUS := 300.0
const PLAYER_START := Vector2(130, 310)
const NON_BOSS_NODE_SCALE := 0.5

const MEMORY_ECHO_SCRIPT := preload("res://scenes/explore/memory_echo.gd")
const POLLUTION_NODE_FRAMES := preload("res://assets/art/explore/pollution_frames.tres")
const BUD_NODE_FRAMES := preload("res://assets/art/explore/bud_frames.tres")
const RUINS_HINT_NODE_FRAMES := preload("res://assets/art/explore/ruins_frames.tres")
const WOUND_NODE_FRAMES := preload("res://assets/art/explore/wound_frames.tres")
const WOUND_NODE_SCRIPT := preload("res://scenes/explore/wound_node.gd")
const BUD_NODE_SCRIPT := preload("res://scenes/explore/consciousness_bud_node.gd")
const RUINS_NODE_SCRIPT := preload("res://scenes/explore/cognitive_ruins_node.gd")


## 在已有位置列表基础上生成指定数量的随机位置。
static func generate_spawn_positions(count: int, occupied_positions: Array) -> Array:
	var positions: Array = []
	var max_attempts := count * 100
	var attempts := 0

	while positions.size() < count and attempts < max_attempts:
		attempts += 1
		var pos := Vector2(
			randf_range(SPAWN_MARGIN, MAP_WIDTH - SPAWN_MARGIN),
			randf_range(SPAWN_MARGIN, GROUND_Y - 200)
		)

		if pos.distance_to(PLAYER_START) < PLAYER_SAFE_RADIUS:
			continue

		var too_close := false
		for occ_pos in occupied_positions:
			if pos.distance_to(occ_pos) < MIN_ENTITY_DISTANCE:
				too_close = true
				break

		if not too_close:
			for p in positions:
				if pos.distance_to(p) < MIN_ENTITY_DISTANCE:
					too_close = true
					break

		if not too_close:
			positions.append(pos)
			occupied_positions.append(pos)

	return positions


## 为伤口Boss生成一个靠近底部的位置。
static func generate_wound_position(occupied_positions: Array) -> Vector2:
	var bottom_top := GROUND_Y - 600.0
	var bottom_bottom := GROUND_Y - 100.0
	var max_attempts := 100

	for i in range(max_attempts):
		var pos := Vector2(
			randf_range(SPAWN_MARGIN + 300.0, MAP_WIDTH - SPAWN_MARGIN - 300.0),
			randf_range(bottom_top, bottom_bottom)
		)
		var too_close := false
		for occ_pos in occupied_positions:
			if pos.distance_to(occ_pos) < MIN_ENTITY_DISTANCE * 1.5:
				too_close = true
				break
		if not too_close:
			occupied_positions.append(pos)
			return pos

	var fallback := Vector2(MAP_WIDTH * 0.5, bottom_top + 250.0)
	occupied_positions.append(fallback)
	return fallback


static func create_animated_sprite_from_frames(frames: SpriteFrames) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.name = "Sprite2D"
	sprite.sprite_frames = frames
	sprite.animation = &"default"
	sprite.play()
	return sprite


static func get_first_frame_from_frames(frames: SpriteFrames) -> Texture2D:
	if frames and frames.has_animation(&"default") and frames.get_frame_count(&"default") > 0:
		return frames.get_frame_texture(&"default", 0)
	return null


static func create_memory_echo(pos: Vector2) -> Area2D:
	var echo := Area2D.new()
	echo.position = pos
	echo.set_script(MEMORY_ECHO_SCRIPT)

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(320, 520) * NON_BOSS_NODE_SCALE
	col.shape = shape
	echo.add_child(col)

	var sprite := create_animated_sprite_from_frames(RUINS_HINT_NODE_FRAMES)
	sprite.scale = Vector2(0.48, 0.48)
	echo.add_child(sprite)

	var highlight := Sprite2D.new()
	highlight.name = "Highlight"
	highlight.texture = get_first_frame_from_frames(RUINS_HINT_NODE_FRAMES)
	highlight.scale = Vector2(0.56, 0.56)
	highlight.self_modulate = Color(0.75, 0.95, 1.0, 0.78)
	highlight.visible = false
	echo.add_child(highlight)
	apply_texture_contour_collision(echo, RUINS_HINT_NODE_FRAMES, sprite.scale)

	return echo


static func create_battle_zone(pos: Vector2) -> Area2D:
	var zone := Area2D.new()
	zone.position = pos

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(160, 156)
	col.shape = shape
	zone.add_child(col)

	var sprite := create_animated_sprite_from_frames(POLLUTION_NODE_FRAMES)
	sprite.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
	sprite.scale = Vector2(1.25, 1.25)
	zone.add_child(sprite)

	var highlight := Sprite2D.new()
	highlight.name = "Highlight"
	highlight.texture = get_first_frame_from_frames(POLLUTION_NODE_FRAMES)
	highlight.self_modulate = Color(1.0, 0.45, 0.45, 0.85)
	highlight.scale = Vector2(1.45, 1.45)
	highlight.visible = false
	zone.add_child(highlight)
	apply_texture_contour_collision(zone, POLLUTION_NODE_FRAMES, sprite.scale)

	return zone


static func create_wound_node(pos: Vector2) -> Area2D:
	var wound := Area2D.new()
	wound.name = "WoundBoss"
	wound.position = pos
	wound.set_script(WOUND_NODE_SCRIPT)
	wound.set_meta("battle_index", 3)
	wound.set_meta("enemy_id", "black_bubble")
	wound.monitoring = true
	wound.monitorable = true
	wound.collision_layer = 1
	wound.collision_mask = 1

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(350.0, 350.0)
	col.shape = shape
	wound.add_child(col)

	var sprite := create_animated_sprite_from_frames(WOUND_NODE_FRAMES)
	sprite.scale = Vector2(1.18, 1.18)
	wound.add_child(sprite)

	var highlight := Sprite2D.new()
	highlight.name = "Highlight"
	highlight.texture = get_first_frame_from_frames(WOUND_NODE_FRAMES)
	highlight.self_modulate = Color(1.0, 0.25, 0.25, 0.82)
	highlight.scale = Vector2(1.32, 1.32)
	highlight.visible = false
	wound.add_child(highlight)

	return wound


static func create_consciousness_bud(pos: Vector2) -> Area2D:
	var bud := Area2D.new()
	bud.position = pos
	bud.set_script(BUD_NODE_SCRIPT)
	bud.monitoring = true
	bud.monitorable = true
	bud.collision_layer = 1
	bud.collision_mask = 1

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(250.0, 300.0) * NON_BOSS_NODE_SCALE
	col.shape = shape
	bud.add_child(col)

	var sprite := create_animated_sprite_from_frames(BUD_NODE_FRAMES)
	sprite.scale = Vector2(0.21, 0.21)
	bud.add_child(sprite)

	var highlight := Sprite2D.new()
	highlight.name = "Highlight"
	highlight.texture = get_first_frame_from_frames(BUD_NODE_FRAMES)
	highlight.self_modulate = Color(1.0, 0.82, 1.0, 0.82)
	highlight.scale = Vector2(0.245, 0.245)
	highlight.visible = false
	bud.add_child(highlight)
	apply_texture_contour_collision(bud, BUD_NODE_FRAMES, sprite.scale)

	return bud


static func create_cognitive_ruins(pos: Vector2) -> Area2D:
	var ruins := Area2D.new()
	ruins.position = pos
	ruins.set_script(RUINS_NODE_SCRIPT)
	ruins.monitoring = true
	ruins.monitorable = true
	ruins.collision_layer = 1
	ruins.collision_mask = 1

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(300.0, 300.0) * NON_BOSS_NODE_SCALE
	col.shape = shape
	ruins.add_child(col)

	var sprite := create_animated_sprite_from_frames(RUINS_HINT_NODE_FRAMES)
	sprite.scale = Vector2(0.52, 0.52)
	ruins.add_child(sprite)

	var highlight := Sprite2D.new()
	highlight.name = "Highlight"
	highlight.texture = get_first_frame_from_frames(RUINS_HINT_NODE_FRAMES)
	highlight.self_modulate = Color(0.75, 0.95, 1.0, 0.78)
	highlight.scale = Vector2(0.6, 0.6)
	highlight.visible = false
	ruins.add_child(highlight)
	apply_texture_contour_collision(ruins, RUINS_HINT_NODE_FRAMES, sprite.scale)

	return ruins


## 为区域节点应用基于纹理轮廓的碰撞多边形
static func apply_texture_contour_collision(zone: Area2D, frames: SpriteFrames, sprite_scale: Vector2) -> void:
	var texture := get_first_frame_from_frames(frames)
	if texture == null:
		return
	var image := texture.get_image()
	if image == null:
		return

	var collision := zone.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision:
		collision.disabled = true

	var old_polygon := zone.get_node_or_null("ContourCollision")
	if old_polygon:
		old_polygon.queue_free()

	var polygon := build_texture_contour_polygon(image, sprite_scale)
	if polygon.size() < 3:
		return

	var contour_collision := CollisionPolygon2D.new()
	contour_collision.name = "ContourCollision"
	contour_collision.polygon = polygon
	zone.add_child(contour_collision)


## 通过射线投射构建纹理轮廓多边形
static func build_texture_contour_polygon(image: Image, sprite_scale: Vector2) -> PackedVector2Array:
	var image_size := Vector2(image.get_width(), image.get_height())
	if image_size.x <= 0.0 or image_size.y <= 0.0:
		return PackedVector2Array()

	var center := image_size * 0.5
	var max_radius := image_size.length() * 0.5
	var points := PackedVector2Array()
	var ray_count := 56
	var step_size := 3.0

	for ray_index in range(ray_count):
		var angle := TAU * float(ray_index) / float(ray_count)
		var dir := Vector2(cos(angle), sin(angle))
		var last_visible := center
		var has_visible := false
		var distance := 0.0
		while distance <= max_radius:
			var pixel_pos := center + dir * distance
			if pixel_pos.x < 0.0 or pixel_pos.y < 0.0 or pixel_pos.x >= image_size.x or pixel_pos.y >= image_size.y:
				break
			if is_visible_texture_pixel(image, int(pixel_pos.x), int(pixel_pos.y)):
				last_visible = pixel_pos
				has_visible = true
			distance += step_size
		if has_visible:
			points.append((last_visible - center) * sprite_scale)

	return points


static func is_visible_texture_pixel(image: Image, x: int, y: int) -> bool:
	var color := image.get_pixel(x, y)
	var brightness := maxf(color.r, maxf(color.g, color.b))
	return color.a > 0.08 and brightness > 0.03
