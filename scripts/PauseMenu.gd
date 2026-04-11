extends CanvasLayer

const TITLE_SCENE := "res://scenes/title/TitleScreen.tscn"
const BASE_SCENE := "res://scenes/base/BaseScene.tscn"
const SETTINGS_SCENE := "res://scenes/ui/SettingsScene.tscn"

@onready var menu_root: Control = $Menu
@onready var title_label: RichTextLabel = $Menu/Label
@onready var button_box: VBoxContainer = $Menu/VBoxContainer

@onready var resume_button: Button = $Menu/VBoxContainer/ResumeButton
@onready var settings_button: Button = $Menu/VBoxContainer/SettingsButton
@onready var save_quit_button: Button = $Menu/VBoxContainer/SaveQuitButton
@onready var return_base_button: Button = $Menu/VBoxContainer/ReturnBaseButton
@onready var quit_button: Button = $Menu/VBoxContainer/QuitButton

@onready var return_base_dialog: ConfirmationDialog = $Menu/ConfirmationDialog

var is_open: bool = false
var settings_dialog: Control = null

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_unhandled_input(true)

	resume_button.pressed.connect(_on_resume_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	save_quit_button.pressed.connect(_on_save_quit_button_pressed)
	return_base_button.pressed.connect(_on_return_base_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	return_base_dialog.confirmed.connect(_on_return_base_dialog_confirmed)

func _unhandled_input(event: InputEvent) -> void:
	# 只处理ESC键输入
	if event.is_action_pressed("ui_cancel"):
		if is_open:
			if return_base_dialog.visible:
				return_base_dialog.hide()
			else:
				close_menu()
		else:
			open_menu()

		# 只在处理ESC键时阻止事件传递
		get_viewport().set_input_as_handled()

func open_menu() -> void:
	if is_open:
		return

	is_open = true
	visible = true
	get_tree().paused = true
	
	# 检查是否在冒险中
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		if not game_manager.in_adventure:
			# 在基地，置灰返回基地和保存并退出按钮
			return_base_button.disabled = true
			save_quit_button.disabled = true
		else:
			# 在冒险中，启用按钮
			return_base_button.disabled = false
			save_quit_button.disabled = false

func close_menu() -> void:
	if not is_open:
		return

	is_open = false
	return_base_dialog.hide()
	
	# 关闭设置对话框
	if settings_dialog:
		settings_dialog.queue_free()
		settings_dialog = null
	
	get_tree().paused = false
	visible = false
	# 不要禁用输入处理，以便能够再次按ESC调出菜单

func _on_resume_button_pressed() -> void:
	close_menu()

func _on_settings_button_pressed() -> void:
	# 如果设置对话框已经打开，先关闭
	if settings_dialog:
		settings_dialog.queue_free()

	# 加载并实例化设置对话框
	settings_dialog = load(SETTINGS_SCENE).instantiate()
	add_child(settings_dialog)

	# 连接信号
	settings_dialog.settings_saved.connect(_on_settings_saved)
	settings_dialog.settings_cancelled.connect(_on_settings_cancelled)

func _on_settings_saved(settings: Dictionary) -> void:
	# 处理设置保存
	print("Settings saved:", settings)
	if settings_dialog:
		settings_dialog.queue_free()
		settings_dialog = null

func _on_settings_cancelled() -> void:
	# 处理设置取消
	print("Settings cancelled")
	if settings_dialog:
		settings_dialog.queue_free()
		settings_dialog = null

func _on_save_quit_button_pressed() -> void:
	is_open = false
	get_tree().paused = false
	# 使用GameManager的save_and_exit()函数
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		game_manager.save_and_exit()

func _on_return_base_button_pressed() -> void:
	return_base_dialog.popup_centered()

func _on_return_base_dialog_confirmed() -> void:
	is_open = false
	get_tree().paused = false
	# 使用GameManager的goto_base()函数
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		game_manager.goto_base()

func _on_quit_button_pressed() -> void:
	# 退出游戏
	get_tree().quit()
