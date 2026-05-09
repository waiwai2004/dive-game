extends Node2D

const BATTLE_SCENE_PATH := "res://scenes/battle/BattleScene.tscn"

const MAP_WIDTH := 2880.0
const MAP_HEIGHT := 1880.0
const GROUND_Y := 1700.0
const SPAWN_MARGIN := 150.0
const MIN_ENTITY_DISTANCE := 200.0
const PLAYER_SAFE_RADIUS := 300.0
const PLAYER_START := Vector2(130, 310)
const EXTRA_MEMORY_COUNT := 4
const EXTRA_BATTLE_COUNT := 8
const WOUND_COUNT := 1
const BUD_COUNT := 3
const RUINS_COUNT := 2
const NON_BOSS_NODE_SCALE := 0.5
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

const MEMORY_ECHO_SCRIPT := preload("res://scenes/explore/memory_echo.gd")
const POLLUTION_NODE_FRAMES := preload("res://assets/art/explore/pollution_frames.tres")
const BUD_NODE_FRAMES := preload("res://assets/art/explore/bud_frames.tres")
const RUINS_HINT_NODE_FRAMES := preload("res://assets/art/explore/ruins_frames.tres")
const WOUND_NODE_FRAMES := preload("res://assets/art/explore/wound_frames.tres")
const WOUND_NODE_SCRIPT := preload("res://scenes/explore/wound_node.gd")
const BUD_NODE_SCRIPT := preload("res://scenes/explore/consciousness_bud_node.gd")
const RUINS_NODE_SCRIPT := preload("res://scenes/explore/cognitive_ruins_node.gd")

const BLOCK_RANGE_RADIUS := 500.0
const LOCK_RADIUS := 250.0

enum ExplorePhase {
	TO_MEMORY,
	MEMORY_EVENT,
	TO_BATTLE,
	TO_RELAY,
	COMPLETE
}

@onready var player: CharacterBody2D = $World/Player
@onready var darkness_overlay: ColorRect = $DarknessLayer/DarknessOverlay
@onready var block_range_viz: Node2D = $BlockRangeViz
@onready var hint_label: Label = $CanvasLayer/HintLabel
@onready var memory_event_ui: Control = $CanvasLayer/MemoryEventUI
@onready var interaction_panel: Control = $HudOverlay/BottomInteractionPanel
@onready var interaction_label: Label = $HudOverlay/BottomInteractionPanel/InteractionText
@onready var interaction_badge: Control = $HudOverlay/InteractionBadge
@onready var location_panel: Control = $HudOverlay/LocationPanel
@onready var location_label: Label = $HudOverlay/LocationPanel/LocationText

var current_target: String = ""
var memory_event_open: bool = false
var _phase: int = ExplorePhase.TO_MEMORY
var _event_context: String = ""
var _transitioning: bool = false

var _memory_zones: Array = []
var _battle_zones: Array = []
var _player_in_memory_zones: Array = []
var _player_in_battle_zones: Array = []
var _active_memory_zone: Area2D = null
var _active_battle_zone: Area2D = null
var _active_block_zone: Area2D = null  # 当前所在的封锁区域
var _player_locked: bool = false  # 玩家是否被污染点锁定
var _occupied_positions: Array = []


func _ready() -> void:
	if has_node("/root/AudioManager"):
		AudioManager.play_bgm_segment("explore")

	Game.load_explore_state()

	_register_existing_zones()
	_restore_player_position()
	_create_boundary_walls()

	if Game.explore_generated:
		_restore_zones()
	else:
		_spawn_memory_echoes(EXTRA_MEMORY_COUNT)
		_spawn_battle_zones(EXTRA_BATTLE_COUNT)
		_spawn_wound_boss()
		_spawn_consciousness_buds(BUD_COUNT)
		_spawn_cognitive_ruins(RUINS_COUNT)
		Game.explore_generated = true
		_save_zone_positions()

	_connect_signals()
	_restore_triggered_states()
	_apply_global_ui_mode()
	_update_global_stats()
	_reset_scene_state()
	_resolve_phase_from_game()
	_update_interaction_target()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE:
		_save_player_position()
		_save_triggered_states()
		Game.save_explore_state()


