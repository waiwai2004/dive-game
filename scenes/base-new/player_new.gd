extends "res://scripts/actors/player.gd"

var min_y_bound: float = 300.0
var max_y_bound: float = 900.0

func _setup_camera_bounds() -> void:
	super._setup_camera_bounds()
	if camera == null:
		return
	
	min_y_bound = 400.0
	max_y_bound = 550.0

func _physics_process(_delta):
	if Game.in_dialogue:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_animation(false)
		return

	var dir_x = Input.get_axis("move_left", "move_right")
	
	var dir_y = 0.0
	if InputMap.has_action("move_up") and InputMap.has_action("move_down"):
		dir_y = Input.get_axis("move_up", "move_down")
	else:
		dir_y = Input.get_axis("ui_up", "ui_down")
		
	velocity.x = dir_x * speed
	velocity.y = dir_y * speed

	move_and_slide()

	if use_bounds:
		global_position.x = clamp(global_position.x, min_x, max_x)
		global_position.y = clamp(global_position.y, min_y_bound, max_y_bound)

	var is_moving = abs(dir_x) > 0.01 or abs(dir_y) > 0.01
	_update_animation(is_moving)
	
	if is_moving and abs(dir_x) > 0.01:
		animated_sprite.flip_h = dir_x > 0

func _update_animation(is_moving: bool) -> void:
	if is_moving:
		if animated_sprite.animation != "run":
			animated_sprite.play("run")
	else:
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")
