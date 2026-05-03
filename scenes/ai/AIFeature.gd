extends Node

@onready var http_request: HTTPRequest = $HTTPRequest
@onready var story_text: RichTextLabel = $CanvasLayer/LeftPanel/StoryText
@onready var right_panel: Control = $CanvasLayer/RightPanel
@onready var question_text: RichTextLabel = $CanvasLayer/RightPanel/QuestionText
@onready var options_container: VBoxContainer = $CanvasLayer/RightPanel/OptionsContainer
@onready var prev_btn: Button = $CanvasLayer/LeftPanel/Pagination/PrevBtn
@onready var next_btn: Button = $CanvasLayer/LeftPanel/Pagination/NextBtn
@onready var page_label: Label = $CanvasLayer/LeftPanel/Pagination/PageLabel
@onready var simple_btn: Button = $CanvasLayer/TopRightSettings/WordCountButtons/SimpleBtn
@onready var default_btn: Button = $CanvasLayer/TopRightSettings/WordCountButtons/DefaultBtn
@onready var detail_btn: Button = $CanvasLayer/TopRightSettings/WordCountButtons/DetailBtn
@onready var loading_panel: ColorRect = $CanvasLayer/LoadingPanel
@onready var loading_label: Label = $CanvasLayer/LoadingPanel/LoadingLabel

var zhipu_api_key: String = "a31b007061814e729b74a355965dd4b3.pqErprnEUvMIyjwO"

var max_loops: int = 3
var current_step: int = 1
var text_limit: int = 300

var story_pages: Array = []
var current_page: int = 0
var accumulated_history: String = ""
var last_action: String = ""

var is_requesting: bool = false

func _ready() -> void:
	# 设置 GlobalUI 为故事模式，并设为可见
	if typeof(GlobalUI) == TYPE_OBJECT:
		GlobalUI.visible = true
		GlobalUI.set_mode(GlobalUI.MODE_BASE)
	
	#zhipu_api_key = OS.get_environment("ZHIPU_API_KEY")
	if zhipu_api_key.is_empty():
		push_error("环境变量 ZHIPU_API_KEY 未设置！")
		story_text.text = "[color=red]环境变量 ZHIPU_API_KEY 未设置！[/color]"
		return
		
	http_request.request_completed.connect(_on_request_completed)
	
	prev_btn.pressed.connect(_on_prev_pressed)
	next_btn.pressed.connect(_on_next_pressed)
	
	simple_btn.pressed.connect(_on_simple_btn_pressed)
	default_btn.pressed.connect(_on_default_btn_pressed)
	detail_btn.pressed.connect(_on_detail_btn_pressed)
	_update_button_states()
	
	right_panel.modulate.a = 0
	setup_initial_story()

