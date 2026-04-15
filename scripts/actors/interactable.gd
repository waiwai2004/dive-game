extends Area2D

@export var interact_type: String = "npc" # "npc" / "door"
@export var hint_text: String = "按 E 交互"

var player_inside: bool = false
@onready var highlight = get_node_or_null("Highlight")

func _ready():
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

	set_highlight(false)
	print("[Interactable ready] ", name, " type=", interact_type)

func _on_body_entered(body):
	print("[ENTER] area=", name, " body=", body.name)

	if not body.is_in_group("player"):
		print("[ENTER] body not in player group")
		return

	player_inside = true
	set_highlight(true)

	var base_scene = get_tree().get_first_node_in_group("base_scene")
	print("[ENTER] base_scene=", base_scene)

	if base_scene:
		base_scene.set_current_interactable(self)

func _on_body_exited(body):
	print("[EXIT] area=", name, " body=", body.name)

	if not body.is_in_group("player"):
		return

	player_inside = false
	set_highlight(false)

	var base_scene = get_tree().get_first_node_in_group("base_scene")
	if base_scene:
		base_scene.clear_current_interactable(self)

func interact():
	print("[INTERACT] ", name, " type=", interact_type)

	var base_scene = get_tree().get_first_node_in_group("base_scene")
	if base_scene == null:
		print("[INTERACT] no base_scene found")
		return

	match interact_type:
		"npc":
			base_scene.show_npc_dialog()
		"door", "dive":
			base_scene.try_enter_dive()

func set_highlight(enable: bool):
	if highlight:
		highlight.visible = enable
