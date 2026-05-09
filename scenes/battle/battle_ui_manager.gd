## 战斗 UI 管理器
## 职责：
##  - 缓存所有 UI 节点引用
##  - 应用初始样式、连接按钮信号
##  - 根据 CardSystem / EnemyAI 状态刷新显示
##  - 管理三类弹窗：弃牌堆、战斗记录、敌人信息
##  - 统一 Tooltip 系统（hover 显示 / 自适应定位）
## 对外信号：end_turn_pressed
class_name BattleUIManager
extends Node

signal end_turn_pressed

const CARD_SCENE := preload("res://scenes/battle/CardUI.tscn")

var _scene: Node
var _card_system: BattleCardSystem
var _enemy_ai: BattleEnemyAI
var _state_manager: BattleStateManager

# ====== 顶部 BOSS 条 ======
var _boss_bar_root: Control
var _boss_name_label: Label
var _boss_hp_bar: ProgressBar
var _boss_intent_label: Label

# ====== 敌人区 ======
var _boss_portrait: TextureRect
var _enemy_texture_normal: Texture2D
var _enemy_texture_injured: Texture2D
var _was_injured: bool = false
var _minion_row: HBoxContainer
var _arena_root: Control

# ====== 左侧玩家状态 ======
var _left_panel: Control
var _pie_chart: Control
var _energy_bar: ProgressBar
var _energy_label: Label
var _energy_section: Control
var _cognition_bar: ProgressBar
var _cognition_label: Label
var _cognition_section: Control
var _status_icon_row: HBoxContainer

# ====== 右侧按钮 ======
var _deck_button_new: TextureButton
var _discard_pile_button_new: TextureButton
var _battle_log_button_new: TextureButton
var _tutorial_button_new: TextureButton

# ====== 右下动作区 ======
var _end_turn_button: TextureButton
var _hand_hint_label: Label

# ====== 手牌区 ======
var _bottom_hand_panel: Control
var _hand_row: HBoxContainer
var _card_pool: Array[Control] = []

# ====== 弹窗 ======
var _discard_panel: PanelContainer
var _discard_close_button: Button
var _discard_cards_flow: HFlowContainer

var _battle_log_panel: PanelContainer
var _battle_log_text: RichTextLabel
var _battle_log_close_button: Button

# ====== Tooltip ======
var _tooltip_panel: PanelContainer
var _tooltip_label: RichTextLabel
var _detail_panel: TextureRect
var _battle_log_window: Control
var _battle_log_drag_bar: Control
var _dragging_log: bool = false
var _drag_offset: Vector2 = Vector2.ZERO

# ====== 旧按钮（保留引用但隐藏） ======
var _battle_log_button: Button
var _discard_pile_button: Button

# Tooltip state
var _current_tooltip_source: Control = null
var _current_tooltip_builder: Callable
var _boss_tooltip_showing: bool = false


func setup(scene: Node, card_system: BattleCardSystem, enemy_ai: BattleEnemyAI, state_manager: BattleStateManager) -> void:
	_scene = scene
	_card_system = card_system
	_enemy_ai = enemy_ai
	_state_manager = state_manager

	_cache_node_refs()
	_apply_initial_styles()
	_connect_button_signals()
	_tooltip_panel.visible = false
	if _battle_log_window:
		_battle_log_window.visible = true


func _process(_delta: float) -> void:
	# Boss portrait tooltip: check every frame if mouse is on visible pixels
	_update_boss_portrait_tooltip()

	if _tooltip_panel and _tooltip_panel.visible:
		_reposition_tooltip()
	_handle_log_drag()

func _handle_log_drag() -> void:
	if not _battle_log_window or not _battle_log_drag_bar:
		return
	if _dragging_log:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_battle_log_window.global_position = _battle_log_window.get_global_mouse_position() - _drag_offset
		else:
			_dragging_log = false


