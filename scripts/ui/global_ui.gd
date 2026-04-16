extends CanvasLayer

const MODE_MENU := "menu"
const MODE_STORY := "story"
const MODE_BASE := "base"
const MODE_EXPLORE := "explore"
const MODE_BATTLE := "battle"

@onready var atmosphere_frame: TextureRect = $AtmosphereFrame
@onready var top_hud: Control = $TopHUD
@onready var san_label: Label = $TopHUD/SanBarRoot/SanLabel
@onready var san_bar_fill: ProgressBar = $TopHUD/SanBarRoot/SanBarFill
@onready var hp_label: Label = $TopHUD/HpBarRoot/HpLabel
@onready var hp_bar_fill: ProgressBar = $TopHUD/HpBarRoot/HpBarFill
@onready var energy_label: Label = get_node_or_null("TopHUD/EnergyLabel")
@onready var bottom_hint_root: Control = $BottomHintRoot
@onready var hint_label: Label = $BottomHintRoot/HintBg/HintLabel
@onready var avatar_image: TextureRect = $TopHUD/AvatarFrame/AvatarImage
@onready var danger_overlay_red: ColorRect = $DangerOverlayRed
@onready var danger_overlay_black: ColorRect = $DangerOverlayBlack

@onready var deck_button: Button = $TopHUD/AvatarFrame/DeckButton
@onready var deck_panel: PanelContainer = $DeckPanel
@onready var deck_title_label: Label = $DeckPanel/MarginContainer/ContentVBox/HeaderRow/TitleLabel
@onready var deck_close_button: Button = $DeckPanel/MarginContainer/ContentVBox/HeaderRow/CloseButton
@onready var deck_text: RichTextLabel = $DeckPanel/MarginContainer/ContentVBox/DeckText

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
	set_mode(MODE_MENU)
	clear_hint()
	clear_energy()

	deck_panel.visible = false
	deck_text.bbcode_enabled = true
	deck_title_label.text = "当前牌库"

	if not deck_button.pressed.is_connected(_on_deck_button_pressed):
		deck_button.pressed.connect(_on_deck_button_pressed)
	if not deck_close_button.pressed.is_connected(_on_deck_close_button_pressed):
		deck_close_button.pressed.connect(_on_deck_close_button_pressed)

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
			bottom_hint_root.visible = false
			atmosphere_frame.visible = true
			danger_overlay_red.visible = false
			danger_overlay_black.visible = false
			clear_energy()
			hide_deck_panel()
		MODE_STORY:
			top_hud.visible = false
			bottom_hint_root.visible = true
			atmosphere_frame.visible = true
			danger_overlay_red.visible = false
			danger_overlay_black.visible = false
			clear_energy()
			hide_deck_panel()
		MODE_BASE:
			top_hud.visible = true
			bottom_hint_root.visible = true
			atmosphere_frame.visible = true
			danger_overlay_red.visible = false
			danger_overlay_black.visible = false
			clear_energy()
		MODE_EXPLORE:
			top_hud.visible = true
			bottom_hint_root.visible = true
			atmosphere_frame.visible = true
			danger_overlay_red.visible = false
			danger_overlay_black.visible = false
			clear_energy()
		MODE_BATTLE:
			top_hud.visible = true
			bottom_hint_root.visible = true
			atmosphere_frame.visible = true
			danger_overlay_red.visible = true
			danger_overlay_black.visible = true
		_:
			top_hud.visible = true
			bottom_hint_root.visible = true
			atmosphere_frame.visible = true
			danger_overlay_red.visible = false
			danger_overlay_black.visible = false
			clear_energy()

	_update_deck_button_visibility()


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

	var hp_changed: bool = hp != _last_hp or max_hp != _last_max_hp
	var san_changed: bool = san != _last_san or max_san != _last_max_san

	_last_hp = hp
	_last_max_hp = max_hp
	_last_san = san
	_last_max_san = max_san

	hp_label.text = "HP %d / %d" % [hp, max_hp]
	san_label.text = "SAN %d / %d" % [san, max_san]

	hp_bar_fill.max_value = max_hp
	san_bar_fill.max_value = max_san

	if hp_changed:
		_tween_progress_bar(hp_bar_fill, float(hp), true)
	if san_changed:
		_tween_progress_bar(san_bar_fill, float(san), false)

	_apply_low_value_feedback()
	_update_danger_overlays()

	if _energy_visible and energy_label:
		energy_label.text = _build_energy_text()


func _tween_progress_bar(bar: ProgressBar, target_value: float, is_hp: bool) -> void:
	target_value = clamp(target_value, 0.0, bar.max_value)

	var tween_ref: Tween = _hp_tween if is_hp else _san_tween
	if tween_ref and is_instance_valid(tween_ref):
		tween_ref.kill()

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(bar, "value", target_value, 0.18)

	if is_hp:
		_hp_tween = tween
	else:
		_san_tween = tween


func _apply_low_value_feedback() -> void:
	var hp_ratio: float = float(_last_hp) / float(max(1, _last_max_hp))
	var san_ratio: float = float(_last_san) / float(max(1, _last_max_san))

	hp_label.modulate = Color(1.15, 0.72, 0.72, 1.0) if hp_ratio <= 0.34 else Color(1, 1, 1, 1)
	san_label.modulate = Color(0.7, 0.92, 1.2, 1.0) if san_ratio <= 0.34 else Color(1, 1, 1, 1)


