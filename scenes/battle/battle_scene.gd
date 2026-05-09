## 战斗场景编排器
## 职责：只负责「组装子系统 + 推进回合 + 胜负与奖励流转」，
## 其余的 UI / 卡牌 / 敌人 / 视觉 / 音效 全部委托给对应 Manager。
extends Control

const NORMAL_BATTLE_ENEMY_POOL := [
	"corpse_shrimp",
	"motor_jellyfish",
	"polluted_fish",
	"corrupted_lion",
]
const BOSS_BATTLE_ENEMY_POOL := [
	"black_bubble",
	"colour_out_of_space",
]
const TUTORIAL_FOCUS_PADDING := 28.0
const BATTLE_TUTORIAL_STEPS := [
	{
		"focus": "enemy_info",
		"title": "敌方信息区",
		"body": "这里会显示敌人的立绘、名称、存在值与下一步意图。先看清敌人的攻击方式，再决定这一轮要防守还是抢先输出。",
		"bubble_anchor": "right",
	},
	{
		"focus": "player_status",
		"title": "自身状态区",
		"body": "左侧集中展示你的存在值、SAN、精神负荷、认知负荷与当前状态。精神负荷决定你这轮能打出多少牌，状态图标则提示护盾、虚弱或异常影响。",
		"bubble_anchor": "right",
	},
	{
		"focus": "hand",
		"title": "手牌区",
		"body": "这里是本轮可用的全部手牌。打出的牌不会立刻补进新牌，只有这一轮手牌彻底耗尽后，下次轮到你时才会重整并重新获得手牌。",
		"bubble_anchor": "above",
	},
	{
		"focus": "right_buttons",
		"title": "辅助按钮区",
		"body": "这里可以查看牌库、弃牌堆和战斗日志。战斗日志只记录真实战斗过程，不再放教学说明；需要复盘时再打开查看。\n\n快捷键提示：按 [K] 打开牌库，按 [Q] 查看弃牌堆，按 [L] 打开战斗日志。",
		"bubble_anchor": "left",
	},
	{
		"focus": "end_turn",
		"title": "结束回合",
		"body": "确认本轮不再出牌后，点击这里结束回合。认知负荷会随着出牌持续累积，只有上一轮手牌耗尽并完成重整后才会回落；一旦超过上限，你的存在值会立刻减半并清空当前认知。\n\n快捷键提示：按 [空格键] 可快速结束回合。",
		"bubble_anchor": "left",
	},
]

@onready var _boss_portrait: TextureRect = $ArenaRoot/BossPortrait
@onready var _reward_story_ui: Control = $RewardStoryUI
@onready var _battle_tutorial_overlay: Control = $BattleTutorialOverlay
@onready var _tutorial_mask_top: ColorRect = $BattleTutorialOverlay/MaskTop
@onready var _tutorial_mask_bottom: ColorRect = $BattleTutorialOverlay/MaskBottom
@onready var _tutorial_mask_left: ColorRect = $BattleTutorialOverlay/MaskLeft
@onready var _tutorial_mask_right: ColorRect = $BattleTutorialOverlay/MaskRight
@onready var _tutorial_focus_frame: PanelContainer = $BattleTutorialOverlay/FocusFrame
@onready var _tutorial_bubble: PanelContainer = $BattleTutorialOverlay/TutorialBubble
@onready var _tutorial_title_label: Label = $BattleTutorialOverlay/TutorialBubble/MarginContainer/VBoxContainer/TitleLabel
@onready var _tutorial_body_label: RichTextLabel = $BattleTutorialOverlay/TutorialBubble/MarginContainer/VBoxContainer/BodyLabel
@onready var _tutorial_page_label: Label = $BattleTutorialOverlay/TutorialBubble/MarginContainer/VBoxContainer/FooterLabel

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
var _inner_drive_extra_turn_pending: bool = false
var _tutorial_step_index: int = -1
var _battle_tutorial_active: bool = false



func _ready() -> void:
	_hide_global_ui_for_battle()
	_build_subsystems()
	_wire_signals()

	_audio.play_battle_bgm()
	_enemy_ai.setup(_get_enemy_id_for_current_battle(), _enemy_buff_manager, _player_buff_manager)
	_apply_enemy_portrait()
	_log("深处的水影开始收束：%s 现身了。" % _enemy_ai.enemy_name)
	_card_system.start_battle()
	_ui.refresh_all(_battle_log_lines)
	_start_player_turn()
	_setup_battle_tutorial_overlay()
	_maybe_start_battle_tutorial()
	_force_battle_log_on()


