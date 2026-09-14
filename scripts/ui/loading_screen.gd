class_name LoadingScreen
extends Control

signal transition_completed()

@onready var dimmer: ColorRect = $Dimmer
@onready var label: Label = $Center/VBox/Label
@onready var icon: TextureRect = $Center/VBox/Icon
@onready var dots_label: Label = $Center/VBox/DotsLabel

var _dot_timer: float = 0.0
var _dot_count: int = 0
var _is_transitioning: bool = false

func _ready() -> void:
	visible = false
	modulate = Color(1, 1, 1, 0)

func _process(delta: float) -> void:
	if _is_transitioning:
		_dot_timer += delta
		if _dot_timer >= 0.3:
			_dot_timer = 0.0
			_dot_count = (_dot_count + 1) % 4
			if is_instance_valid(dots_label):
				dots_label.text = ".".repeat(_dot_count)
		if is_instance_valid(icon):
			icon.rotation += delta * 2.5

func play_transition(to_level_name: String, on_switch_callback: Callable) -> void:
	_is_transitioning = true
	visible = true
	if is_instance_valid(label):
		label.text = "Traveling to %s" % to_level_name
	if is_instance_valid(dots_label):
		dots_label.text = ""
	_dot_count = 0
	_dot_timer = 0.0

	# Fade in
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.2)
	tween.tween_callback(func():
		if on_switch_callback.is_valid():
			on_switch_callback.call()
	)
	tween.tween_interval(0.35)
	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		_is_transitioning = false
		visible = false
		transition_completed.emit()
	)
