extends CharacterBody2D

@export var speed: float = 250.0

@onready var shadow = $Shadow
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var idle_sprite: Sprite2D = $IdleSprite

func _ready():
	add_to_group("player")
	print("animated_sprite =", animated_sprite)
	print("animations =", animated_sprite.sprite_frames.get_animation_names())

	# 初始默认待机
	idle_sprite.visible = true
	animated_sprite.visible = false
	animated_sprite.play("run")

func _physics_process(_delta):
	if Game.in_dialogue:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_visual(false, 0.0)
		return

	var dir = Input.get_axis("move_left", "move_right")
	velocity.x = dir * speed
	velocity.y = 0.0

	move_and_slide()
	_update_visual(abs(dir) > 0.01, dir)

func _update_visual(is_moving: bool, dir: float):
	if is_moving:
		idle_sprite.visible = false
		animated_sprite.visible = true

		if animated_sprite.animation != "run":
			animated_sprite.play("run")

		if dir != 0:
			animated_sprite.flip_h = dir > 0
			idle_sprite.flip_h = dir > 0
	else:
		idle_sprite.visible = true
		animated_sprite.visible = false

		if dir != 0:
			idle_sprite.flip_h = dir > 0