func _force_battle_log_on() -> void:
	if has_node("BattleLogWindow"):
		get_node("BattleLogWindow").visible = true

func _unhandled_input(event: InputEvent) -> void:
	if _battle_tutorial_active:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_advance_battle_tutorial()
			get_viewport().set_input_as_handled()
		elif event is InputEventKey and event.pressed and not event.echo:
			_advance_battle_tutorial()
			get_viewport().set_input_as_handled()
		return
	if not (event is InputEventKey):
		return
	if not event.pressed or event.echo:
		return
	if not _can_handle_battle_hotkeys():
		return

	match event.keycode:
		KEY_SPACE:
			if _state and _state.is_player_turn():
				_on_end_turn_pressed()
				get_viewport().set_input_as_handled()
		KEY_K:
			_on_deck_button_pressed()
			get_viewport().set_input_as_handled()
		KEY_Q:
			if _ui:
				_ui.toggle_discard_panel()
				get_viewport().set_input_as_handled()
		KEY_L:
			if _ui:
				_ui.open_battle_log()
				get_viewport().set_input_as_handled()

func _can_handle_battle_hotkeys() -> bool:
	if _state == null:
		return false
	if _battle_tutorial_active:
		return false
	if _state.is_finished() or _state.is_reward():
		return false
	var focused := get_viewport().gui_get_focus_owner()
	if focused and focused is LineEdit:
		return false
	if focused and focused is TextEdit:
		return false
	return true


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
	var madness_for_fun_status = MadnessForFunStatus.new()
	madness_for_fun_status.setup(_status_manager, _card_system)
	inner_drive_status.extra_turn_granted.connect(_on_inner_drive_extra_turn)
	_status_manager.register_status(manic_status)
	_status_manager.register_status(inner_drive_status)
	_status_manager.register_status(madness_for_fun_status)
	if not _status_manager.status_changed.is_connected(_on_status_changed):
		_status_manager.status_changed.connect(_on_status_changed)


func _wire_signals() -> void:
	_state.state_changed.connect(_on_state_changed)
	_card_system.log_emitted.connect(_log)
	_enemy_ai.log_emitted.connect(_log)
	_ui.end_turn_pressed.connect(_on_end_turn_pressed)

	if _reward_story_ui.has_signal("reward_selected"):
		_reward_story_ui.reward_selected.connect(_on_reward_selected)


# ====== 状态切换回调 ======
func _on_status_changed(status_name: String, activated: bool) -> void:
	if status_name == "癫狂":
		_ui.refresh_hand()
		_ui.refresh_player_ui()

func _on_state_changed(new_state: int) -> void:
	var can_play := new_state == BattleStateManager.State.PLAYER_TURN
	_ui.set_play_enabled(can_play)

	if new_state == BattleStateManager.State.REWARD:
		if _reward_story_ui.has_method("show_ui"):
			_reward_story_ui.show_ui()
		else:
			_reward_story_ui.show()
		_log("战斗余烬尚未散尽，你可以从残响里带走一张新卡。")

	_ui.refresh_all(_battle_log_lines)


# ====== 回合流程 ======
func _start_player_turn() -> void:
	_status_manager.on_turn_start()
	_player_buff_manager.on_turn_start()
	_apply_player_turn_start_buffs()
	if Game.player_hp <= 0:
		await _on_battle_lose()
		return
	_card_system.start_turn()
	_state.change_state(BattleStateManager.State.PLAYER_TURN)
	_log("轮到你出手了。")
	_ui.set_hand_hint("拖拽或点击卡牌，将意志投向战场。")
	_ui.refresh_all(_battle_log_lines)


func _on_end_turn_pressed() -> void:
	if not _state.is_player_turn():
		return
	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("end_turn")
	_log("你收束了这轮行动。")
	await _end_player_turn()


