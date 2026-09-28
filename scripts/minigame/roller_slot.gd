class_name RollerSlot
extends Control

## Represents an active rolling slot/station in the middle of the board.
## Holds a RollerSpool, manages clean docking, draws the vibrating thread line
## connecting to the target BigCloth during cell unrolling, and coordinates the
## throwing-out animation when the roller reaches its capacity.

signal slot_clicked(slot: RollerSlot)
signal spool_docked(slot: RollerSlot, spool: RollerSpool)
signal roll_cycle_finished(slot: RollerSlot, cloth: Node, spool: RollerSpool)

@export var slot_id: int = 0

var is_occupied: bool = false
var is_rolling: bool = false
var is_docking: bool = false # True during the entrance flight/docking animation

var current_spool: RollerSpool = null
var current_cloth: Node = null  # BigCloth (or legacy ClothBlock)

# Thread drawing parameters
var _thread_points: PackedVector2Array = []
var _thread_color: Color = Color.WHITE
var _thread_timer: float = 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(76, 76)
	size = custom_minimum_size
	pivot_offset = size * 0.5
	mouse_filter = MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		slot_clicked.emit(self)

func _process(delta: float) -> void:
	if is_rolling and is_instance_valid(current_cloth) and is_instance_valid(current_spool):
		_thread_timer += delta * 35.0
		_update_thread_geometry()
		queue_redraw()
	elif _thread_points.size() > 0:
		_thread_points.clear()
		queue_redraw()

func _update_thread_geometry() -> void:
	if not is_instance_valid(current_cloth):
		_thread_points.clear()
		return

	var start_pt := Vector2(size.x * 0.5, size.y * 0.5)
	# Target in slot local coordinates
	var target_pt: Vector2 = current_cloth.get_attachment_point() - global_position

	var dist := start_pt.distance_to(target_pt)
	if dist <= 5.0:
		_thread_points.clear()
		return

	var segs := 10
	_thread_points.resize(segs + 1)
	var dir := (target_pt - start_pt).normalized()
	var normal := Vector2(-dir.y, dir.x)

	for i in range(segs + 1):
		var t := float(i) / float(segs)
		var base_pos := start_pt.lerp(target_pt, t)
		# Sine wave vibration that diminishes at endpoints
		var wave_amp := sin(t * PI) * 3.5 * sin(_thread_timer + t * 4.0)
		_thread_points[i] = base_pos + normal * wave_amp

func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.46

	# 1. Base dock socket (metallic dish / socket)
	draw_circle(center + Vector2(0, 3), radius, Color(0, 0, 0, 0.22))
	var base_bg := Color(0.18, 0.20, 0.25, 0.95)
	draw_circle(center, radius, base_bg)

	# Ring outline (golden if occupied, subtle dashed if empty)
	var ring_col := Color(1.0, 0.85, 0.35, 0.9) if is_occupied else Color(0.55, 0.60, 0.70, 0.6)
	draw_arc(center, radius, 0, TAU, 32, ring_col, 2.5, true)

	if not is_occupied:
		# Inner center hole and guide dots
		draw_circle(center, radius * 0.35, Color(0.12, 0.13, 0.16, 1.0))
		draw_arc(center, radius * 0.65, 0, TAU, 16, Color(0.4, 0.45, 0.55, 0.4), 1.5, true)
		draw_circle(center, 3.0, Color(0.7, 0.75, 0.85, 0.5))

	# 2. Thread line if currently rolling
	if is_rolling and _thread_points.size() > 1:
		for i in range(_thread_points.size() - 1):
			draw_line(_thread_points[i], _thread_points[i + 1], _thread_color, 3.2, true)
			draw_line(_thread_points[i], _thread_points[i + 1], Color.WHITE, 1.2, true)