func _save_player_position() -> void:
	if player:
		Game.explore_player_position = player.global_position


func _restore_player_position() -> void:
	var saved_pos: Vector2 = Game.explore_player_position
	if Game.explore_generated:
		player.global_position = saved_pos
	else:
		player.global_position = PLAYER_START


func _save_zone_positions() -> void:
	var mem_pos: Array = []
	for zone in _memory_zones:
		mem_pos.append({"x": zone.position.x, "y": zone.position.y})
	Game.explore_memory_positions = mem_pos

	var wound_pos: Vector2 = Vector2.ZERO
	var bud_pos_list: Array = []
	var ruins_pos_list: Array = []
	var battle_pos_list: Array = []

	for zone in _battle_zones:
		if zone.name == "WoundBoss":
			wound_pos = zone.position
		elif zone.get_script() == BUD_NODE_SCRIPT:
			bud_pos_list.append({"x": zone.position.x, "y": zone.position.y})
		elif zone.get_script() == RUINS_NODE_SCRIPT:
			ruins_pos_list.append({"x": zone.position.x, "y": zone.position.y})
		else:
			battle_pos_list.append({"x": zone.position.x, "y": zone.position.y, "enemy_id": str(zone.get_meta("enemy_id", "motor_jellyfish"))})

	Game.explore_wound_position = wound_pos
	Game.explore_bud_positions = bud_pos_list
	Game.explore_ruins_positions = ruins_pos_list
	Game.explore_battle_positions = battle_pos_list


func _get_zone_script_name(zone: Area2D) -> String:
	var script = zone.get_script()
	if script == WOUND_NODE_SCRIPT:
		return "wound"
	elif script == BUD_NODE_SCRIPT:
		return "bud"
	elif script == RUINS_NODE_SCRIPT:
		return "ruins"
	return "default"


func _restore_zones() -> void:
	var mem_positions: Array = Game.explore_memory_positions
	for data in mem_positions:
		var pos := Vector2(data.x, data.y)
		var echo := _create_memory_echo(pos)
		$World.add_child(echo)
		_memory_zones.append(echo)

	var bud_positions: Array = Game.explore_bud_positions
	for i in range(bud_positions.size()):
		var data = bud_positions[i]
		var pos := Vector2(data.x, data.y)
		var bud := _create_consciousness_bud(pos)
		bud.name = "ConsciousnessBud_%d" % i
		$World.add_child(bud)
		_battle_zones.append(bud)

	var ruins_positions: Array = Game.explore_ruins_positions
	for i in range(ruins_positions.size()):
		var data = ruins_positions[i]
		var pos := Vector2(data.x, data.y)
		var ruins := _create_cognitive_ruins(pos)
		ruins.name = "CognitiveRuins_%d" % i
		$World.add_child(ruins)
		_battle_zones.append(ruins)

	var battle_positions: Array = Game.explore_battle_positions
	for data in battle_positions:
		var pos := Vector2(data.x, data.y)
		var zone := _create_battle_zone(pos)
		zone.set_meta("battle_index", 2)
		zone.set_meta("enemy_id", str(data.get("enemy_id", "motor_jellyfish")))
		$World.add_child(zone)
		_battle_zones.append(zone)

	var wound_pos: Vector2 = Game.explore_wound_position
	if wound_pos != Vector2.ZERO:
		var wound := _create_wound_node(wound_pos)
		$World.add_child(wound)
		_battle_zones.append(wound)


func _save_triggered_states() -> void:
	var zones_dict: Dictionary = {}
	for zone in _memory_zones:
		zones_dict[_zone_to_key(zone)] = zone.has_meta("triggered") and zone.get_meta("triggered")
	for zone in _battle_zones:
		zones_dict[_zone_to_key(zone)] = zone.has_meta("triggered") and zone.get_meta("triggered")
	Game.explore_zones = zones_dict


func _zone_to_key(zone: Area2D) -> String:
	# 仅使用位置作为 key，避免运行时自动分配的名字（@Area2D@xxx）在保存/读取间不一致
	return "%d_%d" % [int(zone.position.x), int(zone.position.y)]


