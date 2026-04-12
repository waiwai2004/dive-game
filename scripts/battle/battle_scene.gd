# 战斗场景脚本
# 处理战斗界面的显示和交互逻辑
extends Control

# 常量定义
const CARD_ITEM_SCENE = preload("res://scenes/ui/card_item.tscn")  # 卡牌项场景
const DAMAGE_NUMBER_SCENE = preload("res://scenes/ui/damage_number.tscn")
const ATTACK_EFFECT_SCENE = preload("res://scenes/ui/attack_effect.tscn")
const BATTLE_HISTORY_SCENE = preload("res://scenes/battle/history/battle_history_screen.tscn")

# 战斗管理器
var battle_manager: RefCounted  # 改为 RefCounted 类型
var battle_history_screen: Control

# 敌人UI组件
@onready var enemy_name_label = $MainBox/EnemyPanel/Enemybar/EnemyVBox/EnemyNameLabel  # 敌人名称标签
@onready var enemy_hp_label = $MainBox/EnemyPanel/Enemybar/EnemyVBox/EnemyHpLabel  # 敌人生命值标签
@onready var enemy_san_label = $MainBox/EnemyPanel/Enemybar/EnemyVBox/EnemySanLabel  # 敌人理智值标签
@onready var enemy_intent_label = $MainBox/EnemyPanel/Enemybar/EnemyVBox/EnemyIntentLabel  # 敌人意图标签
@onready var enemy_status_label = $MainBox/EnemyPanel/Enemybar/EnemyVBox/EnemyStatusLabel  # 敌人状态标签
@onready var enemy_hp_bar = $MainBox/EnemyPanel/Enemybar/EnemyVBox/EnemyHpBar  # 敌人生命进度条

# 玩家UI组件
@onready var player_mode_label = $MainBox/PlayerPanel/PlayerVBox/PlayerHeader/PlayerModeLabel
@onready var player_hp_label = $MainBox/PlayerPanel/PlayerVBox/PlayerContentRow/VitalsPanel/VitalsVBox/PlayerHpLabel  # 玩家生命值标签
@onready var player_san_label = $MainBox/PlayerPanel/PlayerVBox/PlayerContentRow/VitalsPanel/VitalsVBox/PlayerSanLabel  # 玩家理智值标签
@onready var player_energy_label = $MainBox/PlayerPanel/PlayerVBox/PlayerContentRow/ResourcesPanel/ResourcesVBox/PlayerEnergyLabel  # 玩家能量标签
@onready var player_cognition_label = $MainBox/PlayerPanel/PlayerVBox/PlayerContentRow/ResourcesPanel/ResourcesVBox/PlayerCognitionLabel  # 玩家认知负荷标签
@onready var player_buffs_label = $MainBox/PlayerPanel/PlayerVBox/PlayerContentRow/ResourcesPanel/ResourcesVBox/PlayerBuffsLabel
@onready var player_status_label = $MainBox/PlayerPanel/PlayerVBox/PlayerContentRow/StatusPanel/StatusVBox/PlayerStatusLabel  # 玩家状态标签
@onready var player_directive_label = $MainBox/PlayerPanel/PlayerVBox/PlayerContentRow/StatusPanel/StatusVBox/PlayerDirectiveLabel
@onready var player_hp_bar = $MainBox/PlayerPanel/PlayerVBox/PlayerContentRow/VitalsPanel/VitalsVBox/PlayerHpBar  # 玩家生命进度条
@onready var player_san_bar = $MainBox/PlayerPanel/PlayerVBox/PlayerContentRow/VitalsPanel/VitalsVBox/PlayerSanBar  # 玩家理智进度条

# 战术总览UI组件
@onready var battle_round_label = $MainBox/BattleInfoPanel/InfoMargin/InfoRow/RoundPanel/RoundVBox/BattleRoundLabel
@onready var battle_phase_label = $MainBox/BattleInfoPanel/InfoMargin/InfoRow/RoundPanel/RoundVBox/BattlePhaseLabel
@onready var battle_count_label = $MainBox/BattleInfoPanel/InfoMargin/InfoRow/CountPanel/CountVBox/BattleCountLabel
@onready var battle_threat_badge_label = $MainBox/BattleInfoPanel/InfoMargin/InfoRow/ThreatPanel/ThreatVBox/BattleThreatBadgeLabel
@onready var battle_threat_label = $MainBox/BattleInfoPanel/InfoMargin/InfoRow/ThreatPanel/ThreatVBox/BattleThreatLabel
@onready var battle_intent_summary_label = $MainBox/BattleInfoPanel/InfoMargin/InfoRow/ThreatPanel/ThreatVBox/BattleIntentSummaryLabel
@onready var battle_command_label = $MainBox/BattleInfoPanel/InfoMargin/InfoRow/CommandPanel/CommandVBox/BattleCommandLabel
@onready var battle_flow_bar = $MainBox/BattleInfoPanel/InfoMargin/InfoRow/CommandPanel/CommandVBox/BattleFlowBar
@onready var battle_flow_hint_label = $MainBox/BattleInfoPanel/InfoMargin/InfoRow/CommandPanel/CommandVBox/BattleFlowHintLabel
@onready var enemy_tag_label = $MainBox/EnemyPanel/Enemybar/EnemyVBox/EnemyTagLabel
@onready var turn_banner = $HudLayer/TurnBanner
@onready var turn_banner_label = $HudLayer/TurnBanner/TurnBannerLabel

