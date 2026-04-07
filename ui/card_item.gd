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

func _on_mouse_entered() -> void:
	if not disabled and not is_selected:
		self_modulate = Color(0.9, 1.0, 0.9)

func _on_mouse_exited() -> void:
	if not is_selected:
		self_modulate = Color(1, 1, 1)

func _pressed() -> void:
	card_pressed.emit(card_instance_id)

func set_display_size(size: Vector2) -> void:
	custom_minimum_size = size
