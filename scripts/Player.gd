# 玩家脚本，处理玩家移动、动画和交互
extends CharacterBody2D

@export var speed: float = 600.0
@export var left_margin: float = 100.0
@export var right_margin: float = 100.0

@onready var shadow: Sprite2D = get_node_or_null("Shadow") as Sprite2D
@onready var idle_sprite: Sprite2D = $IdleSprite
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = get_node_or_null("Camera2D")

var min_x: float = 0.0
var max_x: float = 0.0
var use_bounds: bool = false

var shadow_base_scale: Vector2 = Vector2(0.15, 0.08)
var shadow_time: float = 0.0

func _ready() -> void:
	if shadow != null:
		shadow.scale = shadow_base_scale
		shadow.modulate.a = 0.45

	idle_sprite.visible = true
	anim.visible = false
	anim.stop()
	anim.frame = 0

	# 抵消子节点的偏移量
	if camera != null and idle_sprite != null:
		# 获取人物图片相对于 Player 根节点的 X 偏移量
		var offset_x: float = idle_sprite.position.x
		
		# 使用相机的绝对物理边界，减去图片的偏移量，才是根节点真正应该停下的位置！
		min_x = camera.limit_left - offset_x + left_margin
		max_x = camera.limit_right - offset_x - right_margin
		use_bounds = true

func _physics_process(delta: float) -> void:
	# 防对话移动
	if GameManager.in_dialogue:
		velocity = Vector2.ZERO
		_update_animation(0.0)
		move_and_slide()
		return

	var dir := Input.get_axis("move_left", "move_right")
	velocity = Vector2(dir * speed, 0.0)
	move_and_slide()

	# 应用修正偏移后的绝对边界
	if use_bounds:
		global_position.x = clamp(global_position.x, min_x, max_x)

	_update_shadow(delta, dir)
	_update_animation(dir)

func _update_animation(dir: float) -> void:
	if dir > 0:
		idle_sprite.visible = false
		anim.visible = true
		idle_sprite.flip_h = false
		anim.flip_h = false
		if anim.animation != "run":
			anim.play("run")
		elif not anim.is_playing():
			anim.play("run")
	elif dir < 0:
		idle_sprite.visible = false
		anim.visible = true
		idle_sprite.flip_h = true
		anim.flip_h = true
		if anim.animation != "run":
			anim.play("run")
		elif not anim.is_playing():
			anim.play("run")
	else:
		anim.stop()
		anim.visible = false
		idle_sprite.visible = true

func _update_shadow(delta: float, dir: float) -> void:
	if shadow == null:
		return
	shadow_time += delta
	if abs(dir) > 0.01:
		var pulse: float = sin(shadow_time * 10.0) * 0.04
		shadow.scale.x = shadow_base_scale.x + pulse
		shadow.scale.y = shadow_base_scale.y - pulse * 0.5
		shadow.modulate.a = 0.5
	else:
		shadow.scale = shadow_base_scale
		shadow.modulate.a = 0.45

func _on_npc_zone_body_entered(_body: Node2D) -> void:
	pass

func _on_npc_zone_body_exited(_body: Node2D) -> void:
	pass