# 其他UI组件
@onready var main_box = $MainBox
@onready var enemy_panel = $MainBox/EnemyPanel
@onready var enemy_portrait = $MainBox/EnemyPanel/Enemybar/EnemyPortrait
@onready var player_panel = $MainBox/PlayerPanel
@onready var battle_log_label = $MainBox/MiddleSplit/LogPanel/LogVBox/LogScroll/BattleLogLabel  # 战斗日志标签
@onready var log_scroll = $MainBox/MiddleSplit/LogPanel/LogVBox/LogScroll  # 战斗日志滚动容器
@onready var hand_container = $MainBox/HandScroll/CenterContainer/HandContainer  # 手牌容器
@onready var end_turn_button = $MainBox/BottomBar/EndTurnButton  # 结束回合按钮
@onready var hint_label = $MainBox/BottomBar/HintLabel  # 提示标签
@onready var history_button = $HudLayer/HistoryButton  # 历史记录按钮

var _main_box_base_position := Vector2.ZERO
var _enemy_portrait_base_position := Vector2.ZERO
var _player_panel_base_position := Vector2.ZERO
var _screen_shake_tween: Tween
var _enemy_hit_tween: Tween
var _player_hit_tween: Tween
var _hint_tween: Tween
var _end_turn_tween: Tween
var _phase_banner_tween: Tween
var _last_announced_phase := ""

# 场景准备就绪
func _ready() -> void:
	# 连接按钮信号
	if end_turn_button:
		end_turn_button.pressed.connect(_on_end_turn_button_pressed)
		end_turn_button.mouse_entered.connect(_on_end_turn_button_hovered)
	else:
		push_error("end_turn_button is null")

	if history_button:
		history_button.pressed.connect(_on_history_button_pressed)
	else:
		push_error("history_button is null")

	# 连接ESC键信号
	set_process_unhandled_input(true)

	# 将玩家面板移到手牌(HandScroll)之后、BottomBar之前
	if player_panel and main_box:
		var bottom_bar = $MainBox/BottomBar
		if bottom_bar:
			main_box.move_child(player_panel, bottom_bar.get_index())

	# 实例化战斗历史记录屏幕
	if BATTLE_HISTORY_SCENE:
		battle_history_screen = BATTLE_HISTORY_SCENE.instantiate()
		add_child(battle_history_screen)
		battle_history_screen.z_index = 1000

	# 创建战斗管理器
	battle_manager = load("res://scripts/battle_manager.gd").new()  # 使用 load() 加载脚本
	# 连接战斗日志添加信号
	battle_manager.battle_log_added.connect(_on_battle_log_added)
	# 连接战斗状态改变信号
	battle_manager.battle_state_changed.connect(_on_battle_state_changed)
	# 连接战斗结束信号
	battle_manager.battle_ended.connect(_on_battle_ended)
	# 连接伤害信号
	battle_manager.enemy_damaged.connect(_on_enemy_damaged)
	battle_manager.player_damaged.connect(_on_player_damaged)

	# 初始化战斗日志
	battle_log_label.text = ""
	# 设置初始提示
	hint_label.text = "战术终端已就绪：选择一张手牌开始行动。"
	end_turn_button.text = "结束回合  ▶"

	# 设置演示战斗
	var is_boss = GameManager.get_current_node_type() == "battle_boss"
	battle_manager.setup_demo_battle(is_boss)
	# 刷新所有UI
	refresh_all_ui()

	await get_tree().process_frame
	_main_box_base_position = main_box.position
	_enemy_portrait_base_position = enemy_portrait.position
	_player_panel_base_position = player_panel.position


# 平滑更新进度条
func update_progress_bar(progress_bar: ProgressBar, new_value: int, max_value: int) -> void:
	# 设置最大值
	progress_bar.max_value = max_value
	# 创建Tween动画，平滑过渡到新值
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(progress_bar, "value", new_value, 0.3)

# 战斗日志添加处理
func _on_battle_log_added(text: String) -> void:
	# 添加日志到UI
	append_log(text)
	# 同时添加到历史记录屏幕
	if battle_history_screen:
		battle_history_screen.add_history_record(text)

# 战斗状态改变处理
func _on_battle_state_changed() -> void:
	# 刷新所有UI
	refresh_all_ui()
	# 同步当前玩家状态到游戏管理器
	sync_player_summary_to_game_manager()

# 战斗结束处理
func _on_battle_ended(is_victory: bool) -> void:
	# 根据战斗结果设置提示
	if is_victory:
		hint_label.text = "胜利！"
		GameManager.battle_result = "victory"
	else:
		hint_label.text = "失败！"
		GameManager.battle_result = "defeat"

	# 同步玩家状态回游戏管理器
	sync_player_summary_to_game_manager()

	# 禁用按钮
	end_turn_button.disabled = true

	# 显示战斗结果界面
	if is_victory:
		show_victory_screen()
	else:
		show_defeat_screen()

