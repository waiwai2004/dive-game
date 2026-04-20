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

# ====== 左侧玩家状态 ======
var _pie_chart: Control
var _energy_bar: ProgressBar
var _energy_label: Label
var _energy_section: Control
var _cognition_bar: ProgressBar
var _cognition_label: Label
var _cognition_section: Control
var _status_icon_row: HBoxContainer

# ====== 右侧圆形按钮 ======
var _battle_log_button: Button
var _discard_pile_button: Button

# ====== 右下动作区 ======
var _end_turn_button: Button
var _hand_hint_label: Label

# ====== 手牌区 ======
var _hand_row: HBoxContainer

# ====== 弹窗 ======
var _discard_panel: PanelContainer
var _discard_text: RichTextLabel
var _discard_close_button: Button

var _battle_log_panel: PanelContainer
var _battle_log_text: RichTextLabel
var _battle_log_close_button: Button

# ====== Tooltip ======
var _tooltip_panel: PanelContainer
var _tooltip_label: RichTextLabel

# Tooltip state
var _current_tooltip_source: Control = null
var _current_tooltip_builder: Callable


func setup(scene: Node, card_system: BattleCardSystem, enemy_ai: BattleEnemyAI, state_manager: BattleStateManager) -> void:
	_scene = scene
	_card_system = card_system
	_enemy_ai = enemy_ai
	_state_manager = state_manager

	_cache_node_refs()
	_apply_initial_styles()
	_connect_button_signals()
	close_all_popups()


func _process(_delta: float) -> void:
	if _tooltip_panel and _tooltip_panel.visible:
		_reposition_tooltip()


# ====== 节点缓存 ======
func _cache_node_refs() -> void:
	_boss_bar_root = _scene.get_node("TopBossBar")
	_boss_name_label = _scene.get_node("TopBossBar/MarginContainer/HBoxContainer/BossNameLabel")
	_boss_hp_bar = _scene.get_node("TopBossBar/MarginContainer/HBoxContainer/BossHpBar")
	_boss_intent_label = _scene.get_node("TopBossBar/MarginContainer/HBoxContainer/BossIntentLabel")

	_boss_portrait = _scene.get_node("ArenaRoot/BossPortrait")

	var left := "LeftPanel/MarginContainer/VBoxContainer"
	_pie_chart = _scene.get_node(left + "/PieChartStat")
	_energy_section = _scene.get_node(left + "/EnergySection")
	_energy_bar = _scene.get_node(left + "/EnergySection/EnergyRow/EnergyBar")
	_energy_label = _scene.get_node(left + "/EnergySection/EnergyRow/EnergyValueLabel")
	_cognition_section = _scene.get_node(left + "/CognitionSection")
	_cognition_bar = _scene.get_node(left + "/CognitionSection/CognitionRow/CognitionBar")
	_cognition_label = _scene.get_node(left + "/CognitionSection/CognitionRow/CognitionValueLabel")
	_status_icon_row = _scene.get_node(left + "/StatusIconRow")

	_battle_log_button = _scene.get_node("BattleLogButton")
	_discard_pile_button = _scene.get_node("DiscardPileButton")
	_end_turn_button = _scene.get_node("EndTurnButton")
	_hand_hint_label = _scene.get_node("HandHintLabel")
	_hand_row = _scene.get_node("BottomHandPanel/MarginContainer/HandScroll/HandRow")

	_discard_panel = _scene.get_node("DiscardPanel")
	_discard_text = _scene.get_node("DiscardPanel/MarginContainer/VBoxContainer/DiscardText")
	_discard_close_button = _scene.get_node("DiscardPanel/MarginContainer/VBoxContainer/HeaderRow/CloseButton")

	_battle_log_panel = _scene.get_node("BattleLogPanel")
	_battle_log_text = _scene.get_node("BattleLogPanel/MarginContainer/VBoxContainer/BattleLogText")
	_battle_log_close_button = _scene.get_node("BattleLogPanel/MarginContainer/VBoxContainer/HeaderRow/CloseButton")

	_tooltip_panel = _scene.get_node("Tooltip")
	_tooltip_label = _scene.get_node("Tooltip/MarginContainer/TooltipLabel")


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
	_discard_pile_button.pressed.connect(_on_discard_button_pressed)
	_discard_close_button.pressed.connect(func() -> void: _discard_panel.visible = false)
	_battle_log_button.pressed.connect(_on_battle_log_button_pressed)
	_battle_log_close_button.pressed.connect(func() -> void: _battle_log_panel.visible = false)

	# 饼状图 hover
	if _pie_chart.has_signal("stat_hovered"):
		_pie_chart.connect("stat_hovered", Callable(self, "_on_stat_hovered"))

	# 能量 / 认知 tooltip
	_register_tooltip_area(_energy_section, Callable(self, "_build_energy_tooltip"))
	_register_tooltip_area(_cognition_section, Callable(self, "_build_cognition_tooltip"))

	# BOSS 肖像悬停 tooltip
	_register_tooltip_area(_boss_portrait, Callable(self, "_build_enemy_tooltip"))


func close_all_popups() -> void:
	_discard_panel.visible = false
	_battle_log_panel.visible = false
	_tooltip_panel.visible = false


# ====== 刷新入口 ======
func refresh_all(battle_log_lines: Array[String]) -> void:
	refresh_enemy_ui()
	refresh_player_ui()
	refresh_hand()
	if _discard_panel.visible:
		_refresh_discard_view()
	if _battle_log_panel.visible:
		refresh_battle_log(battle_log_lines)