func _restore_triggered_states() -> void:
	var zones_dict: Dictionary = Game.explore_zones
	for zone in _memory_zones:
		var key := _zone_to_key(zone)
		if zones_dict.has(key) and zones_dict[key]:
			_mark_zone_triggered(zone)
	for zone in _battle_zones:
		var key := _zone_to_key(zone)
		if zones_dict.has(key) and zones_dict[key]:
			_mark_zone_triggered(zone)


func _process(_delta: float) -> void:
	if memory_event_open or _transitioning:
		return

	var in_block := _update_block_range_state()
	_apply_block_range_effect(in_block)

	if _player_locked and _active_block_zone:
		_constrain_player_in_lock()

	_update_interaction_target()

	if Input.is_action_just_pressed("interact"):
		_interact_current_target()


func _constrain_player_in_lock() -> void:
	if not _active_block_zone or not player:
		return
	var lock_center: Vector2 = _active_block_zone.global_position
	var player_pos: Vector2 = player.global_position
	var dist: float = player_pos.distance_to(lock_center)
	if dist > LOCK_RADIUS:
		var direction: Vector2 = (player_pos - lock_center).normalized()
		player.global_position = lock_center + direction * LOCK_RADIUS


func _connect_signals() -> void:
	if memory_event_ui.has_signal("choice_selected"):
		memory_event_ui.choice_selected.connect(_on_memory_choice_selected)
	if memory_event_ui.has_signal("closed"):
		memory_event_ui.closed.connect(_on_memory_event_closed)

	for zone in _memory_zones:
		zone.body_entered.connect(_on_memory_zone_entered.bind(zone))
		zone.body_exited.connect(_on_memory_zone_exited.bind(zone))

	for zone in _battle_zones:
		zone.body_entered.connect(_on_battle_zone_entered.bind(zone))
		zone.body_exited.connect(_on_battle_zone_exited.bind(zone))


func _reset_scene_state() -> void:
	current_target = ""
	memory_event_open = false
	_player_in_memory_zones.clear()
	_player_in_battle_zones.clear()
	_active_memory_zone = null
	_active_battle_zone = null
	_active_block_zone = null
	_player_locked = false
	_event_context = ""
	_transitioning = false
	Game.in_dialogue = false

	if memory_event_ui.has_method("hide_ui"):
		memory_event_ui.hide_ui()
	else:
		memory_event_ui.hide()

	_update_target_highlight()


func _resolve_phase_from_game() -> void:
	if Game.first_battle_reward_done:
		_phase = ExplorePhase.TO_RELAY
	elif Game.memory_event_done:
		_phase = ExplorePhase.TO_BATTLE
	else:
		_phase = ExplorePhase.TO_MEMORY


func _interact_current_target() -> void:
	match current_target:
		"memory":
			_open_memory_event()
		"battle":
			_enter_battle_or_reward()


func _show_blocked_interaction_feedback() -> void:
	if interaction_label:
		interaction_label.text = "无法与该区域交互，请先击败污染点"
	if hint_label:
		hint_label.text = "无法与该区域交互，请先击败污染点"


func _open_memory_event() -> void:
	if _active_memory_zone == null:
		return
	
	if _is_zone_triggered(_active_memory_zone):
		return
	
	if _active_memory_zone:
		_mark_zone_triggered(_active_memory_zone)
	
	_save_player_position()
	_save_triggered_states()
	Game.save_explore_state()
	
	_transitioning = true
	Game.in_dialogue = false
	call_deferred("_goto_ai_scene")


func _open_relay_report() -> void:
	memory_event_open = true
	current_target = ""
	_event_context = "relay"
	Game.in_dialogue = true
	_set_explore_hud_visible(false)
	_update_target_highlight()

	if "event_text_value" in memory_event_ui:
		memory_event_ui.event_text_value = "你清除了盘踞在浅海中继点附近的异常体。\n\n残骸终端还能勉强启动，吐出一段残缺记录：\n\n\"若再次收到来自海底的呼叫，切勿回应。\"\n\"门并未关闭。\"\n\n你已经完成了这一次浅海任务，该返航了。"
	if "choice_a_text" in memory_event_ui:
		memory_event_ui.choice_a_text = "回收记录，立即返航。"
	if "choice_b_text" in memory_event_ui:
		memory_event_ui.choice_b_text = "记下警告，先将异常封存。"

	if memory_event_ui.has_method("show_event"):
		memory_event_ui.show_event()
	else:
		memory_event_ui.show()


