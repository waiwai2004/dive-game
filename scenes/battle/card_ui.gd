extends Button

signal card_pressed(card_index)
signal card_dragged_to_enemy(card_index, release_global_position)

@export var show_legacy_frame: bool = true

var card_data: Dictionary = {}
var card_index: int = -1
var battle_scene: Node = null
@onready var card_view: Node = get_node_or_null("CardView")

var _base_scale: Vector2 = Vector2.ONE
var _base_z_index: int = 0
var _hover_tween: Tween = null

var is_dragging: bool = false
var _press_started: bool = false
var drag_start_pos: Vector2 = Vector2.ZERO
var drag_offset: Vector2 = Vector2.ZERO
var original_parent: Node
var original_global_position: Vector2
var enemy_area: Control

const HOVER_SCALE: Vector2 = Vector2(1.08, 1.08)
const HOVER_DURATION: float = 0.10
const CLICK_DURATION: float = 0.05
const CLICK_SCALE: Vector2 = Vector2(1.03, 1.03)
const DRAG_THRESHOLD: float = 10.0


func _enter_tree() -> void:
	_apply_legacy_frame_visibility()


func _ready() -> void:
	clip_text = true
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	focus_mode = Control.FOCUS_NONE
	_apply_legacy_frame_visibility()

	_base_scale = scale
	_base_z_index = z_index

	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)
	if not gui_input.is_connected(_on_gui_input):
		gui_input.connect(_on_gui_input)

	set_process(true)
	enemy_area = get_tree().get_root().find_child("ArenaRoot", true, false) as Control

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

	var name_text: String = str(card_data.get("name", "未知卡牌"))
	var type_text: String = CardDatabase.get_type_text(str(card_data.get("type", "")))
	var cost: int = int(card_data.get("cost", 0))
	var cognition: int = int(card_data.get("cognition", 0))
	var desc: String = str(card_data.get("description", card_data.get("desc", "")))
	text = "%s  [%s]\n%d费  认知%d\n%s" % [name_text, type_text, cost, cognition, desc]


# 通过卡牌数据判定是否目标敌人
# 目前规则：造成伤害或施加虚弱 -> 目标敌人；其他（加盾、回SAN、抽牌等）-> 自身/全体
func _targets_enemy() -> bool:
	if card_data.has("target"):
		var t: String = str(card_data["target"]).to_lower()
		if t in ["enemy", "single_enemy", "foe", "target"]:
			return true
		if t in ["self", "all", "ally", "none"]:
			return false
	var damage: int = int(card_data.get("damage", 0))
	var apply_weak: int = int(card_data.get("apply_weak", 0))
	return damage > 0 or apply_weak > 0


# 保留 _pressed 但简化：仅作为保险，避免某些纯键盘/触屏事件的情况。
func _pressed() -> void:
	# 实际触发由 _on_gui_input 完成，这里留空避免双触发。
	pass


func _on_gui_input(event: InputEvent) -> void:
	if disabled:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_press_started = true
		is_dragging = false
		drag_start_pos = get_global_mouse_position()
		drag_offset = global_position - drag_start_pos
		original_parent = get_parent()
		original_global_position = global_position
		accept_event()
		return

	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not _press_started:
			return
		_press_started = false

		var moved_distance: float = get_global_mouse_position().distance_to(drag_start_pos)
		var was_click: bool = not is_dragging or moved_distance < DRAG_THRESHOLD

		var dropped_on_enemy: bool = false
		if enemy_area and is_instance_valid(enemy_area):
			dropped_on_enemy = enemy_area.get_global_rect().has_point(get_global_mouse_position())

		# 决定是否打出
		var should_play: bool = false
		if was_click:
			should_play = true
		elif _targets_enemy():
			should_play = dropped_on_enemy
		else:
			# 自身 / 全体目标：松手即打出
			should_play = true

		# 还原外观
		is_dragging = false
		top_level = false
		z_index = _base_z_index
		scale = Vector2.ONE
		self_modulate = Color(1, 1, 1, 1)

		if original_parent and is_instance_valid(original_parent):
			if get_parent() != original_parent:
				original_parent.add_child(self)
			global_position = original_global_position

		if should_play and battle_scene != null:
			_play_click_feedback()
			if dropped_on_enemy and _targets_enemy():
				card_dragged_to_enemy.emit(card_index, get_global_mouse_position())
			card_pressed.emit(card_index)
			battle_scene.call("play_card", card_index)

		accept_event()


func _process(_delta: float) -> void:
	if not _press_started:
		return

	# 超过阈值后正式进入拖拽状态
	if not is_dragging:
		if get_global_mouse_position().distance_to(drag_start_pos) >= DRAG_THRESHOLD:
			is_dragging = true
			top_level = true
			z_index = 100
			scale = Vector2(1.05, 1.05)
			self_modulate = Color(1, 1, 1, 0.92)

	if is_dragging:
		global_position = get_global_mouse_position() + drag_offset

		var hovering_enemy: bool = false
		if _targets_enemy() and enemy_area and is_instance_valid(enemy_area):
			hovering_enemy = enemy_area.get_global_rect().has_point(get_global_mouse_position())

		if hovering_enemy:
			self_modulate = Color(1.0, 0.95, 0.9, 0.95)
		else:
			self_modulate = Color(1, 1, 1, 0.9)


func _on_mouse_entered() -> void:
	_play_hover_animation(true)
	if battle_scene and battle_scene.has_method("show_card_tooltip"):
		battle_scene.call("show_card_tooltip", card_data)


func _on_mouse_exited() -> void:
	_play_hover_animation(false)
	if battle_scene and battle_scene.has_method("hide_card_tooltip"):
		battle_scene.call("hide_card_tooltip")


func _play_hover_animation(hovered: bool) -> void:
	_kill_hover_tween()

	_hover_tween = create_tween()
	if hovered:
		z_index = _base_z_index + 20
		_hover_tween.tween_property(self, "scale", HOVER_SCALE, HOVER_DURATION)
	else:
		_hover_tween.tween_property(self, "scale", _base_scale, HOVER_DURATION)
		_hover_tween.finished.connect(func() -> void:
			z_index = _base_z_index
		)


func _play_click_feedback() -> void:
	_kill_hover_tween()
	var click_tween: Tween = create_tween()
	click_tween.tween_property(self, "scale", CLICK_SCALE, CLICK_DURATION)
	click_tween.tween_property(self, "scale", _base_scale, CLICK_DURATION)


func _kill_hover_tween() -> void:
	if _hover_tween and is_instance_valid(_hover_tween):
		_hover_tween.kill()
		_hover_tween = null


func _apply_legacy_frame_visibility() -> void:
	flat = not show_legacy_frame
