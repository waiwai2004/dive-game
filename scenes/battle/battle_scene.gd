## 战斗场景编排器
## 职责：只负责「组装子系统 + 推进回合 + 胜负与奖励流转」，
## 其余的 UI / 卡牌 / 敌人 / 视觉 / 音效 全部委托给对应 Manager。
extends Control

@onready var _boss_portrait: TextureRect = $ArenaRoot/BossPortrait
@onready var _reward_story_ui: Control = $RewardStoryUI

@onready var deck_button: Button = $DeckButton
@onready var deck_panel: PanelContainer = $DeckPanel
@onready var deck_title_label: Label = $DeckPanel/MarginContainer/ContentVBox/HeaderRow/TitleLabel
@onready var deck_close_button: Button = $DeckPanel/MarginContainer/ContentVBox/HeaderRow/CloseButton
@onready var deck_text: RichTextLabel = $DeckPanel/MarginContainer/ContentVBox/DeckText
var _deck_open := false
var _deck_scroll: ScrollContainer = null
var _deck_cards_flow: HFlowContainer = null

var _state: BattleStateManager
var _audio: BattleAudioManager
var _vfx: BattleVisualEffects
var _enemy_ai: BattleEnemyAI
var _card_system: BattleCardSystem
var _ui: BattleUIManager
var _status_manager: StatusManager
var _player_buff_manager: BuffManager
var _enemy_buff_manager: BuffManager

var _battle_log_lines: Array[String] = []



func _ready() -> void:
	_hide_global_ui_for_battle()
	_build_subsystems()
	_wire_signals()

	_audio.play_battle_bgm()
	_enemy_ai.setup(_get_enemy_id_for_current_battle(), _enemy_buff_manager, _player_buff_manager)
	_apply_enemy_portrait()
	_log("敌人逼近：%s。" % _enemy_ai.enemy_name)
	_card_system.start_battle()
	_start_player_turn()


# ====== 子系统装配 ======
func _build_subsystems() -> void:
	_state = BattleStateManager.new()
	_audio = BattleAudioManager.new()
	_vfx = BattleVisualEffects.new()
	_enemy_ai = BattleEnemyAI.new()
	_card_system = BattleCardSystem.new()
	_ui = BattleUIManager.new()
	_status_manager = StatusManager.new()
	_player_buff_manager = BuffManager.new()
	_enemy_buff_manager = BuffManager.new()
	for node in [_state, _audio, _vfx, _enemy_ai, _card_system, _ui, _status_manager, _player_buff_manager, _enemy_buff_manager]:
		add_child(node)

	_vfx.setup(_boss_portrait)
	_card_system.setup(_enemy_ai, _vfx, _status_manager, _player_buff_manager, _enemy_buff_manager)
	_ui.setup(self, _card_system, _enemy_ai, _state)

	_setup_statuses()

	if _reward_story_ui.has_method("hide_ui"):
		_reward_story_ui.hide_ui()
	else:
		_reward_story_ui.hide()


func _setup_statuses() -> void:
	var manic_status = ManicStatus.new()
	var inner_drive_status = InnerDriveStatus.new()
	inner_drive_status.extra_turn_granted.connect(_on_inner_drive_extra_turn)
	_status_manager.register_status(manic_status)
	_status_manager.register_status(inner_drive_status)


func _wire_signals() -> void:
	_state.state_changed.connect(_on_state_changed)
	_card_system.log_emitted.connect(_log)
	_enemy_ai.log_emitted.connect(_log)
	_ui.end_turn_pressed.connect(_on_end_turn_pressed)

	if _reward_story_ui.has_signal("reward_selected"):
		_reward_story_ui.reward_selected.connect(_on_reward_selected)


# ====== 状态切换回调 ======
func _on_state_changed(new_state: int) -> void:
	var can_play := new_state == BattleStateManager.State.PLAYER_TURN
	_ui.set_play_enabled(can_play)

	if new_state == BattleStateManager.State.REWARD:
		if _reward_story_ui.has_method("show_ui"):
			_reward_story_ui.show_ui()
		else:
			_reward_story_ui.show()
		_log("从残响中选择一张新卡。")

	_ui.refresh_all(_battle_log_lines)


# ====== 回合流程 ======
func _start_player_turn() -> void:
	_status_manager.on_turn_start()
	_player_buff_manager.on_turn_start()
	_card_system.start_turn()
	_state.change_state(BattleStateManager.State.PLAYER_TURN)
	_log("你的回合开始。")
	_ui.set_hand_hint("拖拽或点击卡牌来使用。")
	_ui.refresh_all(_battle_log_lines)