# 显示胜利界面
func show_victory_screen():
	# 创建胜利界面
	var victory_screen = ColorRect.new()
	victory_screen.name = "VictoryScreen"
	victory_screen.color = Color(0, 0, 0, 0.8)
	victory_screen.size = get_viewport().size
	victory_screen.z_index = 1000
	add_child(victory_screen)

	# 创建胜利文本
	var victory_label = Label.new()
	victory_label.name = "VictoryLabel"
	victory_label.text = "胜利！"
	victory_label.add_theme_color_override("font_color", Color(1, 1, 1))
	victory_label.add_theme_font_override("font", load("res://art/assets/ui/fonts/pixel_font.tres"))
	victory_label.add_theme_font_size_override("font_size", 48)
	victory_label.size = Vector2(400, 100)
	victory_label.position = Vector2((get_viewport().size.x - 400) / 2, (get_viewport().size.y - 300) / 2)
	victory_screen.add_child(victory_label)

	# 创建奖励文本
	var reward_label = Label.new()
	reward_label.name = "RewardLabel"
	reward_label.text = "获得奖励"
	reward_label.add_theme_color_override("font_color", Color(1, 1, 0))
	reward_label.add_theme_font_override("font", load("res://art/assets/ui/fonts/pixel_font.tres"))
	reward_label.add_theme_font_size_override("font_size", 24)
	reward_label.size = Vector2(300, 50)
	reward_label.position = Vector2((get_viewport().size.x - 300) / 2, (get_viewport().size.y - 300) / 2 + 100)
	victory_screen.add_child(reward_label)

	# 创建确认按钮
	var confirm_button = Button.new()
	confirm_button.name = "ConfirmButton"
	confirm_button.text = "点击领取奖励"
	confirm_button.add_theme_color_override("font_color", Color(1, 1, 1))
	confirm_button.add_theme_color_override("bg_color", Color(0.2, 0.6, 0.2))
	confirm_button.add_theme_font_override("font", load("res://art/assets/ui/fonts/pixel_font.tres"))
	confirm_button.add_theme_font_size_override("font_size", 20)
	confirm_button.size = Vector2(200, 50)
	confirm_button.position = Vector2((get_viewport().size.x - 200) / 2, (get_viewport().size.y - 300) / 2 + 180)
	confirm_button.pressed.connect(_on_victory_confirm_pressed)
	victory_screen.add_child(confirm_button)

# 显示失败界面
func show_defeat_screen():
	# 创建失败界面
	var defeat_screen = ColorRect.new()
	defeat_screen.name = "DefeatScreen"
	defeat_screen.color = Color(0, 0, 0, 0.8)
	defeat_screen.size = get_viewport().size
	defeat_screen.z_index = 1000
	add_child(defeat_screen)

	# 创建失败文本
	var defeat_label = Label.new()
	defeat_label.name = "DefeatLabel"
	defeat_label.text = "你死了"
	defeat_label.add_theme_color_override("font_color", Color(1, 0, 0))
	defeat_label.add_theme_font_override("font", load("res://art/assets/ui/fonts/pixel_font.tres"))
	defeat_label.add_theme_font_size_override("font_size", 48)
	defeat_label.size = Vector2(400, 100)
	defeat_label.position = Vector2((get_viewport().size.x - 400) / 2, (get_viewport().size.y - 300) / 2)
	defeat_screen.add_child(defeat_label)

	# 创建重新开始文本
	var restart_label = Label.new()
	restart_label.name = "RestartLabel"
	restart_label.text = "点击重新开始新游戏"
	restart_label.add_theme_color_override("font_color", Color(1, 1, 1))
	restart_label.add_theme_font_override("font", load("res://art/assets/ui/fonts/pixel_font.tres"))
	restart_label.add_theme_font_size_override("font_size", 24)
	restart_label.size = Vector2(300, 50)
	restart_label.position = Vector2((get_viewport().size.x - 300) / 2, (get_viewport().size.y - 300) / 2 + 100)
	defeat_screen.add_child(restart_label)

	# 创建重新开始按钮
	var restart_button = Button.new()
	restart_button.name = "RestartButton"
	restart_button.text = "重新开始"
	restart_button.add_theme_color_override("font_color", Color(1, 1, 1))
	restart_button.add_theme_color_override("bg_color", Color(0.6, 0.2, 0.2))
	restart_button.add_theme_font_override("font", load("res://art/assets/ui/fonts/pixel_font.tres"))
	restart_button.add_theme_font_size_override("font_size", 20)
	restart_button.size = Vector2(200, 50)
	restart_button.position = Vector2((get_viewport().size.x - 200) / 2, (get_viewport().size.y - 300) / 2 + 180)
	restart_button.pressed.connect(_on_defeat_restart_pressed)
	defeat_screen.add_child(restart_button)