func _end_player_turn() -> void:
	var corruption_stacks := _player_buff_manager.get_buff_stacks("腐化")
	var old_san: int = int(Game.player_san)
	_player_buff_manager.on_turn_end()
	if corruption_stacks > 0:
		_log("腐化侵蚀了你，失去1点存在值与%d点SAN。" % maxi(old_san - int(Game.player_san), 0))
	if Game.player_hp <= 0:
		await _on_battle_lose()
		return
	_status_manager.on_turn_end()

	# 检查内驱力额外回合
	if _inner_drive_extra_turn_pending:
		_inner_drive_extra_turn_pending = false
		_log("内驱力爆发！你再次行动！")
		_start_player_turn()
		return

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

		var san_loss_to_player := int(result.get("san_loss_to_player", 0))
		if san_loss_to_player > 0:
			Game.player_san = maxi(Game.player_san - san_loss_to_player, 0)
			if Game.player_san <= 0:
				_log("SAN值耗尽！你陷入了癫狂...")

		var direct_hp_loss := int(result.get("direct_hp_loss", 0))
		if direct_hp_loss > 0:
			Game.player_hp = maxi(Game.player_hp - direct_hp_loss, 0)

		if bool(result.get("swap_player_hp_san", false)):
			var old_hp: int = int(Game.player_hp)
			var old_san: int = int(Game.player_san)
			Game.player_hp = clampi(old_san, 0, Game.max_hp)
			Game.player_san = mini(old_hp, Game.max_san)
			_log("你的存在值与 SAN 值被扭曲互换。")

		var weak_gain := int(result.get("weak_applied_to_player", 0))
		if weak_gain > 0:
			_card_system.player_weak += weak_gain

		var extra_turn := _enemy_ai.end_turn_tick()
		_process_round_end_buffs()

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
	_inner_drive_extra_turn_pending = true
	_log("内驱力触发！你获得了一个额外回合！")


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
	if _card_system.consume_force_end_turn_after_card():
		_log("麻痹打断了你的行动，回合被强制结束。")
		_ui.refresh_all(_battle_log_lines)
		await _end_player_turn()
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
	var result := _player_buff_manager.get_all_active_buffs_info()
	for status_name in _status_manager.get_active_status_names():
		if status_name == "癫狂":
			continue
		result.append({
			"name": status_name,
			"stacks": -1,
			"description": _status_manager.get_status_description(status_name),
		})
	return result


func _apply_player_turn_start_buffs() -> void:
	var collapse_stacks := _player_buff_manager.get_buff_stacks("崩溃")
	if collapse_stacks <= 0:
		return
	Game.player_san -= collapse_stacks
	_log("崩溃撕扯你的理智，失去%d点SAN。" % collapse_stacks)
	if Game.player_san <= 0:
		_log("SAN值耗尽！你陷入了癫狂...")


func _process_round_end_buffs() -> void:
	_player_buff_manager.on_round_end()
	_enemy_buff_manager.on_round_end()
	_status_manager.on_round_end()


# ====== 胜负 / 奖励 ======
func _on_battle_win() -> void:
	_log("异变沉寂了，这一战由你收束。")
	Game.clear_cognition()
	
	_state.change_state(BattleStateManager.State.FINISHED)
	
	var is_boss := not _is_normal_battle()
	Game.set_meta("battle_is_boss", is_boss)
	Game.set_meta("battle_turn_count", _get_battle_turn_count())
	Game.set_meta("battle_boss_card", _roll_boss_drop_card_id())

	if is_boss:
		# Boss 战胜利：先展示 Demo 结束画面，点击后再进奖励
		Game.set_meta("pending_victory_after_end", true)
		get_tree().change_scene_to_file("res://scenes/end/EndScene.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/battle/VictorySettlementUI.tscn")


func _on_battle_lose() -> void:
	_state.change_state(BattleStateManager.State.FINISHED)
	_log("你的意识溃散了。")
	
	Game.set_meta("battle_enemy_name", _enemy_ai.enemy_name)
	
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/battle/DefeatSettlementUI.tscn")


func _get_battle_turn_count() -> int:
	return _battle_log_lines.count("你结束了回合。") + 1


func _roll_boss_drop_card_id() -> String:
	var enemy_data := _enemy_ai.get_enemy_data()
	if enemy_data == null or enemy_data.drop_table.is_empty():
		return ""
	
	var valid_drops := []
	for drop in enemy_data.drop_table:
		var card_id := str(drop.get("card_id", "")).strip_edges()
		var card_name := str(drop.get("card_name", ""))
		if not card_id.is_empty() and card_name != "无":
			valid_drops.append(drop)
	
	if valid_drops.is_empty():
		return ""
	
	var total_chance := 0
	for drop in valid_drops:
		total_chance += maxi(int(drop.get("chance", 0)), 0)
	if total_chance <= 0:
		return ""
	
	var roll := randi() % total_chance
	var cursor := 0
	for drop in valid_drops:
		cursor += maxi(int(drop.get("chance", 0)), 0)
		if roll < cursor:
			var card_id := str(drop.get("card_id", "")).strip_edges()
			return card_id
	return ""


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