func setup_initial_story() -> void:
	var starting_stories = [
		{
			"title": "忧郁的小王同学",
			"story": "寂静的校园里，你远远地注意到了那个孩子。穿着校服，留着不过眉的短发。一个人靠在巨大的礁石旁，背对着你。你走近一看，却发现，那是一棵白桦树。察觉到你的靠近，树干睁开了血淋淋的眼睛。“我好痛我好痛我好痛我好痛我好痛”白桦树嘶吼着，一只只眼睛张开了血盆大口。“看看我看看我看看我。”“能不能，好好看着我。”",
			"question": "你要怎么做？",
			"options": [
				{"text": "杀死白桦树", "desc": "站在那里的是人还是树，已经不重要了。\n此刻你想做的，只是结束一个痛苦的生命。", "tag": "偏善"},
				{"text": "我会注视着你", "desc": "你不知道她遭遇了什么，但“注视”是一\n件很简单的事情。", "tag": "守序"},
				{"text": "挖出他的眼睛", "desc": "眼睛是白桦树的伤口。\n小王同学，你希望她能痊愈。", "tag": "激进"}
			]
		},
		{
			"title": "学术垃圾制造工",
			"story": "你坐在一张书桌前，手中敲着键盘，修改电脑上的论文。发着白光的屏幕闪了闪，变成了黑屏。你焦急地拍打着电脑，因为你想起来你刚才的修改没保存。这时，电脑亮了，上面密密麻麻地写着“垃圾垃圾垃圾垃圾垃圾”。你没有在意。拼命按着重启键。“这里还要修改，这里分析不够，这里格式不对，这里......”",
			"question": "你要怎么做？",
			"options": [
				{"text": "自己的事情自己做", "desc": "我的论文一定还在临时文件里。", "tag": "保守"},
				{"text": "让出座位", "desc": "然后和无面人说：“不管你是人是鬼，帮\n我把论文写了再走。”", "tag": "守序"},
				{"text": "掀翻书桌", "desc": "“一切都是天意。”", "tag": "混乱"}
			]
		},
		{
			"title": "响铃的电话机",
			"story": "“叮铃铃，叮铃铃”\n学校的电话亭里，一个电话机响了。\n你路过这里的时候，它正发出尖锐的铃声。\n四周无人，你接起电话。\n电话那头只有水滴的声音。\n“滴答，滴答，滴答”\n声音突然变得嘈杂，你听见有人的声音模糊地传来。\n“妈，我今天给你打电话，怎么是别人接的？”\n“对面什么也没说。”\n“我只听到了滴答的水滴声。”\n“你和我听到的一样吗？”",
			"question": "你要怎么做？",
			"options": [
				{"text": "保持沉默", "desc": "或许对面没在问你呢？\n你心怀侥幸地想。", "tag": "保守"},
				{"text": "实话实说", "desc": "你诚恳的回答没有得到“它”的赞许。\n因为你听到了身后传来了黏腻的水声。\n“那你就和我一样了。”", "tag": "守序"},
				{"text": "胡言乱语", "desc": "“啊对对对，我是你妈，儿子好啊，今天\n在学校咋样。”\n对面没有回答。\n“嘟——”电话被挂断了", "tag": "混乱"}
			]
		}
	]
	
	var chosen = starting_stories[randi() % starting_stories.size()]
	
	current_step = 1
	var s_text = chosen["story"]
	story_pages = split_text_into_pages(s_text, 600)
	current_page = 0
	accumulated_history += "开局事件 (" + chosen["title"] + ")：" + s_text + "\n"
	
	question_text.text = chosen["question"]
	
	for child in options_container.get_children():
		child.queue_free()
		
	for opt in chosen["options"]:
		var btn = Button.new()
		var display_text = opt["text"] + "\n" + opt["desc"]
		btn.text = display_text
		btn.custom_minimum_size = Vector2(0, 100)
		btn.add_theme_font_size_override("font_size", 20)
		btn.autowrap_mode = 3 # TextServer.AUTOWRAP_WORD_SMART
		
		var style_n = StyleBoxFlat.new()
		style_n.bg_color = Color(0.1, 0.1, 0.2, 0.8)
		style_n.border_width_bottom = 2
		style_n.border_color = Color(0.5, 0.5, 0.8)
		btn.add_theme_stylebox_override("normal", style_n)
		
		var style_h = StyleBoxFlat.new()
		style_h.bg_color = Color(0.3, 0.3, 0.6, 0.9)
		btn.add_theme_stylebox_override("hover", style_h)
		
		btn.pressed.connect(func(): _on_initial_option_selected(opt))
		options_container.add_child(btn)

	update_page_display()
	show_right_panel()

func _on_initial_option_selected(opt: Dictionary) -> void:
	if is_requesting: return
	hide_right_panel()
	
	var action_summary = opt["text"] + " (选项倾向标签: " + opt["tag"] + "，玩家动机: " + opt["desc"].replace("\n", "") + ")"
	last_action = action_summary
	accumulated_history += "玩家选择：" + action_summary + "\n"
	
	current_step += 1
	request_story_step(action_summary)

