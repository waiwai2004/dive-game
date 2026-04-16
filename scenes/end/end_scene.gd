extends Control

@onready var title_label: Label = $TitleLabel
@onready var summary_text: RichTextLabel = $Panel/MarginContainer/SummaryText
@onready var action_button: Button = $ActionButton


func _ready() -> void:
	if has_node("/root/AudioManager"):
		AudioManager.play_bgm_segment("end")

	if has_node("/root/GlobalUI"):
		GlobalUI.set_mode(GlobalUI.MODE_MENU)
		GlobalUI.clear_hint()
		GlobalUI.clear_energy()
		GlobalUI.refresh_stats()

	title_label.text = "第一章完成"
	summary_text.bbcode_enabled = true
	summary_text.text = _build_chapter_one_summary()

	action_button.text = "返回标题"
	if not action_button.pressed.is_connected(_on_action_button_pressed):
		action_button.pressed.connect(_on_action_button_pressed)


func _on_action_button_pressed() -> void:
	Game.reset_run()
	Game.goto_title()


func _build_chapter_one_summary() -> String:
	var lines: Array[String] = []

	lines.append("[center][b]第一章完成：不该出现的电报[/b][/center]")
	lines.append("")
	lines.append("你接受了基地下达的任务，前往浅海中继点确认异常讯号并回收记录。")
	lines.append("在下潜途中，你接触到一段记忆残响，并听见了来自深海的第二次呼唤。")
	lines.append("")
	lines.append("你在残响中的选择是：%s。" % _get_memory_choice_text())

	if Game.first_battle_reward_done:
		lines.append("随后，你清除了盘踞在浅海中继点附近的异常体。")
		lines.append("这场战斗后，你带回了一张新的卡牌：%s。" % _get_reward_card_name())

	lines.append("")
	lines.append("在中继点残骸中，你找到一段残缺记录：")
	lines.append("“若再次收到来自海底的呼叫，切勿回应。”")
	lines.append("“门并未关闭。”")
	lines.append("")
	lines.append("返航前，你最后的决定是：%s。" % _get_end_choice_text())
	lines.append("")
	lines.append("任务结论：")
	lines.append("你已经完成了第一次浅海确认任务，但这封来自深海的电报，显然不是偶然。")
	lines.append("更深处的调查，即将开始。")

	return "\n".join(lines)


func _get_memory_choice_text() -> String:
	if "chapter_one_memory_choice" in Game:
		match String(Game.chapter_one_memory_choice):
			"pursue":
				return "继续追问那道来自深海的呼唤"
			"seal":
				return "先把异常记下并暂时封存"

	if Game.tag_aggressive > Game.tag_orderly:
		return "继续追问那道来自深海的呼唤"
	elif Game.tag_orderly > Game.tag_aggressive:
		return "先把异常记下并暂时封存"

	return "你没有给出明确倾向"


func _get_end_choice_text() -> String:
	if "chapter_one_end_choice" in Game:
		match String(Game.chapter_one_end_choice):
			"pursue":
				return "回收记录，立即返航汇报"
			"seal":
				return "记下警告，先将异常封存"

	return "你带着未解的疑问离开了浅海"


func _get_reward_card_name() -> String:
	if has_node("/root/CardDatabase"):
		if Game.deck.has("pursue"):
			var card_a: Dictionary = CardDatabase.get_card("pursue")
			return str(card_a.get("name", "追问"))
		if Game.deck.has("seal"):
			var card_b: Dictionary = CardDatabase.get_card("seal")
			return str(card_b.get("name", "封存"))
		return "未知卡牌"

	if Game.deck.has("pursue"):
		return "追问"
	if Game.deck.has("seal"):
		return "封存"
	return "未知卡牌"