# 胜利确认按钮按下处理
func _on_victory_confirm_pressed():
	# 移除胜利界面
	for child in get_children():
		if child.name == "VictoryScreen":
			child.queue_free()

	# 获取当前节点类型
	var current_type = GameManager.get_current_node_type()

	# 如果是Boss战斗，切换到结果场景
	if current_type == "battle_boss":
		get_tree().change_scene_to_file("res://scenes/resualt/result_scene.tscn")
	else:
		# 前进到下一个节点
		GameManager.advance_node()
		# 切换到地图场景
		get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")

# 失败重新开始按钮按下处理
func _on_defeat_restart_pressed():
	# 移除失败界面
	for child in get_children():
		if child.name == "DefeatScreen":
			child.queue_free()

	# 切换到标题场景
	get_tree().change_scene_to_file("res://scenes/title/TitleScreen.tscn")

# 刷新所有UI
func refresh_all_ui() -> void:
	# 检查战斗管理器是否存在
	if battle_manager == null:
		return

	# 刷新战术总览UI
	refresh_battle_overview()
	# 刷新敌人UI
	refresh_enemy_ui()
	# 刷新玩家UI
	refresh_player_ui()
	# 构建手牌
	build_hand()

func _format_phase_text(phase: String) -> String:
	match phase:
		"PLAYER TURN":
			return "玩家回合"
		"ENEMY TURN":
			return "敌方回合"
		"ENDING TURN":
			return "回合结算"
		"VICTORY":
			return "胜利结算"
		"DEFEAT":
			return "战斗失败"
		_:
			return "战斗部署"

func _get_phase_progress(phase: String) -> int:
	match phase:
		"PLAYER TURN":
			return 45
		"ENEMY TURN":
			return 75
		"ENDING TURN":
			return 92
		"VICTORY", "DEFEAT":
			return 100
		_:
			return 18

func _get_phase_banner_color(phase: String) -> Color:
	match phase:
		"PLAYER TURN":
			return Color(0.72, 0.9, 1.0, 0.98)
		"ENEMY TURN":
			return Color(1.0, 0.72, 0.72, 0.98)
		"ENDING TURN":
			return Color(1.0, 0.88, 0.66, 0.98)
		"VICTORY":
			return Color(0.76, 1.0, 0.78, 0.98)
		"DEFEAT":
			return Color(1.0, 0.62, 0.62, 0.98)
		_:
			return Color(0.9, 0.95, 1.0, 0.98)

func show_phase_banner(raw_phase: String, phase_text: String) -> void:
	if turn_banner == null or turn_banner_label == null:
		return
	if _phase_banner_tween:
		_phase_banner_tween.kill()

	turn_banner.visible = true
	turn_banner.modulate = Color(1, 1, 1, 0)
	turn_banner.scale = Vector2(0.96, 0.96)
	turn_banner_label.text = "【 %s 】" % phase_text
	turn_banner_label.modulate = _get_phase_banner_color(raw_phase)

	_phase_banner_tween = create_tween()
	_phase_banner_tween.set_trans(Tween.TRANS_SINE)
	_phase_banner_tween.set_ease(Tween.EASE_OUT)
	_phase_banner_tween.parallel().tween_property(turn_banner, "modulate:a", 1.0, 0.16)
	_phase_banner_tween.parallel().tween_property(turn_banner, "scale", Vector2.ONE, 0.18)
	_phase_banner_tween.tween_interval(0.38)
	_phase_banner_tween.parallel().tween_property(turn_banner, "modulate:a", 0.0, 0.24)
	_phase_banner_tween.parallel().tween_property(turn_banner, "scale", Vector2(1.02, 1.02), 0.24)
	_phase_banner_tween.tween_callback(func():
		if is_instance_valid(turn_banner):
			turn_banner.visible = false
	)

