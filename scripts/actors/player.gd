extends CharacterBody2D

@export var speed: float = 250.0
@export var left_margin: float = 100.0
@export var right_margin: float = 100.0

@onready var shadow = $Shadow
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var idle_sprite: Sprite2D = $IdleSprite
@onready var camera: Camera2D = $Camera2D

var min_x: float = 0.0
var max_x: float = 0.0
var use_bounds: bool = false

func _ready():
	add_to_group("player")
	
	# 初始默认待机
	idle_sprite.visible = true
	animated_sprite.visible = false
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("run"):
		animated_sprite.play("run")
		
	# 延迟一帧初始化边界，确保场景和相机都已完全就绪
	call_deferred("_setup_camera_bounds")

func _setup_camera_bounds() -> void:
	if camera == null:
		print("[警告] BasePlayer 未找到 Camera2D，边界限制无法生效！")
		return

	# 获取人物图片相对于 Player 根节点的 X 偏移量
	var offset_x: float = idle_sprite.position.x
	
	# 使用相机的绝对物理边界减去图片的偏移量，得出真正的活动范围
	min_x = camera.limit_left - offset_x + left_margin
	max_x = camera.limit_right - offset_x - right_margin
	use_bounds = true
	
	print("--- Base Player 边界已成功限制 ---")
	print("相机极限: ", camera.limit_left, " 到 ", camera.limit_right)
	print("图片偏移: ", offset_x)
	print("最终限制: ", min_x, " 到 ", max_x)

func _physics_process(_delta):
	# 防对话移动
	if Game.in_dialogue:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_visual(0.0)
		return

	var dir = Input.get_axis("move_left", "move_right")
	velocity.x = dir * speed
	velocity.y = 0.0

	move_and_slide()
	
	# 应用修正偏移后的绝对边界
	if use_bounds:
		global_position.x = clamp(global_position.x, min_x, max_x)

	_update_visual(dir)

func _update_visual(dir: float):
	var is_moving = abs(dir) > 0.01
	
	if is_moving:
		idle_sprite.visible = false
		animated_sprite.visible = true

		if animated_sprite.animation != "run":
			animated_sprite.play("run")

		# 原图默认面朝左，向右走 (dir > 0) 时才需要翻转
		animated_sprite.flip_h = dir > 0
		idle_sprite.flip_h = dir > 0
	else:
		idle_sprite.visible = true
		animated_sprite.visible = false
