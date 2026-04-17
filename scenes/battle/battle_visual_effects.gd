## 战斗视觉反馈
## 职责：
##  - BOSS 的待机呼吸动画（上下浮动）
##  - BOSS 被击打的抖动/变色反馈
##  - 对外提供 ProgressBar / 圆形按钮的 StyleBoxFlat 工具方法（static），供 UIManager 使用
class_name BattleVisualEffects
extends Node

const IDLE_BASE_Y := 26.0
const IDLE_AMPLITUDE := 6.0
const IDLE_FREQUENCY := 1.7

var _boss_portrait: TextureRect
var _hit_tween: Tween = null
var _idle_phase: float = 0.0
var _idle_enabled: bool = true


func setup(boss_portrait: TextureRect) -> void:
	_boss_portrait = boss_portrait


func set_idle_enabled(enabled: bool) -> void:
	_idle_enabled = enabled


func _process(delta: float) -> void:
	if not _idle_enabled or not is_instance_valid(_boss_portrait):
		return
	_idle_phase += delta
	_boss_portrait.position.y = IDLE_BASE_Y + sin(_idle_phase * IDLE_FREQUENCY) * IDLE_AMPLITUDE


func play_enemy_hit_feedback() -> void:
	if not is_instance_valid(_boss_portrait):
		return
	if _hit_tween and is_instance_valid(_hit_tween):
		_hit_tween.kill()

	var start_pos := _boss_portrait.position
	var start_modulate := _boss_portrait.modulate
	_boss_portrait.modulate = Color(1.25, 1.15, 1.15, 1.0)

	_hit_tween = create_tween()
	_hit_tween.tween_property(_boss_portrait, "position", start_pos + Vector2(-10, 0), 0.03)
	_hit_tween.tween_property(_boss_portrait, "position", start_pos + Vector2(8, 0), 0.03)
	_hit_tween.tween_property(_boss_portrait, "position", start_pos, 0.04)
	_hit_tween.parallel().tween_property(_boss_portrait, "modulate", start_modulate, 0.16)


# ====== 样式工具（static，供 UIManager 调用） ======

static func _make_style(bg: Color, border: Color, corner: int, border_width: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	for c in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		sb.set("corner_radius_" + c, corner)
	for side in ["left", "top", "right", "bottom"]:
		sb.set("border_width_" + side, border_width)
	return sb


static func apply_bar_style(bar: ProgressBar, fill_color: Color, border_color: Color) -> void:
	var fill := _make_style(fill_color, border_color, 8, 1)
	var bg := _make_style(Color(0.06, 0.07, 0.10, 0.94), Color(0, 0, 0, 0), 8, 0)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", bg)


static func apply_boss_hp_style(bar: ProgressBar) -> void:
	var fill := _make_style(Color(0.82, 0.14, 0.22, 0.98), Color(1.0, 0.62, 0.66, 0.85), 10, 2)
	var bg := _make_style(Color(0.14, 0.07, 0.08, 0.92), Color(0, 0, 0, 0), 10, 0)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", bg)


static func make_circle_icon_style(color: Color) -> StyleBoxFlat:
	return _make_style(color, Color(1, 1, 1, 0.5), 26, 2)