func _update_danger_overlays() -> void:
	if _mode != MODE_BATTLE:
		_set_overlay_alpha(danger_overlay_red, 0.0, false)
		_set_overlay_alpha(danger_overlay_black, 0.0, true)
		return

	var hp_ratio: float = float(_last_hp) / float(max(1, _last_max_hp))
	var san_ratio: float = float(_last_san) / float(max(1, _last_max_san))

	var red_alpha: float = 0.0
	if hp_ratio <= 0.5:
		red_alpha = lerp(0.0, 0.40, (0.5 - hp_ratio) / 0.5)

	var black_alpha: float = 0.0
	if san_ratio <= 0.5:
		black_alpha = lerp(0.0, 0.52, (0.5 - san_ratio) / 0.5)

	_set_overlay_alpha(danger_overlay_red, red_alpha, false)
	_set_overlay_alpha(danger_overlay_black, black_alpha, true)


func _set_overlay_alpha(rect: ColorRect, alpha: float, is_black: bool) -> void:
	if rect == null:
		return
	rect.visible = alpha > 0.001 or _mode == MODE_BATTLE
	var target := rect.color
	target.a = alpha

	var tween_ref: Tween = _black_overlay_tween if is_black else _red_overlay_tween
	if tween_ref and is_instance_valid(tween_ref):
		tween_ref.kill()

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(rect, "color", target, 0.2)

	if is_black:
		_black_overlay_tween = tween
	else:
		_red_overlay_tween = tween


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


func _update_deck_button_visibility() -> void:
	var can_show := _mode == MODE_BASE or _mode == MODE_EXPLORE or _mode == MODE_BATTLE
	deck_button.visible = can_show
	if not can_show:
		hide_deck_panel()


func _on_deck_button_pressed() -> void:
	if _deck_open:
		hide_deck_panel()
	else:
		show_deck_panel()


func _on_deck_close_button_pressed() -> void:
	hide_deck_panel()


func show_deck_panel() -> void:
	_deck_open = true
	refresh_deck_panel()
	deck_panel.visible = true


func hide_deck_panel() -> void:
	_deck_open = false
	deck_panel.visible = false


func refresh_deck_panel() -> void:
	_ensure_deck_cards_view()

	if not has_node("/root/Game"):
		return

	for child in _deck_cards_flow.get_children():
		child.queue_free()

	if Game.deck.is_empty():
		var empty_label := Label.new()
		empty_label.text = "当前牌库为空。"
		_deck_cards_flow.add_child(empty_label)
		return

	var counts: Dictionary = {}
	var order: Array[String] = []

	for card_id in Game.deck:
		if not counts.has(card_id):
			counts[card_id] = 0
			order.append(card_id)
		counts[card_id] += 1

	for card_id in order:
		_deck_cards_flow.add_child(_build_card_preview(card_id, int(counts[card_id])))


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


func _build_card_preview(card_id: String, count: int) -> Control:
	var db = get_node_or_null("/root/CardDatabase")
	var card: Dictionary = {}
	if db and db.has_method("get_card"):
		card = db.get_card(card_id)

	var name_text := str(card.get("name", card_id))
	var desc_text := str(card.get("description", card.get("desc", "")))
	var cost_text := str(card.get("cost", card.get("energy_cost", 0)))
	var cognition_text := str(card.get("cognition", 0))

	var type_text := str(card.get("type", card.get("card_type", "")))
	if db and db.has_method("get_type_text"):
		type_text = db.get_type_text(type_text)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(180, 280)
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.16, 0.96)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.55, 0.75, 1.0, 0.68)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "%s  x%d" % [name_text, count]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(title)

	var art_holder := PanelContainer.new()
	art_holder.custom_minimum_size = Vector2(0, 110)
	var art_style := StyleBoxFlat.new()
	art_style.bg_color = Color(0.12, 0.15, 0.22, 0.96)
	art_style.corner_radius_top_left = 8
	art_style.corner_radius_top_right = 8
	art_style.corner_radius_bottom_left = 8
	art_style.corner_radius_bottom_right = 8
	art_holder.add_theme_stylebox_override("panel", art_style)
	vbox.add_child(art_holder)

	var art_path := str(card.get("art_illustration_path", ""))
	if not art_path.is_empty():
		var tex: Resource = load(art_path)
		if tex is Texture2D:
			var art := TextureRect.new()
			art.texture = tex
			art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			art.mouse_filter = Control.MOUSE_FILTER_IGNORE
			art.set_anchors_preset(Control.PRESET_FULL_RECT)
			art_holder.add_child(art)
		else:
			_add_art_fallback(art_holder, name_text)
	else:
		_add_art_fallback(art_holder, name_text)

	var stats := Label.new()
	stats.text = "%s费  认知%s  [%s]" % [cost_text, cognition_text, type_text]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(stats)

	var desc := Label.new()
	desc.text = desc_text
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(desc)

	return panel


func _add_art_fallback(parent: Control, name_text: String) -> void:
	var fallback := Label.new()
	fallback.text = name_text
	fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fallback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fallback.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(fallback)
