extends Label

var velocity: Vector2 = Vector2(0, -88)
var lifetime: float = 0.8
var elapsed: float = 0.0

func _ready() -> void:
	modulate.a = 1.0
	scale = Vector2(0.65, 0.65)
	rotation = randf_range(-0.08, 0.08)
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.12)
	tween.tween_property(self, "scale", Vector2.ONE, 0.12)
	set_process(true)

func _process(delta: float) -> void:
	elapsed += delta
	position += velocity * delta
	velocity = velocity.move_toward(Vector2(0, -24), 180 * delta)
	modulate.a = clamp(1.0 - elapsed / lifetime, 0.0, 1.0)
	if elapsed >= lifetime:
		queue_free()
