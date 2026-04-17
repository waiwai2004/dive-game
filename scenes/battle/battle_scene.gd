extends Control

enum BattleState {
	PLAYER_TURN,
	ENEMY_TURN,
	REWARD,
	FINISHED
}

const CARD_SCENE := preload("res://scenes/battle/CardUI.tscn")
const ENERGY_GAIN_PER_TURN := 3
const ENERGY_MAX := 10
const HAND_DRAW_COUNT := 5
const STARTER_DECK: Array[String] = ["cut", "cut", "guard", "guard", "calm", "break"]

# ====== 顶部 BOSS 血条 ======
@onready var boss_bar_root: Control = $TopBossBar
@onready var boss_name_label: Label = $TopBossBar/MarginContainer/HBoxContainer/BossNameLabel
@onready var boss_hp_bar: ProgressBar = $TopBossBar/MarginContainer/HBoxContainer/BossHpBar
@onready var boss_intent_label: Label = $TopBossBar/MarginContainer/HBoxContainer/BossIntentLabel

# ====== 敌人区域 ======
@onready var boss_area: Control = $ArenaRoot
@onready var boss_portrait: TextureRect = $ArenaRoot/BossPortrait
@onready var enemy_info_popup: PanelContainer = $EnemyInfoPopup
@onready var enemy_info_title: Label = $EnemyInfoPopup/MarginContainer/VBoxContainer/TitleLabel
@onready var enemy_info_body: RichTextLabel = $EnemyInfoPopup/MarginContainer/VBoxContainer/BodyLabel

# ====== 左侧玩家状态 ======
@onready var pie_chart: Control = $LeftPanel/MarginContainer/VBoxContainer/PieChartStat
@onready var energy_bar: ProgressBar = $LeftPanel/MarginContainer/VBoxContainer/EnergySection/EnergyRow/EnergyBar
@onready var energy_label: Label = $LeftPanel/MarginContainer/VBoxContainer/EnergySection/EnergyRow/EnergyValueLabel
@onready var energy_section: Control = $LeftPanel/MarginContainer/VBoxContainer/EnergySection
@onready var cognition_bar: ProgressBar = $LeftPanel/MarginContainer/VBoxContainer/CognitionSection/CognitionRow/CognitionBar
@onready var cognition_label: Label = $LeftPanel/MarginContainer/VBoxContainer/CognitionSection/CognitionRow/CognitionValueLabel
@onready var cognition_section: Control = $LeftPanel/MarginContainer/VBoxContainer/CognitionSection
@onready var status_icon_row: HBoxContainer = $LeftPanel/MarginContainer/VBoxContainer/StatusIconRow

# ====== 右侧圆形按钮 ======
@onready var battle_log_button: Button = $BattleLogButton
@onready var discard_pile_button: Button = $DiscardPileButton

# ====== 右下动作区 ======
@onready var end_turn_button: Button = $EndTurnButton
@onready var hand_hint_label: Label = $HandHintLabel

# ====== 手牌区 ======
@onready var hand_panel: PanelContainer = $BottomHandPanel
@onready var hand_row: HBoxContainer = $BottomHandPanel/MarginContainer/HandScroll/HandRow

# ====== 弹窗 ======
@onready var discard_panel: PanelContainer = $DiscardPanel
@onready var discard_text: RichTextLabel = $DiscardPanel/MarginContainer/VBoxContainer/DiscardText
@onready var discard_close_button: Button = $DiscardPanel/MarginContainer/VBoxContainer/HeaderRow/CloseButton

@onready var battle_log_panel: PanelContainer = $BattleLogPanel
@onready var battle_log_text: RichTextLabel = $BattleLogPanel/MarginContainer/VBoxContainer/BattleLogText
@onready var battle_log_close_button: Button = $BattleLogPanel/MarginContainer/VBoxContainer/HeaderRow/CloseButton

@onready var reward_story_ui: Control = $RewardStoryUI

# ====== Tooltip ======
@onready var tooltip_panel: PanelContainer = $Tooltip
@onready var tooltip_label: RichTextLabel = $Tooltip/MarginContainer/TooltipLabel