func _on_end_turn_pressed() -> void:
	if not _state.is_player_turn():
		return
	_log("你结束了回合。")
	_player_buff_manager.on_turn_end()
	_status_manager.on_turn_end()
	await _enemy_turn()


func _enemy_turn() -> void:
	_state.change_state(BattleStateManager.State.ENEMY_TURN)
	var continue_enemy_turn := true

	while continue_enemy_turn:
		_enemy_buff_manager.on_turn_start()
		_enemy_ai.start_turn()

		var result := _enemy_ai.execute_turn(_card_system.player_block)
		var raw_attack := int(result.get("raw_attack_value", 0))
		var dmg_to_player := int(result.get("damage_to_player", 0))

		_card_system.player_block = maxi(
			_card_system.player_block - int(result.get("block_consumed", 0)),
			0
		)
		if dmg_to_player > 0:
			dmg_to_player = _player_buff_manager.modify_damage_taken(dmg_to_player)
			Game.damage_player(dmg_to_player)
		if raw_attack > 0:
			Game.player_san -= raw_attack
			if Game.player_san <= 0:
				_log("SAN值耗尽！你陷入了癫狂...")

		var direct_hp_loss := int(result.get("direct_hp_loss", 0))
		if direct_hp_loss > 0:
			Game.player_hp = maxi(Game.player_hp - direct_hp_loss, 0)

		if bool(result.get("swap_player_hp_san", false)):
			var old_hp := Game.player_hp
			var old_san := Game.player_san
			Game.player_hp = clampi(old_san, 0, Game.max_hp)
			Game.player_san = mini(old_hp, Game.max_san)
			_log("你的存在值与 SAN 值被扭曲互换。")

		var weak_gain := int(result.get("weak_applied_to_player", 0))
		if weak_gain > 0:
			_card_system.player_weak += weak_gain

		var extra_turn := _enemy_ai.end_turn_tick()
		_card_system.tick_player_weak()
		_enemy_buff_manager.on_turn_end()

		if Game.player_hp <= 0:
			await _on_battle_lose()
			return

		continue_enemy_turn = extra_turn
		if continue_enemy_turn:
			_log("%s 的内驱力被触发，立刻再行动一次！" % _enemy_ai.enemy_name)
			_ui.refresh_all(_battle_log_lines)
			await get_tree().create_timer(0.35).timeout

	await get_tree().create_timer(0.35).timeout
	_start_player_turn()


func _on_inner_drive_extra_turn() -> void:
	_log("内驱力触发！你获得了一个额外回合！")
	await get_tree().create_timer(0.5).timeout
	_start_player_turn()


# ====== 对外 API：由 card_ui 调用 ======
func play_card(card_index: int) -> void:
	if not _state.is_player_turn():
		return
	if not _card_system.play_card(card_index):
		_ui.refresh_all(_battle_log_lines)
		return

	if Game.player_hp <= 0:
		await _on_battle_lose()
		return
	if _enemy_ai.is_dead():
		Game.restore_san_to_max()
		_log("敌对单位被击杀，理智值回满！")
		await _on_battle_win()
		return

	_ui.refresh_all(_battle_log_lines)


func show_card_tooltip(card_data: Dictionary) -> void:
	_ui.show_card_tooltip(card_data)


func hide_card_tooltip() -> void:
	_ui.hide_card_tooltip()


# UI Manager 打开战斗记录面板时回调
func _refresh_battle_log_from_scene() -> void:
	_ui.refresh_battle_log(_battle_log_lines)


func get_player_additional_status_info() -> Array[Dictionary]:
	return _player_buff_manager.get_all_active_buffs_info()


# ====== 胜负 / 奖励 ======
func _on_battle_win() -> void:
	_log("战斗胜利。")
	Game.clear_cognition()
	
	if _is_normal_battle() and not Game.first_battle_reward_done:
		_state.change_state(BattleStateManager.State.REWARD)
		return

	_state.change_state(BattleStateManager.State.FINISHED)
	
	Game.set_meta("battle_is_boss", not _is_normal_battle())
	Game.set_meta("battle_turn_count", _get_battle_turn_count())
	Game.set_meta("battle_boss_card", Game.get_first_reward_card_id())
	
	get_tree().change_scene_to_file("res://scenes/battle/VictorySettlementUI.tscn")


func _on_battle_lose() -> void:
	_state.change_state(BattleStateManager.State.FINISHED)
	_log("你的意识溃散了。")
	
	Game.set_meta("battle_enemy_name", _enemy_ai.enemy_name)
	
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/battle/DefeatSettlementUI.tscn")


