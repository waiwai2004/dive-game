extends Control

@onready var spear = $Spear
@onready var ripple = $Ripple

func _ready() -> void:
	visible = false

func play_at(global_target: Vector2) -> void:
	visible = true
	global_position = global_target + Vector2(-30, -30)
	scale = Vector2.ONE
	rotation = randf_range(-0.08, 0.08)
	spear.size = Vector2(0, 16)
	spear.position = Vector2(-240, 20)
	spear.modulate = Color(1, 0.9, 0.4, 1)
	ripple.size = Vector2(8, 8)
	ripple.position = Vector2(36, 18)
	ripple.modulate = Color(1, 1, 0.5, 0.45)

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(spear, "size", Vector2(250, 16), 0.12)
	tween.parallel().tween_property(self, "scale", Vector2(1.06, 1.06), 0.12)
	tween.parallel().tween_property(spear, "modulate:a", 0.0, 0.16)
	tween.tween_property(ripple, "size", Vector2(120, 120), 0.22)
	tween.parallel().tween_property(ripple, "position", Vector2(-20, -18), 0.22)
	tween.parallel().tween_property(ripple, "modulate:a", 0.0, 0.22)
	tween.tween_callback(func(): queue_free()).set_delay(0.02)
