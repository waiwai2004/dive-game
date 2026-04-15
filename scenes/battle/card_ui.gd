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

# 拖拽相关变量
var is_dragging: bool = false
var drag_start_pos: Vector2 = Vector2.ZERO
var drag_offset: Vector2 = Vector2.ZERO
var original_parent: Node
var original_position: Vector2
var original_global_position: Vector2
var enemy_area: Control

const HOVER_SCALE: Vector2 = Vector2(1.12, 1.12)
const HOVER_DURATION: float = 0.12
const CLICK_DURATION: float = 0.05
const CLICK_SCALE: Vector2 = Vector2(1.04, 1.04)
const DRAG_THRESHOLD: float = 5.0


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
	
	# 初始化敌人区域
	enemy_area = get_tree().get_root().find_child("BossArea", true, false) as Control

	# setup() might run before add_child(). Refresh once when tree is ready.
	if not card_data.is_empty():
		_refresh_text()


func setup(data: Dictionary, index: int, owner_scene: Node) -> void:
	card_data = data
	card_index = index
	battle_scene = owner_scene
	if card_data.is_empty():
		push_warning("[CardUI] setup got empty card_data at hand index %d" % card_index)
	if is_node_ready():
		_refresh_text()
	else:
		call_deferred("_refresh_text")


func _refresh_text() -> void:
	print("[CardUI] id=%s name=%s frame=%s illustration=%s card_view_ready=%s" % [
		str(card_data.get("id", "")),
		str(card_data.get("name", card_data.get("card_name", ""))),
		str(card_data.get("art_frame_path", "")),
		str(card_data.get("art_illustration_path", "")),
		str(card_view != null)
	])

	if card_view and card_view.has_method("setup_from_dictionary"):
		card_view.call("setup_from_dictionary", card_data)
		text = ""
		return

	var name_text: String = str(card_data.get("name", "鏈煡鍗＄墝"))
	var type_text: String = CardDatabase.get_type_text(str(card_data.get("type", "")))
	var cost: int = int(card_data.get("cost", 0))
	var cognition: int = int(card_data.get("cognition", 0))
	var desc: String = str(card_data.get("description", card_data.get("desc", "")))
	text = "%s  [%s]\n%d璐?璁ょ煡%d\n%s" % [name_text, type_text, cost, cognition, desc]


func _pressed() -> void:
	if not is_dragging and battle_scene != null:
		_play_click_feedback()
		battle_scene.call("play_card", card_index)
		card_pressed.emit(card_index)

func _on_gui_input(event: InputEvent) -> void:
	if disabled:
		return

	# 处理鼠标按下
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# 开始拖拽
		is_dragging = true
		drag_start_pos = get_global_mouse_position()
		drag_offset = global_position - drag_start_pos
		original_parent = get_parent()
		original_position = position
		original_global_position = global_position
		
		# 提升卡牌层级
		top_level = true
		z_index = 100
		scale = Vector2(1.05, 1.05)
		self_modulate = Color(1, 1, 1, 0.9)
		
		# 阻止事件冒泡
		accept_event()
		
	# 处理鼠标释放
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_dragging:
			is_dragging = false
			
			# 检查是否释放到敌人区域
			var dropped_on_enemy = false
			if enemy_area and is_instance_valid(enemy_area):
				dropped_on_enemy = enemy_area.get_global_rect().has_point(get_global_mouse_position())
			
			# 恢复卡牌状态
			top_level = false
			z_index = 0
			scale = Vector2.ONE
			self_modulate = Color(1, 1, 1, 1)
			
			# 确保卡牌回到原始父节点和位置
			if original_parent and is_instance_valid(original_parent):
				if get_parent() != original_parent:
					original_parent.add_child(self)
				# 恢复原始位置
				global_position = original_global_position
			
			# 如果释放到敌人区域，使用卡牌
			if dropped_on_enemy and battle_scene != null:
				card_dragged_to_enemy.emit(card_index, global_position)
				battle_scene.call("play_card", card_index)
			
			# 阻止事件冒泡，避免触发_pressed()
			accept_event()

func _process(_delta: float) -> void:
	if is_dragging:
		# 更新卡牌位置
		var target_pos = get_global_mouse_position() + drag_offset
		global_position = target_pos
		
		# 检查是否悬停在敌人区域
		var hovering_enemy = false
		if enemy_area and is_instance_valid(enemy_area):
			hovering_enemy = enemy_area.get_global_rect().has_point(get_global_mouse_position())
			
		# 悬停效果
		if hovering_enemy:
			self_modulate = Color(1.0, 0.95, 0.9, 0.95)
			# 敌人图标高亮效果
			_apply_enemy_highlight(true)
		else:
			self_modulate = Color(1, 1, 1, 0.9)
			# 取消敌人图标高亮效果
			_apply_enemy_highlight(false)

func _apply_enemy_highlight(active: bool) -> void:
	if enemy_area and is_instance_valid(enemy_area):
		# 获取敌人图标节点
		var boss_portrait = enemy_area.get_node_or_null("BossPortrait")
		if boss_portrait and is_instance_valid(boss_portrait):
			var tween = create_tween()
			tween.set_trans(Tween.TRANS_CUBIC)
			tween.set_ease(Tween.EASE_OUT)
			
			if active:
				# 增强白光效果，使高光更加明显
				tween.tween_property(boss_portrait, "modulate", Color(1.2, 1.2, 1.2, 1.0), 0.1)
			else:
				# 恢复敌人图标原始状态
				tween.tween_property(boss_portrait, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)


func _on_mouse_entered() -> void:
	_play_hover_animation(true)


func _on_mouse_exited() -> void:
	_play_hover_animation(false)


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
	# Legacy conflicting layer is this Button's StyleBox background.
	# Keep style resources, only toggle via `flat` so it's reversible in Inspector.
	flat = not show_legacy_frame
