class_name FloatingText
extends Node2D

@onready var label: Label = $Label

func setup(text: String, color: Color) -> void:
	if not label:
		label = $Label
	label.text = text
	label.add_theme_color_override("font_color", color)

	scale = Vector2(0.5, 0.5)
	modulate.a = 1.0

	var duration := 0.75
	var tween := create_tween().set_parallel(true)

	# Float up
	tween.tween_property(self, "position:y", position.y - 70.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Pop scale
	var sc_tween := create_tween()
	sc_tween.tween_property(self, "scale", Vector2(1.25, 1.25), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	sc_tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_SINE)

	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, 0.3).set_delay(duration - 0.3)

	tween.chain().tween_callback(queue_free)