# ====== 节点缓存 ======
func _cache_node_refs() -> void:
	_boss_bar_root = _scene.get_node("Bossbar")
	_boss_name_label = _scene.get_node("Bossbar/BossNameLabel")
	_boss_hp_bar = _scene.get_node("Bossbar/BossHpBar")
	_boss_intent_label = _scene.get_node("Bossbar/BossIntentLabel")

	_arena_root = _scene.get_node("ArenaRoot")
	_boss_portrait = _scene.get_node("ArenaRoot/BossPortrait")
	_ensure_minion_row()

	var left := "LeftPanel/VBoxContainer"
	_left_panel = _scene.get_node("LeftPanel")
	_pie_chart = _scene.get_node(left + "/Control/RewardPlate/PieChartStat")
	_energy_section = _scene.get_node(left + "/EnergySection")
	_energy_bar = _scene.get_node(left + "/EnergySection/EnergyRow/EnergyBar")
	_energy_label = _scene.get_node(left + "/EnergySection/EnergyRow/EnergyValueLabel")
	_cognition_section = _scene.get_node(left + "/CognitionSection")
	_cognition_bar = _scene.get_node(left + "/CognitionSection/CognitionRow/CognitionBar")
	_cognition_label = _scene.get_node(left + "/CognitionSection/CognitionRow/CognitionValueLabel")
	_status_icon_row = _scene.get_node(left + "/StatusIconRow")

	_end_turn_button = _scene.get_node("EndTurnButton")
	_hand_hint_label = _scene.get_node_or_null("HandHintLabel")
	_bottom_hand_panel = _scene.get_node("BottomHandPanel")
	_hand_row = _scene.get_node("BottomHandPanel/MarginContainer/HandScroll/HandRow")

	_discard_panel = _scene.get_node_or_null("DiscardPanel")
	if _discard_panel:
		_discard_close_button = _scene.get_node_or_null("DiscardPanel/MarginContainer/VBoxContainer/HeaderRow/DiscardCloseButton")
		_ensure_discard_cards_view()

	_battle_log_panel = _scene.get_node_or_null("BattleLogWindow/BattleLogPanel")
	_battle_log_text = _scene.get_node_or_null("BattleLogWindow/BattleLogPanel/MarginContainer/VBoxContainer/BattleLogText")
	_battle_log_close_button = _scene.get_node_or_null("BattleLogWindow/BattleLogPanel/MarginContainer/VBoxContainer/HeaderRow/CloseButton")
	_battle_log_window = _scene.get_node_or_null("BattleLogWindow")
	_battle_log_drag_bar = _scene.get_node_or_null("BattleLogWindow/DragBar")

	_tooltip_panel = _scene.get_node("Tooltip")
	_tooltip_label = _scene.get_node("Tooltip/MarginContainer/TooltipLabel")
	_detail_panel = _scene.get_node("DetailPanel")

	_deck_button_new = _scene.get_node("DeckButtonnew")
	_discard_pile_button_new = _scene.get_node("DiscardPileButtonNew")
	_battle_log_button_new = _scene.get_node("BattleLogButtonnew")
	_tutorial_button_new = _scene.get_node_or_null("TutorialButton")

	# 旧按钮（可能不存在）
	_battle_log_button = _scene.get_node_or_null("BattleLogButton")
	_discard_pile_button = _scene.get_node_or_null("DiscardPileButton")


func _apply_initial_styles() -> void:
	BattleVisualEffects.apply_boss_hp_style(_boss_hp_bar)
	BattleVisualEffects.apply_bar_style(
		_energy_bar, Color(0.34, 0.30, 0.92, 0.96), Color(0.68, 0.64, 1.0, 0.75)
	)
	BattleVisualEffects.apply_bar_style(
		_cognition_bar, Color(0.58, 0.12, 0.75, 0.96), Color(0.84, 0.54, 1.0, 0.75)
	)


