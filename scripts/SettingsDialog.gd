# 设置对话框脚本
extends Control

# 导出变量，用于存储设置值
@export var brightness: float = 50.0
@export var sound_enabled: bool = true
@export var sound_volume: float = 75.0
@export var bgm_enabled: bool = true
@export var bgm_volume: float = 70.0
@export var system_volume: float = 80.0
@export var fullscreen: bool = false

# UI元素引用
@onready var main_container = $MainContainer
@onready var brightness_slider = $MainContainer/BrightnessSection/BrightnessHeader/BrightnessSlider
@onready var brightness_label = $MainContainer/BrightnessSection/BrightnessValueLabe
@onready var system_check = $MainContainer/SystemSection/SystemToggleRow/SystemToggleButton
@onready var system_slider = $MainContainer/SystemSection/SystemVolumeRow/SystemVolumeSlider
@onready var sound_check = $MainContainer/SoundSection/SoundToggleRow/SoundToggleButton
@onready var sound_slider = $MainContainer/SoundSection/SoundVolumeRow/SoundVolumeSlider
@onready var bgm_check = $MainContainer/BgmSection/BgmToggleRow/BgmToggleButton
@onready var bgm_slider = $MainContainer/BgmSection/BgmVolumeRow/BgmVolumeSlider
@onready var fullscreen_check = $MainContainer/FullscreenRow/FullscreenToggleButton
@onready var save_button = $MainContainer/HBoxContainer/SaveButton
@onready var cancel_button = $MainContainer/HBoxContainer/CancelButton

# 信号
signal settings_saved(settings)
signal settings_cancelled

# 当节点准备好时调用
func _ready() -> void:
	# 初始化UI元素的值
	brightness_slider.value = brightness
	brightness_label.text = str(int(brightness))
	system_check.button_pressed = sound_enabled
	system_slider.value = system_volume
	sound_check.button_pressed = sound_enabled
	sound_slider.value = sound_volume
	bgm_check.button_pressed = bgm_enabled
	bgm_slider.value = bgm_volume
	fullscreen_check.button_pressed = fullscreen

	# 连接信号
	brightness_slider.value_changed.connect(_on_brightness_value_changed)
	system_slider.value_changed.connect(_on_system_volume_changed)
	sound_slider.value_changed.connect(_on_sound_volume_changed)
	bgm_slider.value_changed.connect(_on_bgm_volume_changed)
	bgm_check.toggled.connect(_on_bgm_toggled)
	save_button.pressed.connect(_on_save_button_pressed)
	cancel_button.pressed.connect(_on_cancel_button_pressed)
	
	# 初始化亮度
	var brightness_manager = get_node_or_null("/root/BrightnessManager")
	if brightness_manager:
		brightness = brightness_manager.get_brightness()
		brightness_slider.value = brightness
		brightness_label.text = str(int(brightness))
	
	# 初始化音乐设置
	var music_manager = get_node_or_null("/root/MusicManager")
	if music_manager:
		bgm_enabled = music_manager.get_bgm_enabled()
		bgm_check.button_pressed = bgm_enabled
		bgm_volume = music_manager.get_bgm_volume()
		bgm_slider.value = bgm_volume



# 亮度值变化时调用
func _on_brightness_value_changed(value: float) -> void:
	brightness = value
	brightness_label.text = str(int(value))
	
	# 直接调用 BrightnessManager 的 set_brightness 方法，确保实时更新
	var brightness_manager = get_node_or_null("/root/BrightnessManager")
	if brightness_manager:
		brightness_manager.set_brightness(value)

# 系统音量变化时调用
func _on_system_volume_changed(value: float) -> void:
	system_volume = value

# 音效音量变化时调用
func _on_sound_volume_changed(value: float) -> void:
	sound_volume = value

# BGM音量变化时调用
func _on_bgm_volume_changed(value: float) -> void:
	bgm_volume = value
	
	# 直接调用 MusicManager 的 set_bgm_volume 方法，确保实时更新
	var music_manager = get_node_or_null("/root/MusicManager")
	if music_manager:
		music_manager.set_bgm_volume(value)

# BGM开关变化时调用
func _on_bgm_toggled(enabled: bool) -> void:
	bgm_enabled = enabled
	
	# 直接调用 MusicManager 的 set_bgm_enabled 方法，确保实时更新
	var music_manager = get_node_or_null("/root/MusicManager")
	if music_manager:
		music_manager.set_bgm_enabled(enabled)

# 保存按钮点击时调用
func _on_save_button_pressed() -> void:
	# 更新设置值
	brightness = brightness_slider.value
	sound_enabled = sound_check.button_pressed
	sound_volume = sound_slider.value
	bgm_enabled = bgm_check.button_pressed
	bgm_volume = bgm_slider.value
	system_volume = system_slider.value
	fullscreen = fullscreen_check.button_pressed

	# 更新音乐设置
	var music_manager = get_node_or_null("/root/MusicManager")
	if music_manager:
		music_manager.set_bgm_enabled(bgm_enabled)

	# 触发保存信号
	settings_saved.emit({
		"brightness": brightness,
		"sound_enabled": sound_enabled,
		"sound_volume": sound_volume,
		"bgm_enabled": bgm_enabled,
		"bgm_volume": bgm_volume,
		"system_volume": system_volume,
		"fullscreen": fullscreen
	})

	# 通知父节点关闭对话框
	queue_free()

# 取消按钮点击时调用
func _on_cancel_button_pressed() -> void:
	# 触发取消信号
	settings_cancelled.emit()

	# 通知父节点关闭对话框
	queue_free()
