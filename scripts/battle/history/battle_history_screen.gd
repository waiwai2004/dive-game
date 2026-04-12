# 战斗历史记录屏幕脚本
# 显示战斗中发生的所有历史记录
extends Control

# 历史记录列表
var history_records: Array = []
var is_visible_mode := false

# UI组件
@onready var history_label = $MainContainer/ContentPanel/ContentVBox/HistoryScroll/HistoryLabel
@onready var close_button = $MainContainer/TopBar/CloseButton

# 场景准备就绪
func _ready() -> void:
	# 连接按钮信号
	close_button.pressed.connect(_on_close_button_pressed)
	# 默认隐藏该节点
	hide()

# 添加历史记录
func add_history_record(text: String) -> void:
	history_records.append(text)
	update_history_display()

# 更新历史记录显示
func update_history_display() -> void:
	# 清空旧的内容
	history_label.clear()
	
	# 添加所有历史记录
	for i in range(history_records.size()):
		var record = history_records[i]
		# 使用不同的颜色来区分不同类型的记录
		if record.contains("敌人"):
			history_label.append_text("[color=#ffaa00]")
		elif record.contains("玩家") or record.contains("你"):
			history_label.append_text("[color=#00aa00]")
		else:
			history_label.append_text("[color=#ffffff]")
		
		history_label.append_text("%02d. %s" % [i + 1, record])
		history_label.append_text("[/color]\n")

# 显示历史记录屏幕
func show_history_screen() -> void:
	show()
	is_visible_mode = true
	# 自动滚动到末尾
	await get_tree().process_frame
	$MainContainer/ContentPanel/ContentVBox/HistoryScroll.scroll_vertical = $MainContainer/ContentPanel/ContentVBox/HistoryScroll.get_v_scroll_bar().max_value

# 关闭历史记录屏幕
func hide_history_screen() -> void:
	hide()
	is_visible_mode = false

# 关闭按钮按下
func _on_close_button_pressed() -> void:
	hide_history_screen()

# 清空历史记录
func clear_history() -> void:
	history_records.clear()
	update_history_display()