func refresh_battle_overview() -> void:
	if battle_manager == null:
		return

	var player = battle_manager.player
	var enemy = battle_manager.enemy
	var round_number = max(battle_manager.get_turn_count(), 1)
	var raw_phase = battle_manager.get_phase_text()
	var phase_text = _format_phase_text(raw_phase)
	var estimated_damage := 0
	if enemy != null:
		estimated_damage = enemy.max_energy * 2

	var threat_text := "低"
	var threat_color := Color(0.82, 1.0, 0.82, 1.0)
	if estimated_damage >= 6:
		threat_text = "高"
		threat_color = Color(1.0, 0.66, 0.66, 1.0)
	elif estimated_damage >= 4:
		threat_text = "中"
		threat_color = Color(1.0, 0.86, 0.62, 1.0)

	battle_round_label.text = "第 %02d 回合" % round_number
	battle_phase_label.text = "阶段：%s" % phase_text
	battle_count_label.text = "手牌 %d｜牌库 %d" % [battle_manager.get_hand_size(), battle_manager.get_draw_pile_size()]
	battle_threat_badge_label.text = "⚠ 高压" if estimated_damage >= 6 else ("▲ 中危" if estimated_damage >= 4 else "✓ 可控")
	battle_threat_badge_label.modulate = threat_color
	battle_threat_label.text = "伤害 %d｜%s" % [estimated_damage, threat_text]
	battle_threat_label.modulate = threat_color
	battle_intent_summary_label.text = "⚔ 敌意：%s" % (enemy.intent_text if enemy != null else "未知")
	update_progress_bar(battle_flow_bar, _get_phase_progress(raw_phase), 100)

	if _last_announced_phase != raw_phase:
		_last_announced_phase = raw_phase
		show_phase_banner(raw_phase, phase_text)

	var flow_hint_text := "部署 → 行动 → 敌袭 → 结算"
	match raw_phase:
		"PLAYER TURN":
			flow_hint_text = "▶ 你的行动阶段"
		"ENEMY TURN":
			flow_hint_text = "☠ 敌方行动阶段"
		"ENDING TURN":
			flow_hint_text = "➜ 回合结算中"
		"VICTORY":
			flow_hint_text = "★ 胜利结算中"
		"DEFEAT":
			flow_hint_text = "✖ 失败结算中"
	battle_flow_hint_label.text = flow_hint_text

	var command_text := "拖拽出牌 / 点击指定"
	if battle_manager.battle_finished:
		command_text = "战斗已结束"
	elif player != null and player.energy <= 0 and battle_manager.selected_card_instance_id == -1:
		command_text = "费用不足，建议结束回合"
	elif battle_manager.selected_card_instance_id != -1:
		var selected_card = battle_manager.get_card_by_instance_id(battle_manager.selected_card_instance_id)
		var selected_name = selected_card.get("name", "当前手牌")
		command_text = "已锁定【%s】" % selected_name
	battle_command_label.text = command_text
	if battle_manager.battle_finished:
		battle_command_label.modulate = Color(0.88, 0.96, 1.0, 1.0)
	elif battle_manager.selected_card_instance_id != -1:
		battle_command_label.modulate = Color(0.92, 1.0, 0.9, 1.0)
	elif player != null and player.energy <= 0:
		battle_command_label.modulate = Color(1.0, 0.84, 0.66, 1.0)
	else:
		battle_command_label.modulate = Color(1, 1, 1, 1)

	player_mode_label.text = "ROUND %02d ｜ %s" % [round_number, phase_text]
	if player != null and player.cognition_overloaded:
		player_mode_label.modulate = Color(1.0, 0.72, 0.72, 1.0)
	else:
		player_mode_label.modulate = threat_color if estimated_damage >= 4 else Color(0.8, 0.92, 1, 1)

# 刷新敌人UI
func refresh_enemy_ui() -> void:
	# 获取敌人对象
	var enemy = battle_manager.enemy
	# 检查敌人是否存在
	if enemy == null:
		return

	# 设置敌人名称
	enemy_name_label.text = ("【BOSS】%s" % enemy.name) if enemy.max_hp >= 30 else ("敌人: %s" % enemy.name)
	# 设置敌人生命值并平滑更新进度条
	enemy_hp_label.text = "HP: %d / %d" % [enemy.hp, enemy.max_hp]
	update_progress_bar(enemy_hp_bar, enemy.hp, enemy.max_hp)
	# 设置敌人理智值
	enemy_san_label.text = "SAN: %d / %d" % [enemy.san, enemy.max_san]
	# 设置敌人意图
	var enemy_damage_preview = enemy.max_energy * 2
	enemy_intent_label.text = "【攻势】%s ｜ 预计伤害 %d" % [enemy.intent_text, enemy_damage_preview]
	enemy_intent_label.modulate = Color(1.0, 0.7, 0.7, 1.0) if enemy_damage_preview >= 6 else Color(1, 1, 1, 1)
	# 设置敌人状态
	enemy_status_label.text = "状态: 虚弱 x%d" % enemy.weak if enemy.weak > 0 else "状态: 无异常"
	var enemy_tags: Array[String] = []
	enemy_tags.append("⚠ 高压" if enemy_damage_preview >= 6 else "◎ 常规")
	enemy_tags.append("⚔ 连击 x%d" % enemy.max_energy)
	if enemy.weak > 0:
		enemy_tags.append("↓ 已削弱")
	enemy_tag_label.text = " | ".join(enemy_tags)
	enemy_tag_label.modulate = Color(1.0, 0.8, 0.74, 1.0) if enemy_damage_preview >= 6 else Color(0.9, 0.95, 1, 0.95)

