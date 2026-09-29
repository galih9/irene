class_name RollerStation
extends Control

## Manages the active roller slots in the middle area.
## Supports dynamic slot counts (3 slots initially, upgradable to 2, 3, 4, 5, etc.).
## Dispatches spools to slots and handles layout positioning.

signal slot_selected(slot: RollerSlot)
signal spool_docked(slot: RollerSlot, spool: RollerSpool)
signal roller_finished(slot: RollerSlot, cloth: Node)
signal slots_upgraded(new_count: int)

@export var max_slots: int = 3
@export var slot_spacing: float = 120.0

var slots: Array[RollerSlot] = []

func _ready() -> void:
	custom_minimum_size = Vector2(400, 110)
	mouse_filter = MOUSE_FILTER_PASS
	resized.connect(update_layout)

func setup_station(p_slot_count: int = 3) -> void:
	clear_station()
	max_slots = max(1, p_slot_count)
	_build_slots()

func upgrade_slots(new_count: int) -> void:
	if new_count <= max_slots:
		return
	var prev_count := max_slots
	max_slots = new_count

	# Add new slots
	for i in range(prev_count, max_slots):
		var slot := RollerSlot.new()
		slot.name = "RollerSlot_%d" % i
		slot.slot_id = i
		add_child(slot)
		slot.slot_clicked.connect(func(s): slot_selected.emit(s))
		slot.spool_docked.connect(func(s, sp): spool_docked.emit(s, sp))
		slot.roll_cycle_finished.connect(_on_slot_roll_cycle_finished)
		slots.append(slot)
		# Entrance scale pop
		slot.scale = Vector2.ZERO
		var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(slot, "scale", Vector2.ONE, 0.3)

	update_layout()
	slots_upgraded.emit(max_slots)

func add_slot() -> void:
	upgrade_slots(max_slots + 1)

func _build_slots() -> void:
	for i in range(max_slots):
		var slot := RollerSlot.new()
		slot.name = "RollerSlot_%d" % i
		slot.slot_id = i
		add_child(slot)
		slot.slot_clicked.connect(func(s): slot_selected.emit(s))
		slot.spool_docked.connect(func(s, sp): spool_docked.emit(s, sp))
		slot.roll_cycle_finished.connect(_on_slot_roll_cycle_finished)
		slots.append(slot)
	update_layout()

func update_layout() -> void:
	if slots.is_empty():
		return
	var count := slots.size()
	var current_w := size.x if size.x > 100.0 else (custom_minimum_size.x if custom_minimum_size.x > 100.0 else 672.0)
	var current_h := size.y if size.y > 50.0 else (custom_minimum_size.y if custom_minimum_size.y > 50.0 else 110.0)

	var total_w := float(count - 1) * slot_spacing
	var start_x := (current_w - total_w) * 0.5
	var center_y := (current_h - 76.0) * 0.5

	for i in range(count):
		var target_x := start_x + float(i) * slot_spacing - 38.0
		var target_pos := Vector2(target_x, center_y)
		var slot := slots[i]
		if slot.position == Vector2.ZERO or slot.position.x < -10.0:
			slot.position = target_pos
		else:
			var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(slot, "position", target_pos, 0.25)

func _on_slot_roll_cycle_finished(slot: RollerSlot, cloth: Node, _spool: RollerSpool) -> void:
	roller_finished.emit(slot, cloth)

func get_first_empty_slot() -> RollerSlot:
	for slot in slots:
		if is_instance_valid(slot) and not slot.is_occupied:
			return slot
	return null

func has_empty_slot() -> bool:
	return get_first_empty_slot() != null

func get_occupied_slots() -> Array[RollerSlot]:
	var occupied: Array[RollerSlot] = []
	for slot in slots:
		if is_instance_valid(slot) and slot.is_occupied:
			occupied.append(slot)
	return occupied

func get_ready_to_roll_slots() -> Array[RollerSlot]:
	var ready_slots: Array[RollerSlot] = []
	for slot in slots:
		if is_instance_valid(slot) and slot.is_occupied and not slot.is_rolling and not slot.is_docking and is_instance_valid(slot.current_spool):
			ready_slots.append(slot)
	return ready_slots

func is_all_idle() -> bool:
	for slot in slots:
		if is_instance_valid(slot) and (slot.is_rolling or slot.is_docking):
			return false
	return true

## Checks if game is jammed: all slots occupied, none rolling or docking, and none match any exposed cloth cell.
func is_jammed(grid: ClothGrid) -> bool:
	if has_empty_slot() or not is_all_idle() or not is_instance_valid(grid):
		return false
	var exposed_cells := grid.get_exposed_cells()
	if exposed_cells.is_empty():
		return false

	var exposed_colors: Array[String] = []
	for ec in exposed_cells:
		var ec_color := str(ec.get("color", ""))
		if ec_color != "" and not exposed_colors.has(ec_color):
			exposed_colors.append(ec_color)

	for slot in slots:
		if is_instance_valid(slot) and is_instance_valid(slot.current_spool):
			if exposed_colors.has(slot.current_spool.color_id):
				return false
	return true

func clear_station() -> void:
	for slot in slots:
		if is_instance_valid(slot):
			slot.clear_slot()
			slot.queue_free()
	slots.clear()