func _get_battle_turn_count() -> int:
	return _battle_log_lines.count("你结束了回合。") + 1


func _on_reward_selected(card_id: String) -> void:
	if not _state.is_reward():
		return
	if card_id != "pursue" and card_id != "seal":
		return

	Game.add_card(card_id)
	Game.first_battle_reward_done = true
	_log("你获得了【%s】。" % str(CardDatabase.get_card(card_id).get("name", card_id)))

	_state.change_state(BattleStateManager.State.FINISHED)
	
	Game.set_meta("battle_is_boss", false)
	Game.set_meta("battle_turn_count", _get_battle_turn_count())
	Game.set_meta("battle_boss_card", card_id)
	
	get_tree().change_scene_to_file("res://scenes/battle/VictorySettlementUI.tscn")


# ====== 杂项 ======
func _log(text: String) -> void:
	_battle_log_lines.append(text)
	while _battle_log_lines.size() > 64:
		_battle_log_lines.pop_front()
	_ui.refresh_battle_log(_battle_log_lines)


func _is_normal_battle() -> bool:
	return Game.battle_index < 3


func _get_enemy_id_for_current_battle() -> String:
	var enemy_id := EnemyDatabase.get_enemy_id_for_battle_index(Game.battle_index)
	if enemy_id.is_empty():
		return "corpse_shrimp"
	return enemy_id


func _apply_enemy_portrait() -> void:
	var portrait_path := _enemy_ai.get_portrait_path()
	if portrait_path.is_empty():
		return
	if not ResourceLoader.exists(portrait_path):
		push_warning("[BattleScene] enemy portrait missing: %s" % portrait_path)
		return
	var texture := load(portrait_path)
	if texture is Texture2D:
		_boss_portrait.texture = texture


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

func show_deck_panel() -> void:
	_deck_open = true
	refresh_deck_panel()
	deck_panel.visible = true

func hide_deck_panel() -> void:
	_deck_open = false
	deck_panel.visible = false
	
func _on_deck_button_pressed() -> void:
	if _deck_open:
		hide_deck_panel()
	else:
		show_deck_panel()

func _on_deck_close_button_pressed() -> void:
	hide_deck_panel()
	
func refresh_deck_panel() -> void:
	_ensure_deck_cards_view()
	if not has_node("/root/Game"):
		return
	for child in _deck_cards_flow.get_children():
		child.queue_free()
	if Game.deck.is_empty():
		var empty_label := Label.new()
		empty_label.text = "当前牌库为空。"
		_deck_cards_flow.add_child(empty_label)
		return
	var counts: Dictionary = {}
	var order: Array[String] = []
	for card_id in Game.deck:
		if not counts.has(card_id):
			counts[card_id] = 0
			order.append(card_id)
		counts[card_id] += 1
	for card_id in order:
		_deck_cards_flow.add_child(_build_card_preview(card_id, int(counts[card_id])))
		
func _ensure_deck_cards_view() -> void:
	if _deck_cards_flow and is_instance_valid(_deck_cards_flow):
		return
	if deck_text:
		deck_text.visible = false
	var content_vbox: Node = $DeckPanel/MarginContainer/ContentVBox
	_deck_scroll = ScrollContainer.new()
	_deck_scroll.name = "DeckScroll"
	_deck_scroll.custom_minimum_size = Vector2(0, 360)
	_deck_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_deck_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(_deck_scroll)
	_deck_cards_flow = HFlowContainer.new()
	_deck_cards_flow.name = "DeckCardsFlow"
	_deck_cards_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_deck_cards_flow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_deck_cards_flow.add_theme_constant_override("h_separation", 16)
	_deck_cards_flow.add_theme_constant_override("v_separation", 16)
	_deck_scroll.add_child(_deck_cards_flow)
	
func _build_card_preview(card_id: String, count: int) -> Control:
	var db = get_node_or_null("/root/CardDatabase")
	var card: Dictionary = {}
	if db and db.has_method("get_card"):
		card = db.get_card(card_id)
	
	# 直接实例化 CardUI
	var card_scene = preload("res://scenes/battle/CardUI.tscn")
	var card_ui = card_scene.instantiate()
	
	# 调用 setup 来初始化卡牌，但不设置 battle_scene
	if card_ui.has_method("setup"):
		card_ui.call("setup", card, -1, null)
	
	# 完全禁用交互
	card_ui.disabled = true
	card_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 添加数量标签
	var vbox = VBoxContainer.new()
	vbox.add_child(card_ui)
	
	if count > 1:
		var count_label = Label.new()
		count_label.text = "x%d" % count
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(count_label)
	
	return vbox