func _on_simple_btn_pressed() -> void:
	text_limit = 100
	_update_button_states()

func _on_default_btn_pressed() -> void:
	text_limit = 300
	_update_button_states()

func _on_detail_btn_pressed() -> void:
	text_limit = 500
	_update_button_states()

func _update_button_states() -> void:
	simple_btn.button_pressed = (text_limit == 100)
	default_btn.button_pressed = (text_limit == 300)
	detail_btn.button_pressed = (text_limit == 500)

func _on_prev_pressed() -> void:
	if current_page > 0:
		current_page -= 1
		update_page_display()

func _on_next_pressed() -> void:
	if current_page < story_pages.size() - 1:
		current_page += 1
		update_page_display()

func update_page_display() -> void:
	if story_pages.is_empty():
		page_label.text = "0 / 0"
		return
		
	page_label.text = str(current_page + 1) + " / " + str(story_pages.size())
	story_text.text = story_pages[current_page]
	
	prev_btn.disabled = (current_page == 0)
	next_btn.disabled = (current_page == story_pages.size() - 1)
	
	if current_page == story_pages.size() - 1:
		if right_panel.modulate.a < 0.5:
			show_right_panel()

func show_right_panel() -> void:
	var tween = create_tween()
	tween.tween_property(right_panel, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE)

func hide_right_panel() -> void:
	right_panel.modulate.a = 0.0

func _on_option_selected(option_text: String) -> void:
	if is_requesting: return
	hide_right_panel()
	last_action = option_text
	accumulated_history += "玩家选择：" + last_action + "\n"
	
	if current_step >= max_loops:
		# If it was the final choice on step 3, move to step 4 for resolution
		current_step += 1
		request_story_step(last_action)
	else:
		current_step += 1
		request_story_step(last_action)

func split_text_into_pages(text: String, chars_per_page: int = 600) -> Array:
	var arr = []
	var paragraphs = text.split("\n", false)
	var current_str = ""
	for p in paragraphs:
		var clean_p = p.strip_edges()
		if clean_p.is_empty(): continue
		
		# 处理长段落不换行的情况
		while clean_p.length() > chars_per_page:
			var chunk = clean_p.left(chars_per_page)
			if current_str.length() > 0:
				arr.append(current_str.strip_edges())
				current_str = ""
			arr.append(chunk)
			clean_p = clean_p.substr(chars_per_page)
			
		if current_str.length() + clean_p.length() > chars_per_page and current_str.length() > 0:
			arr.append(current_str.strip_edges())
			current_str = clean_p + "\n\n"
		else:
			current_str += clean_p + "\n\n"

	if current_str.length() > 0:
		arr.append(current_str.strip_edges())
	return arr

