class_name Board
extends Node2D

const COLS: int = 7
const ROWS: int = 9
const CELL_SIZE: float = 88.0
const CELL_SPACING: float = 8.0

const BOARD_WIDTH: float = COLS * CELL_SIZE + (COLS - 1) * CELL_SPACING # 664
const BOARD_HEIGHT: float = ROWS * CELL_SIZE + (ROWS - 1) * CELL_SPACING # 856

const DRAG_THRESHOLD: float = 12.0

@export var item_view_scene: PackedScene = preload("res://scenes/item_view.tscn")
@export var cell_scene: PackedScene = preload("res://scenes/board_cell.tscn")

@onready var cells_container: Control = $CellsContainer
@onready var items_container: Node2D = $ItemsContainer

# Grid data: grid[col][row] -> ItemView or null
var _grid: Array = []
var _cells: Array = [] # 2D array of BoardCell

# Interaction state
var _active_item: ItemView = null
var _drag_start_mouse_pos: Vector2 = Vector2.ZERO
var _item_start_local_pos: Vector2 = Vector2.ZERO
var _item_start_coord: Vector2i = Vector2i(-1, -1)
var _is_dragging: bool = false
var _press_time: float = 0.0
var _hovered_merge_item: ItemView = null
var _last_highlighted_cell: BoardCell = null

# Reference to inventory bar for cross-panel drag and drop
var inventory_bar: InventoryBar = null
var sell_bin: Control = null

func _ready() -> void:
	_init_grid()
	_create_cells()

func _init_grid() -> void:
	_grid.clear()
	_cells.clear()
	for c in range(COLS):
		var col_items: Array = []
		var col_cells: Array = []
		col_items.resize(ROWS)
		col_cells.resize(ROWS)
		col_items.fill(null)
		col_cells.fill(null)
		_grid.append(col_items)
		_cells.append(col_cells)

func _create_cells() -> void:
	for child in cells_container.get_children():
		child.queue_free()

	for c in range(COLS):
		for r in range(ROWS):
			var cell: BoardCell = cell_scene.instantiate()
			cell.grid_coord = Vector2i(c, r)
			cell.position = get_cell_top_left(c, r)
			cells_container.add_child(cell)
			_cells[c][r] = cell

func get_cell_top_left(col: int, row: int) -> Vector2:
	var x := col * (CELL_SIZE + CELL_SPACING)
	var y := row * (CELL_SIZE + CELL_SPACING)
	return Vector2(x, y)

func get_cell_center(col: int, row: int) -> Vector2:
	return get_cell_top_left(col, row) + Vector2(CELL_SIZE * 0.5, CELL_SIZE * 0.5)

func world_to_grid(world_pos: Vector2) -> Vector2i:
	var local_pos := to_local(world_pos)
	if local_pos.x < 0 or local_pos.x > BOARD_WIDTH or local_pos.y < 0 or local_pos.y > BOARD_HEIGHT:
		return Vector2i(-1, -1)

	var col := int(local_pos.x / (CELL_SIZE + CELL_SPACING))
	var row := int(local_pos.y / (CELL_SIZE + CELL_SPACING))

	col = clampi(col, 0, COLS - 1)
	row = clampi(row, 0, ROWS - 1)

	# Verify within cell bounds (not in gap)
	var cell_pos := get_cell_top_left(col, row)
	var offset := local_pos - cell_pos
	if offset.x < 0 or offset.x > CELL_SIZE or offset.y < 0 or offset.y > CELL_SIZE:
		# Still snap to closest cell if inside spacing
		pass

	return Vector2i(col, row)

func is_valid_coord(coord: Vector2i) -> bool:
	return coord.x >= 0 and coord.x < COLS and coord.y >= 0 and coord.y < ROWS

func get_item_at(coord: Vector2i) -> ItemView:
	if not is_valid_coord(coord):
		return null
	return _grid[coord.x][coord.y]

func set_item_at(coord: Vector2i, item: ItemView) -> void:
	if not is_valid_coord(coord):
		return
	_grid[coord.x][coord.y] = item
	if item:
		item.grid_coord = coord
		item.is_in_inventory = false
		item.inventory_slot_idx = -1
		if item.get_parent() != items_container:
			if item.get_parent():
				item.get_parent().remove_child(item)
			items_container.add_child(item)
		item.position = get_cell_center(coord.x, coord.y)

func get_empty_cells() -> Array[Vector2i]:
	var empty: Array[Vector2i] = []
	for c in range(COLS):
		for r in range(ROWS):
			if _grid[c][r] == null:
				empty.append(Vector2i(c, r))
	return empty