func open_battle_log() -> void:
	if has_node("BattleLogWindow"):
		var log_win = get_node("BattleLogWindow")
		log_win.visible = true
		if has_method("_refresh_battle_log_from_scene"):
			call("_refresh_battle_log_from_scene")


func _is_normal_battle() -> bool:
	if BOSS_BATTLE_ENEMY_POOL.has(_enemy_ai.enemy_id):
		return false
	if NORMAL_BATTLE_ENEMY_POOL.has(_enemy_ai.enemy_id):
		return true
	return Game.battle_index < 3


func _get_enemy_id_for_current_battle() -> String:
	var enemy_id := str(Game.current_battle_enemy_id).strip_edges()
	if not enemy_id.is_empty() and EnemyDatabase.has_enemy(enemy_id):
		return enemy_id
	if Game.battle_index >= 3:
		return _pick_random_enemy_id(BOSS_BATTLE_ENEMY_POOL, "black_bubble")
	if Game.battle_index > 0:
		return _pick_random_enemy_id(NORMAL_BATTLE_ENEMY_POOL, "corpse_shrimp")
	enemy_id = EnemyDatabase.get_enemy_id_for_battle_index(Game.battle_index)
	if enemy_id.is_empty():
		return "corpse_shrimp"
	return enemy_id


func _apply_enemy_portrait() -> void:
	var normal_path := _enemy_ai.get_portrait_path()
	var injured_path := _enemy_ai.get_portrait_injured_path()
	var normal_tex: Texture2D = null
	var injured_tex: Texture2D = null
	if not normal_path.is_empty():
		normal_tex = load(normal_path) as Texture2D
	if not injured_path.is_empty():
		injured_tex = load(injured_path) as Texture2D
	if normal_tex and is_instance_valid(_boss_portrait):
		_boss_portrait.texture = normal_tex
		_ui.set_enemy_portraits(normal_tex, injured_tex)


func _pick_random_enemy_id(enemy_pool: Array, fallback: String) -> String:
	if enemy_pool.is_empty():
		return fallback
	return str(enemy_pool[randi() % enemy_pool.size()])


func _hide_global_ui_for_battle() -> void:
	if not has_node("/root/GlobalUI"):
		return
	GlobalUI.set_mode(GlobalUI.MODE_BATTLE)
	if GlobalUI.has_method("set_top_hud_visible"):
		GlobalUI.set_top_hud_visible(false)
	if GlobalUI.has_method("clear_energy"):
		GlobalUI.clear_energy()
	if GlobalUI.has_method("hide_deck_panel"):
		GlobalUI.hide_deck_panel()


func _setup_battle_tutorial_overlay() -> void:
	_battle_tutorial_overlay.visible = false
	_battle_tutorial_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	if not _battle_tutorial_overlay.gui_input.is_connected(_on_battle_tutorial_overlay_input):
		_battle_tutorial_overlay.gui_input.connect(_on_battle_tutorial_overlay_input)
	_tutorial_body_label.bbcode_enabled = false
	_tutorial_body_label.fit_content = true


func _maybe_start_battle_tutorial() -> void:
	if Game.battle_tutorial_shown:
		return
	_start_battle_tutorial()


func _start_battle_tutorial() -> void:
	_battle_tutorial_active = true
	_tutorial_step_index = 0
	_battle_tutorial_overlay.visible = true
	_ui.close_all_popups()
	_ui.hide_card_tooltip()
	_render_battle_tutorial_step()


func reopen_battle_tutorial() -> void:
	_start_battle_tutorial()


func _advance_battle_tutorial() -> void:
	if not _battle_tutorial_active:
		return
	_tutorial_step_index += 1
	if _tutorial_step_index >= BATTLE_TUTORIAL_STEPS.size():
		_finish_battle_tutorial()
		return
	_render_battle_tutorial_step()


func _finish_battle_tutorial() -> void:
	_battle_tutorial_active = false
	_tutorial_step_index = -1
	_battle_tutorial_overlay.visible = false
	Game.mark_battle_tutorial_shown()


