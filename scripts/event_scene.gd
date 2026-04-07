extends Control

@onready var title_label = $CenterContainer/MainVBox/EventTitleLabel
@onready var desc_label = $CenterContainer/MainVBox/EventDescLabel
@onready var option_a_button = $CenterContainer/MainVBox/ChoiceRow/OptionACard
@onready var option_b_button = $CenterContainer/MainVBox/ChoiceRow/OptionBCard

# 存储当前读取的事件数据
var current_event_data: Dictionary

func _ready() -> void:
	option_a_button.pressed.connect(_on_option_a_button_pressed)
	option_b_button.pressed.connect(_on_option_b_button_pressed)
	# 从数据库读取指定ID的事件（这里暂时固定读 event_01）
	load_event("event_01")

func load_event(event_id: String) -> void:
	current_event_data = DBManager.get_event(event_id)
	
	if current_event_data.is_empty():
		title_label.text = "事件读取失败"
		desc_label.text = "未在数据库找到对应ID"
		return
		
	# 自动填充标题和描述
	title_label.text = current_event_data.get("title", "未知事件")
	desc_label.text = current_event_data.get("description", "...")
	
	var options = current_event_data.get("options", [])
	
	# 自动填充选项A
	if options.size() > 0:
		option_a_button.text = options[0].get("text", "")
		option_a_button.show()
	else:
		option_a_button.hide()
		
	# 自动填充选项B
	if options.size() > 1:
		option_b_button.text = options[1].get("text", "")
		option_b_button.show()
	else:
		option_b_button.hide()

# 处理选项带来的数值变化
func apply_option_effects(option_data: Dictionary) -> void:
	var p = GameManager.player_summary
	
	# 根据JSON里的字段自动结算属性
	if option_data.has("max_hp_change"):
		p["max_hp"] += option_data["max_hp_change"]
		
	if option_data.has("cognition_max_change"):
		p["cognition_max"] += option_data["cognition_max_change"]
		
	if option_data.has("extra_energy_change"):
		p["extra_energy"] += option_data["extra_energy_change"]
		
	if option_data.get("heal_to_max", false):
		p["hp"] = p["max_hp"]
		
	# 安全检查，防止血量溢出
	if p["hp"] > p["max_hp"]:
		p["hp"] = p["max_hp"]

func _on_option_a_button_pressed() -> void:
	var options = current_event_data.get("options", [])
	if options.size() > 0:
		apply_option_effects(options[0])
	
	GameManager.advance_node()
	get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")

func _on_option_b_button_pressed() -> void:
	var options = current_event_data.get("options", [])
	if options.size() > 1:
		apply_option_effects(options[1])
		
	GameManager.advance_node()
	get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")