## Places a spool into this slot and animates entrance flight.
## Rolling cannot start until docking is fully finished.
func receive_spool(spool: RollerSpool, from_global_pos: Vector2 = Vector2.ZERO) -> void:
	if is_occupied:
		return
	is_occupied = true
	is_rolling = false
	is_docking = true
	current_spool = spool

	if spool.get_parent() != null:
		spool.get_parent().remove_child(spool)
	add_child(spool)

	spool.setup(spool.color_id, size * 0.88, spool.capacity)
	var final_pos := (size - spool.size) * 0.5

	if from_global_pos != Vector2.ZERO:
		var start_local: Vector2 = from_global_pos - global_position
		spool.position = start_local
		spool.scale = Vector2(0.65, 0.65)
		spool.pivot_offset = spool.size * 0.5

		var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(spool, "position", final_pos, 0.28)
		tween.tween_property(spool, "scale", Vector2.ONE, 0.28)
		tween.tween_property(spool, "rotation", TAU, 0.28)

		tween.chain().tween_callback(func():
			if not is_instance_valid(spool):
				is_docking = false
				return
			spool.position = final_pos
			spool.rotation = 0.0
			# Satisfying dock bounce
			var dock_tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			dock_tween.tween_property(spool, "scale", Vector2(1.15, 1.15), 0.08)
			dock_tween.tween_property(spool, "scale", Vector2.ONE, 0.08)
			dock_tween.chain().tween_callback(func():
				is_docking = false
				spool_docked.emit(self, spool)
			)
			if is_instance_valid(SoundManager):
				SoundManager.play_click()
		)
	else:
		spool.position = final_pos
		spool.scale = Vector2.ONE
		spool.rotation = 0.0
		is_docking = false
		spool_docked.emit(self, spool)

	queue_redraw()

## Begins unrolling thread cell-by-cell (1 second per cell) from cloth into this slot's spool.
func start_rolling(cloth: Node, cells_to_roll: int = 1, on_finished: Callable = Callable()) -> void:
	if not is_occupied or is_rolling or is_docking or not is_instance_valid(current_spool) or not is_instance_valid(cloth):
		return

	var available_capacity := current_spool.get_available_capacity()
	var actual_cells := mini(cells_to_roll, available_capacity)
	actual_cells = mini(actual_cells, cloth.remaining_cells)
	if cloth.has_method("get_consecutive_color_count") and cloth.has_method("find_matching_exposed_col"):
		var match_col: int = cloth.find_matching_exposed_col(current_spool.color_id)
		if match_col >= 0:
			var max_match: int = cloth.get_consecutive_color_count(match_col, current_spool.color_id)
			actual_cells = mini(actual_cells, max_match)

	if actual_cells <= 0:
		return

	is_rolling = true
	current_cloth = cloth
	_thread_color = ThreadColorPalette.get_thread_color(current_spool.color_id)
	_thread_timer = 0.0

	current_spool.start_spinning()

	cloth.roll_cells(
		actual_cells,
		global_position + size * 0.5,
		func():
			# Called every 1.0 second per cell rolled
			if is_instance_valid(current_spool):
				current_spool.add_fill(1)
			queue_redraw(),
		func():
			_finish_rolling(on_finished)
	)

func _finish_rolling(on_finished: Callable) -> void:
	is_rolling = false
	_thread_points.clear()
	queue_redraw()

	var rolled_cloth := current_cloth
	current_cloth = null

	var departing_spool: RollerSpool = null

	if is_instance_valid(current_spool):
		current_spool.stop_spinning()

		if current_spool.is_full():
			# Throwing out animation: Spool is full, toss it out cleanly in an arcing trajectory!
			departing_spool = current_spool
			current_spool = null
			is_occupied = false
			queue_redraw()

			# Determine throw direction: center/right goes right, left goes left
			var exit_dir := Vector2(1.0, -0.6) if slot_id == 0 or slot_id % 2 == 1 else Vector2(-1.0, -0.6)

			# Reparent to top minigame layer so it flies freely across screen without clipping
			var top_layer: Node = get_tree().root
			var p: Node = get_parent()
			while p != null:
				if p.has_method("start_level") or p is CanvasLayer or p is Window:
					top_layer = p
					break
				p = p.get_parent()

			var start_gpos := departing_spool.global_position
			departing_spool.get_parent().remove_child(departing_spool)
			top_layer.add_child(departing_spool)
			departing_spool.global_position = start_gpos

			if is_instance_valid(SoundManager):
				SoundManager.play_drop()

			departing_spool.animate_eject(exit_dir, func():
				pass
			)
		else:
			queue_redraw()

	roll_cycle_finished.emit(self, rolled_cloth, departing_spool if departing_spool else current_spool)
	if on_finished.is_valid():
		on_finished.call()

func clear_slot() -> void:
	if is_instance_valid(current_spool):
		current_spool.queue_free()
		current_spool = null
	is_occupied = false
	is_rolling = false
	is_docking = false
	current_cloth = null
	_thread_points.clear()
	queue_redraw()
