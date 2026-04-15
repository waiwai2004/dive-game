extends CanvasLayer

const MODE_MENU := "menu"
const MODE_STORY := "story"
const MODE_BASE := "base"
const MODE_EXPLORE := "explore"
const MODE_BATTLE := "battle"

@onready var atmosphere_frame: TextureRect = $AtmosphereFrame
@onready var top_hud: Control = $TopHUD
@onready var san_label: Label = $TopHUD/SanBarRoot/SanLabel
@onready var san_bar_fill: TextureProgressBar = $TopHUD/SanBarRoot/SanBarFill
@onready var hp_label: Label = $TopHUD/HpBarRoot/HpLabel
@onready var hp_bar_fill: TextureProgressBar = $TopHUD/HpBarRoot/HpBarFill
@onready var energy_label: Label = get_node_or_null("TopHUD/EnergyLabel")
@onready var bottom_hint_root: Control = $BottomHintRoot
@onready var hint_label: Label = $BottomHintRoot/HintBg/HintLabel
@onready var avatar_image: TextureRect = $TopHUD/AvatarFrame/AvatarImage

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


func _ready() -> void:
	layer = 100
	set_mode(MODE_MENU)
	clear_hint()
	clear_energy()
	_refresh_stats_from_game(true)


func _process(_delta: float) -> void:
	_refresh_stats_from_game(false)


func set_mode(mode: String) -> void:
	_mode = mode

	match mode:
		MODE_MENU:
			top_hud.visible = false
			bottom_hint_root.visible = false
			atmosphere_frame.visible = true
			clear_energy()
		MODE_STORY:
			top_hud.visible = false
			bottom_hint_root.visible = true
			atmosphere_frame.visible = true
			clear_energy()
		MODE_BASE:
			top_hud.visible = true
			bottom_hint_root.visible = true
			atmosphere_frame.visible = true
			clear_energy()
		MODE_EXPLORE:
			top_hud.visible = true
			bottom_hint_root.visible = true
			atmosphere_frame.visible = true
			clear_energy()
		MODE_BATTLE:
			top_hud.visible = true
			bottom_hint_root.visible = true
			atmosphere_frame.visible = true
		_:
			top_hud.visible = true
			bottom_hint_root.visible = true
			atmosphere_frame.visible = true
			clear_energy()


func set_hint(text: String, visible := true) -> void:
	hint_label.text = text
	bottom_hint_root.visible = visible


func clear_hint() -> void:
	hint_label.text = ""
	bottom_hint_root.visible = false


func set_energy(
	value: int,
	max_value: int = 3,
	visible: bool = true,
	block_value: int = -1,
	cognition_value: int = -1,
	cognition_max_value: int = -1
) -> void:
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
	hp_bar_fill.value = clamp(float(hp), 0.0, float(max_hp))

	san_bar_fill.max_value = max_san
	san_bar_fill.value = clamp(float(san), 0.0, float(max_san))

	if _energy_visible and energy_label:
		energy_label.text = _build_energy_text()


func _build_energy_text() -> String:
	var parts: Array[String] = []
	parts.append("能量 %d / %d" % [_last_energy, max(1, _last_max_energy)])

	if _last_block >= 0:
		parts.append("护盾 %d" % _last_block)

	if _last_cognition >= 0 and _last_max_cognition > 0:
		parts.append("认知 %d / %d" % [_last_cognition, _last_max_cognition])

	var text: String = parts[0]
	for i in range(1, parts.size()):
		text += "  " + parts[i]
	return text