func _on_memory_choice_selected(choice_id: String) -> void:
	if _event_context == "ruins":
		if _active_battle_zone:
			_mark_zone_triggered(_active_battle_zone)
		
		if choice_id == "pursue":
			Game.tag_aggressive += 1
		elif choice_id == "seal":
			Game.tag_orderly += 1

		if Game.has_method("set_memory_choice"):
			Game.set_memory_choice(choice_id)

		if not Game.reward_card_given:
			Game.add_card(choice_id)
			Game.reward_card_given = true

		Game.memory_event_done = true
		
		_save_triggered_states()
		Game.save_explore_state()
		
		memory_event_open = false
		Game.in_dialogue = false
		_event_context = ""
		if memory_event_ui.has_method("hide_ui"):
			memory_event_ui.hide_ui()
		else:
			memory_event_ui.hide()
		_update_interaction_target()
		return

	if _event_context == "relay":
		if Game.has_method("set_end_choice"):
			Game.set_end_choice(choice_id)

		_phase = ExplorePhase.COMPLETE
		_transitioning = true
		Game.in_dialogue = false
		call_deferred("_goto_end_scene")

func _on_memory_event_closed() -> void:
	if _transitioning:
		return

	memory_event_open = false
	Game.in_dialogue = false

	if _event_context == "ruins":
		if Game.memory_event_done:
			_phase = ExplorePhase.TO_BATTLE
		else:
			_phase = ExplorePhase.TO_MEMORY
	elif _event_context == "relay":
		_phase = ExplorePhase.TO_RELAY

	_event_context = ""
	_set_explore_hud_visible(true)
	_update_global_stats()

	var ui := _get_global_ui()
	if ui and ui.has_method("refresh_deck_panel"):
		ui.refresh_deck_panel()

	_update_interaction_target()


func _goto_end_scene() -> void:
	Game.goto_end()


func _goto_ai_scene() -> void:
	Game.goto_ai()


func _on_memory_zone_entered(body: Node, zone: Area2D) -> void:
	if body != player or memory_event_open:
		return
	if zone not in _player_in_memory_zones:
		_player_in_memory_zones.append(zone)
	_update_interaction_target()


func _on_memory_zone_exited(body: Node, zone: Area2D) -> void:
	if body != player:
		return
	_player_in_memory_zones.erase(zone)
	_update_interaction_target()


func _on_battle_zone_entered(body: Node, zone: Area2D) -> void:
	if body != player or memory_event_open:
		return
	if zone not in _player_in_battle_zones:
		_player_in_battle_zones.append(zone)
	_update_interaction_target()


func _on_battle_zone_exited(body: Node, zone: Area2D) -> void:
	if body != player:
		return
	_player_in_battle_zones.erase(zone)
	_update_interaction_target()


func _enter_battle_or_reward() -> void:
	if _active_battle_zone == null:
		return
	
	if _is_zone_triggered(_active_battle_zone):
		return
	
	if _active_battle_zone.get_script() == BUD_NODE_SCRIPT:
		_enter_bud_reward()
	elif _active_battle_zone.get_script() == RUINS_NODE_SCRIPT:
		_enter_ruins_event()
	elif _active_battle_zone.name == "WoundBoss":
		_enter_wound_boss()
	else:
		_enter_enemy_battle()


func _enter_ruins_event() -> void:
	memory_event_open = true
	current_target = ""
	_event_context = "ruins"
	Game.in_dialogue = true
	_set_explore_hud_visible(false)
	_update_target_highlight()

	if "event_text_value" in memory_event_ui:
		memory_event_ui.event_text_value = "你触碰到一段模糊的记忆残响。\n\n\"不要相信报告上的死亡时间。\"\n\"我还在下面。\"\n\n海水之下，有什么东西再一次呼唤了你。"
	if "choice_a_text" in memory_event_ui:
		memory_event_ui.choice_a_text = "继续追问那道呼唤。"
	if "choice_b_text" in memory_event_ui:
		memory_event_ui.choice_b_text = "先把异常记下并暂时封存。"

	if memory_event_ui.has_method("show_event"):
		memory_event_ui.show_event()
	else:
		memory_event_ui.show()


