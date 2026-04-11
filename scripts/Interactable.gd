extends Area2D

@export_enum("npc", "dive") var interact_type: String = "npc"

@onready var highlight: CanvasItem = $Highlight

var player_inside: bool = false

func _ready() -> void:
	print(name, " ready")
	highlight.visible = false
	highlight.modulate.a = 0.0
	input_pickable = true
	monitoring = true
	monitorable = true


func _on_body_entered(body: Node) -> void:
	print(name, " body_entered: ", body.name)

	if body.name != "Player":
		return

	player_inside = true
	_show_highlight()

	var base_scene = get_tree().get_first_node_in_group("base_scene")
	if base_scene == null:
		print(name, " cannot find base_scene")
		return

	if interact_type == "npc":
		base_scene.set_hint_label("【点击】与NPC对话")
	else:
		base_scene.set_click_tip("【点击】进入下潜")


func _on_body_exited(body: Node) -> void:
	print(name, " body_exited: ", body.name)

	if body.name != "Player":
		return

	player_inside = false
	_hide_highlight()

	var base_scene = get_tree().get_first_node_in_group("base_scene")
	if base_scene == null:
		return

	base_scene.clear_click_tip()
	base_scene.clear_hint_label()


func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton \
	and event.pressed \
	and event.button_index == MOUSE_BUTTON_LEFT:
		print(name, " clicked, player_inside = ", player_inside)

		if not player_inside:
			return

		var base_scene = get_tree().get_first_node_in_group("base_scene")
		if base_scene == null:
			print(name, " cannot find base_scene on click")
			return

		if interact_type == "npc":
			base_scene.show_npc_dialog()
		else:
			base_scene.enter_adventure()


func _show_highlight() -> void:
	highlight.visible = true
	highlight.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(highlight, "modulate:a", 1.0, 0.15)


func _hide_highlight() -> void:
	var tween := create_tween()
	tween.tween_property(highlight, "modulate:a", 0.0, 0.15)
	tween.finished.connect(func() -> void:
		highlight.visible = false
	)
