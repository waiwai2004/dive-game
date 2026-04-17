extends Control

const BASE_SCENE_PATH := "res://scenes/base/BaseScene.tscn"
const STORY_DATA := preload("res://data/story_data.gd")

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
	# 确保开启 BBCode 解析
	story_text.bbcode_enabled = true
	center_text.bbcode_enabled = true
	  
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

	background.color = Color.BLACK
	center_text.text = "" 
	story_text.text = ""

	# 有图就按剧情页显示，没图就按居中文字显示
	if page.has("image"):
		_show_story_page(page)
	else:
		_show_center_text_page(page)


func _show_story_page(page: Dictionary) -> void:
	illustration.visible = true
	dialogue_panel.visible = true
	center_text.visible = false

	var image_path := String(page.get("image", ""))
	# 改为直接赋值，颜色和特效全靠文字内的 BBCode 解析
	story_text.text = String(page.get("text", ""))

	if image_path.is_empty():
		illustration.texture = null
		return

	var image_tex := load(image_path)
	if image_tex is Texture2D:
		illustration.texture = image_tex
	else:
		illustration.texture = null
		push_warning("Story image load failed: %s" % image_path)


func _show_center_text_page(page: Dictionary) -> void:
	illustration.visible = false
	dialogue_panel.visible = false
	center_text.visible = true

	# 改为直接赋值，颜色和特效全靠文字内的 BBCode 解析
	center_text.text = String(page.get("text", ""))


func _go_to_base_with_fade() -> void:
	if _is_transitioning:
		return

	_is_transitioning = true
	await _fade_to_alpha(1.0, 0.35)
	
	# 尝试加载场景，添加错误处理
	var scene = load(BASE_SCENE_PATH)
	if scene:
		get_tree().change_scene_to_packed(scene)
	else:
		print("Error: Failed to load BaseScene.tscn")
		# 如果加载失败，尝试使用备用方法
		get_tree().change_scene_to_file(BASE_SCENE_PATH)


func _fade_to_alpha(target_alpha: float, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", target_alpha, duration)
	await tween.finished