func _connect_button_signals() -> void:
	_end_turn_button.pressed.connect(func() -> void: end_turn_pressed.emit())
	_end_turn_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_end_turn_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if _discard_close_button:
		_discard_close_button.pressed.connect(func() -> void: _discard_panel.visible = false)
	if _battle_log_drag_bar:
		_battle_log_drag_bar.gui_input.connect(_on_drag_bar_input)
	if _battle_log_close_button:
		_battle_log_close_button.pressed.connect(func() -> void:
			if _battle_log_window:
				_battle_log_window.visible = false
		)
	
	_discard_pile_button_new.pressed.connect(_on_discard_button_pressed)
	_deck_button_new.pressed.connect(func() -> void: _scene._on_deck_button_pressed())
	_battle_log_button_new.pressed.connect(_on_battle_log_button_pressed)
	if _tutorial_button_new:
		_tutorial_button_new.pressed.connect(func() -> void:
			if _scene and _scene.has_method("reopen_battle_tutorial"):
				_scene.call("reopen_battle_tutorial")
		)

	if _deck_button_new:
		_deck_button_new.mouse_filter = Control.MOUSE_FILTER_STOP
		_deck_button_new.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_deck_button_new.mouse_entered.connect(_on_button_hover.bind(_deck_button_new, true))
		_deck_button_new.mouse_exited.connect(_on_button_hover.bind(_deck_button_new, false))
	if _discard_pile_button_new:
		_discard_pile_button_new.mouse_filter = Control.MOUSE_FILTER_STOP
		_discard_pile_button_new.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_discard_pile_button_new.mouse_entered.connect(_on_button_hover.bind(_discard_pile_button_new, true))
		_discard_pile_button_new.mouse_exited.connect(_on_button_hover.bind(_discard_pile_button_new, false))
	if _battle_log_button_new:
		_battle_log_button_new.mouse_filter = Control.MOUSE_FILTER_STOP
		_battle_log_button_new.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_battle_log_button_new.mouse_entered.connect(_on_button_hover.bind(_battle_log_button_new, true))
		_battle_log_button_new.mouse_exited.connect(_on_button_hover.bind(_battle_log_button_new, false))
	if _tutorial_button_new:
		_tutorial_button_new.mouse_filter = Control.MOUSE_FILTER_STOP
		_tutorial_button_new.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_tutorial_button_new.mouse_entered.connect(_on_button_hover.bind(_tutorial_button_new, true))
		_tutorial_button_new.mouse_exited.connect(_on_button_hover.bind(_tutorial_button_new, false))
	
	if _battle_log_button:
		_battle_log_button.visible = false
	if _discard_pile_button:
		_discard_pile_button.visible = false

	# 饼状图 hover
	if _pie_chart and _pie_chart.has_signal("stat_hovered"):
		_pie_chart.connect("stat_hovered", Callable(self, "_on_stat_hovered"))

	# 能量 / 认知 tooltip
	_register_tooltip_area(_energy_section, Callable(self, "_build_energy_tooltip"))
	_register_tooltip_area(_cognition_section, Callable(self, "_build_cognition_tooltip"))

	# BOSS 肖像悬停 tooltip


func _on_drag_bar_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging_log = true
			_drag_offset = _battle_log_window.get_global_mouse_position() - _battle_log_window.position
		else:
			_dragging_log = false

func _on_button_hover(control: Control, is_hovering: bool) -> void:
	var target_scale := Vector2(1.08, 1.08) if is_hovering else Vector2(1.0, 1.0)
	var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(control, "scale", target_scale, 0.15)

func close_all_popups() -> void:
	if _discard_panel:
		_discard_panel.visible = false
	if _battle_log_window:
		_battle_log_window.visible = false
	_tooltip_panel.visible = false


func set_enemy_portrait(tex: Texture2D) -> void:
	if _boss_portrait:
		_boss_portrait.texture = tex
		_enemy_texture_normal = tex
		_enemy_texture_injured = tex
		_was_injured = false


func set_enemy_portraits(normal_tex: Texture2D, injured_tex: Texture2D = null) -> void:
	if _boss_portrait == null:
		return
	_enemy_texture_normal = normal_tex
	_enemy_texture_injured = injured_tex if injured_tex != null else normal_tex
	_boss_portrait.texture = _enemy_texture_normal
	_was_injured = false


# ====== 刷新入口 ======
func refresh_all(battle_log_lines: Array[String]) -> void:
	refresh_enemy_ui()
	refresh_player_ui()
	refresh_hand()
	if _discard_panel and _discard_panel.visible:
		_refresh_discard_view()
	if _battle_log_window and _battle_log_window.visible:
		refresh_battle_log(battle_log_lines)


