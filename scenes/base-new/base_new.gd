extends Node2D

@onready var dialogue_ui = null
var dialogue_data_node = preload("res://data/base_dialogue_data.gd").new()

func _ready():
	_init_dialogue_ui()
	
	if has_node("UI/TalkButton"):
		$UI/TalkButton.pressed.connect(_on_talk_pressed)
	if has_node("UI/DiveButton"):
		$UI/DiveButton.pressed.connect(_on_dive_pressed)
	
	_apply_global_ui_mode()
	_update_global_stats()
	_refresh_objective_hint()


func _init_dialogue_ui():
	# 为了不修改已有文件且保证原有功能完好，我们直接实例化原base场景并摘取其DialogueUI组件
	var base_scene = preload("res://scenes/base/BaseScene.tscn").instantiate()
	var d_ui = base_scene.get_node_or_null("CanvasLayer/DialogueUI")
	if d_ui:
		var parent = d_ui.get_parent()
		parent.remove_child(d_ui)
		
		# 将DialogueUI加到当前的UI层
		$UI.add_child(d_ui)
		dialogue_ui = d_ui
		
		# 连接对话信号
		if dialogue_ui.has_signal("dialogue_finished"):
			dialogue_ui.dialogue_finished.connect(_on_dialogue_finished)
		if dialogue_ui.has_signal("choice_selected"):
			dialogue_ui.choice_selected.connect(_on_dialogue_choice_selected)
			
	# 将之前的玩家实例替换为真实的带有移动脚本的玩家节点
	var real_player = base_scene.get_node_or_null("World/Player")
	if real_player:
		real_player.get_parent().remove_child(real_player)
		# 分配带有上下移动的新脚本
		real_player.set_script(preload("res://scenes/base-new/player_new.gd"))
		
		# 隐藏或删除占位假人
		var dummy_player = $UI.get_node_or_null("Player")
		if dummy_player:
			# 读取编辑器中占位假人Player的坐标，作为真实玩家的生成位置
			real_player.global_position = dummy_player.global_position
			dummy_player.queue_free()
		# 将真实玩家放回新场景，使用 deferred 防止物理更新覆盖
		add_child(real_player)
		# 因为相机绑在玩家身上，确保在场景里也能正确限位，无需再额外添加Camera2D。
		
	base_scene.queue_free()


func _on_talk_pressed():
	if dialogue_ui:
		if not Game.admin_talk_done:
			dialogue_ui.start_dialogue(dialogue_data_node.first_dialogue())
		else:
			dialogue_ui.start_dialogue(dialogue_data_node.repeat_dialogue_after_finish())


func _on_dive_pressed():
	if not Game.admin_talk_done:
		if dialogue_ui:
			dialogue_ui.start_dialogue(dialogue_data_node.repeat_dialogue_before_finish())
		return

	Game.set_chapter_one_state("dive")
	Game.goto_dive()


func _on_dialogue_choice_selected(result: String):
	match result:
		"aggressive":
			Game.tag_aggressive += 1
		"orderly":
			Game.tag_orderly += 1


func _on_dialogue_finished():
	if not Game.admin_talk_done:
		Game.admin_talk_done = true
		Game.begin_chapter_one()
		_set_global_hint("任务已更新：前往下潜舱，确认浅海中继点的异常讯号。", true)
		await get_tree().create_timer(2.0).timeout

	_refresh_objective_hint()


func _refresh_objective_hint() -> void:
	if Game.in_dialogue:
		return

	if not Game.admin_talk_done:
		_set_global_hint("目标：与管理员交谈，领取下潜任务。", true)
	else:
		_set_global_hint("目标：前往下潜舱，开始第一章任务。", true)


func _apply_global_ui_mode() -> void:
	if has_node("/root/GlobalUI"):
		GlobalUI.set_mode(GlobalUI.MODE_BASE)


func _set_global_hint(text: String, visible: bool) -> void:
	if has_node("/root/GlobalUI"):
		if visible:
			GlobalUI.set_hint(text, true)
		else:
			GlobalUI.clear_hint()


func _update_global_stats() -> void:
	if has_node("/root/GlobalUI"):
		GlobalUI.refresh_stats()
