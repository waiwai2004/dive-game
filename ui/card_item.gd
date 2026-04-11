extends Button

signal card_pressed(instance_id)
signal card_dragged_to_enemy(instance_id, release_global_position)

@onready var card_frame = $CardFrame
@onready var art_image = $ContentMargin/ContentVBox/ArtHolder/ArtImage
@onready var name_label = $ContentMargin/ContentVBox/NameLabel
@onready var type_label = $ContentMargin/ContentVBox/TypeLabel
@onready var cost_label = $ContentMargin/ContentVBox/CostLabel
@onready var desc_label = $ContentMargin/ContentVBox/DescLabel

var card_instance_id: int = -1
var is_selected := false
var _is_hovered := false
var is_pressing := false
var is_dragging := false
var drag_offset := Vector2.ZERO
var drag_start_mouse_pos := Vector2.ZERO
var drag_threshold := 5.0
var _original_position := Vector2.ZERO
var _original_global_pos := Vector2.ZERO
var _enemy_panel: Control
var _selection_tween: Tween
var _movement_tween: Tween
var _warning_tween: Tween
var _enemy_highlight_tween: Tween
var _suppress_pressed_once := false
var _selected_before_drag := false
var _enemy_panel_base_scale := Vector2.ONE
var _enemy_panel_base_modulate := Color(1, 1, 1, 1)

var art_path_map := {
	"strike": "res://assets/cards/strike.png",
	"bless": "res://assets/cards/bless.png",
	"break": "res://assets/cards/break.png",
	"relief": "res://assets/cards/relief.png",
	"resonance": "res://assets/cards/resonance.png"
}

func setup(data: Dictionary) -> void:
	card_instance_id = data.get("instance_id", -1)

	var card_id = str(data.get("id", ""))
	if art_path_map.has(card_id):
		art_image.texture = load(art_path_map[card_id])

	name_label.text = str(data.get("name", ""))
	type_label.text = str(data.get("type", ""))
	cost_label.text = "Cost %s | Cog %s" % [
		str(data.get("cost", 0)),
		str(data.get("cognition", 0))
	]
	desc_label.text = str(data.get("desc", ""))

func set_selected(selected: bool) -> void:
	is_selected = selected
	
	if _selection_tween:
		_selection_tween.kill()
	
	_selection_tween = create_tween()
	_selection_tween.set_trans(Tween.TRANS_CUBIC)
	_selection_tween.set_ease(Tween.EASE_OUT)
	
	var target_y = _original_position.y
	var target_color = Color(1, 1, 1)
	var target_scale = Vector2.ONE
	
	if is_selected:
		target_y -= 18
		target_color = Color(1.0, 0.95, 0.75)
		target_scale = Vector2(1.03, 1.03)
	elif _is_hovered and not is_dragging:
		target_y -= 6
		target_color = Color(0.94, 1.0, 0.94)
		target_scale = Vector2(1.015, 1.015)
	
	_selection_tween.parallel().tween_property(self, "position:y", target_y, 0.18)
	_selection_tween.parallel().tween_property(self, "self_modulate", target_color, 0.18)
	_selection_tween.parallel().tween_property(self, "scale", target_scale, 0.18)

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	set_process(true)
	# 在帧后初始化原始位置，确保所有布局已完成
	await get_tree().process_frame
	_sync_layout_state()
	_enemy_panel = get_tree().get_root().find_child("EnemyPanel", true, false) as Control
	if _enemy_panel:
		_enemy_panel.pivot_offset = _enemy_panel.size * 0.5
		_enemy_panel_base_scale = _enemy_panel.scale
		_enemy_panel_base_modulate = _enemy_panel.modulate

func _on_mouse_entered() -> void:
	_is_hovered = true
	if not disabled and not is_dragging:
		set_selected(is_selected)

func _on_mouse_exited() -> void:
	_is_hovered = false
	if not is_dragging:
		set_selected(is_selected)

func _on_button_down() -> void:
	if disabled:
		return

	if _movement_tween:
		_movement_tween.kill()

	is_pressing = true
	is_dragging = false
	_suppress_pressed_once = false
	_selected_before_drag = is_selected
	drag_start_mouse_pos = get_global_mouse_position()
	_original_global_pos = global_position
	drag_offset = _original_global_pos - drag_start_mouse_pos

func _on_button_up() -> void:
	if disabled:
		return

	is_pressing = false

	if is_dragging:
		var dropped_on_enemy = _is_pointer_over_enemy()
		is_dragging = false
		_update_enemy_target_highlight(false)

		if dropped_on_enemy:
			var release_global_position = global_position
			top_level = false
			z_index = 0
			self_modulate = Color(1, 1, 1, 1)
			scale = Vector2.ONE
			set_selected(false)
			card_dragged_to_enemy.emit(card_instance_id, release_global_position)
		else:
			_restore_after_cancel_drag()

func _on_gui_input(event: InputEvent) -> void:
	if disabled:
		return

	if event is InputEventMouseMotion and is_pressing and not is_dragging:
		if drag_start_mouse_pos.distance_to(get_global_mouse_position()) > drag_threshold:
			is_dragging = true
			_suppress_pressed_once = true
			if _selection_tween:
				_selection_tween.kill()
			if _movement_tween:
				_movement_tween.kill()
			top_level = true
			global_position = _original_global_pos
			z_index = 10
			scale = Vector2(1.04, 1.04)
			self_modulate = Color(1, 1, 1, 0.9)
			accept_event()

