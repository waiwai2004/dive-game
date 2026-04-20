extends Control

## 意识花苞结算弹窗：读取 Game.last_bud_rewards 显示，点击"继续"返回探索场景

@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var popup: Control = $Popup
@onready var reward_list: VBoxContainer = $Popup/OuterMargin/InnerFrame/InnerMargin/VBox/RewardList
@onready var continue_button: Button = $Popup/OuterMargin/InnerFrame/InnerMargin/VBox/ButtonRow/ContinueButton


func _ready() -> void:
	# 初始：整屏覆盖白色，弹窗透明——和 RewardScene 的闪白收尾对齐
	fade_overlay.color = Color(1.0, 0.98, 0.9, 1.0)
	popup.modulate.a = 0.0

	_populate_rewards()

	continue_button.pressed.connect(_on_continue_pressed)

	# 进入过渡：白幕淡出 + 弹窗浮现
	var tw := create_tween().set_parallel(true)
	tw.tween_property(fade_overlay, "color:a", 0.0, 0.55).set_ease(Tween.EASE_OUT)
	tw.tween_property(popup, "modulate:a", 1.0, 0.55).set_delay(0.15)

	# 过渡结束后让覆盖层不再吃鼠标
	await tw.finished
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _populate_rewards() -> void:
	# 清空已有
	for child in reward_list.get_children():
		child.queue_free()

	var rewards: Array = Game.last_bud_rewards

	if rewards.is_empty():
		var none_label := Label.new()
		none_label.text = "（似乎什么都没有发生……）"
		none_label.add_theme_font_size_override("font_size", 26)
		none_label.add_theme_color_override("font_color", Color(0.35, 0.28, 0.22, 1))
		reward_list.add_child(none_label)
		return

	for i in rewards.size():
		var reward_text: String = str(rewards[i])
		_add_reward_row(reward_text, float(i) * 0.18)


func _add_reward_row(text: String, delay: float) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)

	var bullet := Label.new()
	bullet.text = "✦"
	bullet.add_theme_font_size_override("font_size", 26)
	bullet.add_theme_color_override("font_color", Color(0.55, 0.38, 0.18, 1))
	row.add_child(bullet)

	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", Color(0.14, 0.1, 0.08, 1))
	row.add_child(lbl)

	reward_list.add_child(row)

	# 入场动画：延迟淡入
	row.modulate.a = 0.0
	var tw := create_tween()
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.tween_property(row, "modulate:a", 1.0, 0.4)


func _on_continue_pressed() -> void:
	continue_button.disabled = true

	# 淡出到纯黑再切场景，避免跳切
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	fade_overlay.color = Color(0.02, 0.03, 0.06, 0.0)

	var tw := create_tween().set_parallel(true)
	tw.tween_property(popup, "modulate:a", 0.0, 0.35)
	tw.tween_property(fade_overlay, "color:a", 1.0, 0.4)
	await tw.finished

	# 返回冒险地图（探索场景）
	Game.goto_explore()
