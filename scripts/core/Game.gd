extends Node

const BATTLE_TUTORIAL_SAVE_FILE := "user://battle_tutorial_state.json"

var player_hp: int = 10
var max_hp: int = 10

var player_san: int = 10
var max_san: int = 10
var player_cognition: int = 0
var max_cognition: int = 15
var cognition_current: int:
	get:
		return player_cognition
	set(value):
		player_cognition = maxi(value, 0)
var cognition_max: int:
	get:
		return max_cognition
	set(value):
		max_cognition = maxi(value, 1)

# 精神负荷（新增，用于意识花苞奖励）
var player_mental_load: int = 0
var max_mental_load: int = 10
var mental_load_current: int:
	get:
		return player_mental_load
	set(value):
		player_mental_load = clampi(value, 0, max_mental_load)
var mental_load_max: int:
	get:
		return max_mental_load
	set(value):
		max_mental_load = maxi(value, 1)

var deck: Array[String] = []

var player_tags: Array[String] = []

var tag_aggressive: int = 0
var tag_orderly: int = 0

var battle_index: int = 0
var current_battle_enemy_id: String = ""
var first_battle_reward_done: bool = false
var battle_tutorial_shown: bool = false
var admin_talk_done: bool = false
var memory_event_done: bool = false
var reward_card_given: bool = false
var in_dialogue: bool = false

var in_adventure: bool:
	get:
		return chapter_one_state != "base" and chapter_one_state != ""

# --- 探索场景状态持久化 ---
const EXPLORE_SAVE_FILE := "user://explore_state.json"

var explore_data: Dictionary = {}

const EXPLORE_PLAYER_START := Vector2(130, 310)

var explore_player_position: Vector2:
	get:
		if explore_data.has("player_pos"):
			return Vector2(explore_data.player_pos.x, explore_data.player_pos.y)
		return EXPLORE_PLAYER_START
	set(value):
		explore_data.player_pos = {"x": value.x, "y": value.y}

var explore_zones: Dictionary:
	get:
		if explore_data.has("zones"):
			return explore_data.zones
		return {}
	set(value):
		explore_data.zones = value

var explore_generated: bool:
	get:
		return explore_data.get("generated", false)
	set(value):
		explore_data.generated = value

var explore_memory_positions: Array:
	get:
		if explore_data.has("memory_positions"):
			return explore_data.memory_positions
		return []
	set(value):
		explore_data.memory_positions = value

var explore_battle_positions: Array:
	get:
		if explore_data.has("battle_positions"):
			return explore_data.battle_positions
		return []
	set(value):
		explore_data.battle_positions = value

var explore_wound_position: Vector2:
	get:
		if explore_data.has("wound_pos"):
			return Vector2(explore_data.wound_pos.x, explore_data.wound_pos.y)
		return Vector2.ZERO
	set(value):
		explore_data.wound_pos = {"x": value.x, "y": value.y}

var explore_bud_positions: Array:
	get:
		if explore_data.has("bud_positions"):
			return explore_data.bud_positions
		return []
	set(value):
		explore_data.bud_positions = value

var explore_ruins_positions: Array:
	get:
		if explore_data.has("ruins_positions"):
			return explore_data.ruins_positions
		return []
	set(value):
		explore_data.ruins_positions = value

func save_explore_state() -> void:
	explore_data.version = 1
	var file := FileAccess.open(EXPLORE_SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(explore_data))

func load_explore_state() -> void:
	if FileAccess.file_exists(EXPLORE_SAVE_FILE):
		var file := FileAccess.open(EXPLORE_SAVE_FILE, FileAccess.READ)
		if file:
			var json := JSON.new()
			var result := json.parse(file.get_as_text())
			if result == OK:
				explore_data = json.data

func reset_explore_state() -> void:
	explore_data = {}
	if FileAccess.file_exists(EXPLORE_SAVE_FILE):
		DirAccess.remove_absolute(EXPLORE_SAVE_FILE)

# 第一章垂直切片状态
var chapter_one_state: String = "base"
var chapter_one_memory_choice: String = ""
var chapter_one_end_choice: String = ""

