extends Node

const BGM_PATH := "res://assets/audio/bgm/Eight.wav"
const SILENT_DB := -60.0

const SFX_PATHS := {
	"card_hover": "res://assets/audio/sfx/sfx_card_hover.wav",
	"card_play": "res://assets/audio/sfx/sfx_card_play.wav",
	"end_turn": "res://assets/audio/sfx/sfx_end_turn.wav",
	"hit": "res://assets/audio/sfx/sfx_hit.wav"
}

var segments: Dictionary = {
	"menu": {"start": 0.0, "end": 18.0},
	"story": {"start": 18.0, "end": 52.0},
	"base": {"start": 52.0, "end": 88.0},
	"explore": {"start": 88.0, "end": 126.0},
	"battle": {"start": 126.0, "end": 170.0},
	"end": {"start": 170.0, "end": 200.0}
}

var _player: AudioStreamPlayer
var _fade_tween: Tween
var _current_segment := ""
var _segment_start := 0.0
var _segment_end := 0.0
var _request_id := 0

var _bgm_volume_percent := 70
var _sfx_volume_percent := 75
var _master_volume_percent := 80
var _bgm_enabled := true
var _sfx_enabled := true
var _master_enabled := true

var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_streams: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	_player.name = "BGMPlayer"
	_player.stream = load(BGM_PATH)
	_player.volume_db = _percent_to_db(_bgm_volume_percent)
	add_child(_player)
	
	for sfx_name in SFX_PATHS:
		var path: String = SFX_PATHS[sfx_name]
		if ResourceLoader.exists(path):
			_sfx_streams[sfx_name] = load(path)
	
	_load_settings()


func _process(_delta: float) -> void:
	if _current_segment.is_empty():
		return
	if not _player.playing:
		_player.seek(_segment_start)
		_player.play()
		return

	var pos := _player.get_playback_position()
	if pos >= _segment_end:
		_player.seek(_segment_start)


func play_bgm_segment(segment_name: String, fade_duration := 0.35) -> void:
	if not segments.has(segment_name):
		push_warning("AudioManager: unknown segment '%s'" % segment_name)
		return

	var seg: Dictionary = segments[segment_name]
	var start := float(seg.get("start", 0.0))
	var end := float(seg.get("end", start + 1.0))
	var stream_length := 0.0
	if _player.stream:
		stream_length = _player.stream.get_length()

	if stream_length > 0.0:
		start = clamp(start, 0.0, max(stream_length - 0.01, 0.0))
		end = clamp(end, start + 0.01, stream_length)
	elif end <= start:
		end = start + 1.0

	_segment_start = start
	_segment_end = end

	if _current_segment == segment_name and _player.playing:
		var pos := _player.get_playback_position()
		if pos < _segment_start or pos >= _segment_end:
			_player.seek(_segment_start)
		return

	_current_segment = segment_name
	_request_id += 1
	_switch_segment(_segment_start, fade_duration, _request_id)


func stop_bgm() -> void:
	_request_id += 1
	_kill_fade_tween()
	_player.stop()
	_current_segment = ""


func fade_out_and_stop(fade_duration := 0.35) -> void:
	_request_id += 1
	var local_request_id := _request_id

	if not _player.playing:
		stop_bgm()
		return

	_kill_fade_tween()
	if fade_duration > 0.0:
		_fade_tween = create_tween()
		_fade_tween.tween_property(_player, "volume_db", SILENT_DB, fade_duration)
		await _fade_tween.finished
		if local_request_id != _request_id:
			return

	_player.stop()
	_player.volume_db = _percent_to_db(_bgm_volume_percent)
	_current_segment = ""


func play_sfx(sfx_name: String) -> void:
	if not _sfx_enabled or not _master_enabled:
		return
	if not _sfx_streams.has(sfx_name):
		push_warning("AudioManager: unknown sfx '%s'" % sfx_name)
		return
	
	var sfx_player := AudioStreamPlayer.new()
	sfx_player.stream = _sfx_streams[sfx_name]
	sfx_player.volume_db = _percent_to_db(_sfx_volume_percent)
	add_child(sfx_player)
	sfx_player.play()
	_sfx_players.append(sfx_player)
	
	sfx_player.finished.connect(func():
		sfx_player.queue_free()
		_sfx_players.erase(sfx_player)
	)