func request_story_step(action_text: String) -> void:
	is_requesting = true
	
	if current_step <= max_loops:
		loading_label.text = "AI KP 正在构思事件 (阶段 " + str(current_step) + "/" + str(max_loops) + ")...\n" + action_text
	else:
		loading_label.text = "AI KP 正在判定剧情走势与生成技能卡牌...\n" + action_text
	loading_panel.show()
	right_panel.modulate.a = 0.0
	
	var url = "https://open.bigmodel.cn/api/paas/v4/chat/completions"
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + zhipu_api_key
	]
	
	for child in options_container.get_children():
		child.queue_free()
		
	var system_prompt = "你是一个深海探险的AI守秘人（KP）。当前是第 " + str(current_step) + " / " + str(max_loops) + " 个互动环节。\n前情提要：\n" + accumulated_history + "\n"
	
	if current_step <= max_loops:
		system_prompt += "描述玩家上一个选择后发生的剧情（约" + str(text_limit) + "字）。"
		system_prompt += "然后抛出一个关键问题，并提供2到3个具体选项。\n"
		system_prompt += "重要：所有文本必须写在单行内，如果有换行请使用转义字符 \\n，绝对不要产生真实换行。务必包围在 ```json 中，返回：story, question, options（字符串数组）。\n"
		system_prompt += "范例：\n```json\n{\n  \"story\": \"剧情...\",\n  \"question\": \"你要怎么做？\",\n  \"options\": [\"选项A\", \"选项B\"]\n}\n```"
	else:
		system_prompt += "这是最终阶段！请给出大结局的文字描述（约" + str(text_limit) + "字）。"
		system_prompt += "并根据玩家前面所有的选择评估性格，生成一张相关的技能卡牌。\n"
		system_prompt += "维度1从【偏善,偏恶】选；维度2从【激进,保守】选；维度3从【守序,混乱】选。X值是1~20的整数。\n"
		system_prompt += "重要：所有文本必须写在单行内，如果有换行请使用转义字符 \\n，绝对不要产生真实换行。务必包围在 ```json 中，返回：story, 维度1, 维度2, 维度3, 精神负荷(1~10), 认知负荷(1~10), X值。\n"
		system_prompt += "范例：\n```json\n{\n  \"story\": \"结局...\",\n  \"维度1\": \"偏善\",\n  \"维度2\": \"激进\",\n  \"维度3\": \"守序\",\n  \"精神负荷\": 4,\n  \"认知负荷\": 5,\n  \"X值\": 10\n}\n```"

	var body = {
		"model": "glm-4-flash",
		"messages": [
			{"role": "system", "content": system_prompt},
			{"role": "user", "content": "行动摘要：" + action_text}
		],
		"temperature": 0.2
	}
	
	var err = http_request.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		is_requesting = false
		loading_panel.hide()
		story_text.text = "[color=red]请求失败[/color]"

func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	is_requesting = false
	loading_panel.hide()
	
	if response_code != 200:
		story_text.text = "网络错误\n" + body.get_string_from_utf8()
		return
		
	var json = JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK: return
		
	var data = json.get_data()
	if data.has("choices") and data["choices"].size() > 0:
		var raw = data["choices"][0]["message"]["content"]
		var json_str = raw
		var lower_raw = raw.to_lower()
		var start = lower_raw.find("```json")
		if start != -1:
			var end = lower_raw.find("```", start + 7)
			if end != -1:
				json_str = raw.substr(start + 7, end - (start + 7)).strip_edges()
		else:
			var fs = raw.find('{')
			var fe = raw.rfind('}')
			if fs != -1 and fe != -1: json_str = raw.substr(fs, fe - fs + 1)

		# 修复大模型偶尔在字符串末尾生成的句号导致JSON解析失败
		json_str = json_str.replace("\".\n", "\",\n").replace("\"。\n", "\",\n").replace("\". \n", "\",\n").replace("\"。 \n", "\",\n")

		var ai_json = JSON.new()
		if ai_json.parse(json_str) == OK:
			var res = ai_json.get_data()
			var s_text = res.get("story", "......")
			story_pages = split_text_into_pages(s_text, 600)
			current_page = 0
			accumulated_history += "剧情：" + s_text.left(80) + "...\n"
			
			if current_step <= max_loops:
				question_text.text = res.get("question", "接下来怎么做？")
				var opts = res.get("options", ["继续"])
				
				# 防呆设计：如果大模型把多个选项写成了一个长字符串列表（例如 ["A选项, B选项"]），强制拆分开
				if typeof(opts) == TYPE_STRING:
					opts = [opts]
				if typeof(opts) == TYPE_ARRAY and opts.size() == 1:
					var first_opt = str(opts[0])
					if "”," in first_opt or "”，" in first_opt or "\",\"" in first_opt:
						opts = first_opt.replace("”,“", ",").replace("\",\"", ",").split(",")
					elif "，" in first_opt:
						opts = first_opt.split("，")
						
				for opt_str in opts:
					var btn = Button.new()
					var clean_opt = str(opt_str).replace("\"", "").replace("”", "").replace("“", "").strip_edges()
					btn.text = clean_opt
					btn.custom_minimum_size = Vector2(0, 60)
					btn.add_theme_font_size_override("font_size", 22)
					btn.autowrap_mode = 3 # TextServer.AUTOWRAP_WORD_SMART，允许按钮文字自动换行
					
					var style_n = StyleBoxFlat.new()
					style_n.bg_color = Color(0.1, 0.1, 0.2, 0.8)
					style_n.border_width_bottom = 2
					style_n.border_color = Color(0.5, 0.5, 0.8)
					btn.add_theme_stylebox_override("normal", style_n)
					
					var style_h = StyleBoxFlat.new()
					style_h.bg_color = Color(0.3, 0.3, 0.6, 0.9)
					btn.add_theme_stylebox_override("hover", style_h)
					
					btn.pressed.connect(func(): _on_option_selected(clean_opt))
					options_container.add_child(btn)
			else:
				question_text.text = "[color=green]结局评估已完成。[/color]"
				var lbl = Label.new()
				lbl.text = "获得性格向性: " + res.get("维度1", "偏善") + ", " + res.get("维度2", "保守") + ", " + res.get("维度3", "守序")
				lbl.add_theme_font_size_override("font_size", 24)
				options_container.add_child(lbl)
				generate_card(res)
			update_page_display()
		else:
			story_text.text = "JSON解析失败\n\n返回内容为：\n" + json_str + "\n\n错误信息：" + ai_json.get_error_message()
	else:
		story_text.text = "无数据返回"