func spawn_item_at(coord: Vector2i, item_id: String) -> ItemView:
	if not is_valid_coord(coord):
		return null
	var data := ItemDatabase.get_item(item_id)
	if not data:
		return null

	# Remove existing if any
	var existing := get_item_at(coord)
	if existing:
		existing.queue_free()

	var item: ItemView = item_view_scene.instantiate()
	items_container.add_child(item)
	item.setup(data)
	set_item_at(coord, item)
	GameEvents.board_changed.emit()
	return item

func spawn_item_flight(from_world_pos: Vector2, target_coord: Vector2i, item_id: String) -> ItemView:
	if not is_valid_coord(target_coord):
		return null
	var data := ItemDatabase.get_item(item_id)
	if not data:
		return null

	var item: ItemView = item_view_scene.instantiate()
	items_container.add_child(item)
	item.setup(data)
	_grid[target_coord.x][target_coord.y] = item
	item.grid_coord = target_coord
	item.is_in_inventory = false

	var to_world_pos := to_global(get_cell_center(target_coord.x, target_coord.y))
	item.animate_spawn_flight(from_world_pos, to_world_pos, func():
		item.position = get_cell_center(target_coord.x, target_coord.y)
		GameEvents.item_spawned.emit(item_id, to_world_pos)
		GameEvents.board_changed.emit()
	)
	return item

# --- Drag and Drop & Tap Processing ---

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_handle_press(mb.global_position)
			else:
				_handle_release(mb.global_position)
	elif event is InputEventMouseMotion and _active_item:
		_handle_motion(event.global_position)

func _handle_press(mouse_pos: Vector2) -> void:
	var coord := world_to_grid(mouse_pos)
	var item := get_item_at(coord)

	# Also check if user clicked an inventory item
	if not item and inventory_bar:
		var inv_idx: int = inventory_bar.get_slot_at_world_pos(mouse_pos)
		if inv_idx >= 0:
			item = inventory_bar.get_item_at(inv_idx)

	if item:
		_active_item = item
		_drag_start_mouse_pos = mouse_pos
		_item_start_local_pos = item.position
		_item_start_coord = item.grid_coord
		_is_dragging = false
		_press_time = Time.get_ticks_msec() / 1000.0

func _handle_motion(mouse_pos: Vector2) -> void:
	if not _active_item:
		return

	if not _is_dragging:
		if mouse_pos.distance_to(_drag_start_mouse_pos) > DRAG_THRESHOLD:
			_is_dragging = true
			_active_item.animate_pickup()
			GameEvents.item_drag_started.emit(_active_item)
		else:
			return

	# Move item with mouse
	_active_item.global_position = mouse_pos

	# Hover preview feedback
	_update_hover_feedback(mouse_pos)

func _update_hover_feedback(mouse_pos: Vector2) -> void:
	_clear_hover_feedback()

	# 1. Over board
	var coord := world_to_grid(mouse_pos)
	if is_valid_coord(coord):
		var target_cell: BoardCell = _cells[coord.x][coord.y]
		var target_item := get_item_at(coord)
		if target_item and target_item != _active_item:
			if _can_merge(_active_item.data, target_item.data):
				target_cell.set_highlight(2) # Merge green
				target_item.set_merge_highlight(true)
				_hovered_merge_item = target_item
			else:
				target_cell.set_highlight(1) # Swap blue
		else:
			target_cell.set_highlight(1) # Empty slot hover
		_last_highlighted_cell = target_cell
		return

	# 2. Over inventory
	if inventory_bar:
		var inv_idx: int = inventory_bar.get_slot_at_world_pos(mouse_pos)
		if inv_idx >= 0:
			inventory_bar.set_slot_highlight(inv_idx, 1)

func _clear_hover_feedback() -> void:
	if _last_highlighted_cell:
		_last_highlighted_cell.set_highlight(0)
		_last_highlighted_cell = null
	if _hovered_merge_item:
		_hovered_merge_item.set_merge_highlight(false)
		_hovered_merge_item = null
	if inventory_bar:
		inventory_bar.clear_highlights()

func _handle_release(mouse_pos: Vector2) -> void:
	if not _active_item:
		return

	var item := _active_item
	_active_item = null
	_clear_hover_feedback()

	if not _is_dragging:
		# It's a tap/click!
		_handle_item_tap(item)
		return

	# Finish drag
	item.animate_drop()
	GameEvents.item_drag_ended.emit(item)

	# Check Sell Bin drop
	if sell_bin and sell_bin.get_global_rect().has_point(mouse_pos):
		_sell_item(item)
		return

	# Check Inventory drop
	if inventory_bar and inventory_bar.is_pos_inside(mouse_pos):
		var target_slot: int = inventory_bar.get_slot_at_world_pos(mouse_pos)
		if target_slot >= 0:
			_drop_into_inventory(item, target_slot)
			return

	# Check Board drop
	var target_coord := world_to_grid(mouse_pos)
	if is_valid_coord(target_coord):
		_drop_into_board(item, target_coord)
		return

	# Dropped outside: bounce back to origin
	_return_item_to_origin(item)

