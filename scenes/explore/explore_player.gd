extends CharacterBody2D

@export var move_speed: float = 220.0
@export var head_offset: Vector2 = Vector2.ZERO
@export var move_animation: StringName = &"swim"
@export var idle_animation: StringName = &"swim"
@export var keep_swim_when_idle: bool = true

@onready var visual_root: Node2D = get_node_or_null("VisualRoot") as Node2D
@onready var animated_sprite: AnimatedSprite2D = get_node_or_null("VisualRoot/AnimatedSprite2D") as AnimatedSprite2D
@onready var head_point: Marker2D = get_node_or_null("VisualRoot/HeadPoint") as Marker2D

var character_state = {
	"facing_direction": Vector2.RIGHT,
	"is_moving": false,
	"head_position": Vector2.ZERO
}

var _visual_base_scale: Vector2 = Vector2.ONE


func _ready() -> void:
	add_to_group("player")

	if not visual_root:
		visual_root = self
	if not animated_sprite:
		animated_sprite = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if not head_point:
		head_point = get_node_or_null("HeadPoint") as Marker2D

	_visual_base_scale = visual_root.scale
	_update_head_position()

	if animated_sprite and animated_sprite.sprite_frames:
		animated_sprite.play()


func _physics_process(_delta: float) -> void:
	if Game.in_dialogue:
		velocity = Vector2.ZERO
		move_and_slide()
		character_state["is_moving"] = false
		_update_visual()
		_update_head_position()
		return

	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * move_speed

	if input_dir.length_squared() > 0.0001:
		character_state["facing_direction"] = input_dir.normalized()
		character_state["is_moving"] = true
	else:
		character_state["is_moving"] = false

	move_and_slide()
	_update_visual()
	_update_head_position()


func get_character_state() -> Dictionary:
	return character_state


func get_head_world_position() -> Vector2:
	var value: Variant = character_state.get("head_position", global_position)
	if value is Vector2:
		return value
	return global_position


func get_facing_direction() -> Vector2:
	var value: Variant = character_state.get("facing_direction", Vector2.RIGHT)
	if value is Vector2 and value.length_squared() > 0.0001:
		return value.normalized()
	return Vector2.RIGHT
func _update_visual() -> void:
	var facing_direction = character_state["facing_direction"]

	if animated_sprite and animated_sprite.sprite_frames:
		if not animated_sprite.is_playing():
			animated_sprite.play(idle_animation)

	var facing_left: bool = facing_direction.x < 0.0
	animated_sprite.flip_h = not facing_left

	var sx: float = absf(_visual_base_scale.x)
	var sy: float = absf(_visual_base_scale.y)
	visual_root.scale = Vector2(sx, sy)


func _update_head_position() -> void:
	if head_point:
		character_state["head_position"] = head_point.global_position + head_offset
	else:
		character_state["head_position"] = global_position + head_offset
