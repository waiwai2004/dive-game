extends CanvasLayer

## 记忆碎片事件控制核心
## 负责大模型异步通讯生命周期、选项生成、回合循环与最终卡牌生成。
## 严格遵照团队规范操作内部逻辑与大模型交互。

var _ai_core: GameAICore
var _chat_history: Array = []
var _iteration: int = 1
var _story_background: String = "玩家下潜到了浮光表层，眼前浮现出一块闪烁的残破记忆碎片，里面似乎回荡着旧文明的求救声。"
var _current_tags: Dictionary = {}
var _current_template: String = ""
var _generated_card_id: String = ""

@onready var _story_label: RichTextLabel = $PanelContainer/MarginContainer/VBoxContainer/StoryLabel
@onready var _choices_container: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/ChoicesContainer
@onready var _continue_button: Button = $PanelContainer/MarginContainer/VBoxContainer/ContinueButton
@onready var _loading_label: Label = $PanelContainer/MarginContainer/VBoxContainer/LoadingLabel
@onready var _title_label: Label = $PanelContainer/MarginContainer/VBoxContainer/TitleLabel

func _ready() -> void:
	_ai_core = GameAICore.new()
	add_child(_ai_core)
	
	_ai_core.story_generated.connect(_on_story_generated)
	_ai_core.tags_analyzed.connect(_on_tags_analyzed)
	_ai_core.card_generated.connect(_on_card_generated)
	_ai_core.error_occurred.connect(_on_error_occurred)
	
	_ai_core.image_generated.connect(_on_image_generated)
	_continue_button.pressed.connect(_on_continue_pressed)
	_continue_button.hide()
	
	_start_next_iteration()

func _clear_choices() -> void:
	for child in _choices_container.get_children():
		child.queue_free()
	_continue_button.hide()

func _start_next_iteration() -> void:
	_clear_choices()
	_loading_label.text = "（深海意识回响中...）"
	_loading_label.show()
	_ai_core.generate_story_node(_story_background, _chat_history, _iteration)

## 信号：每次故事段落生成完毕
func _on_story_generated(data: Dictionary) -> void:
	_loading_label.hide()
	var story_text: String = data.get("story", "")
	_story_label.text = "[color=#c0d8d8]" + story_text + "[/color]"
	
	var assistant_msg: Dictionary = {"role": "assistant", "content": JSON.stringify(data)}
	_chat_history.append(assistant_msg)
	
	if _iteration < 3:
		var options: Array = data.get("options", [])
		if options.is_empty():
			# Fallback 容错处理
			_create_choice_button("谨慎地探索四周")
		else:
			for opt in options:
				_create_choice_button(str(opt.get("text", "未知选择")))
	else:
		_continue_button.text = "凝结记忆（结算）"
		_continue_button.show()

func _create_choice_button(text: String) -> void:
	var btn: Button = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 45)
	btn.pressed.connect(_on_choice_made.bind(text))
	_choices_container.add_child(btn)

func _on_choice_made(choice_text: String) -> void:
	var user_msg: Dictionary = {"role": "user", "content": choice_text}
	_chat_history.append(user_msg)
	_story_background = choice_text
	_iteration += 1
	_start_next_iteration()

func _on_continue_pressed() -> void:
	if _iteration == 3:
		# 开始分析玩家抉择结果并生成卡牌
		_iteration += 1
		_clear_choices()
		_story_label.text = "[color=#ffcc00]“记忆的残片正在重新编织，你的倾向已经定型...”[/color]"
		_loading_label.text = "（正在萃取灵魂特质...）"
		_loading_label.show()
		_title_label.text = "—— 认知凝结 ——"
		_ai_core.analyze_player_tags(_chat_history)
	elif _iteration > 3:
		# 退出场景返回探险逻辑
		queue_free()

## 信号：性格标签分析完毕
func _on_tags_analyzed(tags: Dictionary) -> void:
	_current_tags = tags
	_current_template = _ai_core.calculate_card_template_prob(tags)
	
	_loading_label.text = "（正在具象化卡牌物质...）"
	_ai_core.generate_card_stats(_current_template, tags, _chat_history)

## 信号：最终结果（卡牌）生成完毕
func _on_card_generated(card_data: Dictionary) -> void:
	var dynamic_id: String = "memo_card_" + str(Time.get_unix_time_from_system())
	_generated_card_id = dynamic_id
	var mapped_card: Dictionary = {
		"id": dynamic_id,
		"name": card_data.get("name", "无名之物"),
		"type": {"A":"攻击", "B":"减益", "C":"增益"}.get(_current_template, "未知"),
		"cost": int(card_data.get("mental_cost", 1)),
		"cognition": int(card_data.get("cognitive_cost", 1)),
		"desc": card_data.get("description", "一段混沌的幻影。") + "\n(基础值: " + str(card_data.get("value_x", 0)) + ")"
	}
	
	# 先注册基础数据，等待图片后续下载替换（不阻塞当前主流程展示）
	CardData.register_ai_card(dynamic_id, mapped_card)
	
	_loading_label.text = "（正在绘制虚空卡面...）"
	var img_prompt: String = "卡牌名称：" + mapped_card["name"] + "。描述：" + card_data.get("description", "")
	_ai_core.generate_image(img_prompt)

## 信号：图片下载落库完毕
func _on_image_generated(local_path: String) -> void:
	_loading_label.hide()
	
	# 如果生成成功，将本地路径塞入对应的动态卡牌池数据中
	if CardData.dynamic_cards.has(_generated_card_id):
		CardData.dynamic_cards[_generated_card_id]["image_path"] = local_path
		
	var mapped_card: Dictionary = CardData.dynamic_cards[_generated_card_id]
	
	var result_text: String = (
		"你深处的意识共鸣了！\n\n" +
		"性格倾向判定: " + str(_current_tags) + "\n" +
		"卡牌模板: " + _current_template + "\n\n" +
		"获得新卡牌：[b][color=#00ffff]" + mapped_card["name"] + "[/color][/b]\n" +
		"效果: " + mapped_card["desc"] + "\n\n" +
		"[color=#a9a9a9](卡面素材已写入至: " + local_path + ")[/color]"
	)
	
	_story_label.text = result_text
	_continue_button.text = "收束记忆并离开"
	_continue_button.show()

## 信号：网络异常或提取失败回调
func _on_error_occurred(message: String) -> void:
	push_error("MemoryFragment AI Error: " + message)
	_loading_label.hide()
	_story_label.text = "[color=red]与意识深海的链接中断了。[/color]\n(" + message + ")"
	_continue_button.text = "离开"
	_continue_button.show()
