extends Node2D

var dialogue_data_node = preload("res://data/base_dialogue_data.gd").new()
var dialogue_ui = null
var _current_interactable: Area2D = null
var _npc_animated: AnimatedSprite2D = null
var _prompt_label: Label = null
var _interact_label: Label = null

func _ready() -> void:
	add_to_group("base_scene")
	
	_npc_animated = get_node_or_null("World/NPCZone/NPCAnimated")
	_prompt_label = get_node_or_null("UI/BottomPanel/HintPanel/HintContent/PromptLabel")
	_interact_label = get_node_or_null("UI/BottomPanel/HintPanel/HintContent/InteractLabel")
	
	_init_dialogue_ui()
	_connect_signals()
	_apply_global_ui_mode()
	_update_global_stats()
	_refresh_objective_hint()
	
	_hide_hint()


func _init_dialogue_ui() -> void:
	var base_scene = preload("res://scenes/base/BaseScene.tscn").instantiate()
	var d_ui = base_scene.get_node_or_null("CanvasLayer/DialogueUI")
	if d_ui:
		d_ui.get_parent().remove_child(d_ui)
		$UI.add_child(d_ui)
		dialogue_ui = d_ui
		if dialogue_ui.has_signal("dialogue_finished"):
			dialogue_ui.dialogue_finished.connect(_on_dialogue_finished)
		if dialogue_ui.has_signal("choice_selected"):
			dialogue_ui.choice_selected.connect(_on_dialogue_choice_selected)
	
	base_scene.queue_free()


func _connect_signals() -> void:
	pass


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and _current_interactable:
		_current_interactable.interact()


func set_current_interactable(area: Area2D) -> void:
	_current_interactable = area
	
	if area.interact_type == "npc":
		_show_hint("按 E 与管理员交谈")
		if _npc_animated and _npc_animated.animation != "interaction":
			_npc_animated.play("interaction")
	elif area.interact_type == "dive":
		_show_hint("按 E 开始下潜")


func clear_current_interactable(area: Area2D) -> void:
	if _current_interactable == area:
		_current_interactable = null
		_hide_hint()
		if area.interact_type == "npc" and _npc_animated:
			if _npc_animated.animation != "idle":
				_npc_animated.play("idle")


func show_npc_dialog() -> void:
	if dialogue_ui:
		if not Game.admin_talk_done:
			dialogue_ui.start_dialogue(dialogue_data_node.first_dialogue())
		else:
			dialogue_ui.start_dialogue(dialogue_data_node.repeat_dialogue_after_finish())


func try_enter_dive() -> void:
	if not Game.admin_talk_done:
		if dialogue_ui:
			dialogue_ui.start_dialogue(dialogue_data_node.repeat_dialogue_before_finish())
		return
	Game.set_chapter_one_state("dive")
	Game.goto_dive()


func _on_dialogue_choice_selected(result: String) -> void:
	match result:
		"aggressive":
			Game.tag_aggressive += 1
		"orderly":
			Game.tag_orderly += 1


func _on_dialogue_finished() -> void:
	if not Game.admin_talk_done:
		Game.admin_talk_done = true
		Game.begin_chapter_one()
		await get_tree().create_timer(2.0).timeout
	_refresh_objective_hint()


func _refresh_objective_hint() -> void:
	pass


func _show_hint(text: String) -> void:
	if _prompt_label:
		_prompt_label.text = text
	if _interact_label:
		_interact_label.visible = true


func _hide_hint() -> void:
	if _prompt_label:
		_prompt_label.text = ""
	if _interact_label:
		_interact_label.visible = false


func _apply_global_ui_mode() -> void:
	if has_node("/root/GlobalUI"):
		GlobalUI.set_mode(GlobalUI.MODE_BASE)


func _update_global_stats() -> void:
	if has_node("/root/GlobalUI"):
		GlobalUI.refresh_stats()
