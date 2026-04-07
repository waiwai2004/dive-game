extends Node

# 存储读取后的数据库
var cards_db: Dictionary = {}
var enemies_db: Dictionary = {}
var events_db: Dictionary = {}

func _ready() -> void:
	load_database()

func load_database() -> void:
	# 1. 加载卡牌库
	var card_file = FileAccess.open("res://assets/data/cards.json", FileAccess.READ)
	if card_file:
		var json_text = card_file.get_as_text()
		cards_db = JSON.parse_string(json_text)
		card_file.close()
	else:
		print("找不到卡牌数据库文件！")
		
	# 2. 加载敌人库
	var enemy_file = FileAccess.open("res://assets/data/enemies.json", FileAccess.READ)
	if enemy_file:
		var json_text = enemy_file.get_as_text()
		enemies_db = JSON.parse_string(json_text)
		enemy_file.close()
	
	# 3. 加载事件/剧本库 
	var event_file = FileAccess.open("res://assets/data/events.json", FileAccess.READ)
	if event_file:
		var json_text = event_file.get_as_text()
		events_db = JSON.parse_string(json_text)
		event_file.close()
	else:
		print("找不到事件数据库文件！")

# 提供给外部获取卡牌的方法
func get_card(card_id: String) -> Dictionary:
	if cards_db.has(card_id):
		# 返回深拷贝，防止原始数据被意外修改
		return cards_db[card_id].duplicate(true)
	return {}

# 提供给外部获取敌人的方法
func get_enemy(enemy_id: String) -> Dictionary:
	if enemies_db.has(enemy_id):
		return enemies_db[enemy_id].duplicate(true)
	return {}

# 提供给外部获取事件/剧本的方法
func get_event(event_id: String) -> Dictionary:
	if events_db.has(event_id):
		return events_db[event_id].duplicate(true)
	return {}