func _process(_delta: float) -> void:
	if is_dragging:
		var target_pos = get_global_mouse_position() + drag_offset
		global_position = global_position.lerp(target_pos, min(1.0, _delta * 20.0))
		var hovering_enemy = _is_pointer_over_enemy()
		_update_enemy_target_highlight(hovering_enemy)
		self_modulate = Color(1.0, 0.98, 0.9, 0.95) if hovering_enemy else Color(1, 1, 1, 0.9)

func _is_pointer_over_enemy() -> bool:
	if _enemy_panel == null or not is_instance_valid(_enemy_panel):
		_enemy_panel = get_tree().get_root().find_child("EnemyPanel", true, false) as Control
		if _enemy_panel:
			_enemy_panel.pivot_offset = _enemy_panel.size * 0.5
			_enemy_panel_base_scale = _enemy_panel.scale
			_enemy_panel_base_modulate = _enemy_panel.modulate

	return _enemy_panel != null and _enemy_panel.get_global_rect().has_point(get_global_mouse_position())

func _update_enemy_target_highlight(active: bool) -> void:
	if _enemy_panel == null or not is_instance_valid(_enemy_panel):
		return

	if _enemy_highlight_tween:
		_enemy_highlight_tween.kill()

	_enemy_highlight_tween = create_tween()
	_enemy_highlight_tween.set_trans(Tween.TRANS_CUBIC)
	_enemy_highlight_tween.set_ease(Tween.EASE_OUT)
	var target_scale = _enemy_panel_base_scale
	var target_modulate = _enemy_panel_base_modulate
	if active:
		target_scale = _enemy_panel_base_scale * Vector2(1.02, 1.02)
		target_modulate = Color(1.0, 0.98, 0.88, 1.0)
	_enemy_highlight_tween.parallel().tween_property(_enemy_panel, "scale", target_scale, 0.1)
	_enemy_highlight_tween.parallel().tween_property(_enemy_panel, "modulate", target_modulate, 0.1)

func animate_layout_from(_from_global: Vector2, _to_global: Vector2) -> void:
	if not is_inside_tree() or is_dragging:
		return

	if _movement_tween:
		_movement_tween.kill()

	_sync_layout_state()
	var target_y = _original_position.y
	if is_selected:
		target_y -= 18
	elif _is_hovered:
		target_y -= 6

	position.y = target_y + 20
	self_modulate.a = 0.0 if self_modulate.a < 0.99 else self_modulate.a

	_movement_tween = create_tween()
	_movement_tween.set_trans(Tween.TRANS_CUBIC)
	_movement_tween.set_ease(Tween.EASE_OUT)
	_movement_tween.parallel().tween_property(self, "position:y", target_y, 0.18)
	_movement_tween.parallel().tween_property(self, "scale", Vector2(1.03, 1.03) if is_selected else Vector2.ONE, 0.18)
	_movement_tween.parallel().tween_property(self, "modulate:a", 1.0, 0.14)

func _restore_after_cancel_drag() -> void:
	if not is_inside_tree():
		return

	if _movement_tween:
		_movement_tween.kill()

	_update_enemy_target_highlight(false)
	top_level = true
	z_index = 10

	_movement_tween = create_tween()
	_movement_tween.set_trans(Tween.TRANS_BACK)
	_movement_tween.set_ease(Tween.EASE_OUT)
	_movement_tween.tween_property(self, "global_position", _original_global_pos, 0.22)
	_movement_tween.parallel().tween_property(self, "self_modulate", Color(1, 1, 1, 1), 0.22)
	_movement_tween.parallel().tween_property(self, "scale", Vector2(1.03, 1.03) if _selected_before_drag else Vector2.ONE, 0.22)
	_movement_tween.tween_callback(func():
		if not is_inside_tree():
			return
		top_level = false
		z_index = 0
		call_deferred("_finalize_after_drag_restore", _selected_before_drag)
	)

func _finalize_after_drag_restore(selected_state: bool) -> void:
	if not is_inside_tree():
		return
	_sync_layout_state()
	set_selected(selected_state)

func _sync_layout_state() -> void:
	if not is_inside_tree():
		return

	pivot_offset = size * 0.5
	_original_position = position
	_original_global_pos = global_position

func play_warning_feedback() -> void:
	if _warning_tween:
		_warning_tween.kill()

	var base_scale = scale
	var base_rotation = rotation_degrees
	var base_modulate = self_modulate
	_warning_tween = create_tween()
	_warning_tween.set_trans(Tween.TRANS_SINE)
	_warning_tween.set_ease(Tween.EASE_OUT)
	_warning_tween.parallel().tween_property(self, "self_modulate", Color(1.0, 0.72, 0.72, 1.0), 0.08)
	_warning_tween.parallel().tween_property(self, "rotation_degrees", -4.0, 0.04)
	_warning_tween.parallel().tween_property(self, "scale", base_scale * 1.03, 0.04)
	_warning_tween.tween_property(self, "rotation_degrees", 3.0, 0.05)
	_warning_tween.tween_property(self, "rotation_degrees", -2.0, 0.04)
	_warning_tween.tween_property(self, "rotation_degrees", base_rotation, 0.04)
	_warning_tween.parallel().tween_property(self, "scale", base_scale, 0.16)
	_warning_tween.parallel().tween_property(self, "self_modulate", base_modulate, 0.16)

func _pressed() -> void:
	if _suppress_pressed_once:
		_suppress_pressed_once = false
		return

	if not is_dragging:
		card_pressed.emit(card_instance_id)

func set_display_size(display_size: Vector2) -> void:
	custom_minimum_size = display_size
	pivot_offset = display_size * 0.5