func generate_card(ai_data: Dictionary) -> void:
	var tag1 = ai_data.get("维度1", "偏善")
	var tag2 = ai_data.get("维度2", "激进")
	var tag3 = ai_data.get("维度3", "守序")
	
	var prob_a = 0.33
	var prob_b = 0.34
	var prob_c = 0.33
	
	if tag1 == "偏善":
		prob_a -= 0.15; prob_b += 0.10; prob_c += 0.05
	elif tag1 == "偏恶":
		prob_a += 0.15; prob_b -= 0.10; prob_c -= 0.05
	if tag2 == "激进":
		prob_a += 0.15; prob_b -= 0.10; prob_c -= 0.05
	elif tag2 == "保守":
		prob_a -= 0.15; prob_b += 0.15
	if tag3 == "守序":
		prob_c += 0.15; prob_a -= 0.15
	elif tag3 == "混乱":
		prob_c += 0.15; prob_b -= 0.15
		
	var r = randf()
	var t_type = ""
	var effect = ""
	var x = int(ai_data.get("X值", 1))
	
	var a_pool = [{"desc": "对敌方单体造成 %d 点伤害。" % x, "key": "damage", "val": x}]
	var b_pool = [{"desc": "回复自身 %d 点生命值。" % x, "key": "heal_hp", "val": x}, {"desc": "增加自身 %d 点防御护盾。" % x, "key": "block", "val": x}]
	var c_pool = [{"desc": "对目标施加 %d 层虚弱。" % x, "key": "apply_weak", "val": x}]
	
	if "偏恶" == tag1: 
		a_pool.append({"desc": "冷酷地撕裂目标，造成 %d 点伤害。" % x, "key": "damage", "val": x})
		c_pool.append({"desc": "释放深海神经毒素，施加 %d 层『麻痹』。" % x, "key": "apply_paralysis", "val": x})
	if "偏善" == tag1: 
		b_pool.append({"desc": "牺牲认知，为自身提供 %d 点存在值回复。" % x, "key": "san_heal", "val": x})
		b_pool.append({"desc": "生命之光闪耀，赋予自身 %d 层『残存』。" % x, "key": "apply_survival", "val": x})
	if "激进" == tag2: 
		a_pool.append({"desc": "不顾一切地爆发，对所有敌人造成 %d 点伤害。" % x, "key": "damage", "val": x})
	if "保守" == tag2: 
		b_pool.append({"desc": "闭锁心智，获得 %d 点防御。" % x, "key": "block", "val": x})
		b_pool.append({"desc": "使自身变得无坚不摧，获得 %d 层『坚韧』。" % x, "key": "apply_resilience", "val": x})
	if "守序" == tag3: 
		c_pool.append({"desc": "制定规则，使自身获得 %d 层精神负荷。" % x, "key": "gain_energy", "val": x})
	if "混乱" == tag3: 
		c_pool.append({"desc": "让不可名状充斥脑海，对敌人施加 %d 层『虚弱』。" % x, "key": "apply_weak", "val": x})
		c_pool.append({"desc": "扭曲敌方感知，施加 %d 层『混乱』。" % x, "key": "apply_confusion", "val": x})
		
	var chosen_effect = {}
	if r < prob_a:
		t_type = "理解卡(A类)"
		chosen_effect = a_pool[randi() % a_pool.size()]
	elif r < prob_a + prob_b:
		t_type = "重构卡(B类)"
		chosen_effect = b_pool[randi() % b_pool.size()]
	else:
		t_type = "共情卡(C类)"
		chosen_effect = c_pool[randi() % c_pool.size()]
		
	effect = chosen_effect["desc"]
	
	var available_arts = [
		"res://assets/art/cards/43944f6b22669d538130d73293568073.jpg",
		"res://assets/art/cards/94263a1e9c156ddc5c7d1e2ab78a7b53.jpg",
		"res://assets/art/cards/attack.png",
        "res://assets/art/cards/bless.png"
	]
	
	var card_dict = {
		"id": "ai_card_" + str(Time.get_ticks_msec()),
		"name": "意念干涉",
		"type": t_type,
		"cost": ai_data.get("精神负荷", 1),
		"cognition": ai_data.get("认知负荷", 1),
		"description": chosen_effect.get("desc", ""),
		"effect_key": chosen_effect.get("key", ""),
		"effect_value": chosen_effect.get("val", 0),
		"effect_value_2": chosen_effect.get("val2", 0),
		"target": "enemy" if "A类" in t_type else "self",
		"art_illustration_path": available_arts[randi() % available_arts.size()]
	}
	
	# 将卡牌实例化并存入数据库与玩家牌库
	var cd = CardData.new()
	cd.card_id = card_dict["id"]
	cd.card_name = card_dict["name"]
	cd.card_type = card_dict["type"]
	cd.energy_cost = int(card_dict["cost"])
	cd.cognition = int(card_dict["cognition"])
	cd.description = card_dict["description"]
	cd.effect_key = card_dict["effect_key"]
	cd.effect_value = card_dict["effect_value"]
	cd.effect_value_2 = card_dict["effect_value_2"]
	cd.target_type = card_dict["target"]
	if "art_illustration_path" in cd:
		cd.art_illustration_path = card_dict["art_illustration_path"]
		
	if typeof(CardDatabase) == TYPE_OBJECT and CardDatabase.has_method("get_all_cards"):
		CardDatabase._repo._cards_by_id[cd.card_id] = cd
		
	print("已生成AI卡牌：", cd.card_id)
	
	_show_card_scene(card_dict)

func _show_card_scene(card_dict: Dictionary) -> void:
	print("[AIFeature] _show_card_scene called with card: ", card_dict.get("name", "unknown"))
	var show_card_scene = load("res://scenes/showcard/ShowCard.tscn") as PackedScene
	if show_card_scene == null:
		push_error("[AIFeature] Failed to load ShowCard.tscn")
		return
	var show_card = show_card_scene.instantiate()
	if show_card == null:
		push_error("[AIFeature] Failed to instantiate ShowCard")
		return
	print("[AIFeature] ShowCard instantiated, calling setup...")
	show_card.setup(card_dict)
	var old_scene = get_tree().current_scene
	get_tree().root.add_child(show_card)
	get_tree().current_scene = show_card
	print("[AIFeature] Scene switched to ShowCard")
	if old_scene:
		old_scene.queue_free()
