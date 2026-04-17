extends Node2D

const BATTLE_SCENE_PATH := "res://scenes/battle/BattleScene.tscn"

# --- 地图与生成常量 ---
const MAP_WIDTH := 5760.0
const MAP_HEIGHT := 4320.0
const GROUND_Y := 4140.0
const SPAWN_MARGIN := 300.0
const MIN_ENTITY_DISTANCE := 400.0
const PLAYER_SAFE_RADIUS := 600.0
const PLAYER_START := Vector2(260, 720)
const EXTRA_MEMORY_COUNT := 5
const EXTRA_BATTLE_COUNT := 6

const MEMORY_ECHO_SCRIPT := preload("res://scenes/explore/memory_echo.gd")
const GLASS_SHARDS_TEX := preload("res://assets/art/GlassShards.png")
const ENEMY_TEX := preload("res://assets/art/enemy/enemy01.png")

enum ExplorePhase {
	TO_MEMORY,
	MEMORY_EVENT,
	TO_BATTLE,
	TO_RELAY,
	COMPLETE
}

@onready var player: CharacterBody2D = $World/Player
@onready var hint_label: Label = $CanvasLayer/HintLabel
@onready var memory_event_ui: Control = $CanvasLayer/MemoryEventUI

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
var _occupied_positions: Array = []


func _ready() -> void:
	if has_node("/root/AudioManager"):
		AudioManager.play_bgm_segment("explore")

	_register_existing_zones()
	_create_boundary_walls()
	_spawn_memory_echoes(EXTRA_MEMORY_COUNT)
	_spawn_battle_zones(EXTRA_BATTLE_COUNT)
	_connect_signals()
	_apply_global_ui_mode()
	_update_global_stats()
	_reset_scene_state()
	_resolve_phase_from_game()
	_update_interaction_target()


func _process(_delta: float) -> void:
	if memory_event_open or _transitioning:
		return

	_update_interaction_target()

	if Input.is_action_just_pressed("interact"):
		_interact_current_target()


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
	_event_context = ""
	_transitioning = false
	Game.in_dialogue = false

	if memory_event_ui.has_method("hide_ui"):
		memory_event_ui.hide_ui()
	else:
		memory_event_ui.hide()

	_set_hint("", false)
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
			if _phase == ExplorePhase.TO_BATTLE:
				_enter_tutorial_battle()
			elif _phase == ExplorePhase.TO_RELAY:
				_open_relay_report()
			else:
				_set_hint("先调查记忆残响。", true)


func _open_memory_event() -> void:
	if Game.memory_event_done:
		_set_hint("这段残响已经调查过。", true)
		return
	if _active_memory_zone == null:
		_set_hint("你还无法锁定这段残响。", true)
		return

	memory_event_open = true
	current_target = ""
	_event_context = "memory"
	Game.in_dialogue = true
	_phase = ExplorePhase.MEMORY_EVENT
	_update_target_highlight()
	_set_hint("", false)

	if "event_text_value" in memory_event_ui:
		memory_event_ui.event_text_value = "你触碰到一段模糊的记忆残响。\n\n“不要相信报告上的死亡时间。”\n“我还在下面。”\n\n海水之下，有什么东西再一次呼唤了你。"
	if "choice_a_text" in memory_event_ui:
		memory_event_ui.choice_a_text = "继续追问那道呼唤。"
	if "choice_b_text" in memory_event_ui:
		memory_event_ui.choice_b_text = "先把异常记下并暂时封存。"

	if memory_event_ui.has_method("show_event"):
		memory_event_ui.show_event()
	else:
		memory_event_ui.show()


func _open_relay_report() -> void:
	memory_event_open = true
	current_target = ""
	_event_context = "relay"
	Game.in_dialogue = true
	_update_target_highlight()
	_set_hint("", false)

	if "event_text_value" in memory_event_ui:
		memory_event_ui.event_text_value = "你清除了盘踞在浅海中继点附近的异常体。\n\n残骸终端还能勉强启动，吐出一段残缺记录：\n\n“若再次收到来自海底的呼叫，切勿回应。”\n“门并未关闭。”\n\n你已经完成了这一次浅海任务，该返航了。"
	if "choice_a_text" in memory_event_ui:
		memory_event_ui.choice_a_text = "回收记录，立即返航。"
	if "choice_b_text" in memory_event_ui:
		memory_event_ui.choice_b_text = "记下警告，先将异常封存。"

	if memory_event_ui.has_method("show_event"):
		memory_event_ui.show_event()
	else:
		memory_event_ui.show()