# ====== 牌库状态 ======
var draw_pile: Array[String] = []
var hand: Array[String] = []
var discard_pile: Array[String] = []

var energy: int = 0
var player_block: int = 0
var player_weak: int = 0

var enemy_name: String = "浅海异常体"
var enemy_hp: int = 10
var enemy_max_hp: int = 10
var enemy_attack: int = 2
var enemy_weak: int = 0
var enemy_cycle_index: int = 0
var enemy_cycle: Array[Dictionary] = []

# 敌人的"现有手牌" / buff （用于敌人信息栏展示）
var enemy_hand_preview: Array[String] = []
var enemy_status_notes: Array[String] = []

var battle_state: int = BattleState.PLAYER_TURN
var battle_log_lines: Array[String] = []
var _boss_hit_tween: Tween = null
var _boss_idle_phase: float = 0.0

# tooltip state
var _current_tooltip_source: Control = null
var _current_tooltip_builder: Callable


func _ready() -> void:
	if has_node("/root/AudioManager"):
		AudioManager.play_bgm_segment("battle")

	_hide_global_ui_for_battle()
	_setup_styles()
	_connect_ui_signals()
	_setup_enemy()
	_start_battle()
	set_process(true)


func _process(delta: float) -> void:
	_boss_idle_phase += delta
	if is_instance_valid(boss_portrait) and battle_state != BattleState.FINISHED:
		boss_portrait.position.y = 26.0 + sin(_boss_idle_phase * 1.7) * 6.0

	if tooltip_panel.visible:
		_reposition_tooltip()

	# 敌人信息弹窗跟随 BossPortrait 上方
	if enemy_info_popup.visible:
		_reposition_enemy_info_popup()


func _hide_global_ui_for_battle() -> void:
	if not has_node("/root/GlobalUI"):
		return
	GlobalUI.set_mode(GlobalUI.MODE_BATTLE)
	if GlobalUI.has_method("set_top_hud_visible"):
		GlobalUI.set_top_hud_visible(false)
	if GlobalUI.has_method("clear_hint"):
		GlobalUI.clear_hint()
	if GlobalUI.has_method("clear_energy"):
		GlobalUI.clear_energy()
	if GlobalUI.has_method("hide_deck_panel"):
		GlobalUI.hide_deck_panel()


func _setup_styles() -> void:
	var boss_fill := StyleBoxFlat.new()
	boss_fill.bg_color = Color(0.82, 0.14, 0.22, 0.98)
	boss_fill.corner_radius_top_left = 10
	boss_fill.corner_radius_top_right = 10
	boss_fill.corner_radius_bottom_left = 10
	boss_fill.corner_radius_bottom_right = 10
	boss_fill.border_width_left = 2
	boss_fill.border_width_top = 2
	boss_fill.border_width_right = 2
	boss_fill.border_width_bottom = 2
	boss_fill.border_color = Color(1.0, 0.62, 0.66, 0.85)

	var boss_bg := StyleBoxFlat.new()
	boss_bg.bg_color = Color(0.14, 0.07, 0.08, 0.92)
	boss_bg.corner_radius_top_left = 10
	boss_bg.corner_radius_top_right = 10
	boss_bg.corner_radius_bottom_left = 10
	boss_bg.corner_radius_bottom_right = 10

	boss_hp_bar.add_theme_stylebox_override("fill", boss_fill)
	boss_hp_bar.add_theme_stylebox_override("background", boss_bg)

	_set_bar_style(energy_bar, Color(0.34, 0.30, 0.92, 0.96), Color(0.68, 0.64, 1.0, 0.75))
	_set_bar_style(cognition_bar, Color(0.58, 0.12, 0.75, 0.96), Color(0.84, 0.54, 1.0, 0.75))


func _set_bar_style(bar: ProgressBar, fill_color: Color, border_color: Color) -> void:
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.corner_radius_top_left = 8
	fill.corner_radius_top_right = 8
	fill.corner_radius_bottom_left = 8
	fill.corner_radius_bottom_right = 8
	fill.border_width_left = 1
	fill.border_width_top = 1
	fill.border_width_right = 1
	fill.border_width_bottom = 1
	fill.border_color = border_color

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.06, 0.07, 0.10, 0.94)
	bg.corner_radius_top_left = 8
	bg.corner_radius_top_right = 8
	bg.corner_radius_bottom_left = 8
	bg.corner_radius_bottom_right = 8

	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", bg)


