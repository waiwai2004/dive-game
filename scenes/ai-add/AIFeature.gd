extends Node

@onready var http_request: HTTPRequest = $HTTPRequest
@onready var rich_text_label: RichTextLabel = $CanvasLayer/RichTextLabel
@onready var card_container: Control = $CanvasLayer/CardContainer
@onready var input_panel: Control = $CanvasLayer/InputPanel
@onready var action_input: LineEdit = $CanvasLayer/InputPanel/ActionInput
@onready var submit_btn: Button = $CanvasLayer/InputPanel/SubmitBtn

var zhipu_api_key: String = ""

func _ready() -> void:
    if typeof(GlobalUI) == TYPE_OBJECT:
        GlobalUI.visible = false
        
    rich_text_label.add_theme_font_size_override("normal_font_size", 24)
    zhipu_api_key = OS.get_environment("ZHIPU_API_KEY")
    if zhipu_api_key.is_empty():
        push_error("环境变量 ZHIPU_API_KEY 未设置！")
        rich_text_label.text = "[color=red]环境变量 ZHIPU_API_KEY 未设置！[/color]"
        return
        
    http_request.request_completed.connect(_on_request_completed)
    
    submit_btn.pressed.connect(_on_submit_pressed)
    
    # 设置前置深海剧情
    var initial_story = """[color=cyan]====== 事件：深海的异响 ======[/color]
你独自驾驶探海舱在漆黑的万米深海中航行。外面的水压令人窒息。
突然，探照灯扫过一个巨大的、类似鱼头人身的不明生物阴影。它并没有直接攻击你，而是用苍白的手指在潜艇外部的玻璃上缓慢地划着圈，发出令人毛骨悚然的惨叫声，无线电中同时还传来了已故队友断断续续的哭泣求救......

这超自然的恐惧让你呼吸急促。
[color=yellow]请在下方输入你的行动来做出应对：[/color]"""
    rich_text_label.text = initial_story

func _on_submit_pressed() -> void:
    var player_action = action_input.text.strip_edges()
    if player_action.is_empty():
        return
        
    input_panel.hide()
    evaluate_action(player_action)

func evaluate_action(action_text: String) -> void:
    print("开始评估玩家行为：", action_text)
    rich_text_label.text = "[color=orange]你的行动: [/color]" + action_text + "\n\n[color=yellow]AI KP 正在判定剧情走势与掷骰...[/color]"
    
    var url = "https://open.bigmodel.cn/api/paas/v4/chat/completions"
    var headers = [
        "Content-Type: application/json",
        "Authorization: Bearer " + zhipu_api_key
    ]
    
    var system_prompt = """你是一个跑团游戏中的AI守秘人（KP），负责驱动故事并判定玩家的心智。
游戏背景：玩家是一名潜航员，身处极深的海底进行探索，周围是令人窒息的幽闭深海。他们之前收到了已故同伴的求救信号，深海中似乎还有古老、低沉的未知低语在引诱他们。
1. 首先，结合【深海、未知恐惧、幽闭潜航】的背景框架，根据玩家的行为，进行一到两段精彩且沉浸式的剧情演绎描述，讲述玩家行动后在深海潜艇内或黑暗海水中发生的故事结果（纯客观或第二人称叙述，强调深海氛围）。
2. 在剧情文本之后，务必使用```json包围并输出你的系统判定。

你需要根据玩家行为，给出三个维度的属性标签。
维度1：【偏善】或【偏恶】
维度2：【激进】或【保守】
维度3：【守序】或【混乱】

你还要为系统即将生成的一张技能卡牌设定其精神和认知负荷以及具体数值：
- 精神负荷：0~10（推荐：低费0~2，中费3~5，高费6~10）
- 认知负荷：1~10（推荐：低费1~3，中费4~6，高费7~10）
- X值：这是卡牌效果中的核心数值变量，1到20的整数。

```json
{
  "维度1": "偏善",
  "维度2": "激进",
  "维度3": "守序",
  "精神负荷": 3,
  "认知负荷": 4,
  "X值": 5,
  "理由": "一句话解释你的判定逻辑"
}
```"""
    
    var body = {
        "model": "glm-4-flash",
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": action_text}
        ],
        "temperature": 0.6
    }
    
    var err = http_request.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
    if err != OK:
        rich_text_label.text += "\n[color=red]网络请求错误[/color]"

func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    if response_code != 200:
        rich_text_label.text = "请求错误\n" + body.get_string_from_utf8()
        return
        
    var json = JSON.new()
    if json.parse(body.get_string_from_utf8()) != OK:
        return
        
    var data = json.get_data()
    if data.has("choices") and data["choices"].size() > 0:
        var raw_content: String = data["choices"][0]["message"]["content"]
        
        var text_part = raw_content
        var json_str = ""
        
        var json_start = raw_content.find("```json")
        if json_start != -1:
            var json_end = raw_content.find("```", json_start + 7)
            if json_end != -1:
                json_str = raw_content.substr(json_start + 7, json_end - (json_start + 7)).strip_edges()
                text_part = raw_content.substr(0, json_start).strip_edges()
        else:
            var fb_start = raw_content.find('{')
            var fb_end = raw_content.rfind('}')
            if (fb_start != -1) and (fb_end != -1):
                json_str = raw_content.substr(fb_start, (fb_end - fb_start) + 1).strip_edges()
                text_part = raw_content.substr(0, fb_start).strip_edges()
                
        rich_text_label.text += "\n\n[color=cyan]====== 场景故事 ======[/color]\n" + text_part + "\n\n"
        
        var ai_json = JSON.new()
        if ai_json.parse(json_str) == OK:
            var result_data = ai_json.get_data()
            rich_text_label.text += "[color=green]判定: " + result_data.get("理由", "") + "[/color]"
            generate_card(result_data)
        else:
            rich_text_label.text += "\n[color=red]JSON解析失败！[/color]\n" + json_str
            generate_card({"维度1":"偏善", "维度2":"激进", "维度3":"守序", "精神负荷":1, "认知负荷":1, "X值":1})
    else:
        rich_text_label.text = "AI 返回格式不对！"

