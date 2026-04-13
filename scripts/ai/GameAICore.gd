class_name GameAICore extends Node

## 智谱大模型核心通信组件
## 原生 GDScript 实现的大模型请求处理，负责与智谱 API 进行非阻塞异步通信。
## 严格遵循 Godot 4.6 架构与代码规范（PascalCase 类名，snake_case 方法名等）。

signal story_generated(data: Dictionary)
signal tags_analyzed(tags: Dictionary)
signal card_generated(card_data: Dictionary)
signal image_generated(image_url: String)
signal error_occurred(message: String)

const TEXT_MODEL: String = "glm-4.7" # 智谱 GLM-4 文本模型
const IMAGE_MODEL: String = "glm-image" # 智谱的图像生成模型

var _api_key: String = ""
var _base_url: String = "https://open.bigmodel.cn/api/paas/v4"
var _base_prob: Dictionary = {
	"A": 33, # 直接伤害类
	"B": 34, # 属性改变类
	"C": 33  # buff施加类
}

func _ready() -> void:
	# 尝试从环境变量获取 API Key，如果没有，可以在这里硬编码仅供测试（不推荐生产环境）
	_api_key = OS.get_environment("ZHIPU_API_KEY")
	if _api_key.is_empty():
		push_warning("GameAICore: 未能获取到有效的 ZHIPU_API_KEY。请确保在环境变量中配置了该键值。")

## 从大模型返回的文本中提取并解析 JSON
func _extract_json_from_text(text: String) -> Dictionary:
	if text.is_empty():
		return {}
	
	var clean_text: String = text.strip_edges()
	if clean_text.begins_with("```json"):
		clean_text = clean_text.substr(7)
	elif clean_text.begins_with("```"):
		clean_text = clean_text.substr(3)
		
	if clean_text.ends_with("```"):
		clean_text = clean_text.substr(0, clean_text.length() - 3)
		
	clean_text = clean_text.strip_edges()
	
	var json: JSON = JSON.new()
	var error: Error = json.parse(clean_text)
	if error == OK:
		if json.data is Dictionary:
			return json.data
			
	# 如果基础解析失败，尝试提取片段
	var start_idx: int = clean_text.find("{")
	var end_idx: int = clean_text.rfind("}")
	if start_idx != -1 and end_idx != -1 and end_idx > start_idx:
		var extracted: String = clean_text.substr(start_idx, end_idx - start_idx + 1)
		var json_fallback: JSON = JSON.new()
		if json_fallback.parse(extracted) == OK and json_fallback.data is Dictionary:
			return json_fallback.data
			
	push_warning("JSON 解析失败: " + String(text))
	return {}

## 发起底层的 HTTP 协程请求
func _make_post_request(endpoint: String, payload: Dictionary) -> Dictionary:
	if _api_key.is_empty():
		error_occurred.emit("API Key is missing.")
		return {}
		
	var http_request: HTTPRequest = HTTPRequest.new()
	add_child(http_request)
	
	var headers: PackedStringArray = [
		"Content-Type: application/json",
		"Authorization: Bearer " + _api_key
	]
	
	var json_string: String = JSON.stringify(payload)
	var url: String = _base_url + endpoint
	
	var err: Error = http_request.request(url, headers, HTTPClient.METHOD_POST, json_string)
	if err != OK:
		error_occurred.emit("HTTP Request failed to start.")
		http_request.queue_free()
		return {}
		
	var response: Array = await http_request.request_completed
	var result: int = response[0]
	var response_code: int = response[1]
	var body: PackedByteArray = response[3]
	
	http_request.queue_free()
	
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		var err_msg: String = body.get_string_from_utf8()
		error_occurred.emit("API Error, Code: " + str(response_code) + ", " + err_msg)
		return {}
		
	var parser: JSON = JSON.new()
	if parser.parse(body.get_string_from_utf8()) == OK:
		if parser.data is Dictionary:
			return parser.data
	return {}