func _on_memory_choice_selected(choice_id: String) -> void:
	if _event_context == "memory":
		if choice_id == "pursue":
			Game.tag_aggressive += 1
		elif choice_id == "seal":
			Game.tag_orderly += 1

		if Game.has_method("set_memory_choice"):
			Game.set_memory_choice(choice_id)

		# 这里是真正发牌
		if not Game.reward_card_given:
			Game.add_card(choice_id)
			Game.reward_card_given = true

		Game.memory_event_done = true
		_phase = ExplorePhase.TO_BATTLE
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

	if _event_context == "memory":
		if Game.memory_event_done:
			_phase = ExplorePhase.TO_BATTLE
		else:
			_phase = ExplorePhase.TO_MEMORY
	elif _event_context == "relay":
		_phase = ExplorePhase.TO_RELAY

	_event_context = ""
	_update_global_stats()

	var ui := _get_global_ui()
	if ui and ui.has_method("refresh_deck_panel"):
		ui.refresh_deck_panel()

	_update_interaction_target()


func _goto_end_scene() -> void:
	Game.goto_end()


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


func _enter_tutorial_battle() -> void:
	_transitioning = true
	Game.in_dialogue = false
	Game.battle_index = 1
	_set_hint("", false)
	get_tree().change_scene_to_file(BATTLE_SCENE_PATH)


func _update_interaction_target() -> void:
	if memory_event_open or _transitioning:
		return

	var next_target: String = ""
	_active_memory_zone = null
	_active_battle_zone = null

	match _phase:
		ExplorePhase.TO_MEMORY:
			if not Game.memory_event_done:
				for zone in _player_in_memory_zones:
					if _is_zone_discovered(zone):
						_active_memory_zone = zone
						next_target = "memory"
						break
		ExplorePhase.TO_BATTLE:
			if _player_in_battle_zones.size() > 0:
				_active_battle_zone = _player_in_battle_zones[0]
				next_target = "battle"
		ExplorePhase.TO_RELAY:
			if _player_in_battle_zones.size() > 0:
				_active_battle_zone = _player_in_battle_zones[0]
				next_target = "battle"

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
	match _phase:
		ExplorePhase.TO_MEMORY:
			if current_target == "memory":
				_set_hint("目标：按 E 调查记忆残响。", true)
				return

			if _player_in_memory_zones.size() > 0 and not Game.memory_event_done:
				var any_discovered := false
				for zone in _player_in_memory_zones:
					if _is_zone_discovered(zone):
						any_discovered = true
						break
				if any_discovered:
					_set_hint("你锁定了残响位置，按 E 调查。", true)
				else:
					_set_hint("调整朝向，锁定前方残响。", true)
				return

			_set_hint("目标：探索深海，寻找记忆残响。", true)
			return

		ExplorePhase.TO_BATTLE:
			if current_target == "battle":
				_set_hint("目标：按 E 接近异常聚集点，进入战斗。", true)
				return

			_set_hint("目标：寻找异常聚集点。", true)
			return

		ExplorePhase.TO_RELAY:
			if current_target == "battle":
				_set_hint("目标：按 E 调查中继点残骸，完成本章。", true)
				return

			_set_hint("目标：寻找中继点残骸。", true)
			return

		ExplorePhase.MEMORY_EVENT:
			_set_hint("正在读取记忆残响……", true)
			return

		ExplorePhase.COMPLETE:
			_set_hint("任务完成。", true)
			return

	_set_hint("", false)


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
	if ui and ui.has_method("set_mode"):
		ui.set_mode(ui.MODE_EXPLORE)