func set_bgm_volume(percent: int) -> void:
	_bgm_volume_percent = clampi(percent, 0, 100)
	var db := _percent_to_db(_bgm_volume_percent) if _bgm_enabled and _master_enabled else SILENT_DB
	_player.volume_db = db


func set_bgm_enabled(enabled: bool) -> void:
	_bgm_enabled = enabled
	var db := _percent_to_db(_bgm_volume_percent) if _bgm_enabled and _master_enabled else SILENT_DB
	_player.volume_db = db


func set_sfx_volume(percent: int) -> void:
	_sfx_volume_percent = clampi(percent, 0, 100)


func set_sfx_enabled(enabled: bool) -> void:
	_sfx_enabled = enabled


func set_master_volume(percent: int) -> void:
	_master_volume_percent = clampi(percent, 0, 100)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), _percent_to_db(_master_volume_percent))


func set_master_enabled(enabled: bool) -> void:
	_master_enabled = enabled
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), not enabled)
	var db := _percent_to_db(_bgm_volume_percent) if _bgm_enabled and _master_enabled else SILENT_DB
	_player.volume_db = db


func get_bgm_volume() -> int:
	return _bgm_volume_percent


func get_sfx_volume() -> int:
	return _sfx_volume_percent


func get_master_volume() -> int:
	return _master_volume_percent


func is_bgm_enabled() -> bool:
	return _bgm_enabled


func is_sfx_enabled() -> bool:
	return _sfx_enabled


func is_master_enabled() -> bool:
	return _master_enabled


func _percent_to_db(percent: int) -> float:
	if percent <= 0:
		return SILENT_DB
	return linear_to_db(percent / 100.0)


func _switch_segment(start_time: float, fade_duration: float, request_id: int) -> void:
	_kill_fade_tween()

	var target_db := _percent_to_db(_bgm_volume_percent) if _bgm_enabled and _master_enabled else SILENT_DB

	if _player.playing and fade_duration > 0.0:
		_fade_tween = create_tween()
		_fade_tween.tween_property(_player, "volume_db", SILENT_DB, fade_duration)
		await _fade_tween.finished
		if request_id != _request_id:
			return

	_player.seek(start_time)
	if not _player.playing:
		_player.play()

	if fade_duration > 0.0:
		_player.volume_db = SILENT_DB
		_fade_tween = create_tween()
		_fade_tween.tween_property(_player, "volume_db", target_db, fade_duration)
	else:
		_player.volume_db = target_db


func _kill_fade_tween() -> void:
	if _fade_tween and is_instance_valid(_fade_tween):
		_fade_tween.kill()
		_fade_tween = null


func _load_settings() -> void:
	if not has_node("/root/SettingsManager"):
		return
	
	if SettingsManager.get_setting("system_sound", true) != null:
		_master_enabled = SettingsManager.get_setting("system_sound", true)
	if SettingsManager.get_setting("system_volume", 80) != null:
		_master_volume_percent = SettingsManager.get_setting("system_volume", 80)
	if SettingsManager.get_setting("sound", true) != null:
		_sfx_enabled = SettingsManager.get_setting("sound", true)
	if SettingsManager.get_setting("sound_volume", 75) != null:
		_sfx_volume_percent = SettingsManager.get_setting("sound_volume", 75)
	if SettingsManager.get_setting("bgm", true) != null:
		_bgm_enabled = SettingsManager.get_setting("bgm", true)
	if SettingsManager.get_setting("bgm_volume", 70) != null:
		_bgm_volume_percent = SettingsManager.get_setting("bgm_volume", 70)
	
	var db := _percent_to_db(_bgm_volume_percent) if _bgm_enabled and _master_enabled else SILENT_DB
	_player.volume_db = db
