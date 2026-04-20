extends Control

## 意识花苞：花苞显示 → 点击 → 绽放动画 → 切换到结算弹窗

# ------- 贴图设置（二选一） -------
## 方式一：在 Inspector 的 Bud Texture 里拖入你的花苞图
@export var bud_texture: Texture2D
## 方式二：把花苞图放到这个路径，脚本会自动加载
const BUD_TEXTURE_PATH := "res://assets/bud.png"

## 结算弹窗场景路径
const RESULT_SCENE_PATH := "res://scenes/reward/RewardResultScene.tscn"

# ------- 节点引用 -------
@onready var bud_display: TextureRect = $Center/BudDisplay
@onready var bud_button: Button = $Center/BudButton
@onready var fx_layer: Node2D = $FX
@onready var particles: CPUParticles2D = $FX/Particles
@onready var burst_particles: CPUParticles2D = $FX/BurstParticles
@onready var flash_overlay: ColorRect = $FlashOverlay
@onready var prompt_label: Label = $PromptLabel
@onready var title_label: Label = $TitleLabel

var _is_blooming: bool = false


func _ready() -> void:
	# 粒子贴图（动态生成柔和白色光斑）
	var soft_tex := _create_soft_particle_texture()
	particles.texture = soft_tex
	burst_particles.texture = soft_tex
	burst_particles.emitting = false

	# 花苞贴图：export -> 路径 -> 占位图
	_setup_bud_texture()

	# 初始状态
	flash_overlay.color.a = 0.0

	bud_button.pressed.connect(_on_bud_pressed)

	# 等一帧让布局稳定后设置 pivot，再对齐粒子
	await get_tree().process_frame
	bud_display.pivot_offset = bud_display.size / 2.0
	_align_fx_to_bud()
	get_viewport().size_changed.connect(_on_viewport_resized)

	# 淡入文字
	_fade_in(title_label, 0.6, 0.0)
	_fade_in(prompt_label, 0.6, 0.2)


func _setup_bud_texture() -> void:
	var tex: Texture2D = bud_texture
	if tex == null and ResourceLoader.exists(BUD_TEXTURE_PATH):
		tex = load(BUD_TEXTURE_PATH) as Texture2D
	if tex:
		bud_display.texture = tex
	else:
		# 连占位图都能保证看到一朵花苞轮廓
		bud_display.texture = _make_placeholder_bud_texture()


func _on_viewport_resized() -> void:
	bud_display.pivot_offset = bud_display.size / 2.0
	_align_fx_to_bud()


func _align_fx_to_bud() -> void:
	var center: Vector2 = bud_display.get_global_rect().get_center()
	fx_layer.global_position = center


# ------------------------------------------------------
# 点击花苞：滚奖励 → 绽放动画 → 切场景
# ------------------------------------------------------
func _on_bud_pressed() -> void:
	if _is_blooming:
		return
	_is_blooming = true
	bud_button.disabled = true

	# 1. 抽奖并应用到全局状态，结果文案存在 Game.last_bud_rewards
	Game.roll_bud_rewards()

	# 2. 播放绽放动画
	_fade_out(prompt_label, 0.3)
	await _bloom_animation()

	# 3. 切到结算弹窗
	await get_tree().create_timer(0.15).timeout
	get_tree().change_scene_to_file(RESULT_SCENE_PATH)


func _bloom_animation() -> void:
	bud_display.pivot_offset = bud_display.size / 2.0

	# Phase 1：轻微颤动，蓄势
	var phase1 := create_tween().set_trans(Tween.TRANS_SINE)
	phase1.tween_property(bud_display, "rotation", deg_to_rad(-5), 0.12)
	phase1.tween_property(bud_display, "rotation", deg_to_rad(5), 0.12)
	phase1.tween_property(bud_display, "rotation", deg_to_rad(-4), 0.12)
	phase1.tween_property(bud_display, "rotation", 0.0, 0.1)
	await phase1.finished

	# Phase 2：爆发粒子 + 放大 + 泛光
	_trigger_big_burst()
	var phase2 := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	phase2.tween_property(bud_display, "scale", Vector2(1.7, 1.7), 0.5)
	phase2.tween_property(bud_display, "modulate", Color(1.6, 1.5, 1.3, 1), 0.3)
	await phase2.finished

	# Phase 3：闪白覆盖并继续放大到消隐
	var phase3 := create_tween().set_parallel(true)
	phase3.tween_property(flash_overlay, "color:a", 1.0, 0.5).set_ease(Tween.EASE_IN)
	phase3.tween_property(bud_display, "scale", Vector2(2.5, 2.5), 0.5)
	phase3.tween_property(bud_display, "modulate:a", 0.0, 0.45)
	await phase3.finished


func _trigger_big_burst() -> void:
	burst_particles.restart()
	burst_particles.emitting = true


# ------------------------------------------------------
# 占位花苞贴图（没有美术素材时的兜底）
# ------------------------------------------------------
func _make_placeholder_bud_texture() -> ImageTexture:
	var w := 220
	var h := 280
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx: float = w / 2.0

	# 花苞主体
	for y in h:
		for x in w:
			var nx: float = (x - cx) / (w * 0.36)
			var ny: float = (y - h * 0.4) / (h * 0.42)
			var d: float = nx * nx + ny * ny
			if d < 1.0:
				var edge: float = clampf(1.0 - d, 0.0, 1.0)
				var shade: float = 0.38 + edge * 0.28
				img.set_pixel(x, y, Color(shade * 0.93, shade * 0.97, shade, 1.0))

	# 茎
	var stem_top: int = int(h * 0.7)
	var stem_bottom: int = int(h * 0.95)
	for y in range(stem_top, stem_bottom):
		for dx in range(-3, 4):
			var px: int = int(cx) + dx
			if px >= 0 and px < w:
				img.set_pixel(px, y, Color(0.3, 0.4, 0.33, 1.0))

	# 叶片（右侧）
	for y in range(int(h * 0.72), int(h * 0.88)):
		for x in range(int(cx + 4), int(cx + 36)):
			var dy_leaf: float = y - h * 0.8
			var dx_leaf: float = x - cx - 4
			if absf(dy_leaf) < 11 - dx_leaf * 0.26 and x < w:
				img.set_pixel(x, y, Color(0.33, 0.46, 0.36, 1.0))

	return ImageTexture.create_from_image(img)


# ------------------------------------------------------
# 工具：淡入淡出 + 粒子贴图
# ------------------------------------------------------
func _fade_in(node: CanvasItem, duration: float, delay: float = 0.0) -> void:
	node.modulate.a = 0.0
	var tw := create_tween()
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.tween_property(node, "modulate:a", 1.0, duration)


func _fade_out(node: CanvasItem, duration: float) -> void:
	var tw := create_tween()
	tw.tween_property(node, "modulate:a", 0.0, duration)


func _create_soft_particle_texture() -> ImageTexture:
	var size := 48
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size / 2.0, size / 2.0)
	var max_dist := float(size) / 2.0
	for y in size:
		for x in size:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(center)
			var a := clampf(1.0 - d / max_dist, 0.0, 1.0)
			a = pow(a, 2.2)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	return ImageTexture.create_from_image(img)