func _is_zone_triggered(zone: Area2D) -> bool:
	if zone.has_meta("triggered"):
		return zone.get_meta("triggered")
	return false


func _mark_zone_triggered(zone: Area2D) -> void:
	zone.set_meta("triggered", true)
	_set_zone_grey(zone)


func _set_zone_grey(zone: Area2D) -> void:
	if zone.has_method("set_triggered"):
		zone.call("set_triggered", true)
	else:
		var sprite := zone.get_node_or_null("Sprite2D") as CanvasItem
		if sprite:
			sprite.self_modulate = Color(0.4, 0.4, 0.4, 0.6)
		var highlight := zone.get_node_or_null("Highlight") as CanvasItem
		if highlight:
			highlight.visible = false


func _is_zone_in_block_range(zone: Area2D) -> bool:
	if zone == null:
		return false
	if _is_zone_triggered(zone):
		return false
	if zone.get_script() == BUD_NODE_SCRIPT or zone.get_script() == RUINS_NODE_SCRIPT:
		return false
	return player.global_position.distance_to(zone.global_position) < BLOCK_RANGE_RADIUS


func _update_block_range_state() -> bool:
	var lock_target := _active_block_zone

	if _player_locked:
		if lock_target and _is_zone_triggered(lock_target):
			_player_locked = false
			_active_block_zone = null
			return false
		if lock_target:
			_active_block_zone = lock_target
			return true

	_active_block_zone = null
	for zone in _battle_zones:
		if _is_zone_in_block_range(zone):
			_active_block_zone = zone
			if player.global_position.distance_to(zone.global_position) < LOCK_RADIUS:
				_player_locked = true
			return true
	return false


func _apply_block_range_effect(in_block: bool) -> void:
	if darkness_overlay and darkness_overlay.has_method("set_block_mode"):
		darkness_overlay.block_mode = false
	_update_block_range_visual()


func _update_block_range_visual() -> void:
	if not block_range_viz:
		return
	for child in block_range_viz.get_children():
		child.queue_free()

	if not _player_locked or not _active_block_zone:
		block_range_viz.visible = false
		return

	block_range_viz.visible = true
	var lock_center: Vector2 = _active_block_zone.global_position

	var outer_ring := Line2D.new()
	outer_ring.width = 5.0
	outer_ring.default_color = Color(0.9, 0.05, 0.05, 1.0)
	outer_ring.joint_mode = Line2D.LINE_JOINT_ROUND
	outer_ring.begin_cap_mode = Line2D.LINE_CAP_ROUND
	outer_ring.end_cap_mode = Line2D.LINE_CAP_ROUND
	var points := PackedVector2Array()
	for i in range(65):
		var angle := TAU * i / 64.0
		points.append(lock_center + Vector2(cos(angle), sin(angle)) * LOCK_RADIUS)
	outer_ring.points = points
	block_range_viz.add_child(outer_ring)

	var inner_ring := Line2D.new()
	inner_ring.width = 3.0
	inner_ring.default_color = Color(1.0, 0.15, 0.15, 0.7)
	inner_ring.joint_mode = Line2D.LINE_JOINT_ROUND
	var inner_points := PackedVector2Array()
	for i in range(65):
		var angle := TAU * i / 64.0
		inner_points.append(lock_center + Vector2(cos(angle), sin(angle)) * (LOCK_RADIUS - 12.0))
	inner_ring.points = inner_points
	block_range_viz.add_child(inner_ring)

	var glow_sprite := Sprite2D.new()
	glow_sprite.position = lock_center
	var tex := _create_evil_glow_texture()
	glow_sprite.texture = tex
	glow_sprite.scale = Vector2(LOCK_RADIUS * 2.8 / 256.0, LOCK_RADIUS * 2.8 / 256.0)
	glow_sprite.modulate = Color(0.7, 0.0, 0.0, 0.2)
	block_range_viz.add_child(glow_sprite)


