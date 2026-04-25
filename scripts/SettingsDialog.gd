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

const BRIGHTNESS_LAYER_NAME := "BrightnessLayer"

var _brightness_layer: CanvasLayer = null
var _brightness_overlay: ColorRect = null
var _original_brightness := 100.0
var _original_fullscreen := true


func _ready() -> void:
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
	
	_get_or_create_brightness_layer()
	_load_current_settings()


func _get_or_create_brightness_layer() -> void:
	var root := get_tree().root
	
	_brightness_layer = root.get_node_or_null(BRIGHTNESS_LAYER_NAME)
	if _brightness_layer:
		_brightness_overlay = _brightness_layer.get_child(0) as ColorRect
		if _brightness_overlay:
			_original_brightness = 100.0 - (_brightness_overlay.color.a / 0.5 * 100.0)
			return
	
	_brightness_layer = CanvasLayer.new()
	_brightness_layer.name = BRIGHTNESS_LAYER_NAME
	_brightness_layer.layer = 50
	_brightness_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	
	_brightness_overlay = ColorRect.new()
	_brightness_overlay.name = "BrightnessOverlay"
	_brightness_overlay.color = Color(0, 0, 0, 0)
	_brightness_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_brightness_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	_brightness_layer.add_child(_brightness_overlay)
	root.add_child(_brightness_layer)
	_original_brightness = 100.0


func _load_current_settings() -> void:
	if has_node("/root/SettingsManager"):
		brightness_slider.value = SettingsManager.get_setting("brightness", 100.0)
		system_toggle.button_pressed = SettingsManager.get_setting("system_sound", true)
		system_volume_slider.value = SettingsManager.get_setting("system_volume", 80.0)
		sound_toggle.button_pressed = SettingsManager.get_setting("sound", true)
		sound_volume_slider.value = SettingsManager.get_setting("sound_volume", 75.0)
		bgm_toggle.button_pressed = SettingsManager.get_setting("bgm", true)
		bgm_volume_slider.value = SettingsManager.get_setting("bgm_volume", 70.0)
		_original_fullscreen = SettingsManager.get_setting("fullscreen", true)
	else:
		brightness_slider.value = 100.0
		_original_fullscreen = true
	
	fullscreen_toggle.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	
	_on_system_toggle_toggled(system_toggle.button_pressed)
	_on_sound_toggle_toggled(sound_toggle.button_pressed)
	_on_bgm_toggle_toggled(bgm_toggle.button_pressed)


func _on_brightness_value_changed(value: float) -> void:
	brightness_value_label.text = "当前亮度: %.0f%%" % value
	var alpha := (100.0 - value) / 100.0 * 0.5
	if _brightness_overlay:
		_brightness_overlay.color = Color(0, 0, 0, alpha)


func _on_system_toggle_toggled(button_pressed: bool) -> void:
	system_volume_slider.editable = button_pressed
	if has_node("/root/AudioManager"):
		AudioManager.set_master_enabled(button_pressed)


func _on_system_volume_value_changed(value: float) -> void:
	if has_node("/root/AudioManager"):
		AudioManager.set_master_volume(int(value))


func _on_sound_toggle_toggled(button_pressed: bool) -> void:
	sound_volume_slider.editable = button_pressed
	if has_node("/root/AudioManager"):
		AudioManager.set_sfx_enabled(button_pressed)


func _on_sound_volume_value_changed(value: float) -> void:
	if has_node("/root/AudioManager"):
		AudioManager.set_sfx_volume(int(value))


func _on_bgm_toggle_toggled(button_pressed: bool) -> void:
	bgm_volume_slider.editable = button_pressed
	if has_node("/root/AudioManager"):
		AudioManager.set_bgm_enabled(button_pressed)


func _on_bgm_volume_value_changed(value: float) -> void:
	if has_node("/root/AudioManager"):
		AudioManager.set_bgm_volume(int(value))


func _on_fullscreen_toggle_toggled(button_pressed: bool) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if button_pressed else DisplayServer.WINDOW_MODE_WINDOWED)


func _on_save_button_pressed() -> void:
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
	
	if has_node("/root/SettingsManager"):
		for key in settings:
			SettingsManager.set_setting(key, settings[key])
		SettingsManager.save_settings()
	
	settings_saved.emit(settings)


func _on_cancel_button_pressed() -> void:
	if _brightness_overlay:
		var alpha := (100.0 - _original_brightness) / 100.0 * 0.5
		_brightness_overlay.color = Color(0, 0, 0, alpha)
	
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if _original_fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	
	settings_cancelled.emit()
