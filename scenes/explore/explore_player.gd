extends CharacterBody2D

@export var move_speed: float = 220.0
@export var head_offset: Vector2 = Vector2.ZERO
@export var move_animation: StringName = &"swim"
@export var idle_animation: StringName = &"swim"
@export var keep_swim_when_idle: bool = true

@onready var visual_root: Node2D = get_node_or_null("VisualRoot") as Node2D
@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("VisualRoot/AnimatedSprite2D") as AnimatedSprite2D
@onready var idle_sprite: Sprite2D = get_node_or_null("VisualRoot/IdleSprite") as Sprite2D
@onready var head_point: Marker2D = get_node_or_null("VisualRoot/HeadPoint") as Marker2D

var facing_direction: Vector2 = Vector2.RIGHT
var _visual_base_scale: Vector2 = Vector2.ONE


func _ready() -> void:
	add_to_group("player")

	if not visual_root:
		visual_root = self
	if not animated_sprite:
		animated_sprite = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if not idle_sprite:
		idle_sprite = get_node_or_null("IdleSprite") as Sprite2D
	if not head_point:
		head_point = get_node_or_null("HeadPoint") as Marker2D

	_visual_base_scale = visual_root.scale

	if keep_swim_when_idle:
		if idle_sprite:
			idle_sprite.visible = false
		if animated_sprite:
			animated_sprite.visible = true
		_play_animation_safe(idle_animation)
	else:
		if idle_sprite:
			idle_sprite.visible = true
		if animated_sprite:
			animated_sprite.visible = false


func _physics_process(_delta: float) -> void:
	if Game.in_dialogue:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_visual(false)
		return

	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * move_speed

	if input_dir.length_squared() > 0.0001:
		facing_direction = input_dir.normalized()

	move_and_slide()
	_update_visual(input_dir.length_squared() > 0.0001)


func get_head_world_position() -> Vector2:
	if head_point:
		return head_point.global_position + head_offset
	return global_position + head_offset


func get_facing_direction() -> Vector2:
	if facing_direction.length_squared() <= 0.0001:
		return Vector2.RIGHT
	return facing_direction.normalized()


func _update_visual(is_moving: bool) -> void:
	if is_moving:
		if idle_sprite:
			idle_sprite.visible = false
		if animated_sprite:
			animated_sprite.visible = true
		if animated_sprite and animated_sprite.animation != move_animation:
			_play_animation_safe(move_animation)
	else:
		if keep_swim_when_idle:
			if idle_sprite:
				idle_sprite.visible = false
			if animated_sprite:
				animated_sprite.visible = true
			if animated_sprite and animated_sprite.animation != idle_animation:
				_play_animation_safe(idle_animation)
		else:
			if idle_sprite:
				idle_sprite.visible = true
			if animated_sprite:
				animated_sprite.visible = false

	if absf(facing_direction.x) > 0.01:
		var facing_left: bool = facing_direction.x < 0.0
		var sx: float = absf(_visual_base_scale.x)
		var sy: float = _visual_base_scale.y
		visual_root.scale = Vector2(-sx if facing_left else sx, sy)


func _play_animation_safe(anim_name: StringName) -> void:
	if not animated_sprite:
		return
	if not animated_sprite.sprite_frames:
		return

	if animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
		return

	if animated_sprite.sprite_frames.has_animation(&"swim"):
		animated_sprite.play(&"swim")
		return

	if animated_sprite.sprite_frames.has_animation(&"run"):
		animated_sprite.play(&"run")
