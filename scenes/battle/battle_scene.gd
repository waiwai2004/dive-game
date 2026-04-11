# 战斗场景脚本
# 处理战斗界面的显示和交互逻辑
extends Control

# 常量定义
const CARD_ITEM_SCENE = preload("res://ui/card_item.tscn")  # 卡牌项场景

# 战斗管理器
var battle_manager: BattleManager

# 敌人UI组件
@onready var enemy_name_label = $MainBox/EnemyPanel/Enemybar/EnemyVBox/EnemyNameLabel  # 敌人名称标签
@onready var enemy_hp_label = $MainBox/EnemyPanel/Enemybar/EnemyVBox/EnemyHpLabel  # 敌人生命值标签
@onready var enemy_san_label = $MainBox/EnemyPanel/Enemybar/EnemyVBox/EnemySanLabel  # 敌人理智值标签
@onready var enemy_intent_label = $MainBox/EnemyPanel/Enemybar/EnemyVBox/EnemyIntentLabel  # 敌人意图标签
@onready var enemy_status_label = $MainBox/EnemyPanel/Enemybar/EnemyVBox/EnemyStatusLabel  # 敌人状态标签
@onready var target_enemy_button = $MainBox/EnemyPanel/Enemybar/EnemyVBox/TargetEnemyButton  # 目标敌人按钮

# 玩家UI组件
@onready var player_hp_label = $MainBox/MiddleSplit/PlayerPanel/PlayerVBox/PlayerHpLabel  # 玩家生命值标签
@onready var player_san_label = $MainBox/MiddleSplit/PlayerPanel/PlayerVBox/PlayerSanLabel  # 玩家理智值标签
@onready var player_energy_label = $MainBox/MiddleSplit/PlayerPanel/PlayerVBox/PlayerEnergyLabel  # 玩家能量标签
@onready var player_cognition_label = $MainBox/MiddleSplit/PlayerPanel/PlayerVBox/PlayerCognitionLabel  # 玩家认知负荷标签
@onready var player_status_label = $MainBox/MiddleSplit/PlayerPanel/PlayerVBox/PlayerStatusLabel  # 玩家状态标签

# 其他UI组件
@onready var battle_log_label = $MainBox/MiddleSplit/LogPanel/LogVBox/LogScroll/BattleLogLabel  # 战斗日志标签
@onready var log_scroll = $MainBox/MiddleSplit/LogPanel/LogVBox/LogScroll  # 战斗日志滚动容器
@onready var hand_container = $MainBox/HandScroll/CenterContainer/HandContainer  # 手牌容器
@onready var end_turn_button = $MainBox/BottomBar/EndTurnButton  # 结束回合按钮
@onready var hint_label = $MainBox/BottomBar/HintLabel  # 提示标签

# 场景准备就绪
func _ready() -> void:
	# 连接目标敌人按钮的按下信号
	target_enemy_button.pressed.connect(_on_target_enemy_button_pressed)
	# 连接结束回合按钮的按下信号
	end_turn_button.pressed.connect(_on_end_turn_button_pressed)

	# 创建战斗管理器
	battle_manager = BattleManager.new()
	# 连接战斗日志添加信号
	battle_manager.battle_log_added.connect(_on_battle_log_added)
	# 连接战斗状态改变信号
	battle_manager.battle_state_changed.connect(_on_battle_state_changed)
	# 连接战斗结束信号
	battle_manager.battle_ended.connect(_on_battle_ended)

	# 初始化战斗日志
	battle_log_label.text = ""
	# 设置初始提示
	hint_label.text = "选择一张手牌打出."

	# 设置演示战斗
	battle_manager.setup_demo_battle(false)
	# 刷新所有UI
	refresh_all_ui()

# 战斗日志添加处理
func _on_battle_log_added(text: String) -> void:
	# 添加日志到UI
	append_log(text)

# 战斗状态改变处理
func _on_battle_state_changed() -> void:
	# 刷新所有UI
	refresh_all_ui()

