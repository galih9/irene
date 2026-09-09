class_name SaveToast
extends Control

@onready var panel: PanelContainer = $Panel
@onready var message_label: Label = $Panel/Margin/HBox/Label
@onready var icon_label: Label = $Panel/Margin/HBox/Icon

var _anim_tween: Tween = null
var _original_y: float = 0.0

func _ready() -> void:
	visible = false
	modulate.a = 0.0
	_original_y = position.y
	if SaveManager:
		SaveManager.toast_requested.connect(show_toast)

func show_toast(text: String, duration: float = 3.0) -> void:
	if not is_inside_tree():
		return

	message_label.text = text
	visible = true

	if _anim_tween and _anim_tween.is_valid():
		_anim_tween.kill()

	_anim_tween = create_tween().set_parallel(false)
	
	# Initial position & opacity
	position.y = _original_y - 25.0
	modulate.a = 0.0

	# Slide in and fade in
	var in_tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	in_tween.tween_property(self, "position:y", _original_y, 0.25)
	in_tween.tween_property(self, "modulate:a", 1.0, 0.2)

	# Pulse icon
	var icon_tween := create_tween().set_loops(int(duration * 2)).set_trans(Tween.TRANS_SINE)
	icon_tween.tween_property(icon_label, "scale", Vector2(1.2, 1.2), 0.25)
	icon_tween.tween_property(icon_label, "scale", Vector2.ONE, 0.25)

	# Hold on screen
	_anim_tween.tween_interval(duration)

	# Slide out and fade out
	_anim_tween.tween_property(self, "position:y", _original_y - 25.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_anim_tween.parallel().tween_property(self, "modulate:a", 0.0, 0.25)
	_anim_tween.finished.connect(func():
		visible = false
		if icon_tween and icon_tween.is_valid():
			icon_tween.kill()
		icon_label.scale = Vector2.ONE
	)
