class_name RollerQueue
extends Control

## Manages the conveyor queue of upcoming thread rollers.
## Clicking a specific spool dispatches THAT spool (not always the front).
## The remaining spools slide forward to fill the gap.

signal spool_dispatched(spool: RollerSpool)
signal queue_empty()

@export var spool_spacing: float = 64.0
@export var max_visible_spools: int = 9

var spool_queue: Array[RollerSpool] = []

func _ready() -> void:
	custom_minimum_size = Vector2(600, 80)
	mouse_filter = MOUSE_FILTER_PASS

func setup_queue(colors_list: Array[String], capacity_per_spool: int = 3) -> void:
	clear_queue()
	for color_id in colors_list:
		var spool := RollerSpool.new()
		spool.setup(color_id, Vector2(50, 50), capacity_per_spool)
		add_child(spool)
		# Pass the specific spool that was clicked — not a fixed front pop
		spool.spool_clicked.connect(_on_specific_spool_clicked)
		spool_queue.append(spool)

	update_layout(false)

func update_spools_capacity(new_capacity: int) -> void:
	for spool in spool_queue:
		if is_instance_valid(spool) and spool.current_fill == 0:
			spool.capacity = new_capacity
			spool.queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	# Conveyor track background
	var track_c := Color(0.12, 0.14, 0.18, 0.65)
	var border_c := Color(0.35, 0.38, 0.45, 0.4)
	draw_rect(rect, track_c, true, -1, false)
	draw_rect(rect, border_c, false, 2.0, false)

	# Subtle guide rail
	var rail_y := size.y * 0.5
	draw_line(Vector2(16, rail_y), Vector2(size.x - 16, rail_y), Color(1, 1, 1, 0.08), 2.0)

func update_layout(animated: bool = true) -> void:
	var count := spool_queue.size()
	var center_y := (size.y - 50.0) * 0.5
	var start_x := 32.0

	for i in range(count):
		var spool := spool_queue[i]
		if not is_instance_valid(spool):
			continue
		var target_pos := Vector2(start_x + float(i) * spool_spacing, center_y)

		# Only display up to max_visible_spools
		if i >= max_visible_spools:
			spool.visible = false
		else:
			spool.visible = true
			var alpha := 1.0 if i < (max_visible_spools - 2) else 0.5
			spool.modulate.a = alpha

		if animated:
			var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(spool, "position", target_pos, 0.22)
		else:
			spool.position = target_pos

## Called when the player taps a specific spool in the queue.
## Dispatches THAT spool — not necessarily the front one.
func _on_specific_spool_clicked(clicked_spool: RollerSpool) -> void:
	dispatch_spool(clicked_spool)

## Removes a specific spool from anywhere in the queue and dispatches it.
## Does nothing if there are no empty roller slots to receive it.
func dispatch_spool(spool: RollerSpool) -> void:
	if not is_instance_valid(spool):
		return
	if not spool_queue.has(spool):
		return

	# Only dispatch if there's an empty slot waiting — otherwise shake the spool to give feedback
	# (the minigame will handle actual slot assignment via spool_dispatched signal)
	# We let ThreadRollerMinigame decide if there's a slot; just emit the signal.
	# But guard against double-dispatching the same spool.
	if spool.get_parent() != self:
		return  # Already being dispatched or reparented

	# Brief selection pulse before flying to the slot
	_play_select_pulse(spool)

	spool_queue.erase(spool)
	update_layout(true)

	if spool_queue.is_empty():
		queue_empty.emit()

	spool_dispatched.emit(spool)

## Plays a quick scale-pop highlight on the selected spool.
func _play_select_pulse(spool: RollerSpool) -> void:
	if not is_instance_valid(spool):
		return
	spool.pivot_offset = spool.size * 0.5
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(spool, "scale", Vector2(1.3, 1.3), 0.08)
	tween.tween_property(spool, "scale", Vector2.ONE, 0.08)

## Pops the front spool from the queue and slides the rest forward.
func pop_front_spool() -> RollerSpool:
	if spool_queue.is_empty():
		queue_empty.emit()
		return null

	var front: RollerSpool = spool_queue.pop_front()
	update_layout(true)

	if spool_queue.is_empty():
		queue_empty.emit()

	return front

func dispatch_front() -> RollerSpool:
	var front := pop_front_spool()
	if front != null:
		spool_dispatched.emit(front)
	return front

func peek_front_spool() -> RollerSpool:
	if spool_queue.is_empty():
		return null
	return spool_queue[0]

func has_spools() -> bool:
	return not spool_queue.is_empty()

func get_remaining_count() -> int:
	return spool_queue.size()

func clear_queue() -> void:
	for spool in spool_queue:
		if is_instance_valid(spool):
			spool.queue_free()
	spool_queue.clear()
