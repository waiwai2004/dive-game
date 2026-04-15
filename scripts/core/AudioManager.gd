extends Node

const BGM_PATH := "res://assets/audio/bgm/Eight.wav"
const SILENT_DB := -60.0

# Placeholder segment timings. You can tune these values directly.
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
var _target_volume_db := -10.0
var _current_segment := ""
var _segment_start := 0.0
var _segment_end := 0.0
var _request_id := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	_player.name = "BGMPlayer"
	_player.stream = load(BGM_PATH)
	_player.volume_db = _target_volume_db
	add_child(_player)


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
	_player.volume_db = _target_volume_db
	_current_segment = ""


func set_volume(db: float) -> void:
	_target_volume_db = db
	_player.volume_db = _target_volume_db


func _switch_segment(start_time: float, fade_duration: float, request_id: int) -> void:
	_kill_fade_tween()

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
		_fade_tween.tween_property(_player, "volume_db", _target_volume_db, fade_duration)
	else:
		_player.volume_db = _target_volume_db


func _kill_fade_tween() -> void:
	if _fade_tween and is_instance_valid(_fade_tween):
		_fade_tween.kill()
		_fade_tween = null
