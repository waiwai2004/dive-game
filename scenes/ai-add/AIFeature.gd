extends Node

@onready var http_request: HTTPRequest = $HTTPRequest
@onready var story_text: RichTextLabel = $CanvasLayer/LeftPanel/StoryText
@onready var right_panel: Control = $CanvasLayer/RightPanel
@onready var question_text: RichTextLabel = $CanvasLayer/RightPanel/QuestionText
@onready var options_container: VBoxContainer = $CanvasLayer/RightPanel/OptionsContainer
@onready var prev_btn: Button = $CanvasLayer/LeftPanel/Pagination/PrevBtn
@onready var next_btn: Button = $CanvasLayer/LeftPanel/Pagination/NextBtn
@onready var page_label: Label = $CanvasLayer/LeftPanel/Pagination/PageLabel
@onready var word_count_option: OptionButton = $CanvasLayer/TopRightSettings/WordCountOption
@onready var loading_panel: ColorRect = $CanvasLayer/LoadingPanel
@onready var loading_label: Label = $CanvasLayer/LoadingPanel/LoadingLabel
@onready var card_container: Control = $CanvasLayer/CardContainer

var zhipu_api_key: String = ""

var max_loops: int = 3
var current_step: int = 1
var text_limit: int = 300

var story_pages: Array = []
var current_page: int = 0
var accumulated_history: String = ""
var last_action: String = ""

var is_requesting: bool = false

func _ready() -> void:
    if typeof(GlobalUI) == TYPE_OBJECT:
        GlobalUI.visible = false
        
    zhipu_api_key = OS.get_environment("ZHIPU_API_KEY")
    if zhipu_api_key.is_empty():
        push_error("环境变量 ZHIPU_API_KEY 未设置！")
        story_text.text = "[color=red]环境变量 ZHIPU_API_KEY 未设置！[/color]"
        return
        
    http_request.request_completed.connect(_on_request_completed)
    
    prev_btn.pressed.connect(_on_prev_pressed)
    next_btn.pressed.connect(_on_next_pressed)
    
    word_count_option.add_item("默认 (300字)", 0)
    word_count_option.add_item("简易 (100字)", 1)
    word_count_option.add_item("细致 (500字)", 2)
    word_count_option.select(0)
    word_count_option.item_selected.connect(_on_word_count_changed)
    
    right_panel.modulate.a = 0
    request_story_step("开始深海下潜，四周漆黑一片。")

func _on_word_count_changed(index: int) -> void:
    if index == 0: text_limit = 300
    elif index == 1: text_limit = 100
    else: text_limit = 500

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

func split_text_into_pages(text: String, chars_per_page: int = 140) -> Array:
    var arr = []
    var paragraphs = text.split("\n", false)
    var current_str = ""
    for p in paragraphs:
        var clean_p = p.strip_edges()
        if clean_p.is_empty(): continue
        
        if current_str.length() + clean_p.length() > chars_per_page and current_str.length() > 0:
            arr.append(current_str.strip_edges())
            current_str = clean_p + "\n\n"
        else:
            current_str += clean_p + "\n\n"
            
    if current_str.strip_edges().length() > 0:
        arr.append(current_str.strip_edges())
        
    return arr if arr.size() > 0 else ["..."]

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
        system_prompt += "务必包围在 ```json 中，返回：story, question, options（字符串数组）。\n"
        system_prompt += "范例：\n```json\n{\n  \"story\": \"剧情...\",\n  \"question\": \"你要怎么做？\",\n  \"options\": [\"选项A\", \"选项B\"]\n}\n```"
    else:
        system_prompt += "这是最终阶段！请给出大结局的文字描述（约" + str(text_limit) + "字）。"
        system_prompt += "并根据玩家前面所有的选择评估性格，生成一张相关的技能卡牌。\n"
        system_prompt += "维度1从【偏善,偏恶】选；维度2从【激进,保守】选；维度3从【守序,混乱】选。X值是1~20的整数。\n"
        system_prompt += "务必包围在 ```json 中，返回：story, 维度1, 维度2, 维度3, 精神负荷(1~10), 认知负荷(1~10), X值。\n"
        system_prompt += "范例：\n```json\n{\n  \"story\": \"结局...\",\n  \"维度1\": \"偏善\",\n  \"维度2\": \"激进\",\n  \"维度3\": \"守序\",\n  \"精神负荷\": 4,\n  \"认知负荷\": 5,\n  \"X值\": 10\n}\n```"

    var body = {
        "model": "glm-4-flash",
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": "行动摘要：" + action_text}
        ],
        "temperature": 0.6
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
        var start = raw.find("```json")
        if start != -1:
            var end = raw.find("```", start + 7)
            if end != -1:
                json_str = raw.substr(start + 7, end - (start + 7)).strip_edges()
        else:
            var fs = raw.find('{')
            var fe = raw.rfind('}')
            if fs != -1 and fe != -1: json_str = raw.substr(fs, fe - fs + 1)
                
        var ai_json = JSON.new()
        if ai_json.parse(json_str) == OK:
            var res = ai_json.get_data()
            var s_text = res.get("story", "......")
            story_pages = split_text_into_pages(s_text, 140)
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
            story_text.text = "JSON解析失败"
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
    
    var a_pool = ["对敌方单体造成 %d 点伤害。" % x]
    var b_pool = ["回复自身 %d 点生命值。" % x, "增加自身 %d 点防御护盾。" % x]
    var c_pool = ["对目标施加 %d 层『深海凝视』（减速）。" % x]
    
    if "偏恶" == tag1: a_pool.append("冷酷地撕裂目标，造成 %d 点穿透伤害。" % x)
    if "偏善" == tag1: b_pool.append("牺牲认知，为自身提供 %d 点精神庇护。" % x)
    if "激进" == tag2: a_pool.append("不顾一切地爆发，对所有敌人造成 %d 点伤害。" % x)
    if "保守" == tag2: b_pool.append("闭锁心智，获得 %d 点防御并抵御下一次深海侵蚀。" % x)
    if "守序" == tag3: c_pool.append("制定规则，使自身获得 %d 层『理智锚点』。" % x)
    if "混乱" == tag3: c_pool.append("让不可名状充斥脑海，随机施加 %d 层『异变』。" % x)
        
    if r < prob_a:
        t_type = "理解卡(A类)"
        effect = a_pool[randi() % a_pool.size()]
    elif r < prob_a + prob_b:
        t_type = "重构卡(B类)"
        effect = b_pool[randi() % b_pool.size()]
    else:
        t_type = "共情卡(C类)"
        effect = c_pool[randi() % c_pool.size()]
        
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
        "description": effect,
        "target": "enemy" if "A类" in t_type else "self",
        "art_illustration_path": available_arts[randi() % available_arts.size()]
    }
    show_card_in_ui(card_dict)

func show_card_in_ui(card_dict: Dictionary) -> void:
    card_container.show()
    for child in card_container.get_children(): child.queue_free()
    var scene = load("res://scenes/battle/CardUI.tscn") as PackedScene
    if scene:
        var card_ui = scene.instantiate()
        card_container.add_child(card_ui)
        card_ui.custom_minimum_size = Vector2(250, 350)
        card_ui.anchors_preset = Control.PRESET_CENTER
        card_ui.position = Vector2(0, 0)
        if card_ui.has_method("setup"):
            card_ui.setup(card_dict, 0, self)
            if card_ui.has_method("_refresh_text"): card_ui.call("_refresh_text")

func play_card(card_idx, card_dict=null):
    print("卡牌展示场景中不允许打出卡牌: ", card_idx)
