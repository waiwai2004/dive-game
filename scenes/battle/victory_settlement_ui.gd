extends Control

@onready var title_label: Label = find_child("TitleLabel", true, false)
@onready var status_label: Label = find_child("StatusLabel", true, false)
@onready var reward_title_label: Label = find_child("RewardTitleLabel", true, false)
@onready var reward_texture: TextureRect = find_child("RewardTexture", true, false)

@export var normal_reward_icon: Texture2D  
@export var boss_reward_icon: Texture2D    

var _is_boss: bool = false
var _boss_card_id: String = ""
var _boss_card_data: Dictionary = {}

# 自己管理悬停的卡牌详情框
var _tooltip_instance: Control = null

func _ready() -> void:
	show()
	
	# 1. 从全局 Game 提取刚打完的战斗数据
	_is_boss = Game.get_meta("battle_is_boss", false)
	var turns_taken = Game.get_meta("battle_turn_count", 0)
	_boss_card_id = Game.get_meta("battle_boss_card", "")
	
	# 2. 状态恢复
	Game.player_san = Game.max_san 
	Game.clear_cognition() 
	
	# 3. 填充文字
	if status_label: status_label.text = "花费回合: %d" % turns_taken
	if reward_title_label: reward_title_label.text = "战斗奖励:"
	
	if _is_boss:
		if title_label: title_label.text = "BOSS挑战成功"
		if reward_texture and boss_reward_icon: reward_texture.texture = boss_reward_icon
		var db = get_node_or_null("/root/CardDatabase")
		if db and db.has_method("get_card"):
			_boss_card_data = db.get_card(_boss_card_id)
	else:
		if title_label: title_label.text = "战斗胜利"
		if reward_texture and normal_reward_icon: reward_texture.texture = normal_reward_icon
		
	# 4. 绑定图片交互
	if reward_texture:
		reward_texture.gui_input.connect(_on_reward_texture_gui_input)
		reward_texture.mouse_entered.connect(_on_reward_mouse_entered)
		reward_texture.mouse_exited.connect(_on_reward_mouse_exited)


func _on_reward_texture_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_hide_tooltip()
		
		# 真正的流转控制权交到了这个独立场景手里
		if _is_boss:
			Game.add_card(_boss_card_id)
			Game.goto_end()
		else:
			# 这里由于原来依赖 BattleScene 里的剧情选卡界面
			# 现在场景分开了，直接跳转回探索地图
			# (如果后续你把 RewardStory 也做成了独立场景，这里可以 change_scene_to 选卡场景)
			Game.goto_explore()


func _on_reward_mouse_entered() -> void:
	if _is_boss and not _boss_card_data.is_empty():
		# 动态加载并实例化 CardUI 作为独立悬浮窗，不依赖 BattleScene
		if _tooltip_instance == null:
			var card_scene = load("res://scenes/battle/CardUI.tscn")
			if card_scene:
				_tooltip_instance = card_scene.instantiate()
				add_child(_tooltip_instance)
				# 禁用悬浮窗的鼠标响应，防止挡住贴图
				_tooltip_instance.mouse_filter = Control.MOUSE_FILTER_IGNORE
				_tooltip_instance.disabled = true
				if _tooltip_instance.has_method("setup"):
					_tooltip_instance.setup(_boss_card_data, -1, null)
				
				# 让悬浮窗出现在贴图的右侧
				_tooltip_instance.global_position = reward_texture.global_position + Vector2(150, 0)
		else:
			_tooltip_instance.show()

func _on_reward_mouse_exited() -> void:
	_hide_tooltip()

func _hide_tooltip() -> void:
	if _tooltip_instance:
		_tooltip_instance.hide()