func _connect_ui_signals() -> void:
	if not end_turn_button.pressed.is_connected(_on_end_turn_button_pressed):
		end_turn_button.pressed.connect(_on_end_turn_button_pressed)
	if not discard_pile_button.pressed.is_connected(_on_discard_button_pressed):
		discard_pile_button.pressed.connect(_on_discard_button_pressed)
	if not discard_close_button.pressed.is_connected(_on_discard_close_button_pressed):
		discard_close_button.pressed.connect(_on_discard_close_button_pressed)
	if not battle_log_button.pressed.is_connected(_on_battle_log_button_pressed):
		battle_log_button.pressed.connect(_on_battle_log_button_pressed)
	if not battle_log_close_button.pressed.is_connected(_on_battle_log_close_button_pressed):
		battle_log_close_button.pressed.connect(_on_battle_log_close_button_pressed)

	# 饼状图 hover
	if pie_chart.has_signal("stat_hovered") and not pie_chart.is_connected("stat_hovered", Callable(self, "_on_stat_hovered")):
		pie_chart.connect("stat_hovered", Callable(self, "_on_stat_hovered"))

	# 能量/认知 hover
	_register_tooltip_area(energy_section, Callable(self, "_build_energy_tooltip"))
	_register_tooltip_area(cognition_section, Callable(self, "_build_cognition_tooltip"))

	# BOSS 肖像点击
	if not boss_portrait.gui_input.is_connected(_on_boss_portrait_gui_input):
		boss_portrait.gui_input.connect(_on_boss_portrait_gui_input)
	boss_portrait.mouse_filter = Control.MOUSE_FILTER_STOP

	# 奖励 UI
	var on_reward_selected := Callable(self, "_on_reward_story_selected")
	if reward_story_ui.has_signal("reward_selected") and not reward_story_ui.is_connected("reward_selected", on_reward_selected):
		reward_story_ui.connect("reward_selected", on_reward_selected)

	if reward_story_ui.has_method("hide_ui"):
		reward_story_ui.hide_ui()
	else:
		reward_story_ui.hide()

	discard_panel.visible = false
	battle_log_panel.visible = false
	enemy_info_popup.visible = false
	tooltip_panel.visible = false


func _setup_enemy() -> void:
	if _is_normal_battle():
		enemy_name = "浅海异常体"
		enemy_max_hp = 12
		enemy_hp = enemy_max_hp
		enemy_cycle = [
			{"type": "attack", "value": 2, "text": "撕咬：造成2点伤害"},
			{"type": "attack", "value": 3, "text": "扑袭：造成3点伤害"},
			{"type": "apply_weak", "value": 1, "text": "污染：施加1层虚弱"}
		]
		enemy_hand_preview = ["撕咬", "扑袭", "污染"]
	else:
		enemy_name = "深层凝视体"
		enemy_max_hp = 18
		enemy_hp = enemy_max_hp
		enemy_cycle = [
			{"type": "attack", "value": 4, "text": "凝视：造成4点伤害"},
			{"type": "apply_weak", "value": 2, "text": "侵蚀：施加2层虚弱"},
			{"type": "attack", "value": 5, "text": "重压：造成5点伤害"}
		]
		enemy_hand_preview = ["凝视", "侵蚀", "重压"]
	enemy_cycle_index = 0
	enemy_weak = 0
	_log("敌人逼近：%s。" % enemy_name)
	_refresh_enemy_ui()


func _start_battle() -> void:
	if Game.deck.is_empty():
		Game.reset_run()
	_ensure_playable_deck()

	draw_pile = Game.deck.duplicate()
	draw_pile.shuffle()
	hand.clear()
	discard_pile.clear()

	player_block = 0
	player_weak = 0
	energy = 0  # 会在 _start_player_turn 中 +3
	Game.clear_cognition()

	_start_player_turn()


