extends Control

@onready var chapter_label = $MarginContainer/MainVBox/ChapterLabel
@onready var player_summary_label = $MarginContainer/MainVBox/PlayerSummaryLabel
@onready var node_line = $MarginContainer/MainVBox/CenterContainer/NodeLine
@onready var enter_node_button = $MarginContainer/MainVBox/EnterNodeButton

var node_name_map := {
	"start": "起点",
	"dialogue": "人格残影",
	"reward": "记忆残影",
	"battle_normal": "污染点",
	"event": "认知废墟",
	"rest": "自我锚点",
	"battle_boss": "伤口"
}

func _ready() -> void:
	enter_node_button.pressed.connect(_on_enter_node_button_pressed)
	refresh_ui()

func refresh_ui() -> void:
	var current_type = GameManager.get_current_node_type()
	var current_name_text = node_name_map.get(current_type, "未知节点")

	chapter_label.text = "当前节点：%s" % current_name_text

	var p = GameManager.player_summary
	player_summary_label.text = "存在值 %d/%d | 理智 %d/%d | 认知上限 %d" % [
		p["hp"], p["max_hp"],
		p["san"], p["max_san"],
		p["cognition_max"]
	]

	build_nodes()

func build_nodes() -> void:
	for child in node_line.get_children():
		child.queue_free()

	for i in range(GameManager.map_nodes.size()):
		var node_type = GameManager.map_nodes[i]
		var display_name = node_name_map.get(node_type, node_type)

		var btn = Button.new()
		btn.text = display_name
		btn.custom_minimum_size = Vector2(120, 60)

		if i < GameManager.current_node_index:
			btn.disabled = true
			btn.modulate = Color(0.6, 0.6, 0.6)
		elif i == GameManager.current_node_index:
			btn.disabled = false
			btn.modulate = Color(1.0, 1.0, 1.0)
		else:
			btn.disabled = true
			btn.modulate = Color(0.35, 0.35, 0.35)

		node_line.add_child(btn)

		if i < GameManager.map_nodes.size() - 1:
			var arrow = Label.new()
			arrow.text = "→"
			node_line.add_child(arrow)

func _on_enter_node_button_pressed() -> void:
	var node_type = GameManager.get_current_node_type()

	match node_type:
		"start":
			GameManager.advance_node()
			refresh_ui()
		"dialogue":
			get_tree().change_scene_to_file("res://scenes/dialogue/dialogue_scene.tscn")
		"reward":
			get_tree().change_scene_to_file("res://scenes/reward/reward_scene.tscn")
		"battle_normal", "battle_boss":
			get_tree().change_scene_to_file("res://scenes/battle/battle_scene.tscn")
		"event":
			get_tree().change_scene_to_file("res://scenes/event/event_scene.tscn")
		"rest":
			get_tree().change_scene_to_file("res://scenes/rest/rest_scene.tscn")
		_:
			get_tree().change_scene_to_file("res://scenes/result/result_scene.tscn")
