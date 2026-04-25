extends Node

const SETTINGS_FILE := "user://settings.cfg"

var _settings: Dictionary = {}


func _ready() -> void:
	_load_settings()
	_apply_settings()


func _load_settings() -> void:
	if FileAccess.file_exists(SETTINGS_FILE):
		var file := FileAccess.open(SETTINGS_FILE, FileAccess.READ)
		if file:
			while not file.eof_reached():
				var line := file.get_line()
				if line.contains("="):
					var parts := line.split("=")
					if parts.size() >= 2:
						var key := parts[0].strip_edges()
						var value := parts[1].strip_edges()
						if value == "true":
							_settings[key] = true
						elif value == "false":
							_settings[key] = false
						elif value.is_valid_float():
							_settings[key] = value.to_float()


func _apply_settings() -> void:
	var fullscreen: bool = _settings.get("fullscreen", true)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)


func get_setting(key: String, default: Variant = null) -> Variant:
	return _settings.get(key, default)


func set_setting(key: String, value: Variant) -> void:
	_settings[key] = value


func save_settings() -> void:
	var file := FileAccess.open(SETTINGS_FILE, FileAccess.WRITE)
	if file:
		for key in _settings:
			file.store_line("%s=%s" % [key, _settings[key]])