func _create_evil_glow_texture() -> ImageTexture:
	var img := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center := Vector2(128, 128)
	for y in range(256):
		for x in range(256):
			var pos := Vector2(x, y)
			var dist: float = pos.distance_to(center)
			var alpha: float = 0.0
			if dist > 90.0 and dist < 128.0:
				alpha = (dist - 90.0) / 38.0 * 0.4
			elif dist <= 90.0:
				alpha = 0.15
			var color := Color(0.8, 0.0, 0.0, alpha)
			img.set_pixel(x, y, color)
	var tex := ImageTexture.create_from_image(img)
	return tex


func _enter_enemy_battle() -> void:
	if _active_battle_zone:
		_mark_zone_triggered(_active_battle_zone)
	_save_player_position()
	_save_triggered_states()
	Game.save_explore_state()
	_transitioning = true
	Game.in_dialogue = false
	Game.battle_index = int(_active_battle_zone.get_meta("battle_index", 1))
	Game.current_battle_enemy_id = _pick_random_enemy_id(NORMAL_BATTLE_ENEMY_POOL, "corpse_shrimp")
	get_tree().change_scene_to_file(BATTLE_SCENE_PATH)


func _enter_bud_reward() -> void:
	if _active_battle_zone:
		_mark_zone_triggered(_active_battle_zone)
	_save_player_position()
	_save_triggered_states()
	Game.save_explore_state()
	_transitioning = true
	Game.in_dialogue = false
	if Game.has_method("goto_bud_reward"):
		Game.goto_bud_reward()
	else:
		get_tree().change_scene_to_file("res://scenes/Reward/RewardScene.tscn")


func _enter_wound_boss() -> void:
	if _active_battle_zone:
		_mark_zone_triggered(_active_battle_zone)
	_save_player_position()
	_save_triggered_states()
	Game.save_explore_state()
	_transitioning = true
	Game.in_dialogue = false
	Game.battle_index = 3
	Game.current_battle_enemy_id = _pick_random_enemy_id(BOSS_BATTLE_ENEMY_POOL, "black_bubble")
	get_tree().change_scene_to_file(BATTLE_SCENE_PATH)


func _pick_random_enemy_id(enemy_pool: Array, fallback: String) -> String:
	if enemy_pool.is_empty():
		return fallback
	return str(enemy_pool[randi() % enemy_pool.size()])


func _update_interaction_target() -> void:
	if memory_event_open or _transitioning:
		return

	var in_block := _update_block_range_state()

	var next_target: String = ""
	_active_memory_zone = null
	_active_battle_zone = null

	if in_block:
		if not _is_zone_triggered(_active_block_zone):
			_active_battle_zone = _active_block_zone
			next_target = "battle"
	else:
		for zone in _player_in_memory_zones:
			if not _is_zone_triggered(zone) and _is_zone_discovered(zone):
				_active_memory_zone = zone
				next_target = "memory"
				break

		if next_target.is_empty() and _player_in_battle_zones.size() > 0:
			for zone in _player_in_battle_zones:
				if not _is_zone_triggered(zone):
					_active_battle_zone = zone
					next_target = "battle"
					break

	current_target = next_target
	_update_target_highlight()
	_update_hint_text()


func _is_zone_discovered(zone: Area2D) -> bool:
	if zone.has_method("is_discovered_by_player"):
		var result: Variant = zone.call("is_discovered_by_player", player)
		if result is bool:
			return bool(result)
	return true


func _update_target_highlight() -> void:
	for zone in _memory_zones:
		var hl: CanvasItem = zone.get_node_or_null("Highlight")
		if hl:
			hl.visible = (zone == _active_memory_zone and not memory_event_open)

	for zone in _battle_zones:
		var hl: CanvasItem = zone.get_node_or_null("Highlight")
		if hl:
			hl.visible = (zone == _active_battle_zone and not memory_event_open)