## 功能1: 交互式剧情与选项生成
func generate_story_node(background: String, history: Array, iteration: int) -> void:
	var system_prompt: String = (
		"你是一个克苏鲁、中式恐怖、修仙等多元素世界观游戏的游戏剧本大师。玩家正在探索旧文明的意识之海中的'记忆碎片'。\n" +
		"请根据提供的背景信息和之前的故事，续写一段充满神秘感和悬疑感的故事段落（约 100-300 字）。\n"
	)
	
	if iteration < 3:
		system_prompt += (
			"在故事的结尾，提供 2 到 3 个选项供玩家选择以应对当前的局面。\n" +
			"请务必以 JSON 格式输出，包含字段： 'story' (故事正文), 'options' (选项数组，每个元素包含 'id' 和 'text' 字段)。"
		)
	else:
		system_prompt += (
			"这是本次记忆碎片事件的最后一段故事。请根据玩家上一步的选择为本次事件画上一个句号，不需要再提供选项。\n" +
			"请务必以 JSON 格式输出，包含字段： 'story' (故事正文)。"
		)
		
	var messages: Array = [{"role": "system", "content": system_prompt}]
	for msg in history:
		messages.append(msg)
		
	var prompt: String = ""
	if iteration == 1:
		prompt = "当前场景初始背景：{0}\n请以此为开端生成故事和选项。".format([background])
	else:
		prompt = "玩家上一步的选择：{0}\n请根据玩家的选择继续生成后续故事。".format([background])
		
	messages.append({"role": "user", "content": prompt})
	
	var payload: Dictionary = {
		"model": TEXT_MODEL,
		"messages": messages,
		"temperature": 0.7,
		"max_tokens": 4096
	}
	
	var response: Dictionary = await _make_post_request("/chat/completions", payload)
	if response.is_empty():
		return
		
	var content: String = response.get("choices", [{}])[0].get("message", {}).get("content", "")
	var data: Dictionary = _extract_json_from_text(content)
	
	if data.is_empty():
		error_occurred.emit("Failed to parse story JSON.")
	else:
		story_generated.emit(data)

## 功能2: 玩家行为标签评估
func analyze_player_tags(history: Array) -> void:
	var history_text: String = ""
	for msg in history:
		var role_str: String = "AI(故事)" if msg["role"] == "assistant" else "玩家(选择)"
		if msg["role"] == "assistant":
			var content_dict: Dictionary = _extract_json_from_text(str(msg["content"]))
			if not content_dict.is_empty():
				history_text += "[{0}]: {1}\n".format([role_str, content_dict.get("story", "")])
			else:
				history_text += "[{0}]: {1}\n".format([role_str, str(msg["content"])])
		else:
			history_text += "[{0}]: {1}\n".format([role_str, str(msg["content"])])
			
	var prompt: String = (
		"以下是玩家在探索游戏内“记忆碎片”事件时的完整对话和探索故事记录：\n" +
		history_text + "\n" +
		"请根据玩家在面对上述各种诡异、危险的剧情局面时所作出的选择，分析玩家的行为和心理倾向。\n" +
		"请在以下三个维度中分别选出一个最符合的标签：\n" +
		"维度1: 偏善 vs 偏恶\n" +
		"维度2: 激进 vs 保守\n" +
		"维度3: 守序 vs 混乱\n" +
		"请务必以 JSON 格式输出，包含三个字段: 'morality' (偏善或偏恶), 'strategy' (激进或保守), 'alignment' (守序或混乱)。"
	)
	
	var payload: Dictionary = {
		"model": TEXT_MODEL,
		"messages": [{"role": "user", "content": prompt}],
		"temperature": 0.7,
		"max_tokens": 4096
	}
	
	var response: Dictionary = await _make_post_request("/chat/completions", payload)
	if response.is_empty():
		return
		
	var content: String = response.get("choices", [{}])[0].get("message", {}).get("content", "")
	var data: Dictionary = _extract_json_from_text(content)
	
	if data.is_empty():
		error_occurred.emit("Failed to parse tags JSON.")
	else:
		tags_analyzed.emit(data)

## 功能3 (核心规则逻辑): 根据标签修正卡牌模板概率
func calculate_card_template_prob(tags: Dictionary) -> String:
	var prob: Dictionary = _base_prob.duplicate()
	
	if tags.get("morality") == "偏善":
		prob["C"] += 10; prob["A"] -= 5; prob["B"] -= 5
	elif tags.get("morality") == "偏恶":
		prob["A"] += 15; prob["C"] -= 10; prob["B"] -= 5
		
	if tags.get("strategy") == "激进":
		prob["A"] += 10; prob["C"] -= 5; prob["B"] -= 5
	elif tags.get("strategy") == "保守":
		prob["C"] += 10; prob["A"] -= 5; prob["B"] -= 5
		
	if tags.get("alignment") == "守序":
		prob["B"] += 15; prob["A"] -= 5; prob["C"] -= 10
	elif tags.get("alignment") == "混乱":
		prob["A"] += 5; prob["B"] += 5; prob["C"] -= 10
		
	for k in prob.keys():
		prob[k] = max(0, prob[k])
		
	var total: int = 0
	for k in prob.keys():
		total += prob[k]
		
	var rand_val: float = randf_range(0.0, float(total))
	var current_val: float = 0.0
	
	for template in prob.keys():
		current_val += prob[template]
		if rand_val <= current_val:
			return template
			
	return "A"

