extends Control

signal choice_pressed

@export var normal_texture: Texture2D
@export var hover_texture: Texture2D
@export var pressed_texture: Texture2D
@export var disabled_modulate: Color = Color(0.55, 0.55, 0.55, 1.0)
@export var hover_scale: Vector2 = Vector2(1.05, 1.05)
@export var tween_duration: float = 0.12

@onready var visual_root = $VisualRoot
@onready var bg = $VisualRoot/Bg
@onready var hover_glow = $VisualRoot/HoverFx
@onready var text_label = $VisualRoot/Label
@onready var click_button = $ClickButton

var _is_disabled := false
var _tween: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS

	click_button.flat = true
	click_button.text = ""
	click_button.focus_mode = Control.FOCUS_NONE
	click_button.mouse_filter = Control.MOUSE_FILTER_STOP

	if normal_texture:
		bg.texture = normal_texture

	hover_glow.visible = false

	# 只更新缩放中心，不改你的编辑器布局
	await get_tree().process_frame
	_update_pivot()

	click_button.mouse_entered.connect(_on_mouse_entered)
	click_button.mouse_exited.connect(_on_mouse_exited)
	click_button.pressed.connect(_on_pressed)

func _update_pivot() -> void:
	visual_root.pivot_offset = visual_root.size * 0.5

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		_update_pivot()

func set_choice_text(value: String) -> void:
	text_label.text = value

func set_disabled_state(value: bool) -> void:
	_is_disabled = value
	click_button.disabled = value

	if value:
		visual_root.modulate = disabled_modulate
		hover_glow.visible = false
		_set_scale(Vector2.ONE)
	else:
		visual_root.modulate = Color.WHITE

func _on_mouse_entered() -> void:
	if _is_disabled:
		return

	if hover_texture:
		bg.texture = hover_texture

	hover_glow.visible = true
	_tween_scale(hover_scale)

func _on_mouse_exited() -> void:
	if _is_disabled:
		return

	if normal_texture:
		bg.texture = normal_texture

	hover_glow.visible = false
	_tween_scale(Vector2.ONE)

func _on_pressed() -> void:
	if _is_disabled:
		return

	if pressed_texture:
		bg.texture = pressed_texture

	var t = create_tween()
	t.tween_property(visual_root, "scale", Vector2(0.96, 0.96), 0.05)
	t.tween_property(visual_root, "scale", hover_scale, 0.07)

	choice_pressed.emit()

func _tween_scale(target: Vector2) -> void:
	if _tween:
		_tween.kill()

	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_OUT)
	_tween.tween_property(visual_root, "scale", target, tween_duration)

func _set_scale(value: Vector2) -> void:
	visual_root.scale = value
