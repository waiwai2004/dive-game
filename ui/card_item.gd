extends Button

signal card_pressed(instance_id)

@onready var card_frame = $CardFrame
@onready var art_image = $ContentMargin/ContentVBox/ArtHolder/ArtImage
@onready var name_label = $ContentMargin/ContentVBox/NameLabel
@onready var type_label = $ContentMargin/ContentVBox/TypeLabel
@onready var cost_label = $ContentMargin/ContentVBox/CostLabel
@onready var desc_label = $ContentMargin/ContentVBox/DescLabel

var card_instance_id: int = -1
var is_selected := false

# 拖动相关变量
var is_dragging := false           # 是否正在拖动
var drag_offset := Vector2.ZERO    # 鼠标与卡牌的偏移
var _original_global_pos := Vector2.ZERO  # 卡牌原始全局位置
var _drag_start_mouse_pos := Vector2.ZERO # 拖动开始时鼠标位置
const DRAG_THRESHOLD := 5.0       # 拖动阈值（像素）

var art_path_map := {
	"strike": "res://assets/cards/strike.png",
	"bless": "res://assets/cards/bless.png",
	"break": "res://assets/cards/break.png",
	"relief": "res://assets/cards/relief.png",
	"resonance": "res://assets/cards/resonance.png"
}

func setup(data: Dictionary) -> void:
	card_instance_id = data.get("instance_id", -1)

	var card_id = str(data.get("id", ""))
	if art_path_map.has(card_id):
		art_image.texture = load(art_path_map[card_id])

	name_label.text = str(data.get("name", ""))
	type_label.text = str(data.get("type", ""))
	cost_label.text = "Cost %s | Cog %s" % [
		str(data.get("cost", 0)),
		str(data.get("cognition", 0))
	]
	desc_label.text = str(data.get("desc", ""))

func set_selected(selected: bool) -> void:
	is_selected = selected
	if is_selected:
		self_modulate = Color(1.0, 0.95, 0.75)
	else:
		self_modulate = Color(1, 1, 1)

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)

func _on_mouse_entered() -> void:
	if not disabled and not is_selected:
		self_modulate = Color(0.9, 1.0, 0.9)

func _on_mouse_exited() -> void:
	if not is_selected:
		self_modulate = Color(1, 1, 1)

func _pressed() -> void:
	# 只有非拖动的点击才触发卡牌选择
	var mouse_travel = get_global_mouse_position().distance_to(_drag_start_mouse_pos)
	if mouse_travel < DRAG_THRESHOLD:
		card_pressed.emit(card_instance_id)

# 鼠标按下：开始拖动
func _on_button_down() -> void:
	is_dragging = true
	_original_global_pos = global_position
	_drag_start_mouse_pos = get_global_mouse_position()
	drag_offset = global_position - get_global_mouse_position()
	top_level = true
	global_position = _original_global_pos
	z_index = 10

# 鼠标松开：卡牌回归初始位置
func _on_button_up() -> void:
	if is_dragging:
		is_dragging = false
		top_level = false
		z_index = 0

func _process(_delta: float) -> void:
	if is_dragging:
		global_position = get_global_mouse_position() + drag_offset

func set_display_size(size: Vector2) -> void:
	custom_minimum_size = size
