extends CanvasLayer

const MODE_MENU := "menu"
const MODE_STORY := "story"
const MODE_BASE := "base"
const MODE_EXPLORE := "explore"
const MODE_BATTLE := "battle"

@onready var atmosphere_frame: TextureRect = $AtmosphereFrame
@onready var top_hud: Control = $TopHUD

# 贴图资源
const FRAME_TEXTURE_01: String = "res://assets/art/ui/global/ui_global_frame_01.PNG"
const FRAME_TEXTURE_02: String = "res://assets/art/ui/global/ui_global_frame_02.PNG"

var _texture_frame_01: Texture2D = null
var _texture_frame_02: Texture2D = null
@onready var san_label: Label = $TopHUD/SanBarRoot/SanLabel
@onready var san_bar_fill: ProgressBar = $TopHUD/SanBarRoot/SanBarFill
@onready var hp_label: Label = $TopHUD/HpBarRoot/HpLabel
@onready var hp_bar_fill: ProgressBar = $TopHUD/HpBarRoot/HpBarFill
@onready var energy_label: Label = get_node_or_null("TopHUD/EnergyLabel")
@onready var avatar_image: TextureRect = $TopHUD/AvatarFrame/AvatarImage
@onready var danger_overlay_red: ColorRect = $DangerOverlayRed
@onready var danger_overlay_black: ColorRect = $DangerOverlayBlack

@onready var deck_panel: PanelContainer = $DeckPanel
@onready var deck_title_label: Label = $DeckPanel/MarginContainer/ContentVBox/HeaderRow/TitleLabel
@onready var deck_close_button: Button = $DeckPanel/MarginContainer/ContentVBox/HeaderRow/CloseButton
@onready var deck_text: RichTextLabel = $DeckPanel/MarginContainer/ContentVBox/DeckText

@onready var deck_icon_button: Button = $TopHUD/DeckIconButton
@onready var settings_button: Button = $TopHUD/SettingsButton

var _deck_scroll: ScrollContainer = null
var _deck_cards_flow: HFlowContainer = null

var _mode: String = MODE_MENU
var _last_hp := -999
var _last_max_hp := -999
var _last_san := -999
var _last_max_san := -999
var _energy_visible := false
var _last_energy := -999
var _last_max_energy := -999
var _last_block := -999
var _last_cognition := -999
var _last_max_cognition := -999

var _hp_tween: Tween = null
var _san_tween: Tween = null
var _red_overlay_tween: Tween = null
var _black_overlay_tween: Tween = null

var _deck_open := false


func _ready() -> void:
	layer = 100
	
	# 加载贴图资源
	_texture_frame_01 = load(FRAME_TEXTURE_01)
	_texture_frame_02 = load(FRAME_TEXTURE_02)
	
	set_mode(MODE_MENU)
	clear_energy()

	deck_panel.visible = false
	deck_text.bbcode_enabled = true
	deck_title_label.text = "当前牌库"

	if not deck_close_button.pressed.is_connected(_on_deck_close_button_pressed):
		deck_close_button.pressed.connect(_on_deck_close_button_pressed)
	if not deck_icon_button.pressed.is_connected(_on_deck_icon_button_pressed):
		deck_icon_button.pressed.connect(_on_deck_icon_button_pressed)
	if not settings_button.pressed.is_connected(_on_settings_button_pressed):
		settings_button.pressed.connect(_on_settings_button_pressed)

	_ensure_deck_cards_view()
	_refresh_stats_from_game(true)
	_update_deck_button_visibility()


func _process(_delta: float) -> void:
	_refresh_stats_from_game(false)
	if _deck_open:
		refresh_deck_panel()


func _unhandled_input(event: InputEvent) -> void:
	if _deck_open and event.is_action_pressed("ui_cancel"):
		hide_deck_panel()
		get_viewport().set_input_as_handled()


func set_mode(mode: String) -> void:
	_mode = mode

	match mode:
		MODE_MENU:
			top_hud.visible = false
			atmosphere_frame.visible = true
			_set_atmosphere_frame_texture(_texture_frame_01)
			danger_overlay_red.visible = false
			danger_overlay_black.visible = false
			clear_energy()
			hide_deck_panel()
		MODE_STORY:
			top_hud.visible = false
			atmosphere_frame.visible = true
			_set_atmosphere_frame_texture(_texture_frame_01)
			danger_overlay_red.visible = false
			danger_overlay_black.visible = false
			clear_energy()
			hide_deck_panel()
		MODE_BASE:
			top_hud.visible = true
			atmosphere_frame.visible = true
			_set_atmosphere_frame_texture(_texture_frame_02)
			danger_overlay_red.visible = false
			danger_overlay_black.visible = false
			clear_energy()
		MODE_EXPLORE:
			top_hud.visible = true
			atmosphere_frame.visible = true
			_set_atmosphere_frame_texture(_texture_frame_02)
			danger_overlay_red.visible = false
			danger_overlay_black.visible = false
			clear_energy()
		MODE_BATTLE:
			top_hud.visible = false
			atmosphere_frame.visible = false
			_set_atmosphere_frame_texture(_texture_frame_01)
			danger_overlay_red.visible = false
			danger_overlay_black.visible = false
			clear_energy()
			hide_deck_panel()
		_:
			top_hud.visible = true
			atmosphere_frame.visible = true
			_set_atmosphere_frame_texture(_texture_frame_02)
			danger_overlay_red.visible = false
			danger_overlay_black.visible = false
			clear_energy()

	_update_deck_button_visibility()

