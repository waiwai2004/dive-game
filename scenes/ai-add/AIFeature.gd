extends Node

@onready var http_request: HTTPRequest = $HTTPRequest

var zhipu_api_key: String = ""

func _ready() -> void:
    zhipu_api_key = OS.get_environment("ZHIPU_API_KEY")
    if zhipu_api_key.is_empty():
        push_error("环境变量 ZHIPU_API_KEY 未设置！")
        return
        
    http_request.request_completed.connect(_on_request_completed)
    
    # 测试用例：传入一个测试用户的行为
    var player_action = "我看到路上有一只受伤的猫，我决定立刻冲上去用尽全力保护它并把它带回家。"
    evaluate_action(player_action)

func evaluate_action(action_text: String) -> void:
    print("开始评估玩家行为：", action_text)
    
    var url = "https://open.bigmodel.cn/api/paas/v4/chat/completions"
    var headers = [
        "Content-Type: application/json",
        "Authorization: Bearer " + zhipu_api_key
    ]
    
    var system_prompt = """
你是一个游戏中的AI助手，并且扮演故事中的判定系统。
你需要根据玩家在一件事情中的行为描述给予三个维度的属性标签。
维度1：【偏善】或【偏恶】
维度2：【激进】或【保守】
维度3：【守序】或【混乱】

你还要为系统即将生成的一张卡牌设定其费用和具体数值。
卡牌数值属性包括：
- 精神负荷：0~10（推荐：低费0~2，中费3~5，高费6~10）
- 认知负荷：1~10（推荐：低费1~3，中费4~6，高费7~10）
- X值：这是卡牌效果中的具体数值变量（比如造成X点伤害，恢复X点属性，叠加X层buff），通常是 1 到 20 的整数。

请直接以严格的JSON格式进行输出，不要包含任何多余的话语和Markdown语法（比如不要包在```json里）：
{
  "维度1": "偏善",
  "维度2": "激进",
  "维度3": "守序",
  "精神负荷": 3,
  "认知负荷": 4,
  "X值": 5,
  "理由": "简短的一句话解释原因"
}
"""
    
    var body = {
        "model": "glm-4-flash",
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": action_text}
        ],
        "temperature": 0.5
    }
    
    var json_string = JSON.stringify(body)
    var err = http_request.request(url, headers, HTTPClient.METHOD_POST, json_string)
    if err != OK:
        push_error("发送HTTP请求失败: " + str(err))

func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    if response_code != 200:
        push_error("请求失败, 状态码: " + str(response_code))
        print("Body: ", body.get_string_from_utf8())
        return
        
    var json = JSON.new()
    var err = json.parse(body.get_string_from_utf8())
    if err != OK:
        push_error("JSON解析失败: " + json.get_error_message())
        return
        
    var data = json.get_data()
    if data.has("choices") and data["choices"].size() > 0:
        var content: String = data["choices"][0]["message"]["content"]
        content = content.replace("```json", "").replace("```", "").strip_edges()
        var ai_json = JSON.new()
        if ai_json.parse(content) == OK:
            var result_data = ai_json.get_data()
            print("AI返回结果: ", result_data)
            generate_card(result_data)
        else:
            push_error("无法解析AI返回的内容为JSON: " + content)
    else:
        push_error("AI返回数据格式不正确")

func generate_card(ai_data: Dictionary) -> void:
    var tag1 = ai_data.get("维度1", "偏善")
    var tag2 = ai_data.get("维度2", "激进")
    var tag3 = ai_data.get("维度3", "守序")
    
    # 基础概率
    var prob_a = 0.33
    var prob_b = 0.34
    var prob_c = 0.33
    
    # 计算概率修正
    # 偏善: A-20%, B+10%, C+10%   |   偏恶: A+20%, B-10%, C-10%
    if tag1 == "偏善":
        prob_a -= 0.20; prob_b += 0.10; prob_c += 0.10
    elif tag1 == "偏恶":
        prob_a += 0.20; prob_b -= 0.10; prob_c -= 0.10
        
    # 激进: A+5%, B+5%, C-10%    |   保守: A+5%, C-5%
    if tag2 == "激进":
        prob_a += 0.05; prob_b += 0.05; prob_c -= 0.10
    elif tag2 == "保守":
        prob_a += 0.05; prob_c -= 0.05
        
    # 守序: B+10%, C-10%         |   混乱: 不变
    if tag3 == "守序":
        prob_b += 0.10; prob_c -= 0.10
        
    print("最终概率 -> A类(伤害):%.0f%% B类(属性):%.0f%% C类(buff):%.0f%%" % [prob_a*100, prob_b*100, prob_c*100])
    
    var r = randf()
    var template_type = ""
    var category = ""
    if r < prob_a:
        template_type = "A类"
        category = "理解卡（攻击）"
    elif r < prob_a + prob_b:
        template_type = "B类"
        category = "重构卡（改变属性）"
    else:
        template_type = "C类"
        category = "共情卡（增益/减益）"
        
    print("抽中模板类型: ", template_type, " (", category, ")")
    
    var card_data = {
        "名字": "AI融合卡牌",
        "类别": category,
        "精神负荷": ai_data.get("精神负荷", 1),
        "认知负荷": ai_data.get("认知负荷", 1),
        "效果模板": template_type,
        "X值": ai_data.get("X值", 1)
    }
    
    print("生成的新卡牌数据：\n", card_data)