func _set_hint(text: String, visible: bool) -> void:
	var ui := _get_global_ui()
	if ui:
		if visible:
			ui.set_hint(text, true)
		else:
			ui.clear_hint()
	elif is_instance_valid(hint_label):
		hint_label.text = text
		hint_label.visible = visible


func _update_global_stats() -> void:
	var ui := _get_global_ui()
	if ui and ui.has_method("refresh_stats"):
		ui.refresh_stats()


# --- 区域注册与边界 ---

func _register_existing_zones() -> void:
	var mem_zone: Area2D = get_node_or_null("World/MemoryEchoZone")
	if mem_zone:
		_memory_zones.append(mem_zone)
		_occupied_positions.append(mem_zone.position)

	var bat_zone: Area2D = get_node_or_null("World/BattleZone")
	if bat_zone:
		_battle_zones.append(bat_zone)
		_occupied_positions.append(bat_zone.position)


func _create_boundary_walls() -> void:
	var world := $World
	# 左墙
	_add_wall(world, Vector2(-10, MAP_HEIGHT / 2.0), Vector2(20, MAP_HEIGHT))
	# 右墙
	_add_wall(world, Vector2(MAP_WIDTH + 10, MAP_HEIGHT / 2.0), Vector2(20, MAP_HEIGHT))
	# 上墙
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
	var positions := _generate_spawn_positions(count)
	for pos in positions:
		var echo := _create_memory_echo(pos)
		$World.add_child(echo)
		_memory_zones.append(echo)


func _spawn_battle_zones(count: int) -> void:
	var positions := _generate_spawn_positions(count)
	for pos in positions:
		var zone := _create_battle_zone(pos)
		$World.add_child(zone)
		_battle_zones.append(zone)


func _generate_spawn_positions(count: int) -> Array:
	var positions: Array = []
	var max_attempts := count * 100
	var attempts := 0

	while positions.size() < count and attempts < max_attempts:
		attempts += 1
		var pos := Vector2(
			randf_range(SPAWN_MARGIN, MAP_WIDTH - SPAWN_MARGIN),
			randf_range(SPAWN_MARGIN, GROUND_Y - 200)
		)

		if pos.distance_to(PLAYER_START) < PLAYER_SAFE_RADIUS:
			continue

		var too_close := false
		for occ_pos in _occupied_positions:
			if pos.distance_to(occ_pos) < MIN_ENTITY_DISTANCE:
				too_close = true
				break

		if not too_close:
			for p in positions:
				if pos.distance_to(p) < MIN_ENTITY_DISTANCE:
					too_close = true
					break

		if not too_close:
			positions.append(pos)
			_occupied_positions.append(pos)

	return positions


func _create_memory_echo(pos: Vector2) -> Area2D:
	var echo := Area2D.new()
	echo.position = pos
	echo.set_script(MEMORY_ECHO_SCRIPT)

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(320, 520)
	col.shape = shape
	echo.add_child(col)

	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = GLASS_SHARDS_TEX
	sprite.scale = Vector2(0.9, 0.9)
	echo.add_child(sprite)

	var highlight := Sprite2D.new()
	highlight.name = "Highlight"
	highlight.texture = GLASS_SHARDS_TEX
	highlight.scale = Vector2(0.9, 0.9)
	highlight.self_modulate = Color(0.8, 1.0, 1.0, 0.65)
	highlight.visible = false
	echo.add_child(highlight)

	return echo


func _create_battle_zone(pos: Vector2) -> Area2D:
	var zone := Area2D.new()
	zone.position = pos

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(336, 312)
	col.shape = shape
	zone.add_child(col)

	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = ENEMY_TEX
	sprite.self_modulate = Color(1.0, 0.75, 0.75, 1.0)
	sprite.scale = Vector2(0.077, 0.069)
	zone.add_child(sprite)

	var highlight := Sprite2D.new()
	highlight.name = "Highlight"
	highlight.texture = ENEMY_TEX
	highlight.self_modulate = Color(1.0, 0.65, 0.65, 1.0)
	highlight.scale = Vector2(0.084, 0.086)
	highlight.visible = false
	zone.add_child(highlight)

	return zone