# 刷新玩家UI
func refresh_player_ui() -> void:
	# 获取玩家对象
	var player = battle_manager.player
	# 检查玩家是否存在
	if player == null:
		return

	# 确保玩家面板始终可见
	player_panel.visible = true
	player_panel.scale = Vector2.ONE
	if player_panel.modulate.a < 0.99:
		player_panel.modulate = Color(1, 1, 1, 1)

	# 设置玩家生命值并平滑更新进度条
	player_hp_label.text = "生命 HP  %d / %d" % [player.hp, player.max_hp]
	update_progress_bar(player_hp_bar, player.hp, player.max_hp)
	# 设置玩家理智值并平滑更新进度条
	player_san_label.text = "理智 SAN  %d / %d" % [player.san, player.max_san]
	update_progress_bar(player_san_bar, player.san, player.max_san)
	# 设置玩家能量
	player_energy_label.text = "行动费用  %d / %d" % [player.energy, player.max_energy + player.extra_energy]
	# 设置玩家认知负荷
	player_cognition_label.text = "认知负荷  %d / %d" % [player.cognition, player.cognition_max]

	var hp_ratio: float = float(player.hp) / float(max(1, player.max_hp))
	var san_ratio: float = float(player.san) / float(max(1, player.max_san))
	var cognition_ratio: float = float(player.cognition) / float(max(1, player.cognition_max))
	player_hp_label.modulate = Color(1.0, 0.6, 0.6, 1.0) if hp_ratio <= 0.35 else Color(1, 1, 1, 1)
	player_san_label.modulate = Color(0.6, 0.85, 1.0, 1.0) if san_ratio <= 0.35 else Color(1, 1, 1, 1)
	if player.cognition_overloaded:
		player_cognition_label.modulate = Color(1.0, 0.58, 0.58, 1.0)
	elif cognition_ratio >= 0.7:
		player_cognition_label.modulate = Color(1.0, 0.84, 0.5, 1.0)
	else:
		player_cognition_label.modulate = Color(1, 1, 1, 1)
	player_energy_label.modulate = Color(1.0, 0.82, 0.58, 1.0) if player.energy <= 1 else Color(1, 1, 1, 1)

	var player_tags: Array[String] = []
	if player.extra_energy > 0:
		player_tags.append("✦ 激励 +%d" % player.extra_energy)
	if player.weak > 0:
		player_tags.append("⚠ 虚弱 x%d" % player.weak)
	if player.cognition_overloaded:
		player_tags.append("🧠 过载")
	elif player.cognition > 0:
		player_tags.append("◈ 负荷 %d" % player.cognition)
	if player_tags.is_empty():
		player_tags.append("✓ 状态稳定")
	player_buffs_label.text = " | ".join(player_tags)
	player_buffs_label.modulate = Color(1.0, 0.82, 0.72, 1.0) if player.cognition_overloaded or player.weak > 0 else Color(0.86, 0.94, 1, 0.95)

	# 设置玩家状态
	var player_state := "稳定"
	if player.is_mad():
		player_state = "恼怒"
	if player.cognition_overloaded:
		player_state = "认知过载"
	if player.weak > 0:
		player_state += " | 虚弱 x%d" % player.weak

	player_status_label.text = "战斗状态  %s" % player_state
	player_status_label.modulate = Color(1.0, 0.7, 0.7, 1.0) if player.cognition_overloaded or player.is_mad() else Color(1, 1, 1, 1)

	var directive_text := "建议：优先压制敌方输出"
	if player.cognition_overloaded:
		directive_text = "🧠 认知过载，先求稳"
	elif player.energy <= 1:
		directive_text = "⏳ 费用偏低，可结束回合"
	elif player.weak > 0:
		directive_text = "🛡 当前虚弱，优先辅助"
	elif hp_ratio <= 0.35:
		directive_text = "❤ 生命危险，先保命"
	player_directive_label.text = directive_text

# 构建手牌
func build_hand() -> void:
	var current_hand = battle_manager.get_hand_cards()
	var existing_children = hand_container.get_children()
	
	# 构建现有卡牌的映射表
	var existing_map := {}
	for card in existing_children:
		if card.card_instance_id != -1:
			existing_map[card.card_instance_id] = card
	
	# 第一步：删除不在当前手牌中的卡牌
	var current_ids_set := {}
	for card_data in current_hand:
		current_ids_set[card_data.get("instance_id", -1)] = true
	
	for instance_id in existing_map.keys():
		if not current_ids_set.has(instance_id):
			var stale_card = existing_map[instance_id]
			if is_instance_valid(stale_card) and stale_card.get_parent() == hand_container:
				stale_card.queue_free()
	
	# 第二步：按当前手牌顺序重建/复用卡牌，保证顺序不变
	for i in range(current_hand.size()):
		var card_data = current_hand[i]
		var instance_id = card_data.get("instance_id", -1)
		var card_ui
		
		if existing_map.has(instance_id) and is_instance_valid(existing_map[instance_id]):
			card_ui = existing_map[instance_id]
		else:
			card_ui = CARD_ITEM_SCENE.instantiate()
			hand_container.add_child(card_ui)
			card_ui.setup(card_data)
			card_ui.card_pressed.connect(_on_card_pressed)
			card_ui.card_dragged_to_enemy.connect(_on_card_dragged_to_enemy)
			card_ui.set_display_size(Vector2(220, 260))
			existing_map[instance_id] = card_ui
		
		if card_ui.get_parent() == hand_container:
			hand_container.move_child(card_ui, i)
		
		# 直接设置选中状态，不使用call_deferred
		card_ui.set_selected(instance_id == battle_manager.selected_card_instance_id)
		# 直接同步布局状态
		card_ui._sync_layout_state()
	
	# 强制更新容器布局
	hand_container.queue_sort()