func _ensure_playable_deck() -> void:
	if Game.deck.size() >= HAND_DRAW_COUNT:
		return
	Game.deck.clear()
	for card_id in STARTER_DECK:
		Game.deck.append(card_id)


func set_battle_state(new_state: int) -> void:
	battle_state = new_state
	var can_play := battle_state == BattleState.PLAYER_TURN

	end_turn_button.disabled = not can_play
	_set_hand_interactable(can_play)

	if battle_state == BattleState.REWARD:
		_open_reward_story()
	elif battle_state == BattleState.FINISHED:
		_set_hand_interactable(false)

	_refresh_full_ui()


func _start_player_turn() -> void:
	# 精神负荷：+3/回合，上限10，未使用的会保留
	energy = mini(energy + ENERGY_GAIN_PER_TURN, ENERGY_MAX)
	draw_cards(HAND_DRAW_COUNT)
	set_battle_state(BattleState.PLAYER_TURN)
	_log("你的回合开始。")
	hand_hint_label.text = "拖拽或点击卡牌来使用。"


func draw_cards(count: int) -> void:
	for _i in range(count):
		if draw_pile.is_empty():
			draw_pile = discard_pile.duplicate()
			discard_pile.clear()
			draw_pile.shuffle()
			if not draw_pile.is_empty():
				_log("弃牌堆洗回抽牌堆。")

		if draw_pile.is_empty():
			break

		hand.append(draw_pile.pop_back())


func play_card(card_index: int) -> void:
	if battle_state != BattleState.PLAYER_TURN:
		return
	if card_index < 0 or card_index >= hand.size():
		return

	var card_id: String = hand[card_index]
	var card: Dictionary = CardDatabase.get_card(card_id)
	var cost: int = _get_effective_cost(card)
	if cost > energy:
		_log("能量不足，无法打出【%s】。" % str(card.get("name", card_id)))
		_refresh_full_ui()
		return

	energy -= cost
	_apply_card_effect(card)
	_apply_cognition_cost(card)

	discard_pile.append(card_id)
	hand.remove_at(card_index)

	if Game.player_hp <= 0:
		await _on_battle_lose()
		return

	if enemy_hp <= 0:
		await _on_battle_win()
		return

	_refresh_full_ui()


func _apply_card_effect(card: Dictionary) -> void:
	var card_name := str(card.get("name", "未知卡牌"))
	var damage: int = int(card.get("damage", 0))
	var block_gain: int = int(card.get("block", 0))
	var san_heal: int = int(card.get("san_heal", 0))
	var apply_weak: int = int(card.get("apply_weak", 0))
	var san_cost: int = int(card.get("san_cost", 0))
	var draw_count: int = int(card.get("draw", 0))
	var gain_energy: int = int(card.get("gain_energy", 0))
	var reduce_cognition: int = int(card.get("reduce_cognition", 0))

	var fragments: Array[String] = []

	if damage > 0:
		var final_damage := _apply_weak_to_damage(damage, player_weak)
		enemy_hp = maxi(0, enemy_hp - final_damage)
		fragments.append("造成%d点伤害" % final_damage)
		_play_enemy_hit_feedback()

	if block_gain > 0:
		player_block += block_gain
		fragments.append("获得%d点护盾" % block_gain)

	if san_heal > 0:
		Game.heal_san(san_heal)
		fragments.append("恢复%d点SAN" % san_heal)

	if apply_weak > 0:
		enemy_weak += apply_weak
		fragments.append("施加%d层虚弱" % apply_weak)

	if san_cost > 0:
		Game.player_san = maxi(Game.player_san - san_cost, 0)
		fragments.append("失去%d点SAN" % san_cost)

	if draw_count > 0:
		draw_cards(draw_count)
		fragments.append("抽%d张牌" % draw_count)

	if gain_energy > 0:
		energy = mini(energy + gain_energy, ENERGY_MAX)
		fragments.append("获得%d点精神负荷" % gain_energy)

	if reduce_cognition > 0:
		Game.player_cognition = maxi(Game.player_cognition - reduce_cognition, 0)
		fragments.append("降低%d点认知负荷" % reduce_cognition)

	if fragments.is_empty():
		_log("你使用了【%s】。" % card_name)
	else:
		_log("你使用【%s】：%s。" % [card_name, "，".join(fragments)])