# 战斗结束处理
func _on_battle_ended(is_victory: bool) -> void:
	# 根据战斗结果设置提示
	if is_victory:
		hint_label.text = "胜利！"
		GameManager.battle_result = "victory"
	else:
		hint_label.text = "失败！"
		GameManager.battle_result = "defeat"

	# 禁用按钮
	end_turn_button.disabled = true
	target_enemy_button.disabled = true

	# 等待1秒后切换场景
	await get_tree().create_timer(1.0).timeout

	# 如果失败，切换到结果场景
	if not is_victory:
		get_tree().change_scene_to_file("res://scenes/result/result_scene.tscn")
		return

	# 获取当前节点类型
	var current_type = GameManager.get_current_node_type()

	# 如果是Boss战斗，切换到结果场景
	if current_type == "battle_boss":
		get_tree().change_scene_to_file("res://scenes/result/result_scene.tscn")
	else:
		# 前进到下一个节点
		GameManager.advance_node()
		# 切换到地图场景
		get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")

# 刷新所有UI
func refresh_all_ui() -> void:
	# 检查战斗管理器是否存在
	if battle_manager == null:
		return

	# 刷新敌人UI
	refresh_enemy_ui()
	# 刷新玩家UI
	refresh_player_ui()
	# 构建手牌
	build_hand()

# 刷新敌人UI
func refresh_enemy_ui() -> void:
	# 获取敌人对象
	var enemy = battle_manager.enemy
	# 检查敌人是否存在
	if enemy == null:
		return

	# 设置敌人名称
	enemy_name_label.text = "敌人: %s" % enemy.name
	# 设置敌人生命值
	enemy_hp_label.text = "HP: %d / %d" % [enemy.hp, enemy.max_hp]
	# 设置敌人理智值
	enemy_san_label.text = "SAN: %d / %d" % [enemy.san, enemy.max_san]
	# 设置敌人意图
	enemy_intent_label.text = "意图: %s" % enemy.intent_text
	# 设置敌人状态
	enemy_status_label.text = "状态: Weak x%d" % enemy.weak

# 刷新玩家UI
func refresh_player_ui() -> void:
	# 获取玩家对象
	var player = battle_manager.player
	# 检查玩家是否存在
	if player == null:
		return

	# 设置玩家生命值
	player_hp_label.text = "HP: %d / %d" % [player.hp, player.max_hp]
	# 设置玩家理智值
	player_san_label.text = "SAN: %d / %d" % [player.san, player.max_san]
	# 设置玩家能量
	player_energy_label.text = "费用: %d / %d" % [player.energy, player.max_energy + player.extra_energy]
	# 设置玩家认知负荷
	player_cognition_label.text = "认知负荷: %d / %d" % [player.cognition, player.cognition_max]

	# 设置玩家状态
	var player_state := "正常"
	if player.is_mad():
		player_state = "恼怒"
	if player.weak > 0:
		player_state += " | 虚弱 x%d" % player.weak

	player_status_label.text = "状态: %s" % player_state

# 构建手牌
func build_hand() -> void:
	# 清除现有手牌
	for child in hand_container.get_children():
		child.queue_free()

	# 遍历所有手牌
	for card_data in battle_manager.get_hand_cards():
		# 实例化卡牌项
		var card_ui = CARD_ITEM_SCENE.instantiate()
		# 添加到手牌容器
		hand_container.add_child(card_ui)
		# 设置卡牌数据
		card_ui.setup(card_data)
		# 连接卡牌按下信号
		card_ui.card_pressed.connect(_on_card_pressed)
		# 设置卡牌显示大小
		card_ui.set_display_size(Vector2(220, 260))

		# 设置卡牌选中状态
		if card_data["instance_id"] == battle_manager.selected_card_instance_id:
			card_ui.set_selected(true)
		else:
			card_ui.set_selected(false)

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

# 卡牌按下处理
func _on_card_pressed(instance_id: int) -> void:
	# 调用战斗管理器的卡牌点击处理
	var result_text = battle_manager.on_card_clicked(instance_id)
	# 设置提示文本
	hint_label.text = result_text
	# 刷新所有UI
	refresh_all_ui()

# 目标敌人按钮按下处理
func _on_target_enemy_button_pressed() -> void:
	# 调用战斗管理器的敌人目标点击处理
	var result_text = battle_manager.on_enemy_target_clicked()
	# 设置提示文本
	hint_label.text = result_text
	# 刷新所有UI
	refresh_all_ui()

# 结束回合按钮按下处理
func _on_end_turn_button_pressed() -> void:
	# 调用战斗管理器的结束回合处理
	var result_text = battle_manager.end_player_turn()
	# 设置提示文本
	hint_label.text = result_text
	# 刷新所有UI
	refresh_all_ui()
