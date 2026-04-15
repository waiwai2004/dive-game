extends Control

const DEFAULT_BASE_SCENE := "res://scenes/base/BaseScene.tscn"
const DEFAULT_EXPLORE_SCENE := "res://scenes/explore/ExploreScene.tscn"

@export var base_scene_path: String = DEFAULT_BASE_SCENE
@export var explore_scene_path: String = DEFAULT_EXPLORE_SCENE
@export var allow_esc_back: bool = true
@export var click_fade_duration: float = 0.45
@export var narration_line_duration: float = 1.4
@export var final_fade_duration: float = 0.35
@export var narration_fade_alpha: float = 0.78

@export_multiline var description_text: String = "先前往浅海中继点，确认讯号，回收记录。"
@export_multiline var narration_line_1: String = "于是，你接受了这份不该开始的下潜任务。"
@export_multiline var narration_line_2: String = "海面之下，是旧文明沉没后的遗骸。"
@export_multiline var narration_line_3: String = "而你，正要前往它们之间的第一层边界。"

@onready var dive_button: Button = $DiveButton
@onready var description_label: Label = $DescriptionLabel
@onready var hint_label: Label = $HintLabel
@onready var fade_rect: ColorRect = $FadeRect
@onready var narration_label: RichTextLabel = $NarrationLabel

var _is_transitioning := false


func _ready() -> void:
	if has_node("/root/AudioManager"):
		AudioManager.play_bgm_segment("explore")

	_apply_global_ui()
	_setup_initial_content()

	if dive_button and not dive_button.pressed.is_connected(_on_dive_pressed):
		dive_button.pressed.connect(_on_dive_pressed)

	fade_rect.visible = true
	fade_rect.color.a = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if _is_transitioning:
		return

	if allow_esc_back and event.is_action_pressed("ui_cancel"):
		_return_to_base()


func _setup_initial_content() -> void:
	description_label.text = description_text
	var hint_text := "点击“下潜”开始"
	if allow_esc_back:
		hint_text += "   ESC 返回基地"
	hint_label.text = hint_text
	hint_label.visible = not has_node("/root/GlobalUI")
	narration_label.visible = false
	narration_label.text = ""

	if has_node("/root/GlobalUI"):
		GlobalUI.set_hint(hint_text, true)


func _apply_global_ui() -> void:
	if has_node("/root/GlobalUI"):
		GlobalUI.set_mode(GlobalUI.MODE_STORY)
		GlobalUI.refresh_stats()


func _on_dive_pressed() -> void:
	if _is_transitioning:
		return

	_is_transitioning = true
	dive_button.visible = false
	hint_label.visible = false
	description_label.visible = false

	if has_node("/root/GlobalUI"):
		GlobalUI.set_hint("下潜中...", true)

	await _fade_to_alpha(narration_fade_alpha, click_fade_duration)
	await _play_narration_sequence()
	await _fade_to_alpha(1.0, final_fade_duration)
	_go_to_explore()


func _play_narration_sequence() -> void:
	var lines: Array[String] = []
	if not narration_line_1.strip_edges().is_empty():
		lines.append(narration_line_1.strip_edges())
	if not narration_line_2.strip_edges().is_empty():
		lines.append(narration_line_2.strip_edges())
	if not narration_line_3.strip_edges().is_empty():
		lines.append(narration_line_3.strip_edges())

	if lines.is_empty():
		return

	narration_label.visible = true
	for line in lines:
		narration_label.text = line
		await get_tree().create_timer(narration_line_duration).timeout


func _return_to_base() -> void:
	_is_transitioning = true
	await _fade_to_alpha(1.0, 0.25)
	get_tree().change_scene_to_file(base_scene_path)


func _go_to_explore() -> void:
	if has_node("/root/Game"):
		Game.goto_explore()
	else:
		get_tree().change_scene_to_file(explore_scene_path)


func _fade_to_alpha(target_alpha: float, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", target_alpha, duration)
	await tween.finished
