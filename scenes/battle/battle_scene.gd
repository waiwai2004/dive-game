extends Control

const CARD_ITEM_SCENE = preload("res://ui/card_item.tscn")

var battle_manager: BattleManager

@onready var enemy_name_label = $MainBox/EnemyPanel/Enemybar/EnemyVBox/EnemyNameLabel
@onready var enemy_hp_label = $MainBox/EnemyPanel/Enemybar/EnemyVBox/EnemyHpLabel
@onready var enemy_san_label = $MainBox/EnemyPanel/Enemybar/EnemyVBox/EnemySanLabel
@onready var enemy_intent_label = $MainBox/EnemyPanel/Enemybar/EnemyVBox/EnemyIntentLabel
@onready var enemy_status_label = $MainBox/EnemyPanel/Enemybar/EnemyVBox/EnemyStatusLabel
@onready var target_enemy_button = $MainBox/EnemyPanel/Enemybar/EnemyVBox/TargetEnemyButton

@onready var player_hp_label = $MainBox/MiddleSplit/PlayerPanel/PlayerVBox/PlayerHpLabel
@onready var player_san_label = $MainBox/MiddleSplit/PlayerPanel/PlayerVBox/PlayerSanLabel
@onready var player_energy_label = $MainBox/MiddleSplit/PlayerPanel/PlayerVBox/PlayerEnergyLabel
@onready var player_cognition_label = $MainBox/MiddleSplit/PlayerPanel/PlayerVBox/PlayerCognitionLabel
@onready var player_status_label = $MainBox/MiddleSplit/PlayerPanel/PlayerVBox/PlayerStatusLabel

@onready var battle_log_label = $MainBox/MiddleSplit/LogPanel/LogVBox/LogScroll/BattleLogLabel
@onready var hand_container = $MainBox/HandScroll/CenterContainer/HandContainer
@onready var end_turn_button = $MainBox/BottomBar/EndTurnButton
@onready var hint_label = $MainBox/BottomBar/HintLabel

func _ready() -> void:
	target_enemy_button.pressed.connect(_on_target_enemy_button_pressed)
	end_turn_button.pressed.connect(_on_end_turn_button_pressed)

	battle_manager = BattleManager.new()
	battle_manager.battle_log_added.connect(_on_battle_log_added)
	battle_manager.battle_state_changed.connect(_on_battle_state_changed)
	battle_manager.battle_ended.connect(_on_battle_ended)

	battle_log_label.text = ""
	hint_label.text = "选择一张手牌打出."

	battle_manager.setup_demo_battle(false)
	refresh_all_ui()

func _on_battle_log_added(text: String) -> void:
	append_log(text)

func _on_battle_state_changed() -> void:
	refresh_all_ui()

func _on_battle_ended(is_victory: bool) -> void:
	if is_victory:
		hint_label.text = "胜利！"
		GameManager.battle_result = "victory"
	else:
		hint_label.text = "失败！"
		GameManager.battle_result = "defeat"

	end_turn_button.disabled = true
	target_enemy_button.disabled = true

	await get_tree().create_timer(1.0).timeout

	if not is_victory:
		get_tree().change_scene_to_file("res://scenes/result/result_scene.tscn")
		return

	var current_type = GameManager.get_current_node_type()

	if current_type == "battle_boss":
		get_tree().change_scene_to_file("res://scenes/result/result_scene.tscn")
	else:
		GameManager.advance_node()
		get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")


func refresh_all_ui() -> void:
	if battle_manager == null:
		return

	refresh_enemy_ui()
	refresh_player_ui()
	build_hand()

func refresh_enemy_ui() -> void:
	var enemy = battle_manager.enemy
	if enemy == null:
		return

	enemy_name_label.text = "敌人: %s" % enemy.name
	enemy_hp_label.text = "HP: %d / %d" % [enemy.hp, enemy.max_hp]
	enemy_san_label.text = "SAN: %d / %d" % [enemy.san, enemy.max_san]
	enemy_intent_label.text = "意图: %s" % enemy.intent_text
	enemy_status_label.text = "状态: Weak x%d" % enemy.weak

func refresh_player_ui() -> void:
	var player = battle_manager.player
	if player == null:
		return

	player_hp_label.text = "HP: %d / %d" % [player.hp, player.max_hp]
	player_san_label.text = "SAN: %d / %d" % [player.san, player.max_san]
	player_energy_label.text = "费用: %d / %d" % [player.energy, player.max_energy]
	player_cognition_label.text = "认知负荷: %d / %d" % [player.cognition, player.cognition_max]

	var player_state := "正常"
	if player.is_mad():
		player_state = "恼怒"
	if player.weak > 0:
		player_state += " | 虚弱 x%d" % player.weak

	player_status_label.text = "状态: %s" % player_state

func build_hand() -> void:
	
	for child in hand_container.get_children():
		child.queue_free()

	for card_data in battle_manager.get_hand_cards():
		var card_ui = CARD_ITEM_SCENE.instantiate()
		hand_container.add_child(card_ui)
		card_ui.setup(card_data)
		card_ui.card_pressed.connect(_on_card_pressed)
		card_ui.set_display_size(Vector2(220, 260))


		if card_data["instance_id"] == battle_manager.selected_card_instance_id:
			card_ui.set_selected(true)
		else:
			card_ui.set_selected(false)
	


func append_log(text: String) -> void:
	if battle_log_label.text.is_empty():
		battle_log_label.text = text
	else:
		battle_log_label.text += "\n" + text

func _on_card_pressed(instance_id: int) -> void:
	var result_text = battle_manager.on_card_clicked(instance_id)
	hint_label.text = result_text
	refresh_all_ui()

func _on_target_enemy_button_pressed() -> void:
	var result_text = battle_manager.on_enemy_target_clicked()
	hint_label.text = result_text
	refresh_all_ui()

func _on_end_turn_button_pressed() -> void:
	var result_text = battle_manager.end_player_turn()
	hint_label.text = result_text
	refresh_all_ui()