func _on_battle_tutorial_overlay_input(event: InputEvent) -> void:
	if not _battle_tutorial_active:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_advance_battle_tutorial()
		get_viewport().set_input_as_handled()


func _render_battle_tutorial_step() -> void:
	if _tutorial_step_index < 0 or _tutorial_step_index >= BATTLE_TUTORIAL_STEPS.size():
		return
	var step: Dictionary = BATTLE_TUTORIAL_STEPS[_tutorial_step_index]
	var focus_rect := _expand_tutorial_rect(_ui.get_tutorial_focus_rect(str(step.get("focus", ""))))
	_tutorial_title_label.text = str(step.get("title", ""))
	_tutorial_body_label.text = str(step.get("body", ""))
	_tutorial_page_label.text = "点击任意位置继续  %d / %d" % [_tutorial_step_index + 1, BATTLE_TUTORIAL_STEPS.size()]
	_apply_tutorial_focus_mask(focus_rect)
	_position_tutorial_bubble(focus_rect, str(step.get("bubble_anchor", "right")))


func _expand_tutorial_rect(rect: Rect2) -> Rect2:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return rect
	return Rect2(
		rect.position - Vector2(TUTORIAL_FOCUS_PADDING, TUTORIAL_FOCUS_PADDING),
		rect.size + Vector2(TUTORIAL_FOCUS_PADDING * 2.0, TUTORIAL_FOCUS_PADDING * 2.0)
	)


func _apply_tutorial_focus_mask(focus_rect: Rect2) -> void:
	var viewport_rect := get_viewport_rect()
	var viewport_size := viewport_rect.size
	var safe_rect := focus_rect
	safe_rect.position.x = clampf(safe_rect.position.x, 0.0, viewport_size.x)
	safe_rect.position.y = clampf(safe_rect.position.y, 0.0, viewport_size.y)
	safe_rect.size.x = clampf(safe_rect.size.x, 0.0, viewport_size.x - safe_rect.position.x)
	safe_rect.size.y = clampf(safe_rect.size.y, 0.0, viewport_size.y - safe_rect.position.y)

	_tutorial_mask_top.position = Vector2.ZERO
	_tutorial_mask_top.size = Vector2(viewport_size.x, safe_rect.position.y)

	_tutorial_mask_bottom.position = Vector2(0.0, safe_rect.position.y + safe_rect.size.y)
	_tutorial_mask_bottom.size = Vector2(viewport_size.x, maxf(0.0, viewport_size.y - _tutorial_mask_bottom.position.y))

	_tutorial_mask_left.position = Vector2(0.0, safe_rect.position.y)
	_tutorial_mask_left.size = Vector2(safe_rect.position.x, safe_rect.size.y)

	_tutorial_mask_right.position = Vector2(safe_rect.position.x + safe_rect.size.x, safe_rect.position.y)
	_tutorial_mask_right.size = Vector2(maxf(0.0, viewport_size.x - _tutorial_mask_right.position.x), safe_rect.size.y)

	_tutorial_focus_frame.position = safe_rect.position
	_tutorial_focus_frame.size = safe_rect.size


func _position_tutorial_bubble(focus_rect: Rect2, anchor: String) -> void:
	var viewport_size := get_viewport_rect().size
	_tutorial_bubble.reset_size()
	var bubble_size := _tutorial_bubble.size
	if bubble_size.x <= 0.0 or bubble_size.y <= 0.0:
		bubble_size = _tutorial_bubble.get_combined_minimum_size()
	_tutorial_bubble.size = bubble_size

	var margin := 24.0
	var gap := 18.0
	var pos := Vector2.ZERO
	match anchor:
		"left":
			pos = Vector2(focus_rect.position.x - bubble_size.x - gap, focus_rect.position.y)
		"above":
			pos = Vector2(focus_rect.position.x, focus_rect.position.y - bubble_size.y - gap)
		"below":
			pos = Vector2(focus_rect.position.x, focus_rect.position.y + focus_rect.size.y + gap)
		_:
			pos = Vector2(focus_rect.position.x + focus_rect.size.x + gap, focus_rect.position.y)

	pos.x = clampf(pos.x, margin, viewport_size.x - bubble_size.x - margin)
	pos.y = clampf(pos.y, margin, viewport_size.y - bubble_size.y - margin)
	_tutorial_bubble.position = pos

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
	DeckPanelHelper.refresh_deck(_deck_cards_flow)
		
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
	