# 添加日志
func append_log(text: String) -> void:
	# 如果日志为空，直接设置文本
	if battle_log_label.text.is_empty():
		battle_log_label.text = text
	else:
		# 否则添加新行
		battle_log_label.text += "\n" + text
	
	# 自动滚动到日志底部
	if log_scroll:
		# 下一帧执行滚动，确保文本已更新
		await get_tree().process_frame
		log_scroll.scroll_vertical = log_scroll.get_v_scroll_bar().max_value

func sync_player_summary_to_game_manager() -> void:
	if battle_manager != null and battle_manager.player != null:
		var p = battle_manager.player
		GameManager.player_summary["hp"] = p.hp
		GameManager.player_summary["max_hp"] = p.max_hp
		GameManager.player_summary["san"] = p.san
		GameManager.player_summary["max_san"] = p.max_san
		GameManager.player_summary["energy_max"] = p.max_energy
		GameManager.player_summary["extra_energy"] = p.extra_energy
		GameManager.player_summary["cognition"] = p.cognition
		GameManager.player_summary["cognition_max"] = p.cognition_max
		GameManager.player_summary["cognition_overloaded"] = p.cognition_overloaded

func shake_control(target: Control, base_position: Vector2, strength: float, duration: float, existing_tween: Tween = null) -> Tween:
	if target == null or not is_instance_valid(target):
		return null

	if existing_tween:
		existing_tween.kill()

	target.position = base_position
	var step_duration = duration / 5.0
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)

	for i in range(4):
		var offset = Vector2(
			randf_range(-strength, strength),
			randf_range(-strength * 0.45, strength * 0.45)
		)
		tween.tween_property(target, "position", base_position + offset, step_duration)

	tween.tween_property(target, "position", base_position, step_duration)
	return tween

func flash_control(target: CanvasItem, flash_color: Color, duration: float) -> void:
	if target == null or not is_instance_valid(target):
		return

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "modulate", flash_color, duration * 0.4)
	tween.tween_property(target, "modulate", Color(1, 1, 1, 1), duration * 0.6)

func pulse_control(target: Control, flash_color: Color, scale_multiplier: float = 1.04, duration: float = 0.18, existing_tween: Tween = null) -> Tween:
	if target == null or not is_instance_valid(target):
		return null

	if existing_tween:
		existing_tween.kill()

	var base_scale = target.scale
	var base_modulate = target.modulate
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(target, "scale", base_scale * scale_multiplier, duration * 0.45)
	tween.parallel().tween_property(target, "modulate", flash_color, duration * 0.4)
	tween.tween_property(target, "scale", base_scale, duration * 0.55)
	tween.parallel().tween_property(target, "modulate", base_modulate, duration * 0.6)
	return tween

func get_card_ui_by_instance_id(instance_id: int):
	for child in hand_container.get_children():
		if child.card_instance_id == instance_id:
			return child
	return null

func animate_result_feedback(result_text: String, instance_id: int = -1) -> void:
	if result_text.find("没有足够") != -1:
		_hint_tween = pulse_control(hint_label, Color(1.0, 0.78, 0.78, 1.0), 1.05, 0.18, _hint_tween)
		_end_turn_tween = pulse_control(end_turn_button, Color(1.0, 0.94, 0.82, 1.0), 1.03, 0.18, _end_turn_tween)
		var card_ui = get_card_ui_by_instance_id(instance_id)
		if card_ui != null and card_ui.has_method("play_warning_feedback"):
			card_ui.play_warning_feedback()
	elif result_text.find("请选择敌人") != -1:
		_hint_tween = pulse_control(hint_label, Color(1.0, 0.98, 0.84, 1.0), 1.03, 0.16, _hint_tween)
		pulse_control(enemy_panel, Color(1.0, 0.98, 0.9, 1.0), 1.02, 0.16)
	elif result_text.find("使用了") != -1 or result_text.find("恢复") != -1 or result_text.find("胜利") != -1:
		_hint_tween = pulse_control(hint_label, Color(0.9, 1.0, 0.9, 1.0), 1.04, 0.18, _hint_tween)
	elif result_text.find("取消选择") != -1:
		_hint_tween = pulse_control(hint_label, Color(0.92, 0.96, 1.0, 1.0), 1.02, 0.14, _hint_tween)

func _on_end_turn_button_hovered() -> void:
	if end_turn_button != null and not end_turn_button.disabled:
		_end_turn_tween = pulse_control(end_turn_button, Color(1.0, 0.97, 0.88, 1.0), 1.03, 0.14, _end_turn_tween)

func _on_enemy_damaged(amount: int) -> void:
	_screen_shake_tween = shake_control(main_box, _main_box_base_position, 9.0, 0.16, _screen_shake_tween)
	_enemy_hit_tween = shake_control(enemy_portrait, _enemy_portrait_base_position, 16.0, 0.2, _enemy_hit_tween)
	flash_control(enemy_panel, Color(1.0, 0.82, 0.82, 1.0), 0.16)
	pulse_control(enemy_panel, Color(1.0, 0.9, 0.9, 1.0), 1.02, 0.16)
	show_damage_number(amount, enemy_hp_bar.get_global_position() + Vector2(enemy_hp_bar.size.x / 2, -20), false)