func _update_hint_text() -> void:
	var prompt_text := ""
	if _player_locked:
		prompt_text = "你已被困于此污染区域，按 E 直面异变"
	elif _active_block_zone != null and current_target == "battle":
		prompt_text = "按 E 直面潜伏于水影中的异变（该区域已被封锁）"
	elif current_target == "memory":
		prompt_text = "按 E 聆听这段浮上海面的残响"
	elif current_target == "battle":
		prompt_text = _get_battle_prompt_text()
	else:
		prompt_text = "海水仍在回响，留意那些不该出现的讯号"

	if hint_label:
		hint_label.text = prompt_text
		hint_label.visible = false
	if interaction_label:
		interaction_label.text = prompt_text
	if interaction_panel:
		interaction_panel.visible = not memory_event_open
	if interaction_badge:
		interaction_badge.visible = not memory_event_open
	if location_label:
		location_label.text = _get_depth_layer_name()
	if location_panel:
		location_panel.visible = not memory_event_open


func _set_explore_hud_visible(value: bool) -> void:
	if interaction_panel:
		interaction_panel.visible = value
	if interaction_badge:
		interaction_badge.visible = value
	if location_panel:
		location_panel.visible = value


func _get_battle_prompt_text() -> String:
	if _active_battle_zone == null:
		return "按 E 靠近前方那道异动"
	if _active_battle_zone.get_script() == BUD_NODE_SCRIPT:
		return "按 E 触碰那枚在水中脉动的意识花苞"
	if _active_battle_zone.get_script() == RUINS_NODE_SCRIPT:
		return "按 E 探查前方裸露出的认知废墟"
	if _active_battle_zone.name == "WoundBoss":
		return "按 E 直面那道尚未愈合的深渊裂口"
	return "按 E 直面潜伏于水影中的异变"


func _get_depth_layer_name() -> String:
	if not player:
		return "浮光表层"
	var y := player.global_position.y
	if y < 450.0:
		return "浮光表层"
	if y < 950.0:
		return "浅海残域"
	if y < 1450.0:
		return "中层暗流"
	return "沉没海沟"


func _get_global_ui() -> Node:
	if not is_inside_tree():
		return null
	var tree := get_tree()
	if tree == null:
		return null
	var root := tree.root
	if root == null:
		return null
	return root.get_node_or_null("GlobalUI")


func _apply_global_ui_mode() -> void:
	var ui := _get_global_ui()
	if ui:
		ui.visible = true
		if ui.has_method("set_mode"):
			ui.set_mode(ui.MODE_EXPLORE)


func _update_global_stats() -> void:
	var ui := _get_global_ui()
	if ui and ui.has_method("refresh_stats"):
		ui.refresh_stats()


# --- 区域注册与边界 ---

func _register_existing_zones() -> void:
	var mem_zone: Area2D = get_node_or_null("World/MemoryEchoZone")
	if mem_zone:
		if "detect_radius" in mem_zone:
			mem_zone.detect_radius = 520.0 * NON_BOSS_NODE_SCALE
		_set_zone_animated(mem_zone, RUINS_HINT_NODE_FRAMES, Vector2(0.48, 0.48), Color.WHITE, Vector2(0.56, 0.56), Color(0.75, 0.95, 1.0, 0.78))
		_memory_zones.append(mem_zone)
		_occupied_positions.append(mem_zone.position)

	var bat_zone: Area2D = get_node_or_null("World/BattleZone")
	if bat_zone:
		_set_zone_animated(bat_zone, POLLUTION_NODE_FRAMES, Vector2(0.25, 0.25), Color.WHITE, Vector2(0.29, 0.29), Color(1.0, 0.45, 0.45, 0.85))
		bat_zone.set_meta("battle_index", 1)
		bat_zone.set_meta("enemy_id", "corpse_shrimp")
		_battle_zones.append(bat_zone)
		_occupied_positions.append(bat_zone.position)


func _create_boundary_walls() -> void:
	var world := $World
	_add_wall(world, Vector2(-10, MAP_HEIGHT / 2.0), Vector2(20, MAP_HEIGHT))
	_add_wall(world, Vector2(MAP_WIDTH + 10, MAP_HEIGHT / 2.0), Vector2(20, MAP_HEIGHT))
	_add_wall(world, Vector2(MAP_WIDTH / 2.0, -10), Vector2(MAP_WIDTH, 20))