func _apply_cognition_cost(card: Dictionary) -> void:
	var cognition_gain: int = int(card.get("cognition", 0))
	if cognition_gain <= 0:
		return

	Game.add_cognition(cognition_gain)
	if Game.player_cognition > Game.max_cognition:
		var hp_before := Game.player_hp
		Game.player_hp = maxi(1, int(round(float(Game.player_hp) / 2.0)))
		Game.clear_cognition()
		_log("认知超载！存在值由%d降至%d。" % [hp_before, Game.player_hp])


func _on_end_turn_button_pressed() -> void:
	if battle_state != BattleState.PLAYER_TURN:
		return

	_log("你结束了回合。")
	await _enemy_turn()


func _enemy_turn() -> void:
	set_battle_state(BattleState.ENEMY_TURN)
	_discard_hand_to_pile()

	var intent := _get_current_enemy_intent()
	match String(intent.get("type", "attack")):
		"attack":
			var attack_value := _apply_weak_to_damage(int(intent.get("value", 0)), enemy_weak)
			var actual_damage := maxi(0, attack_value - player_block)
			player_block = maxi(0, player_block - attack_value)
			Game.damage_player(actual_damage)
			_log("敌人发动【%s】，造成%d点伤害。" % [str(intent.get("text", "攻击")), actual_damage])
		"apply_weak":
			var weak_value := int(intent.get("value", 0))
			player_weak += weak_value
			_log("敌人发动【%s】，你获得%d层虚弱。" % [str(intent.get("text", "侵蚀")), weak_value])

	if enemy_weak > 0:
		enemy_weak = maxi(enemy_weak - 1, 0)
	if player_weak > 0:
		player_weak = maxi(player_weak - 1, 0)

	if Game.player_hp <= 0:
		await _on_battle_lose()
		return

	enemy_cycle_index = (enemy_cycle_index + 1) % max(enemy_cycle.size(), 1)
	await get_tree().create_timer(0.35).timeout
	_start_player_turn()


func _discard_hand_to_pile() -> void:
	for card_id in hand:
		discard_pile.append(card_id)
	hand.clear()


func _on_battle_win() -> void:
	_log("战斗胜利。")
	if _is_normal_battle() and not Game.first_battle_reward_done:
		set_battle_state(BattleState.REWARD)
		return

	set_battle_state(BattleState.FINISHED)
	await get_tree().create_timer(0.5).timeout
	if _is_normal_battle():
		Game.goto_explore()
	else:
		Game.goto_end()


func _on_battle_lose() -> void:
	set_battle_state(BattleState.FINISHED)
	_log("你的意识溃散了。")
	await get_tree().create_timer(1.0).timeout
	Game.goto_title()


func _open_reward_story() -> void:
	if reward_story_ui.has_method("show_ui"):
		reward_story_ui.show_ui()
	else:
		reward_story_ui.show()
	_log("从残响中选择一张新卡。")


func _on_reward_story_selected(card_id: String) -> void:
	if battle_state != BattleState.REWARD:
		return
	if card_id != "pursue" and card_id != "seal":
		return

	Game.add_card(card_id)
	Game.first_battle_reward_done = true
	_log("你获得了【%s】。" % str(CardDatabase.get_card(card_id).get("name", card_id)))

	set_battle_state(BattleState.FINISHED)
	await get_tree().create_timer(0.5).timeout
	Game.goto_explore()


# ====== 弃牌堆弹窗 ======
func _on_discard_button_pressed() -> void:
	battle_log_panel.visible = false
	discard_panel.visible = true
	_refresh_discard_view()


func _on_discard_close_button_pressed() -> void:
	discard_panel.visible = false


