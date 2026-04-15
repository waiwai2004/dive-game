extends Control

const BASE_SCENE_PATH := "res://scenes/base/BaseScene.tscn"
const STORY_DATA := preload("res://data/story_data.gd")
const RED_TEXT_COLOR := Color(0.85, 0.15, 0.15, 1.0)
const WHITE_TEXT_COLOR := Color(1.0, 1.0, 1.0, 1.0)

@onready var background: ColorRect = $Background
@onready var illustration: TextureRect = $Illustration
@onready var dialogue_panel: PanelContainer = $DialoguePanel
@onready var story_text: RichTextLabel = $DialoguePanel/StoryText
@onready var center_text: RichTextLabel = $CenterText
@onready var page_hint: Label = $PageHint
@onready var fade_rect: ColorRect = $FadeRect

var _pages: Array[Dictionary] = STORY_DATA.PAGES
var _current_index := 0
var _is_transitioning := false


func _ready() -> void:
	if has_node("/root/AudioManager"):
		AudioManager.play_bgm_segment("story")
	if has_node("/root/GlobalUI"):
		GlobalUI.set_mode(GlobalUI.MODE_STORY)
		GlobalUI.set_hint("空格 / Z 下一页    ESC 跳过")
		GlobalUI.refresh_stats()

	_show_page(_current_index)
	page_hint.text = "左键 / 空格 / Z 下一页    ESC 跳过"
	page_hint.visible = not has_node("/root/GlobalUI")

	fade_rect.visible = true
	fade_rect.color.a = 1.0
	await _fade_to_alpha(0.0, 0.25)


func _unhandled_input(event: InputEvent) -> void:
	if _is_transitioning:
		return

	if _is_skip_pressed(event):
		_go_to_base_with_fade()
		return

	if _is_advance_pressed(event):
		_next_page()


func _is_advance_pressed(event: InputEvent) -> bool:
	if event.is_action_pressed("advance"):
		return true

	if event is InputEventKey and event.pressed and not event.echo:
		return event.keycode == KEY_Z

	return false


func _is_skip_pressed(event: InputEvent) -> bool:
	if event.is_action_pressed("ui_cancel"):
		return true

	if event is InputEventKey and event.pressed and not event.echo:
		return event.keycode == KEY_ESCAPE

	return false


func _next_page() -> void:
	if _current_index >= _pages.size() - 1:
		_go_to_base_with_fade()
		return

	_current_index += 1
	_show_page(_current_index)


func _show_page(index: int) -> void:
	if index < 0 or index >= _pages.size():
		return

	var page: Dictionary = _pages[index]
	var page_type := String(page.get("type", "credit"))
	_set_red_text_effect_enabled(page_type == "black_text_red")

	background.color = Color.BLACK
	center_text.clear()
	story_text.clear()

	match page_type:
		"story":
			_show_story_page(page)
		"black_text_red":
			_show_center_text_page(page, RED_TEXT_COLOR)
		_:
			_show_center_text_page(page, WHITE_TEXT_COLOR)


func _show_story_page(page: Dictionary) -> void:
	illustration.visible = true
	dialogue_panel.visible = true
	center_text.visible = false

	var image_path := String(page.get("image", ""))
	var text_value := String(page.get("text", ""))
	story_text.text = text_value

	if image_path.is_empty():
		illustration.texture = null
		return

	var image_tex := load(image_path)
	if image_tex is Texture2D:
		illustration.texture = image_tex
	else:
		illustration.texture = null
		push_warning("Story image load failed: %s" % image_path)


func _show_center_text_page(page: Dictionary, color: Color) -> void:
	illustration.visible = false
	dialogue_panel.visible = false
	center_text.visible = true

	center_text.text = String(page.get("text", ""))
	center_text.add_theme_color_override("default_color", color)


func _go_to_base_with_fade() -> void:
	if _is_transitioning:
		return

	_is_transitioning = true
	await _fade_to_alpha(1.0, 0.35)
	get_tree().change_scene_to_file(BASE_SCENE_PATH)


func _fade_to_alpha(target_alpha: float, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", target_alpha, duration)
	await tween.finished


func _set_red_text_effect_enabled(enabled: bool) -> void:
	if center_text.has_method("set_effect_enabled"):
		center_text.call("set_effect_enabled", enabled)
