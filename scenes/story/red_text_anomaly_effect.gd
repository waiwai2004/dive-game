extends RichTextLabel

@export var enable_jitter: bool = true
@export var jitter_amplitude: float = 2.2
@export var jitter_speed: float = 16.0

@export var enable_alpha_pulse: bool = true
@export var alpha_min: float = 0.82
@export var alpha_max: float = 1.0
@export var alpha_speed: float = 3.4

@export var enable_scale_pulse: bool = false
@export var scale_amplitude: float = 0.015
@export var scale_speed: float = 2.2

var _effect_enabled: bool = false
var _base_position: Vector2 = Vector2.ZERO
var _base_scale: Vector2 = Vector2.ONE
var _base_modulate: Color = Color.WHITE
var _time_passed: float = 0.0
var _phase_x: float = 0.0
var _phase_y: float = 0.0


func _ready() -> void:
	_base_position = position
	_base_scale = scale
	_base_modulate = modulate
	_phase_x = randf() * TAU
	_phase_y = randf() * TAU
	set_process(true)
	_restore_base_state()


func set_effect_enabled(enabled: bool) -> void:
	_effect_enabled = enabled
	if not _effect_enabled:
		_restore_base_state()


func _process(delta: float) -> void:
	if not _effect_enabled:
		return

	_time_passed += delta

	var final_position: Vector2 = _base_position
	if enable_jitter:
		var jx: float = sin(_time_passed * jitter_speed + _phase_x)
		var jy: float = cos(_time_passed * jitter_speed * 1.17 + _phase_y)
		final_position += Vector2(jx, jy) * jitter_amplitude
	position = final_position

	var final_modulate: Color = _base_modulate
	if enable_alpha_pulse:
		var pulse01: float = 0.5 + 0.5 * sin(_time_passed * alpha_speed)
		var alpha_value: float = lerpf(alpha_min, alpha_max, pulse01)
		final_modulate.a = _base_modulate.a * clampf(alpha_value, 0.0, 1.0)
	modulate = final_modulate

	var final_scale: Vector2 = _base_scale
	if enable_scale_pulse:
		var s: float = 1.0 + sin(_time_passed * scale_speed) * scale_amplitude
		final_scale = _base_scale * s
	scale = final_scale


func _restore_base_state() -> void:
	position = _base_position
	scale = _base_scale
	modulate = _base_modulate