func _refresh_discard_view() -> void:
	if discard_pile.is_empty():
		discard_text.text = "[center]当前弃牌堆为空。[/center]"
		return

	var lines: Array[String] = []
	lines.append("[center][b]弃牌堆[/b][/center]")
	lines.append("")
	for card_id in discard_pile:
		var card: Dictionary = CardDatabase.get_card(card_id)
		lines.append("• %s" % str(card.get("name", card_id)))
	discard_text.text = "\n".join(lines)


# ====== 战斗记录弹窗 ======
func _on_battle_log_button_pressed() -> void:
	discard_panel.visible = false
	battle_log_panel.visible = true
	_refresh_battle_log_view()


func _on_battle_log_close_button_pressed() -> void:
	battle_log_panel.visible = false


func _refresh_battle_log_view() -> void:
	if battle_log_lines.is_empty():
		battle_log_text.text = "[center]（暂无记录）[/center]"
		return
	battle_log_text.text = "\n".join(battle_log_lines)


# ====== UI 刷新 ======
func _refresh_full_ui() -> void:
	_refresh_enemy_ui()
	_refresh_player_ui()
	_refresh_hand_cards()
	_refresh_discard_view()
	_refresh_battle_log_view()
	if enemy_info_popup.visible:
		_refresh_enemy_info_popup_content()


func _refresh_enemy_ui() -> void:
	boss_bar_root.visible = enemy_hp > 0
	boss_name_label.text = enemy_name
	boss_hp_bar.max_value = float(max(enemy_max_hp, 1))
	boss_hp_bar.value = float(clamp(enemy_hp, 0, enemy_max_hp))
	var intent := _get_current_enemy_intent()
	var intent_text := str(intent.get("text", "攻击"))
	if String(intent.get("type", "attack")) == "attack":
		intent_text += "（实际 %d）" % _apply_weak_to_damage(int(intent.get("value", 0)), enemy_weak)
	boss_intent_label.text = intent_text


func _refresh_player_ui() -> void:
	# 饼状图
	pie_chart.call("set_stats", Game.player_hp, Game.max_hp, Game.player_san, Game.max_san)

	# 精神负荷
	energy_label.text = "%d / %d" % [energy, ENERGY_MAX]
	energy_bar.max_value = float(ENERGY_MAX)
	energy_bar.value = float(clamp(energy, 0, ENERGY_MAX))

	# 认知负荷
	cognition_label.text = "%d / %d" % [Game.player_cognition, Game.max_cognition]
	cognition_bar.max_value = float(max(Game.max_cognition, 1))
	cognition_bar.value = float(clamp(Game.player_cognition, 0, Game.max_cognition))

	# Buff / 状态图标
	_refresh_status_icons()


func _refresh_status_icons() -> void:
	for child in status_icon_row.get_children():
		child.queue_free()

	# 护盾
	if player_block > 0:
		_add_status_icon(
			"盾",
			player_block,
			Color(0.45, 0.72, 0.95, 1.0),
			"护盾",
			"护盾 %d：抵挡下回合 %d 点伤害，超出部分失效。" % [player_block, player_block]
		)

	# 虚弱（玩家）
	if player_weak > 0:
		_add_status_icon(
			"弱",
			player_weak,
			Color(0.85, 0.55, 0.90, 1.0),
			"虚弱",
			"虚弱 %d：本轮每次造成伤害时，伤害值 -%d（最低为1）。" % [player_weak, player_weak]
		)

	# 癫狂
	if Game.is_distorted():
		_add_status_icon(
			"癫",
			-1,
			Color(0.95, 0.45, 0.45, 1.0),
			"癫狂",
			"癫狂状态：所有卡牌费用 +1。"
		)


func _add_status_icon(label_text: String, stack: int, color: Color, display_name: String, tip_text: String) -> void:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(52, 52)
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.text = label_text if stack < 0 else ("%s%d" % [label_text, stack])
	btn.add_theme_font_size_override("font_size", 18)

	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.corner_radius_top_left = 26
	sb.corner_radius_top_right = 26
	sb.corner_radius_bottom_left = 26
	sb.corner_radius_bottom_right = 26
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(1, 1, 1, 0.5)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("disabled", sb)
	btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))

	status_icon_row.add_child(btn)

	var tooltip_text := "[b]%s[/b]\n%s" % [display_name, tip_text]
	var builder := func() -> String: return tooltip_text
	_register_tooltip_area(btn, builder)


