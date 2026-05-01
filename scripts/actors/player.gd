extends CharacterBody2D

@export var speed: float = 250.0
@export var left_margin: float = 100.0
@export var right_margin: float = 100.0

@onready var shadow = $Shadow
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D

var min_x: float = 0.0
var max_x: float = 0.0
var use_bounds: bool = false

func _ready():
	add_to_group("player")
	
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("idle"):
		animated_sprite.play("idle")
	
	call_deferred("_setup_camera_bounds")

func _setup_camera_bounds() -> void:
	if camera == null:
		print("[警告] Player 未找到 Camera2D，边界限制无法生效！")
		return

	min_x = camera.limit_left + left_margin
	max_x = camera.limit_right - right_margin
	use_bounds = true
	
	print("--- Player 边界已成功限制 ---")
	print("相机极限: ", camera.limit_left, " 到 ", camera.limit_right)
	print("最终限制: ", min_x, " 到 ", max_x)

func _physics_process(_delta):
	if Game.in_dialogue:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var dir = Input.get_axis("move_left", "move_right")
	velocity.x = dir * speed
	velocity.y = 0.0

	move_and_slide()
	
	if use_bounds:
		global_position.x = clamp(global_position.x, min_x, max_x)

	var is_moving = abs(dir) > 0.01
	if is_moving:
		animated_sprite.flip_h = dir > 0
