extends CharacterBody2D
class_name AdventurePlayer

enum MoveState {
	SURFACE,
	UNDERWATER
}

@export var surface_speed := 500.0
@export var swim_speed := 320.0
@export var gravity := 1400.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var idle_sprite: Sprite2D = $IdleSprite

var state: MoveState = MoveState.SURFACE
@onready var surface_light_anchor: Marker2D = $SurfaceLightAnchor
@onready var underwater_light_anchor: Marker2D = $UnderwaterLightAnchor

func get_light_world_position() -> Vector2:
	if state == MoveState.UNDERWATER:
		return underwater_light_anchor.global_position
	return surface_light_anchor.global_position

func _ready() -> void:
	_show_surface_idle()

func _physics_process(delta: float) -> void:
	match state:
		MoveState.SURFACE:
			_update_surface(delta)
		MoveState.UNDERWATER:
			_update_underwater()

	move_and_slide()
	_update_visual()

func _update_surface(delta: float) -> void:
	var x_dir := Input.get_axis("move_left", "move_right")
	velocity.x = x_dir * surface_speed

	if x_dir != 0:
		anim.flip_h = x_dir < 0
		idle_sprite.flip_h = x_dir < 0

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

func _update_underwater() -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * swim_speed

	if dir.x != 0:
		anim.flip_h = dir.x < 0
		idle_sprite.flip_h = dir.x < 0

func _update_visual() -> void:
	match state:
		MoveState.SURFACE:
			if abs(velocity.x) > 1.0:
				_show_run()
			else:
				_show_surface_idle()

		MoveState.UNDERWATER:
			_show_swim()

func _show_surface_idle() -> void:
	idle_sprite.visible = true
	anim.visible = false
	anim.stop()

func _show_run() -> void:
	idle_sprite.visible = false
	anim.visible = true

	if anim.animation != "run" or not anim.is_playing():
		anim.play("run")

func _show_swim() -> void:
	idle_sprite.visible = false
	anim.visible = true

	if anim.animation != "swim" or not anim.is_playing():
		anim.play("swim")

func enter_underwater(spawn_pos: Vector2) -> void:
	global_position = spawn_pos
	state = MoveState.UNDERWATER
	velocity = Vector2.ZERO
	_show_swim()

func return_to_surface(spawn_pos: Vector2) -> void:
	global_position = spawn_pos
	state = MoveState.SURFACE
	velocity = Vector2.ZERO
	_show_surface_idle()

func return_from_battle(spawn_pos: Vector2, mode: String) -> void:
	global_position = spawn_pos
	velocity = Vector2.ZERO

	if mode == "underwater":
		state = MoveState.UNDERWATER

		idle_sprite.visible = false
		anim.visible = true
		anim.play("swim")
		anim.stop()
		anim.frame = 0
	else:
		state = MoveState.SURFACE
		_show_surface_idle()