func _handle_item_tap(item: ItemView) -> void:
	# 1. Spawner tap
	if item.data.is_spawner:
		_trigger_spawner(item)
		return

	# 2. Consumable tap
	if item.data.is_consumable:
		_trigger_consumable(item)
		return

	# 3. Normal item tap: juicy wobble & info
	item.animate_wobble()
	SoundManager.play_pickup()
	GameEvents.show_floating_text.emit(
		"%s (T%d)" % [item.data.display_name, item.data.tier],
		item.global_position + Vector2(0, -50),
		Color(1.0, 0.9, 0.5)
	)

func _trigger_spawner(spawner: ItemView) -> void:
	if not EconomyManager.has_energy(spawner.data.energy_cost):
		spawner.animate_wobble()
		SoundManager.play_error()
		GameEvents.show_floating_text.emit("Need Energy! ⚡", spawner.global_position + Vector2(0, -50), Color(1.0, 0.4, 0.4))
		return

	var empty_cells := get_empty_cells()
	if empty_cells.is_empty():
		spawner.animate_wobble()
		SoundManager.play_error()
		GameEvents.show_floating_text.emit("Board is Full!", spawner.global_position + Vector2(0, -50), Color(1.0, 0.4, 0.4))
		return

	# Deduct energy and trigger animation
	EconomyManager.consume_energy(spawner.data.energy_cost)
	spawner.animate_spawner_tap()
	SoundManager.play_spawn()

	# Pick drop item
	var drop_id := ItemDatabase.get_spawner_drop(spawner.data.id)

	# Find closest empty cell
	var best_coord := empty_cells[0]
	var best_dist := INF
	var spawner_coord := spawner.grid_coord
	for ec in empty_cells:
		var d := Vector2(ec).distance_to(Vector2(spawner_coord))
		if d < best_dist:
			best_dist = d
			best_coord = ec

	spawn_item_flight(spawner.global_position, best_coord, drop_id)

func _trigger_consumable(item: ItemView) -> void:
	var amt := item.data.consume_amount
	var curr := item.data.consume_currency
	var pos := item.global_position

	if curr == "coins":
		EconomyManager.add_coins(amt)
		GameEvents.show_floating_text.emit("+%d Coins!" % amt, pos + Vector2(0, -40), Color(1.0, 0.85, 0.2))
	elif curr == "energy":
		EconomyManager.add_energy(amt)
		GameEvents.show_floating_text.emit("+%d Energy! ⚡" % amt, pos + Vector2(0, -40), Color(0.3, 1.0, 0.5))

	SoundManager.play_consume()
	remove_item(item)
	item.queue_free()
	GameEvents.board_changed.emit()

func _can_merge(data_a: ItemData, data_b: ItemData) -> bool:
	if not data_a or not data_b:
		return false
	if data_a.chain_id != data_b.chain_id:
		return false
	if data_a.tier != data_b.tier:
		return false
	if data_a.tier >= data_a.max_tier:
		return false
	return true

func _drop_into_board(dragged: ItemView, target_coord: Vector2i) -> void:
	var target_item := get_item_at(target_coord)

	# Case 1: Dropped onto same cell
	if target_item == dragged:
		dragged.animate_snap_to(get_cell_center(target_coord.x, target_coord.y))
		return

	# Case 2: Dropped onto merge target
	if target_item and _can_merge(dragged.data, target_item.data):
		_execute_merge(dragged, target_item)
		return

	# Case 3: Dropped onto empty board cell
	if not target_item:
		_clear_source_slot(dragged)
		set_item_at(target_coord, dragged)
		dragged.animate_snap_to(get_cell_center(target_coord.x, target_coord.y))
		GameEvents.board_changed.emit()
		return

	# Case 4: Dropped onto another item -> SWAP
	_execute_swap(dragged, target_item)

func _drop_into_inventory(dragged: ItemView, target_slot_idx: int) -> void:
	var target_item: ItemView = inventory_bar.get_item_at(target_slot_idx)

	# Case 1: Same slot
	if target_item == dragged:
		dragged.animate_snap_to(inventory_bar.get_slot_center(target_slot_idx))
		return

	# Case 2: Merge in inventory
	if target_item and _can_merge(dragged.data, target_item.data):
		_execute_merge(dragged, target_item)
		return

	# Case 3: Empty inventory slot
	if not target_item:
		_clear_source_slot(dragged)
		inventory_bar.set_item_at(target_slot_idx, dragged)
		dragged.animate_snap_to(inventory_bar.get_slot_center(target_slot_idx))
		GameEvents.inventory_changed.emit()
		GameEvents.board_changed.emit()
		return

	# Case 4: Swap between board and inventory (or two inventory slots)
	_execute_swap(dragged, target_item)