func _refresh_hand_cards() -> void:
	for child in hand_row.get_children():
		child.queue_free()

	for i in range(hand.size()):
		var card_id: String = hand[i]
		var card_data: Dictionary = CardDatabase.get_card(card_id)
		var card_ui: Control = CARD_SCENE.instantiate()
		card_ui.custom_minimum_size = Vector2(165, 250)
		card_ui.call("setup", card_data, i, self)
		card_ui.disabled = battle_state != BattleState.PLAYER_TURN or _get_effective_cost(card_data) > energy
		hand_row.add_child(card_ui)

	hand_hint_label.text = "手牌 %d / 弃牌 %d / 抽牌 %d" % [hand.size(), discard_pile.size(), draw_pile.size()]


func _set_hand_interactable(enabled: bool) -> void:
	for node in hand_row.get_children():
		if node is Button:
			node.disabled = not enabled


func _get_effective_cost(card: Dictionary) -> int:
	var cost: int = int(card.get("cost", 0))
	if Game.is_distorted():
		cost += 1
	return max(cost, 0)


func _get_current_enemy_intent() -> Dictionary:
	if enemy_cycle.is_empty():
		return {"type": "attack", "value": 2, "text": "攻击：造成2点伤害"}
	return enemy_cycle[enemy_cycle_index % enemy_cycle.size()]


func _apply_weak_to_damage(base_damage: int, weak_stack: int) -> int:
	if base_damage <= 0:
		return 0
	if weak_stack <= 0:
		return base_damage
	return maxi(1, base_damage - weak_stack)


func _play_enemy_hit_feedback() -> void:
	if _boss_hit_tween and is_instance_valid(_boss_hit_tween):
		_boss_hit_tween.kill()

	var start_pos := boss_portrait.position
	var start_modulate := boss_portrait.modulate
	boss_portrait.modulate = Color(1.25, 1.15, 1.15, 1.0)

	_boss_hit_tween = create_tween()
	_boss_hit_tween.tween_property(boss_portrait, "position", start_pos + Vector2(-10, 0), 0.03)
	_boss_hit_tween.tween_property(boss_portrait, "position", start_pos + Vector2(8, 0), 0.03)
	_boss_hit_tween.tween_property(boss_portrait, "position", start_pos, 0.04)
	_boss_hit_tween.parallel().tween_property(boss_portrait, "modulate", start_modulate, 0.16)


func _log(text: String) -> void:
	battle_log_lines.append(text)
	while battle_log_lines.size() > 64:
		battle_log_lines.pop_front()
	_refresh_battle_log_view()


func _is_normal_battle() -> bool:
	return Game.battle_index <= 1


# ====== 敌人信息弹窗（点击 BossPortrait 切换） ======
func _on_boss_portrait_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_toggle_enemy_info_popup()


func _toggle_enemy_info_popup() -> void:
	enemy_info_popup.visible = not enemy_info_popup.visible
	if enemy_info_popup.visible:
		_refresh_enemy_info_popup_content()
		_reposition_enemy_info_popup()


func _refresh_enemy_info_popup_content() -> void:
	enemy_info_title.text = "敌人类型：%s" % enemy_name
	var intent := _get_current_enemy_intent()

	var lines: Array[String] = []
	lines.append("存在值：%d / %d" % [enemy_hp, enemy_max_hp])
	lines.append("现有手牌：%s" % (", ".join(enemy_hand_preview) if not enemy_hand_preview.is_empty() else "—"))
	lines.append("状态栏：下一回合意图 → %s" % str(intent.get("text", "攻击")))
	var buffs: Array[String] = []
	if enemy_weak > 0:
		buffs.append("虚弱 %d" % enemy_weak)
	lines.append("Buff栏：%s" % ("，".join(buffs) if not buffs.is_empty() else "无"))
	enemy_info_body.text = "\n".join(lines)


