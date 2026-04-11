extends RichTextLabel

func _ready() -> void:
	bbcode_enabled = true

	var effect: RichTextEffect = preload("res://richtext2/text_effects/effects/rte_wave.gd").new()
	custom_effects.append(effect)

	text = "[wave]海底无[color=#ff5555]明日[/color][/wave]"