## 功能4: 卡牌数值及描述生成
func generate_card_stats(template_type: String, tags: Dictionary, history: Array) -> void:
	var full_story: String = ""
	for msg in history:
		if msg["role"] == "assistant":
			var content_dict: Dictionary = _extract_json_from_text(str(msg["content"]))
			full_story += content_dict.get("story", "") + "\n"
			
	if full_story.length() > 1000:
		full_story = full_story.substr(0, 1000) + "...（故事内容过长，已截断）"
		
	var prompt: String = (
		"你需要设计一张基于卡牌战斗游戏的特殊卡牌。这张卡牌是玩家经历完整的“记忆碎片”事件后凝聚的具象化力量：\n" +
		"【完整的探索故事背景】：\n" + full_story + "\n" +
		"玩家在事件中表现出的性格倾向标签是：" + JSON.stringify(tags) + "。\n" +
		"这张卡牌的类型属于模板：" + template_type + "（A代表直接伤害类，B代表属性改变类，C代表buff施加类）。\n\n" +
		"请遵循游戏费用表输出以下数值：\n" +
		"1. 精神负荷 (消耗的精神值，通常在 1~3 之间)\n" +
		"2. 认知负荷 (打出卡牌所需的认知值，通常在 1~5 之间)\n" +
		"3. 核心数值X (如伤害量、属性改变值、层数)\n" +
		"4. 卡牌名称 (符合旧日文明、克苏鲁、修仙等神秘恐怖风格，且与故事背景相关)\n" +
		"5. 卡牌描述 (生动描绘该卡牌的效果与风味)\n\n" +
		"请务必以 JSON 格式输出，只包含JSON，不要其他文字：'name', 'mental_cost', 'cognitive_cost', 'value_x', 'description'."
	)
	
	var payload: Dictionary = {
		"model": TEXT_MODEL,
		"messages": [{"role": "user", "content": prompt}],
		"temperature": 0.7,
		"max_tokens": 4096
	}
	
	var response: Dictionary = await _make_post_request("/chat/completions", payload)
	if response.is_empty():
		return
		
	var content: String = response.get("choices", [{}])[0].get("message", {}).get("content", "")
	var data: Dictionary = _extract_json_from_text(content)
	
	if data.is_empty():
		error_occurred.emit("Failed to parse card JSON.")
	else:
		card_generated.emit(data)

## 功能5: 图像生成
func generate_image(prompt_text: String) -> void:
	var image_prompt: String = "黑暗、诡异的蒸汽朋克风格，混合中式恐怖与克苏鲁元素。" + prompt_text
	
	var payload: Dictionary = {
		"model": IMAGE_MODEL,
		"prompt": image_prompt
	}
	
	var response: Dictionary = await _make_post_request("/images/generations", payload)
	if response.is_empty():
		return
		
	var data_arr: Array = response.get("data", [])
	if data_arr.size() > 0:
		var image_url: String = data_arr[0].get("url", "")
		var local_path: String = await _download_and_save_image(image_url)
		if not local_path.is_empty():
			image_generated.emit(local_path)
		else:
			error_occurred.emit("图片下载失败。")
	else:
		error_occurred.emit("No image URL returned.")

func _download_and_save_image(url: String) -> String:
	var dir: DirAccess = DirAccess.open("user://")
	if not dir.dir_exists("ai_cards"):
		dir.make_dir("ai_cards")
		
	var file_name: String = "card_img_" + str(Time.get_unix_time_from_system()) + ".png"
	# 统一指定在 user://ai_cards 目录下
	var save_path: String = "user://ai_cards/" + file_name
	
	var http_request: HTTPRequest = HTTPRequest.new()
	add_child(http_request)
	http_request.download_file = save_path
	
	var err: Error = http_request.request(url)
	if err != OK:
		http_request.queue_free()
		return ""
		
	var response: Array = await http_request.request_completed
	http_request.queue_free()
	
	if response[0] == HTTPRequest.RESULT_SUCCESS and response[1] == 200:
		return save_path
		
	return ""
