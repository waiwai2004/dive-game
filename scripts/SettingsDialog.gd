extends Control

signal settings_saved(settings: Dictionary)
signal settings_cancelled()

@onready var brightness_slider: HSlider = $MainContainer/BrightnessSection/BrightnessHeader/BrightnessSlider
@onready var brightness_value_label: Label = $MainContainer/BrightnessSection/BrightnessValueLabe
@onready var system_toggle: CheckButton = $MainContainer/SystemSection/SystemToggleRow/SystemToggleButton
@onready var system_volume_slider: HSlider = $MainContainer/SystemSection/SystemVolumeRow/SystemVolumeSlider
@onready var sound_toggle: CheckButton = $MainContainer/SoundSection/SoundToggleRow/SoundToggleButton
@onready var sound_volume_slider: HSlider = $MainContainer/SoundSection/SoundVolumeRow/SoundVolumeSlider
@onready var bgm_toggle: CheckButton = $MainContainer/BgmSection/BgmToggleRow/BgmToggleButton
@onready var bgm_volume_slider: HSlider = $MainContainer/BgmSection/BgmVolumeRow/BgmVolumeSlider
@onready var fullscreen_toggle: CheckButton = $MainContainer/FullscreenRow/FullscreenToggleButton
@onready var save_button: Button = $MainContainer/HBoxContainer/SaveButton
@onready var cancel_button: Button = $MainContainer/HBoxContainer/CancelButton

func _ready() -> void:
	# 连接信号
	brightness_slider.value_changed.connect(_on_brightness_value_changed)
	system_toggle.toggled.connect(_on_system_toggle_toggled)
	system_volume_slider.value_changed.connect(_on_system_volume_value_changed)
	sound_toggle.toggled.connect(_on_sound_toggle_toggled)
	sound_volume_slider.value_changed.connect(_on_sound_volume_value_changed)
	bgm_toggle.toggled.connect(_on_bgm_toggle_toggled)
	bgm_volume_slider.value_changed.connect(_on_bgm_volume_value_changed)
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggle_toggled)
	save_button.pressed.connect(_on_save_button_pressed)
	cancel_button.pressed.connect(_on_cancel_button_pressed)

	# 初始化值
	_on_brightness_value_changed(brightness_slider.value)

func _on_brightness_value_changed(value: float) -> void:
	brightness_value_label.text = "当前亮度: %.0f%%" % value

func _on_system_toggle_toggled(button_pressed: bool) -> void:
	system_volume_slider.disabled = not button_pressed

func _on_system_volume_value_changed(value: float) -> void:
	pass

func _on_sound_toggle_toggled(button_pressed: bool) -> void:
	sound_volume_slider.disabled = not button_pressed

func _on_sound_volume_value_changed(value: float) -> void:
	pass

func _on_bgm_toggle_toggled(button_pressed: bool) -> void:
	bgm_volume_slider.disabled = not button_pressed

func _on_bgm_volume_value_changed(value: float) -> void:
	pass

func _on_fullscreen_toggle_toggled(button_pressed: bool) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if button_pressed else DisplayServer.WINDOW_MODE_WINDOWED)

func _on_save_button_pressed() -> void:
	# 收集设置
	var settings = {
		"brightness": brightness_slider.value,
		"system_sound": system_toggle.button_pressed,
		"system_volume": system_volume_slider.value,
		"sound": sound_toggle.button_pressed,
		"sound_volume": sound_volume_slider.value,
		"bgm": bgm_toggle.button_pressed,
		"bgm_volume": bgm_volume_slider.value,
		"fullscreen": fullscreen_toggle.button_pressed
	}

	# 发送保存信号
	settings_saved.emit(settings)

func _on_cancel_button_pressed() -> void:
	# 发送取消信号
	settings_cancelled.emit()