func generate_card(ai_data: Dictionary) -> void:
    var tag1 = ai_data.get("维度1", "偏善")
    var tag2 = ai_data.get("维度2", "激进")
    var tag3 = ai_data.get("维度3", "守序")
    
    if typeof(Game) == TYPE_OBJECT and Game.has_method("add_card"):
        if "player_tags" in Game:
            Game.player_tags.append(tag1)
            Game.player_tags.append(tag2)
            Game.player_tags.append(tag3)
            print("记录玩家标签: ", Game.player_tags)
    
    var prob_a = 0.33 # A类：直白攻击伤害类
    var prob_b = 0.34 # B类：自身防御回复类
    var prob_c = 0.33 # C类：状态控制异常类
    
    # 根据玩家性格对不同种类卡牌的抽取概率进行修正
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
    
    # 根据需求表创建对应的模板分类组（A类/B类/C类）以及对应标签的独有选项
    var a_pool = ["对敌方单体造成 %d 点伤害。" % x]
    var b_pool = ["回复自身 %d 点生命值。" % x, "增加自身 %d 点防御护盾。" % x]
    var c_pool = ["对目标施加 %d 层『深海凝视』（减速）。" % x]
    
    if "偏恶" == tag1:
        a_pool.append("冷酷地撕裂目标，造成 %d 点穿透伤害。" % x)
    if "偏善" == tag1:
        b_pool.append("牺牲认知，为自身提供 %d 点精神庇护。" % x)
        
    if "激进" == tag2:
        a_pool.append("不顾一切地爆发，对所有敌人造成 %d 点伤害。" % x)
    if "保守" == tag2:
        b_pool.append("闭锁心智，获得 %d 点防御并抵御下一次深海侵蚀。" % x)
        
    if "守序" == tag3:
        c_pool.append("制定规则，使自身获得 %d 层『理智锚点』。" % x)
    if "混乱" == tag3:
        c_pool.append("让不可名状充斥脑海，随机给全场施加 %d 层『异变』。" % x)
        
    if r < prob_a:
        t_type = "理解卡(A类)"
        effect = a_pool[randi() % a_pool.size()]
    elif r < prob_a + prob_b:
        t_type = "重构卡(B类)"
        effect = b_pool[randi() % b_pool.size()]
    else:
        t_type = "共情卡(C类)"
        effect = c_pool[randi() % c_pool.size()]
        
    var ai_card_id = "ai_card_" + str(Time.get_ticks_msec())
    
    var available_arts = [
        "res://assets/art/cards/43944f6b22669d538130d73293568073.jpg",
        "res://assets/art/cards/94263a1e9c156ddc5c7d1e2ab78a7b53.jpg",
        "res://assets/art/cards/aa6cf5bc1cce7edc9d5d5d795ca8cf3d.jpg",
        "res://assets/art/cards/attack.png",
        "res://assets/art/cards/bless.png",
        "res://assets/art/cards/ca2994c8126823498642732e30308f81.jpg",
        "res://assets/art/cards/d5437c59e130fbe526170a63d575a5e0.png",
        "res://assets/art/cards/ea6fbd55192c28382eec7c62e36bb91c.png",
        "res://assets/art/cards/relief.png",
        "res://assets/art/cards/resonance.png"
    ]
    var random_art = available_arts[randi() % available_arts.size()]
        
    var card_dict = {
        "id": ai_card_id,
        "name": "意念干涉",
        "type": t_type,
        "cost": ai_data.get("精神负荷", 1),
        "cognition": ai_data.get("认知负荷", 1),
        "description": effect,
        "target": "enemy" if "A类" in t_type else "self",
        "art_illustration_path": random_art
    }
    
    var cd = CardData.new()
    cd.card_id = card_dict["id"]
    cd.card_name = card_dict["name"]
    cd.card_type = card_dict["type"]
    cd.energy_cost = int(card_dict["cost"])
    cd.cognition = int(card_dict["cognition"])
    cd.description = card_dict["description"]
    cd.target_type = card_dict["target"]
    if "art_illustration_path" in cd:
        cd.art_illustration_path = card_dict["art_illustration_path"]
    
    if typeof(CardDatabase) == TYPE_OBJECT:
        if CardDatabase.has_method("get_all_cards"):
            CardDatabase._repo._cards_by_id[cd.card_id] = cd
    
    if typeof(Game) == TYPE_OBJECT and Game.has_method("add_card"):
        Game.add_card(cd.card_id)
        print("卡牌已存入Game.deck：", Game.deck)
        
    show_card_in_ui(card_dict)

func show_card_in_ui(card_dict: Dictionary) -> void:
    for child in card_container.get_children():
        child.queue_free()
        
    var card_scene = load("res://scenes/battle/CardUI.tscn") as PackedScene
    if card_scene:
        var card_ui = card_scene.instantiate()
        card_container.add_child(card_ui)
        card_ui.custom_minimum_size = Vector2(250, 350)
        card_ui.anchors_preset = Control.PRESET_CENTER
        card_ui.position = Vector2(0, 0)
        
        if card_ui.has_method("setup"):
            card_ui.setup(card_dict, 0, self)
            if card_ui.has_method("_refresh_text"):
                card_ui.call("_refresh_text")