func _add_wall(parent: Node, pos: Vector2, wall_size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = wall_size
	col.shape = shape
	body.add_child(col)
	parent.add_child(body)

# --- 随机生成 ---

func _spawn_memory_echoes(count: int) -> void:
	var positions := ExploreMapGenerator.generate_spawn_positions(count, _occupied_positions)
	for pos in positions:
		var echo := ExploreMapGenerator.create_memory_echo(pos)
		$World.add_child(echo)
		_memory_zones.append(echo)


func _spawn_battle_zones(count: int) -> void:
	var positions := ExploreMapGenerator.generate_spawn_positions(count, _occupied_positions)
	for pos in positions:
		var zone := ExploreMapGenerator.create_battle_zone(pos)
		zone.set_meta("battle_index", 2)
		zone.set_meta("enemy_id", "motor_jellyfish")
		$World.add_child(zone)
		_battle_zones.append(zone)


func _create_memory_echo(pos: Vector2) -> Area2D:
	return ExploreMapGenerator.create_memory_echo(pos)


func _create_battle_zone(pos: Vector2) -> Area2D:
	return ExploreMapGenerator.create_battle_zone(pos)


# --- 伤口 / 意识花苞 / 认知废墟 ---

func _spawn_wound_boss() -> void:
	var pos := ExploreMapGenerator.generate_wound_position(_occupied_positions)
	var wound := ExploreMapGenerator.create_wound_node(pos)
	$World.add_child(wound)
	_battle_zones.append(wound)


func _create_wound_node(pos: Vector2) -> Area2D:
	return ExploreMapGenerator.create_wound_node(pos)


func _spawn_consciousness_buds(count: int) -> void:
	var positions := ExploreMapGenerator.generate_spawn_positions(count, _occupied_positions)
	for i in range(positions.size()):
		var bud := ExploreMapGenerator.create_consciousness_bud(positions[i])
		bud.name = "ConsciousnessBud_%d" % i
		$World.add_child(bud)
		_battle_zones.append(bud)


func _create_consciousness_bud(pos: Vector2) -> Area2D:
	return ExploreMapGenerator.create_consciousness_bud(pos)


func _spawn_cognitive_ruins(count: int) -> void:
	var positions := ExploreMapGenerator.generate_spawn_positions(count, _occupied_positions)
	for i in range(positions.size()):
		var ruins := ExploreMapGenerator.create_cognitive_ruins(positions[i])
		ruins.name = "CognitiveRuins_%d" % i
		$World.add_child(ruins)
		_battle_zones.append(ruins)


func _create_cognitive_ruins(pos: Vector2) -> Area2D:
	return ExploreMapGenerator.create_cognitive_ruins(pos)


func _set_zone_animated(zone: Area2D, frames: SpriteFrames, sprite_scale: Vector2, sprite_modulate: Color, highlight_scale: Vector2, highlight_modulate: Color) -> void:
	var sprite := zone.get_node_or_null("Sprite2D") as CanvasItem
	if sprite:
		if sprite is AnimatedSprite2D:
			var anim_sprite := sprite as AnimatedSprite2D
			anim_sprite.sprite_frames = frames
			anim_sprite.animation = &"default"
			anim_sprite.play()
		sprite.scale = sprite_scale
		sprite.self_modulate = sprite_modulate
		sprite.position = Vector2.ZERO

	var highlight := zone.get_node_or_null("Highlight") as Sprite2D
	if highlight:
		highlight.texture = ExploreMapGenerator.get_first_frame_from_frames(frames)
		highlight.scale = highlight_scale
		highlight.self_modulate = highlight_modulate
		highlight.position = Vector2.ZERO
		highlight.visible = false

	ExploreMapGenerator.apply_texture_contour_collision(zone, frames, sprite_scale)


func _expand_zone_interaction(zone: Area2D, factor: float) -> void:
	var collision := zone.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null or collision.shape == null:
		return
	var shape := collision.shape.duplicate()
	if shape is RectangleShape2D:
		(shape as RectangleShape2D).size *= factor
	elif shape is CircleShape2D:
		(shape as CircleShape2D).radius *= factor
	collision.shape = shape

