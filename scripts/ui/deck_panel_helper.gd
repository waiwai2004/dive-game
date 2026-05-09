## 卡组面板辅助工具
## 提取自 global_ui.gd / battle_scene.gd 的重复卡组查看器逻辑。
class_name DeckPanelHelper

const CARD_UI_SCENE := preload("res://scenes/battle/CardUI.tscn")


## 构建卡组内容到指定的 HFlowContainer 中。
## 调用方需保证 flow_container 已加入场景树。
static func refresh_deck(flow_container: HFlowContainer) -> void:
	for child in flow_container.get_children():
		child.queue_free()

	if not flow_container.is_inside_tree():
		return
	if not flow_container.has_node("/root/Game"):
		return

	if Game.deck.is_empty():
		var empty_label := Label.new()
		empty_label.text = "当前牌库为空。"
		flow_container.add_child(empty_label)
		return

	var counts: Dictionary = {}
	var order: Array[String] = []
	for card_id in Game.deck:
		if not counts.has(card_id):
			counts[card_id] = 0
			order.append(card_id)
		counts[card_id] += 1

	for card_id in order:
		flow_container.add_child(_build_card_preview(card_id, int(counts[card_id])))


## 确保 ScrollContainer + HFlowContainer 结构存在于 content_vbox 中。
## 返回 HFlowContainer 节点。
static func ensure_deck_flow(deck_text: RichTextLabel, content_vbox: Node, scroll_ref: RefCounted, flow_ref: RefCounted) -> Dictionary:
	# 检查已有引用是否有效
	if flow_ref and is_instance_valid(flow_ref):
		return {"scroll": scroll_ref, "flow": flow_ref}

	if deck_text:
		deck_text.visible = false

	var scroll := ScrollContainer.new()
	scroll.name = "DeckScroll"
	scroll.custom_minimum_size = Vector2(0, 360)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(scroll)

	var flow := HFlowContainer.new()
	flow.name = "DeckCardsFlow"
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	flow.add_theme_constant_override("h_separation", 16)
	flow.add_theme_constant_override("v_separation", 16)
	scroll.add_child(flow)

	return {"scroll": scroll, "flow": flow}


static func _build_card_preview(card_id: String, count: int) -> Control:
	var db = Engine.get_main_loop().root.get_node_or_null("CardDatabase")
	var card: Dictionary = {}
	if db and db.has_method("get_card"):
		card = db.get_card(card_id)

	var card_ui = CARD_UI_SCENE.instantiate()

	if card_ui.has_method("setup"):
		card_ui.call("setup", card, -1, null)

	card_ui.disabled = true
	card_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var vbox = VBoxContainer.new()
	vbox.add_child(card_ui)

	if count > 1:
		var count_label = Label.new()
		count_label.text = "x%d" % count
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(count_label)

	return vbox