func refresh_enemy_ui() -> void:
	_boss_bar_root.visible = _enemy_ai.hp > 0
	_boss_name_label.text = _enemy_ai.enemy_name
	_boss_hp_bar.max_value = float(maxi(_enemy_ai.max_hp, 1))
	_boss_hp_bar.value = float(clampi(_enemy_ai.hp, 0, _enemy_ai.max_hp))
	_boss_intent_label.text = _enemy_ai.get_current_intent_display()


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
			"虚弱 %d：本轮每次造成伤害时，伤害值 -%d（最低为1）。" % [w, w]
		)

	if Game.is_distorted():
		_add_status_icon(
			"癫", -1, Color(0.95, 0.45, 0.45, 1.0), "癫狂",
			"癫狂状态：所有卡牌费用 +1。"
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
	for child in _hand_row.get_children():
		child.queue_free()

	var can_play := _state_manager.is_player_turn()
	for i in range(_card_system.hand.size()):
		var card_id: String = _card_system.hand[i]
		var card_data: Dictionary = CardDatabase.get_card(card_id)
		var card_ui: Control = CARD_SCENE.instantiate()
		card_ui.custom_minimum_size = Vector2(165, 250)
		card_ui.call("setup", card_data, i, _scene)
		card_ui.disabled = not can_play or _card_system.get_effective_cost(card_data) > _card_system.energy
		_hand_row.add_child(card_ui)

	_hand_hint_label.text = "手牌 %d / 弃牌 %d / 抽牌 %d" % [
		_card_system.hand.size(), _card_system.discard_pile.size(), _card_system.draw_pile.size()
	]


func set_hand_hint(text: String) -> void:
	_hand_hint_label.text = text


func set_play_enabled(enabled: bool) -> void:
	_end_turn_button.disabled = not enabled
	for node in _hand_row.get_children():
		if node is Button:
			node.disabled = not enabled


# ====== 弃牌堆 ======
func _on_discard_button_pressed() -> void:
	_battle_log_panel.visible = false
	_discard_panel.visible = true
	_refresh_discard_view()


func _refresh_discard_view() -> void:
	if _card_system.discard_pile.is_empty():
		_discard_text.text = "[center]当前弃牌堆为空。[/center]"
		return

	var lines: Array[String] = ["[center][b]弃牌堆[/b][/center]", ""]
	for card_id in _card_system.discard_pile:
		var card: Dictionary = CardDatabase.get_card(card_id)
		lines.append("• %s" % str(card.get("name", card_id)))
	_discard_text.text = "\n".join(lines)


# ====== 战斗记录 ======
func _on_battle_log_button_pressed() -> void:
	_discard_panel.visible = false
	_battle_log_panel.visible = true
	# 由调用方 refresh 一次即可
	if _scene.has_method("_refresh_battle_log_from_scene"):
		_scene.call("_refresh_battle_log_from_scene")


func refresh_battle_log(lines: Array[String]) -> void:
	if not _battle_log_panel.visible:
		return
	if lines.is_empty():
		_battle_log_text.text = "[center]（暂无记录）[/center]"
		return
	_battle_log_text.text = "\n".join(lines)


# ====== 敌人信息 Tooltip ======
func _build_enemy_tooltip() -> String:
	var intent := _enemy_ai.get_current_intent()
	var preview_text := (", ".join(_enemy_ai.hand_preview)
		if not _enemy_ai.hand_preview.is_empty() else "—")
	var buffs: Array[String] = []
	if _enemy_ai.weak > 0:
		buffs.append("虚弱 %d" % _enemy_ai.weak)
	var buff_text := "，".join(buffs) if not buffs.is_empty() else "无"

	return "[b]%s[/b]\n存在值：%d / %d\n现有手牌：%s\n下一回合意图 → %s\n状态：%s" % [
		_enemy_ai.enemy_name,
		_enemy_ai.hp, _enemy_ai.max_hp,
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
	_reposition_tooltip()


func _hide_tooltip() -> void:
	_tooltip_panel.visible = false


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
	return "[b]认知负荷[/b]\n当前 %d / %d\n超过上限时，存在值减半并清零累积。" % [
		Game.player_cognition, Game.max_cognition
	]


# ====== 卡牌 Tooltip（由 card_ui 经 battle_scene 转发） ======
func show_card_tooltip(card_data: Dictionary) -> void:
	if card_data.is_empty():
		return
	var name_text := str(card_data.get("name", "未知卡牌"))
	var type_text := CardDatabase.get_type_text(str(card_data.get("type", "")))
	var cost := int(card_data.get("cost", 0))
	var cognition := int(card_data.get("cognition", 0))
	var desc := str(card_data.get("description", card_data.get("desc", "")))

	var body := "[b]%s[/b]  [%s]\n费用：%d    认知：%d" % [name_text, type_text, cost, cognition]
	if not desc.is_empty():
		body += "\n" + desc

	_tooltip_label.text = body
	_tooltip_panel.visible = true
	_tooltip_panel.z_index = 200
	_current_tooltip_source = null  # 卡牌 tooltip 不走 source 机制
	_reposition_tooltip()


func hide_card_tooltip() -> void:
	if _current_tooltip_source == null:
		_hide_tooltip()