# --- 意识花苞奖励池定义（新增） ---
const _BUD_POOL := [
	{"id": "hp_current",    "name": "存在值 +5",       "weight": 40},
	{"id": "hp_max",        "name": "存在值上限 +2",   "weight": 15},
	{"id": "san_max",       "name": "SAN 值上限 +2",   "weight": 15},
	{"id": "cognition_max", "name": "认知负荷上限 +2", "weight": 15},
	{"id": "mental_max",    "name": "精神负荷上限 +5", "weight": 15},
]
const _BUD_MAX_REWARDS: int = 3
const _BUD_CONTINUE_PROB: float = 0.20

# 最近一次意识花苞抽到的奖励描述（供结算页面显示）
var last_bud_rewards: Array[String] = []


func _ready() -> void:
	_load_battle_tutorial_state()


func reset_run():
	max_hp = 10
	player_hp = 10
	player_san = 10
	max_san = 10
	player_cognition = 0
	max_cognition = 15
	player_mental_load = 0
	max_mental_load = 10

	tag_aggressive = 0
	tag_orderly = 0

	battle_index = 0
	current_battle_enemy_id = ""
	first_battle_reward_done = false
	_reset_battle_tutorial_state()
	admin_talk_done = false
	memory_event_done = false
	reward_card_given = false
	in_dialogue = false

	chapter_one_state = "base"
	chapter_one_memory_choice = ""
	chapter_one_end_choice = ""

	last_bud_rewards.clear()

	reset_explore_state()

	deck = [
		"cut",
		"cut",
		"bless",
		"break",
		"release"
	]


func begin_chapter_one() -> void:
	chapter_one_state = "briefed"
	memory_event_done = false
	first_battle_reward_done = false
	_load_battle_tutorial_state()
	reward_card_given = false
	battle_index = 0
	current_battle_enemy_id = ""
	chapter_one_memory_choice = ""
	chapter_one_end_choice = ""


func set_chapter_one_state(state: String) -> void:
	chapter_one_state = state


func set_memory_choice(choice_id: String) -> void:
	chapter_one_memory_choice = choice_id


func set_end_choice(choice_id: String) -> void:
	chapter_one_end_choice = choice_id


func add_card(card_id: String):
	deck.append(card_id)


func mark_battle_tutorial_shown() -> void:
	battle_tutorial_shown = true
	var file := FileAccess.open(BATTLE_TUTORIAL_SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"shown": true}))


func _reset_battle_tutorial_state() -> void:
	battle_tutorial_shown = false
	if FileAccess.file_exists(BATTLE_TUTORIAL_SAVE_FILE):
		DirAccess.remove_absolute(BATTLE_TUTORIAL_SAVE_FILE)


func _load_battle_tutorial_state() -> void:
	battle_tutorial_shown = false
	if not FileAccess.file_exists(BATTLE_TUTORIAL_SAVE_FILE):
		return
	var file := FileAccess.open(BATTLE_TUTORIAL_SAVE_FILE, FileAccess.READ)
	if file == null:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return
	if json.data is Dictionary:
		battle_tutorial_shown = bool((json.data as Dictionary).get("shown", false))


func damage_player(amount: int, _san_loss: int = -1):
	player_hp = max(player_hp - amount, 0)
	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("hit")


func heal_player(amount: int):
	player_hp = min(player_hp + amount, max_hp)


func heal_san(amount: int):
	player_san = min(player_san + amount, max_san)


func restore_san_to_max() -> void:
	player_san = max_san


func is_distorted() -> bool:
	return player_san <= 0


func add_cognition(amount: int) -> void:
	player_cognition = maxi(player_cognition + amount, 0)


func reduce_cognition(amount: int) -> void:
	player_cognition = maxi(player_cognition - amount, 0)


func clear_cognition() -> void:
	player_cognition = 0


# --- 精神负荷相关（新增） ---

func add_mental_load(amount: int) -> void:
	player_mental_load = clampi(player_mental_load + amount, 0, max_mental_load)


func reduce_mental_load(amount: int) -> void:
	player_mental_load = maxi(player_mental_load - amount, 0)


func clear_mental_load() -> void:
	player_mental_load = 0


# --- 意识花苞奖励相关（新增） ---

# 给一个奖励 id 就直接应用到全局状态，返回可读描述
func apply_bud_reward(reward_id: String) -> String:
	match reward_id:
		"hp_current":
			heal_player(5)
			return "存在值 +5"
		"hp_max":
			max_hp += 2
			heal_player(2)
			return "存在值上限 +2"
		"san_max":
			max_san += 2
			heal_san(2)
			return "SAN 值上限 +2"
		"cognition_max":
			max_cognition += 2
			return "认知负荷上限 +2"
		"mental_max":
			max_mental_load += 5
			return "精神负荷上限 +5"
		_:
			return ""


