class_name ModalPresenter
extends Node
## Shared focus management and panel-only transitions for dismissible dialogs.

var dialog: Control
var dismiss: Callable
var close_button: Button
var previous_focus: WeakRef

static func install(target: Control, button: Button, close_action: Callable) -> void:
	var presenter := ModalPresenter.new()
	presenter.dialog = target
	presenter.close_button = button
	presenter.dismiss = close_action
	target.add_child(presenter)
	target.visibility_changed.connect(presenter._visibility_changed)
	button.tooltip_text = "Close · Esc"

func _visibility_changed() -> void:
	if dialog.visible:
		var focused := dialog.get_viewport().gui_get_focus_owner()
		previous_focus = weakref(focused) if focused else null
		close_button.grab_focus.call_deferred()
	elif previous_focus:
		var previous := previous_focus.get_ref() as Control
		if is_instance_valid(previous) and previous.is_visible_in_tree():
			previous.grab_focus()

func _input(event: InputEvent) -> void:
	if not dialog.is_visible_in_tree():
		return
	var focused := dialog.get_viewport().gui_get_focus_owner()
	if focused and not dialog.is_ancestor_of(focused):
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		dismiss.call()
	elif event.is_action_pressed("ui_focus_next") or event.is_action_pressed("ui_focus_prev"):
		var controls: Array[Control] = []
		for node in dialog.find_children("*", "Control", true, false):
			if node.is_visible_in_tree() and node.focus_mode == Control.FOCUS_ALL:
				if not (node is BaseButton and node.disabled):
					controls.append(node)
		if not controls.is_empty():
			var direction := -1 if event.is_action_pressed("ui_focus_prev") else 1
			controls[posmod(controls.find(focused) + direction, controls.size())].grab_focus()
			get_viewport().set_input_as_handled()

static func show_dialog(target: Control) -> void:
	_stop_tween(target)
	target.scale = Vector2.ONE
	target.visible = true
	var panel := target.get_node("Panel") as Control
	panel.pivot_offset = panel.size * 0.5
	panel.scale = Vector2(0.97, 0.97)
	panel.modulate.a = 0.0
	var tween := target.create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.20)
	tween.tween_property(panel, "modulate:a", 1.0, 0.16)
	target.set_meta("presentation_tween", tween)

static func hide_dialog(target: Control, after_close: Callable = Callable()) -> void:
	_stop_tween(target)
	var panel := target.get_node("Panel") as Control
	var tween := target.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(panel, "modulate:a", 0.0, 0.12)
	tween.tween_callback(func():
		target.visible = false
		panel.modulate.a = 1.0
		if after_close.is_valid():
			after_close.call()
	)
	target.set_meta("presentation_tween", tween)

static func _stop_tween(target: Control) -> void:
	if target.has_meta("presentation_tween"):
		var tween: Tween = target.get_meta("presentation_tween")
		if tween and tween.is_valid():
			tween.kill()
