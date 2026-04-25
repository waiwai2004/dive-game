extends "res://scripts/actors/player.gd"

@export var top_limit_margin: float = 400.0
@export var bottom_limit_margin: float = 50.0

var min_y_bound: float = 0.0
var max_y_bound: float = 0.0

func _setup_camera_bounds() -> void:
	super._setup_camera_bounds()
	if camera == null:
		return
	
	# 设置上下的移动边界
	# 放宽上下 y 轴限位，因为目前是在基地的走廊里走动，且原位置可能超出了限制
	min_y_bound = camera.limit_top - 200.0  # 你可以根据需要调整这个具体坐标
	max_y_bound = camera.limit_bottom - 800.0
	
func _physics_process(_delta):
	# 防对话移动
	if Game.in_dialogue:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_visual(0.0)
		return

	var dir_x = Input.get_axis("move_left", "move_right")
	
	# 处理上下移动，兼容标准的 ui_up/ui_down 或 自定义的 move_up/move_down
	var dir_y = 0.0
	if InputMap.has_action("move_up") and InputMap.has_action("move_down"):
		dir_y = Input.get_axis("move_up", "move_down")
	else:
		dir_y = Input.get_axis("ui_up", "ui_down")
		
	velocity.x = dir_x * speed
	velocity.y = dir_y * speed

	move_and_slide()

	# 应用修正偏移后的绝对边界 (横向与纵向)
	if use_bounds:
		global_position.x = clamp(global_position.x, min_x, max_x)
		global_position.y = clamp(global_position.y, min_y_bound, max_y_bound)

	_update_visual(dir_x)