func set_energy(value: int, max_value: int = 3, visible: bool = true, block_value: int = -1, cognition_value: int = -1, cognition_max_value: int = -1) -> void:
	if not energy_label:
		return
	_energy_visible = visible
	_last_energy = value
	_last_max_energy = max(1, max_value)
	_last_block = block_value
	_last_cognition = cognition_value
	_last_max_cognition = cognition_max_value
	energy_label.visible = visible
	if visible:
		energy_label.text = _build_energy_text()


func clear_energy() -> void:
	_energy_visible = false
	_last_energy = -999
	_last_max_energy = -999
	_last_block = -999
	_last_cognition = -999
	_last_max_cognition = -999
	if energy_label:
		energy_label.visible = false


func set_avatar_texture(texture: Texture2D) -> void:
	avatar_image.texture = texture


func set_atmosphere_visible(visible: bool) -> void:
	atmosphere_frame.visible = visible


func _set_atmosphere_frame_texture(texture: Texture2D) -> void:
	if texture and atmosphere_frame:
		atmosphere_frame.texture = texture


func set_top_hud_visible(visible: bool) -> void:
	top_hud.visible = visible


func refresh_stats() -> void:
	_refresh_stats_from_game(true)


func _refresh_stats_from_game(force: bool) -> void:
	if not has_node("/root/Game"):
		return
	var hp: int = Game.player_hp
	var max_hp: int = max(Game.max_hp, 1)
	var san: int = Game.player_san
	var max_san: int = max(Game.max_san, 1)

	if not force and hp == _last_hp and max_hp == _last_max_hp and san == _last_san and max_san == _last_max_san:
		return

	_last_hp = hp
	_last_max_hp = max_hp
	_last_san = san
	_last_max_san = max_san

	hp_label.text = "HP %d / %d" % [hp, max_hp]
	san_label.text = "SAN %d / %d" % [san, max_san]
	hp_bar_fill.max_value = max_hp
	san_bar_fill.max_value = max_san
	hp_bar_fill.value = hp
	san_bar_fill.value = san

	if _energy_visible and energy_label:
		energy_label.text = _build_energy_text()


func _build_energy_text() -> String:
	var parts: Array[String] = []
	parts.append("能量 %d / %d" % [_last_energy, max(1, _last_max_energy)])
	if _last_block >= 0:
		parts.append("护盾 %d" % _last_block)
	if _last_cognition >= 0 and _last_max_cognition > 0:
		parts.append("认知 %d / %d" % [_last_cognition, _last_max_cognition])
	var text := parts[0]
	for i in range(1, parts.size()):
		text += "  " + parts[i]
	return text


func _update_deck_button_visibility() -> void:
	# 在 BASE、EXPLORE 和 STORY 模式下显示按钮
	var can_show := _mode == MODE_BASE or _mode == MODE_EXPLORE or _mode == MODE_STORY
	# 控制新按钮的可见性
	deck_icon_button.visible = can_show
	if not can_show:
		hide_deck_panel()
	else:
		_update_deck_button_state()


func _update_deck_button_state() -> void:
	# 根据卡组面板的开关状态，更新按钮的视觉效果
	# 如果需要，可以在这里添加按钮高亮、颜色变化等效果
	# 例如：当卡组打开时，让按钮更亮或改变颜色
	pass  # 目前保持简单，可以根据需要扩展


func _on_deck_close_button_pressed() -> void:
	hide_deck_panel()


func _on_deck_icon_button_pressed() -> void:
	if _deck_open:
		hide_deck_panel()
	else:
		show_deck_panel()


func _on_settings_button_pressed() -> void:
	if has_node("PauseMenu"):
		var pause_menu = get_node("PauseMenu")
		if pause_menu and pause_menu.has_method("open_menu"):
			pause_menu.open_menu()


func show_deck_panel() -> void:
	_deck_open = true
	refresh_deck_panel()
	deck_panel.visible = true
	# 更新按钮状态（可选：添加视觉反馈）
	_update_deck_button_state()


func hide_deck_panel() -> void:
	_deck_open = false
	deck_panel.visible = false
	# 更新按钮状态
	_update_deck_button_state()


func refresh_deck_panel() -> void:
	_ensure_deck_cards_view()
	DeckPanelHelper.refresh_deck(_deck_cards_flow)


func _ensure_deck_cards_view() -> void:
	if _deck_cards_flow and is_instance_valid(_deck_cards_flow):
		return
	if deck_text:
		deck_text.visible = false
	var content_vbox: Node = $DeckPanel/MarginContainer/ContentVBox
	_deck_scroll = ScrollContainer.new()
	_deck_scroll.name = "DeckScroll"
	_deck_scroll.custom_minimum_size = Vector2(0, 360)
	_deck_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_deck_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(_deck_scroll)
	_deck_cards_flow = HFlowContainer.new()
	_deck_cards_flow.name = "DeckCardsFlow"
	_deck_cards_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_deck_cards_flow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_deck_cards_flow.add_theme_constant_override("h_separation", 16)
	_deck_cards_flow.add_theme_constant_override("v_separation", 16)
	_deck_scroll.add_child(_deck_cards_flow)