func _reposition_enemy_info_popup() -> void:
	if not is_instance_valid(boss_portrait):
		return
	var boss_rect: Rect2 = boss_portrait.get_global_rect()
	var popup_size: Vector2 = enemy_info_popup.size
	var target_x: float = boss_rect.position.x + (boss_rect.size.x - popup_size.x) * 0.5
	var target_y: float = boss_rect.position.y - popup_size.y - 16.0
	target_y = maxf(target_y, 12.0)
	var viewport_size: Vector2 = get_viewport_rect().size
	target_x = clampf(target_x, 8.0, viewport_size.x - popup_size.x - 8.0)
	enemy_info_popup.global_position = Vector2(target_x, target_y)


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
	var text_result: Variant = _current_tooltip_builder.call()
	var body: String = str(text_result)
	if body.is_empty():
		_hide_tooltip()
		return
	tooltip_label.text = body
	tooltip_panel.visible = true
	tooltip_panel.z_index = 200
	_reposition_tooltip()


func _hide_tooltip() -> void:
	tooltip_panel.visible = false


func _reposition_tooltip() -> void:
	if not tooltip_panel.visible:
		return
	# 让panel自适应大小
	tooltip_panel.reset_size()
	var mouse_pos: Vector2 = get_global_mouse_position()
	var tsize: Vector2 = tooltip_panel.size
	var viewport_size: Vector2 = get_viewport_rect().size
	var pos: Vector2 = mouse_pos + Vector2(20, 20)
	pos.x = clamp(pos.x, 4, viewport_size.x - tsize.x - 4)
	pos.y = clamp(pos.y, 4, viewport_size.y - tsize.y - 4)
	tooltip_panel.global_position = pos


# 饼状图 hover 回调
func _on_stat_hovered(stat_key: String, is_hovering: bool) -> void:
	if is_hovering:
		_current_tooltip_source = pie_chart
		if stat_key == "hp":
			_current_tooltip_builder = Callable(self, "_build_hp_tooltip")
		else:
			_current_tooltip_builder = Callable(self, "_build_san_tooltip")
		_show_active_tooltip()
	else:
		if _current_tooltip_source == pie_chart:
			_current_tooltip_source = null
			_hide_tooltip()


func _build_hp_tooltip() -> String:
	return "[b]存在值（HP）[/b]\n%d / %d\n当前护盾：%d" % [Game.player_hp, Game.max_hp, player_block]


func _build_san_tooltip() -> String:
	var parts: Array[String] = []
	parts.append("[b]理智值（SAN）[/b]")
	parts.append("%d / %d" % [Game.player_san, Game.max_san])
	if Game.is_distorted():
		parts.append("当前：癫狂")
	return "\n".join(parts)


func _build_energy_tooltip() -> String:
	return "[b]精神负荷[/b]\n当前 %d / %d\n每回合 +%d，未用完保留至下回合，上限 %d。" % [
		energy, ENERGY_MAX, ENERGY_GAIN_PER_TURN, ENERGY_MAX
	]


func _build_cognition_tooltip() -> String:
	return "[b]认知负荷[/b]\n当前 %d / %d\n超过上限时，存在值减半并清零累积。" % [
		Game.player_cognition, Game.max_cognition
	]


# ====== 卡牌 tooltip（由 card_ui.gd 调用） ======
func show_card_tooltip(card_data: Dictionary) -> void:
	if card_data.is_empty():
		return
	var name_text: String = str(card_data.get("name", "未知卡牌"))
	var type_text: String = CardDatabase.get_type_text(str(card_data.get("type", "")))
	var cost: int = int(card_data.get("cost", 0))
	var cognition: int = int(card_data.get("cognition", 0))
	var desc: String = str(card_data.get("description", card_data.get("desc", "")))
	var body: String = "[b]%s[/b]  [%s]\n费用：%d    认知：%d" % [name_text, type_text, cost, cognition]
	if not desc.is_empty():
		body += "\n" + desc
	tooltip_label.text = body
	tooltip_panel.visible = true
	tooltip_panel.z_index = 200
	_current_tooltip_source = null  # 卡牌 tooltip 不使用 source 机制
	_reposition_tooltip()


func hide_card_tooltip() -> void:
	if _current_tooltip_source == null:
		_hide_tooltip()