func _execute_merge(source: ItemView, target: ItemView) -> void:
	var next_id := target.data.get_next_tier_id()
	var new_data := ItemDatabase.get_item(next_id)
	if not new_data:
		_return_item_to_origin(source)
		return

	_clear_source_slot(source)
	source.queue_free()

	target.setup(new_data)
	target.animate_merge_pop()

	var pop_pos := target.global_position + Vector2(0, -50)
	GameEvents.show_floating_text.emit(
		"%s (T%d)!" % [new_data.display_name, new_data.tier],
		pop_pos,
		Color(1.0, 0.9, 0.3)
	)
	GameEvents.item_merged.emit(source.data.id, target.data.id, next_id, target.global_position)
	GameEvents.board_changed.emit()
	GameEvents.inventory_changed.emit()

func _execute_swap(item_a: ItemView, item_b: ItemView) -> void:
	var a_in_inv := item_a.is_in_inventory
	var a_inv_idx := item_a.inventory_slot_idx
	var a_coord := item_a.grid_coord

	var b_in_inv := item_b.is_in_inventory
	var b_inv_idx := item_b.inventory_slot_idx
	var b_coord := item_b.grid_coord

	# Clear slots
	_clear_source_slot(item_a)
	_clear_source_slot(item_b)

	# Place A in B's old location
	if b_in_inv:
		inventory_bar.set_item_at(b_inv_idx, item_a)
		item_a.animate_snap_to(inventory_bar.get_slot_center(b_inv_idx))
	else:
		set_item_at(b_coord, item_a)
		item_a.animate_snap_to(get_cell_center(b_coord.x, b_coord.y))

	# Place B in A's old location
	if a_in_inv:
		inventory_bar.set_item_at(a_inv_idx, item_b)
		item_b.animate_snap_to(inventory_bar.get_slot_center(a_inv_idx))
	else:
		set_item_at(a_coord, item_b)
		item_b.animate_snap_to(get_cell_center(a_coord.x, a_coord.y))

	SoundManager.play_drop()
	GameEvents.board_changed.emit()
	GameEvents.inventory_changed.emit()

func _clear_source_slot(item: ItemView) -> void:
	if item.is_in_inventory:
		if inventory_bar and item.inventory_slot_idx >= 0:
			inventory_bar.clear_slot(item.inventory_slot_idx)
	else:
		if is_valid_coord(item.grid_coord):
			_grid[item.grid_coord.x][item.grid_coord.y] = null
	item.grid_coord = Vector2i(-1, -1)
	item.inventory_slot_idx = -1

func _return_item_to_origin(item: ItemView) -> void:
	if item.is_in_inventory:
		if inventory_bar:
			item.animate_bounce_back(inventory_bar.get_slot_center(item.inventory_slot_idx))
	else:
		if is_valid_coord(_item_start_coord):
			item.animate_bounce_back(get_cell_center(_item_start_coord.x, _item_start_coord.y))
		else:
			item.animate_bounce_back(_item_start_local_pos)

func _sell_item(item: ItemView) -> void:
	var value := item.data.sell_value
	EconomyManager.add_coins(value)
	SoundManager.play_consume()
	GameEvents.show_floating_text.emit("+%d Coins (Sold)" % value, item.global_position + Vector2(0, -40), Color(1.0, 0.85, 0.2))
	remove_item(item)
	item.queue_free()
	GameEvents.board_changed.emit()
	GameEvents.inventory_changed.emit()

func remove_item(item: ItemView) -> void:
	_clear_source_slot(item)

func clear_board() -> void:
	for c in range(COLS):
		for r in range(ROWS):
			var it: ItemView = _grid[c][r]
			if it:
				it.queue_free()
				_grid[c][r] = null
	GameEvents.board_changed.emit()

func fill_board_random() -> void:
	var sample_pool := ["tools_1", "tools_2", "plant_1", "plant_2", "gem_1", "coins_1", "energy_1"]
	for c in range(COLS):
		for r in range(ROWS):
			if _grid[c][r] == null:
				var rand_id: String = sample_pool[randi() % sample_pool.size()]
				spawn_item_at(Vector2i(c, r), rand_id)
	GameEvents.board_changed.emit()

func get_all_items_on_board() -> Array[ItemView]:
	var items: Array[ItemView] = []
	for c in range(COLS):
		for r in range(ROWS):
			if _grid[c][r] != null:
				items.append(_grid[c][r])
	return items