func refresh_enemy_ui() -> void:
	_boss_bar_root.visible = _enemy_ai.hp > 0
	_boss_name_label.text = _enemy_ai.enemy_name
	_boss_hp_bar.max_value = float(maxi(_enemy_ai.max_hp, 1))
	_boss_hp_bar.value = float(clampi(_enemy_ai.hp, 0, _enemy_ai.max_hp))
	_boss_intent_label.text = _enemy_ai.get_current_intent_display()
	
	# 受伤贴图切换：血量小于等于一半时显示受伤状态
	if _boss_portrait and _enemy_texture_injured:
		var is_injured = _enemy_ai.hp <= _enemy_ai.max_hp * 0.5
		if is_injured != _was_injured:
			_was_injured = is_injured
			_boss_portrait.texture = _enemy_texture_injured if is_injured else _enemy_texture_normal

	_refresh_minion_row()


func _ensure_minion_row() -> void:
	if _minion_row and is_instance_valid(_minion_row):
		return
	var root := _scene as Control
	if root == null:
		return
	_minion_row = HBoxContainer.new()
	_minion_row.name = "MinionRow"
	_minion_row.add_theme_constant_override("separation", 32)
	_minion_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_minion_row.z_index = 50
	# 屏幕右上区域：在 Boss 头像条下方、按钮列左侧
	_minion_row.anchor_left = 1.0
	_minion_row.anchor_right = 1.0
	_minion_row.anchor_top = 0.0
	_minion_row.anchor_bottom = 0.0
	_minion_row.offset_left = -680.0
	_minion_row.offset_right = -80.0
	_minion_row.offset_top = 200.0
	_minion_row.offset_bottom = 450.0
	_minion_row.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	root.add_child(_minion_row)


func _refresh_minion_row() -> void:
	_ensure_minion_row()
	if _minion_row == null:
		return
	for child in _minion_row.get_children():
		child.queue_free()
	if _enemy_ai == null or not _enemy_ai.has_method("get_summoned_allies_info"):
		return
	var allies: Array = _enemy_ai.get_summoned_allies_info()
	for info in allies:
		_minion_row.add_child(_build_minion_icon(info))