func _on_player_damaged(amount: int) -> void:
	_screen_shake_tween = shake_control(main_box, _main_box_base_position, 7.0, 0.14, _screen_shake_tween)
	_player_hit_tween = shake_control(player_panel, _player_panel_base_position, 12.0, 0.18, _player_hit_tween)
	flash_control(player_panel, Color(1.0, 0.86, 0.86, 1.0), 0.14)
	pulse_control(player_panel, Color(1.0, 0.9, 0.9, 1.0), 1.02, 0.14)
	show_damage_number(amount, player_hp_bar.get_global_position() + Vector2(player_hp_bar.size.x / 2, -20), true)

func show_damage_number(amount: int, pos: Vector2, is_player_damage: bool) -> void:
	var number = DAMAGE_NUMBER_SCENE.instantiate()
	number.text = str(amount)
	if is_player_damage:
		number.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	else:
		number.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
	number.global_position = pos
	add_child(number)

func show_attack_effect(global_target_position: Vector2) -> void:
	var effect = ATTACK_EFFECT_SCENE.instantiate()
	add_child(effect)
	effect.play_at(global_target_position)

func play_card_fly_animation(card_data: Dictionary, start_global_position: Vector2, target_global_position: Vector2) -> void:
	var flying_card = CARD_ITEM_SCENE.instantiate()
	add_child(flying_card)
	flying_card.setup(card_data)
	flying_card.set_display_size(Vector2(220, 260))
	flying_card.disabled = true
	flying_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flying_card.top_level = true
	flying_card.z_index = 50
	flying_card.pivot_offset = flying_card.custom_minimum_size * 0.5
	flying_card.global_position = start_global_position
	flying_card.scale = Vector2(1.02, 1.02)

	var midpoint = start_global_position.lerp(target_global_position, 0.5) + Vector2(0, -80)
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(flying_card, "global_position", midpoint, 0.12)
	tween.parallel().tween_property(flying_card, "rotation", -0.08, 0.12)
	tween.tween_property(flying_card, "global_position", target_global_position, 0.14)
	tween.parallel().tween_property(flying_card, "scale", Vector2(0.78, 0.78), 0.14)
	tween.parallel().tween_property(flying_card, "modulate:a", 0.0, 0.12)
	tween.tween_callback(func():
		show_attack_effect(target_global_position)
		if is_instance_valid(flying_card):
			flying_card.queue_free()
	)

# 卡牌按下处理
func _on_card_pressed(instance_id: int) -> void:
	# 调用战斗管理器的卡牌点击处理
	var result_text = battle_manager.on_card_clicked(instance_id)
	# 设置提示文本
	hint_label.text = result_text
	animate_result_feedback(result_text, instance_id)
	# 刷新所有UI
	refresh_all_ui()

func _on_card_dragged_to_enemy(instance_id: int, release_global_position: Vector2) -> void:
	# 先记录拖拽卡牌数据，用于播放飞向敌人的动画
	var card_data = battle_manager.get_card_by_instance_id(instance_id)
	var impact_position = enemy_hp_bar.get_global_position() + Vector2(enemy_hp_bar.size.x / 2, enemy_hp_bar.size.y / 2)

	# 直接将拖拽卡牌设为选中并攻击敌人
	battle_manager.selected_card_instance_id = instance_id
	var result_text = battle_manager.on_enemy_target_clicked()
	hint_label.text = result_text
	animate_result_feedback(result_text, instance_id)

	if result_text.find("使用了") != -1:
		play_card_fly_animation(card_data, release_global_position, impact_position)

	# 刷新所有UI
	refresh_all_ui()

# 结束回合按钮按下处理
func _on_end_turn_button_pressed() -> void:
	# 调用战斗管理器的结束回合处理
	var result_text = battle_manager.end_player_turn()
	# 设置提示文本
	hint_label.text = result_text
	_end_turn_tween = pulse_control(end_turn_button, Color(1.0, 0.96, 0.86, 1.0), 1.04, 0.18, _end_turn_tween)
	animate_result_feedback(result_text)
	# 刷新所有UI
	refresh_all_ui()

# 历史记录按钮按下处理
func _on_history_button_pressed() -> void:
	# 如果历史记录屏幕存在
	if battle_history_screen:
		# 切换历史记录屏幕的显示状态
		if battle_history_screen.is_visible_mode:
			battle_history_screen.hide_history_screen()
		else:
			battle_history_screen.show_history_screen()

# 处理未处理的输入
func _unhandled_input(event):
	# 如果按下ESC键
	if event.is_action_pressed("ui_cancel"):
		# 显示暂停菜单
		show_pause_menu()

# 显示暂停菜单
func show_pause_menu():
	# 检查是否已经有PauseMenu节点
	var pause_menu = get_tree().get_root().find_child("PauseMenu", true, false)
	if pause_menu:
		# 如果已经存在，显示它
		pause_menu.open_menu()
	else:
		# 如果不存在，加载并显示
		var menu_scene = load("res://scenes/ui/PauseMenu.tscn")
		if menu_scene:
			var menu_instance = menu_scene.instantiate()
			get_tree().get_root().add_child(menu_instance)
			menu_instance.open_menu()
