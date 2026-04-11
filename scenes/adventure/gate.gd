extends Area2D

@export var player_path: NodePath
@export var underwater_spawn_path: NodePath

@onready var player = get_node(player_path)
@onready var underwater_spawn = get_node(underwater_spawn_path)

func _ready() -> void:
	input_pickable = true

func _input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		player.enter_underwater(underwater_spawn.global_position)