func _build_minion_icon(info: Dictionary) -> Control:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 4)
	wrapper.mouse_filter = Control.MOUSE_FILTER_PASS
	wrapper.tooltip_text = str(info.get("enemy_name", "援军"))

	var icon := TextureRect.new()
	var path := str(info.get("portrait_path", ""))
	if not path.is_empty() and ResourceLoader.exists(path):
		icon.texture = load(path) as Texture2D
	icon.custom_minimum_size = Vector2(400, 400)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(icon)

	var label := Label.new()
	label.text = str(info.get("enemy_name", "援军"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(1, 0.86, 0.6, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("outline_size", 4)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(label)

	return wrapper


func refresh_player_ui() -> void:
	_pie_chart.call("set_stats", Game.player_hp, Game.max_hp, Game.player_san, Game.max_san)

	_energy_label.text = "%d / %d" % [_card_system.energy, BattleCardSystem.ENERGY_MAX]
	_energy_bar.max_value = float(BattleCardSystem.ENERGY_MAX)
	_energy_bar.value = float(clampi(_card_system.energy, 0, BattleCardSystem.ENERGY_MAX))

	_cognition_label.text = "%d / %d" % [Game.player_cognition, Game.max_cognition]
	_cognition_bar.max_value = float(maxi(Game.max_cognition, 1))
	_cognition_bar.value = float(clampi(Game.player_cognition, 0, Game.max_cognition))

	_refresh_status_icons()


func _refresh_status_icons() -> void:
	for child in _status_icon_row.get_children():
		child.queue_free()

	if _card_system.player_block > 0:
		var b := _card_system.player_block
		_add_status_icon(
			"盾", b, Color(0.45, 0.72, 0.95, 1.0), "护盾",
			"护盾 %d：抵挡下回合 %d 点伤害，超出部分失效。" % [b, b]
		)

	if _card_system.player_weak > 0:
		var w := _card_system.player_weak
		_add_status_icon(
			"弱", w, Color(0.85, 0.55, 0.90, 1.0), "虚弱",
			"虚弱 %d：本轮每次造成伤害时，伤害值 -%d（最低为1）。" % [w, w * 2]
		)

	if Game.is_distorted():
		_add_status_icon(
			"癫", -1, Color(0.95, 0.45, 0.45, 1.0), "癫狂",
			"癫狂状态：手牌已有数值 +1，包括精神负荷、认知负荷、伤害值与Buff层数。"
		)

	if _scene and _scene.has_method("get_player_additional_status_info"):
		var extra_statuses: Array = _scene.call("get_player_additional_status_info")
		for info in extra_statuses:
			if not (info is Dictionary):
				continue
			var buff_name := str(info.get("name", "状态"))
			var stacks := int(info.get("stacks", 0))
			var description := str(info.get("description", ""))
			if buff_name in ["护盾", "虚弱"]:
				continue
			_add_status_icon(
				buff_name.substr(0, 1),
				stacks,
				_get_status_color(buff_name),
				buff_name,
				description
			)


func _add_status_icon(label_text: String, stack: int, color: Color, display_name: String, tip_text: String) -> void:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(52, 52)
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.text = label_text if stack < 0 else ("%s%d" % [label_text, stack])
	btn.add_theme_font_size_override("font_size", 18)

	var sb := BattleVisualEffects.make_circle_icon_style(color)
	for state in ["normal", "hover", "pressed", "disabled"]:
		btn.add_theme_stylebox_override(state, sb)
	btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))

	_status_icon_row.add_child(btn)

	var tip := "[b]%s[/b]\n%s" % [display_name, tip_text]
	_register_tooltip_area(btn, func() -> String: return tip)


func refresh_hand() -> void:
	# 回收现有手牌到对象池
	for child in _hand_row.get_children():
		_hand_row.remove_child(child)
		child.visible = false
		_card_pool.append(child)

	var can_play := _state_manager.is_player_turn()
	var is_manic := _card_system.is_manic_active()
	for i in range(_card_system.hand.size()):
		var card_id: String = _card_system.hand[i]
		var card_data: Dictionary = CardDatabase.get_card(card_id)

		# 从池中取出或实例化新卡
		var card_ui: Control
		if _card_pool.size() > 0:
			card_ui = _card_pool.pop_back()
		else:
			card_ui = CARD_SCENE.instantiate()
		card_ui.custom_minimum_size = Vector2(165, 250)
		card_ui.visible = true
		card_ui.call("setup", card_data, i, _scene)
		card_ui.disabled = not can_play or _card_system.get_effective_cost(card_data) > _card_system.energy
		_hand_row.add_child(card_ui)
		if is_manic and card_ui.has_method("set_manic_active"):
			card_ui.call("set_manic_active", true)

	if _hand_hint_label:
		_hand_hint_label.text = "手牌 %d 张  ·  弃堆 %d 张  ·  抽堆 %d 张" % [
			_card_system.hand.size(), _card_system.discard_pile.size(), _card_system.draw_pile.size()
		]


func set_hand_hint(text: String) -> void:
	if _hand_hint_label:
		_hand_hint_label.text = text


func set_play_enabled(enabled: bool) -> void:
	_end_turn_button.disabled = not enabled
	for node in _hand_row.get_children():
		if node is Button:
			node.disabled = not enabled


func get_tutorial_focus_rect(focus_id: String) -> Rect2:
	match focus_id:
		"enemy_info":
			return _merge_control_rects([_boss_bar_root, _arena_root])
		"player_status":
			return _get_control_global_rect(_left_panel)
		"hand":
			return _get_control_global_rect(_bottom_hand_panel)
		"right_buttons":
			return _merge_control_rects([
				_deck_button_new,
				_discard_pile_button_new,
				_battle_log_button_new,
				_tutorial_button_new,
			])
		"end_turn":
			return _get_control_global_rect(_end_turn_button)
		_:
			return Rect2()


# ====== 弃牌堆 ======
func _on_discard_button_pressed() -> void:
	if _battle_log_window:
		_battle_log_window.visible = false
	if _discard_panel:
		if _discard_panel.visible:
			_discard_panel.visible = false
		else:
			_discard_panel.visible = true
			_refresh_discard_view()

func toggle_discard_panel() -> void:
	_on_discard_button_pressed()


func _refresh_discard_view() -> void:
	if not _discard_cards_flow:
		return
	for child in _discard_cards_flow.get_children():
		child.queue_free()
	if _card_system.discard_pile.is_empty():
		var empty_label := Label.new()
		empty_label.text = "此刻尚无卡牌沉入弃堆。"
		empty_label.add_theme_font_size_override("font_size", 24)
		empty_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		_discard_cards_flow.add_child(empty_label)
		return
	var counts: Dictionary = {}
	var order: Array[String] = []
	for card_id in _card_system.discard_pile:
		if not counts.has(card_id):
			counts[card_id] = 0
			order.append(card_id)
		counts[card_id] += 1
	for card_id in order:
		_discard_cards_flow.add_child(_build_discard_card_preview(card_id, int(counts[card_id])))

func _ensure_discard_cards_view() -> void:
	if _discard_cards_flow and is_instance_valid(_discard_cards_flow):
		return
	var content_vbox: Node = _discard_panel.get_node_or_null("MarginContainer/VBoxContainer")
	if not content_vbox:
		return
	var scroll := ScrollContainer.new()
	scroll.name = "DiscardScroll"
	scroll.custom_minimum_size = Vector2(0, 320)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(scroll)
	_discard_cards_flow = HFlowContainer.new()
	_discard_cards_flow.name = "DiscardCardsFlow"
	_discard_cards_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_discard_cards_flow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_discard_cards_flow.add_theme_constant_override("h_separation", 14)
	_discard_cards_flow.add_theme_constant_override("v_separation", 14)
	scroll.add_child(_discard_cards_flow)

func _build_discard_card_preview(card_id: String, count: int) -> Control:
	var card: Dictionary = CardDatabase.get_card(card_id)
	var card_scene = preload("res://scenes/battle/CardUI.tscn")
	var card_ui = card_scene.instantiate()
	if card_ui.has_method("setup"):
		card_ui.call("setup", card, -1, null)
	card_ui.disabled = true
	card_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vbox = VBoxContainer.new()
	vbox.add_child(card_ui)
	if count > 1:
		var count_label = Label.new()
		count_label.text = "x%d" % count
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		vbox.add_child(count_label)
	return vbox


# ====== 战斗记录 ======
func _on_battle_log_button_pressed() -> void:
	if _discard_panel:
		_discard_panel.visible = false
	if _battle_log_window:
		_battle_log_window.visible = true
	if _scene.has_method("_refresh_battle_log_from_scene"):
		_scene.call("_refresh_battle_log_from_scene")

func open_battle_log() -> void:
	_on_battle_log_button_pressed()


func refresh_battle_log(lines: Array[String]) -> void:
	if not _battle_log_text:
		return
	if not _battle_log_window or not _battle_log_window.visible:
		return
	if lines.is_empty():
		_battle_log_text.text = "[center]（暂无记录）[/center]"
		return
	_battle_log_text.text = "\n".join(lines)


# ====== 敌人信息 Tooltip ======

func _update_boss_portrait_tooltip() -> void:
	if _boss_portrait == null or not is_instance_valid(_boss_portrait):
		return
	if _boss_tooltip_showing:
		if not _is_mouse_over_visible_pixel(_boss_portrait):
			_boss_tooltip_showing = false
			_hide_tooltip()
	else:
		if _is_mouse_over_visible_pixel(_boss_portrait):
			_boss_tooltip_showing = true
			_current_tooltip_source = _boss_portrait
			_current_tooltip_builder = Callable(self, "_build_enemy_tooltip")
			_show_active_tooltip()


func _build_enemy_tooltip() -> String:
	var intent := _enemy_ai.get_current_intent()
	var preview_text := (", ".join(_enemy_ai.hand_preview)
		if not _enemy_ai.hand_preview.is_empty() else "—")
	var buffs: Array[String] = []
	for info in _enemy_ai.get_active_buffs_info():
		var buff_name := str(info.get("name", "状态"))
		var stacks := int(info.get("stacks", 0))
		if stacks < 0:
			buffs.append(buff_name)
		elif stacks > 0:
			buffs.append("%s %d" % [buff_name, stacks])
	var buff_text := "，".join(buffs) if not buffs.is_empty() else "无"

	return "[b]%s[/b]\n存在值：%d / %d\n精神负荷：%d / %d（下回合 +%d）\n现有手牌：%s\n下一回合意图 → %s\n状态：%s" % [
		_enemy_ai.enemy_name,
		_enemy_ai.hp, _enemy_ai.max_hp,
		_enemy_ai.energy, _enemy_ai.energy_max, _enemy_ai.energy_gain_per_turn,
		preview_text,
		str(intent.get("text", "攻击")),
		buff_text,
	]


# ====== Tooltip 系统 ======
func _register_tooltip_area(control: Control, builder: Callable) -> void:
	if control == null:
		return
	control.mouse_filter = Control.MOUSE_FILTER_STOP
	control.mouse_entered.connect(func() -> void:
		_current_tooltip_source = control
		_current_tooltip_builder = builder
		_show_active_tooltip()
	)
	control.mouse_exited.connect(func() -> void:
		if _current_tooltip_source == control:
			_current_tooltip_source = null
			_hide_tooltip()
	)
	control.tree_exiting.connect(func() -> void:
		if _current_tooltip_source == control:
			_current_tooltip_source = null
			_hide_tooltip()
	)


## 检查鼠标是否在 TextureRect 的非透明像素上
func _is_mouse_over_visible_pixel(tex_rect: TextureRect) -> bool:
	var tex: Texture2D = tex_rect.texture
	if tex == null:
		return false
	var img := tex.get_image()
	if img == null:
		return false
	var local_pos := tex_rect.get_local_mouse_position()
	# 将本地坐标转换为纹理 UV 坐标
	var uv := _control_pos_to_uv(tex_rect, local_pos)
	if uv.x < 0.0 or uv.y < 0.0 or uv.x >= 1.0 or uv.y >= 1.0:
		return false
	var px := int(uv.x * float(img.get_width()))
	var py := int(uv.y * float(img.get_height()))
	if px < 0 or py < 0 or px >= img.get_width() or py >= img.get_height():
		return false
	var color := img.get_pixel(px, py)
	return color.a > 0.1


## 将 Control 本地坐标转为 UV（适配 stretch_mode / anchors）
func _control_pos_to_uv(tex_rect: TextureRect, local_pos: Vector2) -> Vector2:
	var tex: Texture2D = tex_rect.texture
	if tex == null:
		return Vector2(-1.0, -1.0)
	var tex_size := tex.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return Vector2(-1.0, -1.0)
	var rect := tex_rect.get_rect()
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return Vector2(-1.0, -1.0)
	# TextureRect 默认 stretch_mode = FIT_WIDTH, 按比例映射
	var uv_x := (local_pos.x - rect.position.x) / rect.size.x
	var uv_y := (local_pos.y - rect.position.y) / rect.size.y
	return Vector2(uv_x, uv_y)


func _show_active_tooltip() -> void:
	if _current_tooltip_source == null or not is_instance_valid(_current_tooltip_source):
		_hide_tooltip()
		return
	if not _current_tooltip_builder.is_valid():
		return
	var body: String = str(_current_tooltip_builder.call())
	if body.is_empty():
		_hide_tooltip()
		return
	_tooltip_label.text = body
	
	_tooltip_panel.visible = true
	_tooltip_panel.z_index = 200
	
	if _detail_panel:
		_detail_panel.visible = true
		_detail_panel.z_index = _tooltip_panel.z_index - 1
	
	_reposition_tooltip()


func _hide_tooltip() -> void:
	_tooltip_panel.visible = false
	if _detail_panel:
		_detail_panel.visible = false


func _reposition_tooltip() -> void:
	if not _tooltip_panel.visible:
		return
	_tooltip_panel.reset_size()
	var mouse_pos: Vector2 = _scene.get_global_mouse_position()
	var tsize: Vector2 = _tooltip_panel.size
	var viewport_size: Vector2 = _scene.get_viewport_rect().size
	var pos: Vector2 = mouse_pos + Vector2(20, 20)
	pos.x = clampf(pos.x, 4, viewport_size.x - tsize.x - 4)
	pos.y = clampf(pos.y, 4, viewport_size.y - tsize.y - 4)
	_tooltip_panel.global_position = pos
	
	# DetailPanel 跟随 tooltip 位置
	if _detail_panel and _detail_panel.visible:
		_detail_panel.global_position = pos - Vector2(10, 10)
		_detail_panel.size = tsize + Vector2(20, 20)


func _on_stat_hovered(stat_key: String, is_hovering: bool) -> void:
	if is_hovering:
		_current_tooltip_source = _pie_chart
		_current_tooltip_builder = Callable(
			self,
			"_build_hp_tooltip" if stat_key == "hp" else "_build_san_tooltip"
		)
		_show_active_tooltip()
	elif _current_tooltip_source == _pie_chart:
		_current_tooltip_source = null
		_hide_tooltip()


# ====== Tooltip builders ======
func _build_hp_tooltip() -> String:
	return "[b]存在值（HP）[/b]\n%d / %d\n当前护盾：%d" % [
		Game.player_hp, Game.max_hp, _card_system.player_block
	]


func _build_san_tooltip() -> String:
	var parts: Array[String] = ["[b]理智值（SAN）[/b]", "%d / %d" % [Game.player_san, Game.max_san]]
	if Game.is_distorted():
		parts.append("当前：癫狂")
	return "\n".join(parts)


func _build_energy_tooltip() -> String:
	return "[b]精神负荷[/b]\n当前 %d / %d\n每回合 +%d，未用完保留至下回合，上限 %d。" % [
		_card_system.energy, BattleCardSystem.ENERGY_MAX,
		BattleCardSystem.ENERGY_GAIN_PER_TURN, BattleCardSystem.ENERGY_MAX
	]


func _build_cognition_tooltip() -> String:
	return "[b]认知负荷[/b]\n当前 %d / %d\n每打出一张牌都会累积认知负荷。\n只有上一轮手牌耗尽，并在下一轮重整时，认知才会回落。\n超过上限时，存在值减半，并清空当前累积。" % [
		Game.player_cognition, Game.max_cognition
	]


func _get_status_color(status_name: String) -> Color:
	match status_name:
		"麻痹":
			return Color(0.96, 0.78, 0.28, 1.0)
		"混乱":
			return Color(0.92, 0.45, 0.62, 1.0)
		"坚韧":
			return Color(0.40, 0.78, 0.54, 1.0)
		"残存":
			return Color(0.44, 0.86, 0.88, 1.0)
		"愤怒":
			return Color(0.94, 0.32, 0.22, 1.0)
		"腐化":
			return Color(0.45, 0.78, 0.28, 1.0)
		"崩溃":
			return Color(0.62, 0.42, 0.95, 1.0)
		"援军":
			return Color(0.50, 0.74, 0.96, 1.0)
		"内驱力":
			return Color(0.36, 0.62, 1.0, 1.0)
		"疯狂为乐":
			return Color(1.0, 0.52, 0.72, 1.0)
		_:
			return Color(0.68, 0.72, 0.90, 1.0)


# ====== 卡牌 Tooltip（由 card_ui 经 battle_scene 转发） ======
func show_card_tooltip(card_data: Dictionary) -> void:
	if card_data.is_empty():
		return
	var name_text := str(card_data.get("name", "未知卡牌"))
	var type_text: String = str(CardDatabase.get_type_text(str(card_data.get("type", ""))))
	var cost := int(card_data.get("cost", 0))
	var cognition := int(card_data.get("cognition", 0))
	var desc := str(card_data.get("description", card_data.get("desc", "")))

	var body := "[b]%s[/b]  [%s]\n费用：%d    认知：%d" % [name_text, type_text, cost, cognition]
	if not desc.is_empty():
		body += "\n" + desc

	_tooltip_label.text = body
	_tooltip_panel.visible = true
	_tooltip_panel.z_index = 200
	if _detail_panel:
		_detail_panel.visible = true
		_detail_panel.z_index = _tooltip_panel.z_index - 1
	_current_tooltip_source = null
	_reposition_tooltip()


func hide_card_tooltip() -> void:
	if _current_tooltip_source == null:
		_hide_tooltip()


func _get_control_global_rect(control: Control) -> Rect2:
	if control == null or not is_instance_valid(control):
		return Rect2()
	return Rect2(control.global_position, control.size)


func _merge_control_rects(controls: Array) -> Rect2:
	var merged := Rect2()
	var has_rect := false
	for control in controls:
		if not (control is Control):
			continue
		var rect := _get_control_global_rect(control)
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			continue
		if not has_rect:
			merged = rect
			has_rect = true
			continue
		merged = merged.merge(rect)
	return merged
