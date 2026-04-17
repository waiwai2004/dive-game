extends Button

## 手牌视图：支持 hover 放大、点击使用、拖拽至敌人区打出。

signal card_pressed(card_index)
signal card_dragged_to_enemy(card_index, release_global_position)

const HOVER_SCALE: Vector2 = Vector2(1.08, 1.08)
const HOVER_DURATION: float = 0.10
const CLICK_DURATION: float = 0.05
const CLICK_SCALE: Vector2 = Vector2(1.03, 1.03)
const DRAG_THRESHOLD: float = 10.0

@export var show_legacy_frame: bool = true

var card_data: Dictionary = {}
var card_index: int = -1
var battle_scene: Node = null

@onready var card_view: Node = get_node_or_null("CardView")

var _base_scale: Vector2 = Vector2.ONE
var _base_z_index: int = 0
var _hover_tween: Tween = null

var _press_started: bool = false
var _is_dragging: bool = false
var _drag_start_pos: Vector2 = Vector2.ZERO
var _drag_offset: Vector2 = Vector2.ZERO
var _original_parent: Node
var _original_global_position: Vector2
var _enemy_area: Control


func _ready() -> void:
	clip_text = true
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	focus_mode = Control.FOCUS_NONE
	flat = not show_legacy_frame

	_base_scale = scale
	_base_z_index = z_index

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)

	_enemy_area = get_tree().get_root().find_child("ArenaRoot", true, false) as Control

	if not card_data.is_empty():
		_refresh_text()


func setup(data: Dictionary, index: int, owner_scene: Node) -> void:
	card_data = data
	card_index = index
	battle_scene = owner_scene
	if is_node_ready():
		_refresh_text()
	else:
		call_deferred("_refresh_text")


func _refresh_text() -> void:
	if card_view and card_view.has_method("setup_from_dictionary"):
		card_view.call("setup_from_dictionary", card_data)
		text = ""
		return

	var name_text := str(card_data.get("name", "未知卡牌"))
	var type_text := CardDatabase.get_type_text(str(card_data.get("type", "")))
	var cost := int(card_data.get("cost", 0))
	var cognition := int(card_data.get("cognition", 0))
	var desc := str(card_data.get("description", card_data.get("desc", "")))
	text = "%s  [%s]\n%d费  认知%d\n%s" % [name_text, type_text, cost, cognition, desc]


## 判定是否以"敌人"为目标：显式 target 字段优先；否则看造伤/施弱。
func _targets_enemy() -> bool:
	if card_data.has("target"):
		var t := str(card_data["target"]).to_lower()
		if t in ["enemy", "single_enemy", "foe", "target"]:
			return true
		if t in ["self", "all", "ally", "none"]:
			return false
	return int(card_data.get("damage", 0)) > 0 or int(card_data.get("apply_weak", 0)) > 0


# ====== 输入处理 ======
func _on_gui_input(event: InputEvent) -> void:
	if disabled:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_press()
		else:
			_end_press()
		accept_event()


func _begin_press() -> void:
	_press_started = true
	_is_dragging = false
	_drag_start_pos = get_global_mouse_position()
	_drag_offset = global_position - _drag_start_pos
	_original_parent = get_parent()
	_original_global_position = global_position


func _end_press() -> void:
	if not _press_started:
		return
	_press_started = false

	var moved := get_global_mouse_position().distance_to(_drag_start_pos)
	var was_click := not _is_dragging or moved < DRAG_THRESHOLD
	var dropped_on_enemy := _mouse_over_enemy()

	# 决定是否真正使用：点击直接打；拖拽则看是否命中敌人（自/全体目标松手即打）
	var should_play := was_click or (not _targets_enemy()) or dropped_on_enemy

	# 还原外观
	_is_dragging = false
	top_level = false
	z_index = _base_z_index
	scale = Vector2.ONE
	self_modulate = Color(1, 1, 1, 1)

	if _original_parent and is_instance_valid(_original_parent):
		if get_parent() != _original_parent:
			_original_parent.add_child(self)
		global_position = _original_global_position

	if should_play and battle_scene != null:
		_play_click_feedback()
		if dropped_on_enemy and _targets_enemy():
			card_dragged_to_enemy.emit(card_index, get_global_mouse_position())
		card_pressed.emit(card_index)
		battle_scene.call("play_card", card_index)


func _process(_delta: float) -> void:
	if not _press_started:
		return

	# 超过阈值进入拖拽
	if not _is_dragging and get_global_mouse_position().distance_to(_drag_start_pos) >= DRAG_THRESHOLD:
		_is_dragging = true
		top_level = true
		z_index = 100
		scale = Vector2(1.05, 1.05)
		self_modulate = Color(1, 1, 1, 0.92)

	if _is_dragging:
		global_position = get_global_mouse_position() + _drag_offset
		var hover := _targets_enemy() and _mouse_over_enemy()
		self_modulate = Color(1.0, 0.95, 0.9, 0.95) if hover else Color(1, 1, 1, 0.9)


func _mouse_over_enemy() -> bool:
	if _enemy_area == null or not is_instance_valid(_enemy_area):
		return false
	return _enemy_area.get_global_rect().has_point(get_global_mouse_position())


# ====== Hover / Click 动画 ======
func _on_mouse_entered() -> void:
	_play_hover_animation(true)
	if battle_scene and battle_scene.has_method("show_card_tooltip"):
		battle_scene.call("show_card_tooltip", card_data)


func _on_mouse_exited() -> void:
	_play_hover_animation(false)
	if battle_scene and battle_scene.has_method("hide_card_tooltip"):
		battle_scene.call("hide_card_tooltip")


func _play_hover_animation(hovered: bool) -> void:
	if _hover_tween and is_instance_valid(_hover_tween):
		_hover_tween.kill()

	_hover_tween = create_tween()
	if hovered:
		z_index = _base_z_index + 20
		_hover_tween.tween_property(self, "scale", HOVER_SCALE, HOVER_DURATION)
	else:
		_hover_tween.tween_property(self, "scale", _base_scale, HOVER_DURATION)
		_hover_tween.finished.connect(func() -> void: z_index = _base_z_index)


func _play_click_feedback() -> void:
	if _hover_tween and is_instance_valid(_hover_tween):
		_hover_tween.kill()
	var tw := create_tween()
	tw.tween_property(self, "scale", CLICK_SCALE, CLICK_DURATION)
	tw.tween_property(self, "scale", _base_scale, CLICK_DURATION)