# 完整抽奖：首次必抽，之后每次 20% 概率继续，最多 3 项。
# 抽完后奖励已经应用到全局状态，描述文案存入 last_bud_rewards
func roll_bud_rewards() -> Array[String]:
	last_bud_rewards.clear()
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var first := _roll_one_bud(rng)
	if not first.is_empty():
		last_bud_rewards.append(first)

	while last_bud_rewards.size() < _BUD_MAX_REWARDS:
		if rng.randf() >= _BUD_CONTINUE_PROB:
			break
		var next_reward := _roll_one_bud(rng)
		if next_reward.is_empty():
			break
		last_bud_rewards.append(next_reward)

	return last_bud_rewards


func _roll_one_bud(rng: RandomNumberGenerator) -> String:
	var total: int = 0
	for r in _BUD_POOL:
		total += int(r.weight)
	var roll: int = rng.randi_range(1, total)
	var cumul: int = 0
	for r in _BUD_POOL:
		cumul += int(r.weight)
		if roll <= cumul:
			return apply_bud_reward(str(r.id))
	return ""


func get_memory_choice_text() -> String:
	match chapter_one_memory_choice:
		"pursue":
			return "继续追问那道来自深海的呼唤"
		"seal":
			return "先把异常记下并暂时封存"
		_:
			return "尚未做出明确判断"


func get_end_choice_text() -> String:
	match chapter_one_end_choice:
		"pursue":
			return "第一时间回收记录并返航汇报"
		"seal":
			return "记下那句警告，选择先将异常封存"
		_:
			return "带着未解的疑问离开了浅海"


func get_first_reward_card_id() -> String:
	if deck.has("pursue"):
		return "pursue"
	if deck.has("seal"):
		return "seal"
	return ""


func get_first_reward_card_name() -> String:
	var card_id := get_first_reward_card_id()
	if card_id.is_empty():
		return "无"

	var db := get_node_or_null("/root/CardDatabase")
	if db and db.has_method("get_card"):
		var card: Dictionary = db.get_card(card_id)
		return str(card.get("name", card_id))
	return card_id


func build_chapter_one_summary() -> String:
	var lines: Array[String] = []
	lines.append("[center][b]第一章完成：不该出现的电报[/b][/center]")
	lines.append("")
	lines.append("你接受了基地下达的任务，前往浅海中继点确认异常讯号并回收记录。")
	lines.append("在下潜途中，你听见了来自深海的第二次呼唤。")
	lines.append("面对那段记忆残响，你选择了：%s。" % get_memory_choice_text())

	if first_battle_reward_done:
		lines.append("随后你清除了盘踞在中继点附近的浅海异常体。")
		lines.append("战斗结束后，你从残响中带回了一张新卡：%s。" % get_first_reward_card_name())

	lines.append("在中继点残骸里，你找到一段残缺记录：")
	lines.append("“若再次收到来自海底的呼叫，切勿回应。”")
	lines.append("“门并未关闭。”")
	lines.append("返航前，你最终决定：%s。" % get_end_choice_text())
	lines.append("")
	lines.append("下一步：返回基地，整理记录，准备更深一次的下潜。")

	return "\n".join(lines)


func goto_title():
	get_tree().change_scene_to_file("res://scenes/main_manu/MainMenu.tscn")


func goto_base():
	chapter_one_state = "base"
	get_tree().change_scene_to_file("res://scenes/base-new/BaseNew.tscn")


func save_and_exit():
	goto_title()


func goto_dive():
	get_tree().change_scene_to_file("res://scenes/dive/DiveScene.tscn")


func goto_explore():
	get_tree().change_scene_to_file("res://scenes/explore/ExploreScene.tscn")


func goto_end():
	get_tree().change_scene_to_file("res://scenes/end/EndScene.tscn")
	
func goto_ai():
	get_tree().change_scene_to_file("res://scenes/ai/AIFeature.tscn")


# 跳转到意识花苞奖励界面（新增）
func goto_bud_reward() -> void:
	get_tree().change_scene_to_file("res://scenes/reward/RewardScene.tscn")
