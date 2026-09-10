class_name Board
extends Node2D

@export_group("Grid Dimensions")
@export var cols: int = 7:
	set(val):
		cols = val
		if is_inside_tree():
			_apply_board_styling()
			_init_grid()
			_create_cells()

@export var rows: int = 9:
	set(val):
		rows = val
		if is_inside_tree():
			_apply_board_styling()
			_init_grid()
			_create_cells()

@export var cell_size: float = 88.0:
	set(val):
		cell_size = val
		if is_inside_tree():
			_apply_board_styling()
			_create_cells()

@export var cell_spacing: float = 8.0:
	set(val):
		cell_spacing = val
		if is_inside_tree():
			_apply_board_styling()
			_create_cells()

@export_group("Board Styling")
@export var board_bg_color: Color = Color(0.1, 0.12, 0.16, 0.95):
	set(val):
		board_bg_color = val
		_apply_board_styling()

@export var board_border_color: Color = Color(0.2, 0.25, 0.32, 0.8):
	set(val):
		board_border_color = val
		_apply_board_styling()

@export var board_border_width: int = 3:
	set(val):
		board_border_width = val
		_apply_board_styling()

@export var board_corner_radius: int = 16:
	set(val):
		board_corner_radius = val
		_apply_board_styling()

@export_group("Tile Styling")
@export var tile_bg_color: Color = Color(0.18, 0.21, 0.27, 0.9):
	set(val):
		tile_bg_color = val
		_apply_cells_styling()

@export var tile_border_color: Color = Color(0.28, 0.32, 0.4, 0.5):
	set(val):
		tile_border_color = val
		_apply_cells_styling()

@export var tile_hover_empty_color: Color = Color(0.28, 0.38, 0.52, 0.95):
	set(val):
		tile_hover_empty_color = val
		_apply_cells_styling()

@export var tile_hover_merge_color: Color = Color(0.25, 0.65, 0.38, 0.95):
	set(val):
		tile_hover_merge_color = val
		_apply_cells_styling()

@export var tile_corner_radius: int = 12:
	set(val):
		tile_corner_radius = val
		_apply_cells_styling()

@export var tile_locked_bg_color: Color = Color(0.10, 0.11, 0.14, 0.95):
	set(val):
		tile_locked_bg_color = val
		_apply_cells_styling()

@export var tile_locked_border_color: Color = Color(0.20, 0.22, 0.26, 0.6):
	set(val):
		tile_locked_border_color = val
		_apply_cells_styling()

const DRAG_THRESHOLD: float = 12.0

@export var item_view_scene: PackedScene = preload("res://scenes/item_view.tscn")
@export var cell_scene: PackedScene = preload("res://scenes/board_cell.tscn")

@onready var background_panel: Panel = $Background
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

# Reference to bottom navigation bar and sell bin
var bottom_nav_bar: BottomNavBar = null
var sell_bin: Control = null

func _ready() -> void:
	_apply_board_styling()
	_init_grid()
	_create_cells()
	GameEvents.player_leveled_up.connect(_on_player_leveled_up)
	GameEvents.board_changed.connect(update_all_cells_lock_visuals)

func _on_player_leveled_up(new_level: int) -> void:
	check_boxed_items_unlock(new_level)

func get_board_width() -> float:
	return cols * cell_size + (cols - 1) * cell_spacing

func get_board_height() -> float:
	return rows * cell_size + (rows - 1) * cell_spacing

func _apply_board_styling() -> void:
	if not background_panel or not is_inside_tree():
		return
	var b_width := get_board_width()
	var b_height := get_board_height()
	background_panel.offset_left = -12.0
	background_panel.offset_top = -12.0
	background_panel.offset_right = b_width + 12.0
	background_panel.offset_bottom = b_height + 12.0

	if cells_container:
		cells_container.size = Vector2(b_width, b_height)

	var style: StyleBoxFlat = background_panel.get_theme_stylebox("panel")
	if style:
		style = style.duplicate()
	else:
		style = StyleBoxFlat.new()

	style.bg_color = board_bg_color
	style.border_color = board_border_color
	style.border_width_left = board_border_width
	style.border_width_top = board_border_width
	style.border_width_right = board_border_width
	style.border_width_bottom = board_border_width
	style.corner_radius_top_left = board_corner_radius
	style.corner_radius_top_right = board_corner_radius
	style.corner_radius_bottom_right = board_corner_radius
	style.corner_radius_bottom_left = board_corner_radius

	background_panel.add_theme_stylebox_override("panel", style)

func _apply_cells_styling() -> void:
	for c in range(_cells.size()):
		for r in range(_cells[c].size()):
			var cell: BoardCell = _cells[c][r]
			if is_instance_valid(cell):
				cell.setup_style(tile_bg_color, tile_border_color, tile_hover_empty_color, tile_hover_merge_color, tile_corner_radius, tile_locked_bg_color, tile_locked_border_color)

func _init_grid() -> void:
	_grid.clear()
	_cells.clear()
	for c in range(cols):
		var col_items: Array = []
		var col_cells: Array = []
		col_items.resize(rows)
		col_cells.resize(rows)
		col_items.fill(null)
		col_cells.fill(null)
		_grid.append(col_items)
		_cells.append(col_cells)

func _create_cells() -> void:
	if not cells_container:
		return
	for child in cells_container.get_children():
		child.queue_free()

	for c in range(cols):
		for r in range(rows):
			var cell: BoardCell = cell_scene.instantiate()
			cell.grid_coord = Vector2i(c, r)
			cell.custom_minimum_size = Vector2(cell_size, cell_size)
			cell.size = Vector2(cell_size, cell_size)
			cell.position = get_cell_top_left(c, r)
			cells_container.add_child(cell)
			cell.setup_style(tile_bg_color, tile_border_color, tile_hover_empty_color, tile_hover_merge_color, tile_corner_radius, tile_locked_bg_color, tile_locked_border_color)
			_cells[c][r] = cell

func get_cell_top_left(col: int, row: int) -> Vector2:
	var x := col * (cell_size + cell_spacing)
	var y := row * (cell_size + cell_spacing)
	return Vector2(x, y)

func get_cell_center(col: int, row: int) -> Vector2:
	return get_cell_top_left(col, row) + Vector2(cell_size * 0.5, cell_size * 0.5)

func world_to_grid(world_pos: Vector2) -> Vector2i:
	var local_pos := to_local(world_pos)
	var b_width := get_board_width()
	var b_height := get_board_height()
	if local_pos.x < 0 or local_pos.x > b_width or local_pos.y < 0 or local_pos.y > b_height:
		return Vector2i(-1, -1)

	var col := int(local_pos.x / (cell_size + cell_spacing))
	var row := int(local_pos.y / (cell_size + cell_spacing))

	col = clampi(col, 0, cols - 1)
	row = clampi(row, 0, rows - 1)

	# Verify within cell bounds (not in gap)
	var cell_pos := get_cell_top_left(col, row)
	var offset := local_pos - cell_pos
	if offset.x < 0 or offset.x > cell_size or offset.y < 0 or offset.y > cell_size:
		# Snap to closest cell
		pass

	return Vector2i(col, row)

func is_valid_coord(coord: Vector2i) -> bool:
	return coord.x >= 0 and coord.x < cols and coord.y >= 0 and coord.y < rows

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
	update_cell_lock_visual(coord)

func get_empty_cells() -> Array[Vector2i]:
	var empty: Array[Vector2i] = []
	for c in range(cols):
		for r in range(rows):
			if _grid[c][r] == null:
				empty.append(Vector2i(c, r))
	return empty

func spawn_item_at(coord: Vector2i, item_id: String, state: int = ItemView.ItemState.NORMAL, req_level: int = 1) -> ItemView:
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
	item.setup(data, state as ItemView.ItemState, req_level)
	set_item_at(coord, item)
	if state == ItemView.ItemState.NORMAL:
		ProgressionManager.unlock_item(item_id, true)
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

	if not item:
		return

	# Boxed item interaction: prevent interaction, display required unlock level
	if item.is_boxed():
		item.animate_wobble()
		SoundManager.play_error()
		GameEvents.show_floating_text.emit(
			"Unlocks at Lv. %d" % item.unlock_level,
			item.global_position + Vector2(0, -45),
			Color(0.85, 0.85, 0.95)
		)
		return

	# Locked item interaction: cannot move, says "Locked"
	if item.is_locked():
		item.animate_wobble()
		SoundManager.play_error()
		GameEvents.show_floating_text.emit(
			"Locked",
			item.global_position + Vector2(0, -45),
			Color(0.85, 0.85, 0.9)
		)
		return

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
			if target_item.is_boxed():
				# Boxed items cannot be merged into or swapped
				pass
			elif target_item.is_locked():
				# Locked items can only be merged into, never swapped
				if _can_merge(_active_item.data, target_item.data):
					target_cell.set_highlight(2) # Merge green
					target_item.set_merge_highlight(true)
					_hovered_merge_item = target_item
			else:
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

	# 2. Over bottom nav bar (inventory dropzone)
	if bottom_nav_bar:
		if bottom_nav_bar.is_pos_inside_inventory_button(mouse_pos):
			bottom_nav_bar.set_inventory_hover(true)
		else:
			bottom_nav_bar.set_inventory_hover(false)

func _clear_hover_feedback() -> void:
	if _last_highlighted_cell:
		_last_highlighted_cell.set_highlight(0)
		_last_highlighted_cell = null
	if _hovered_merge_item:
		_hovered_merge_item.set_merge_highlight(false)
		_hovered_merge_item = null
	if bottom_nav_bar:
		bottom_nav_bar.set_inventory_hover(false)

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

	# Check Inventory dropzone button
	if bottom_nav_bar and bottom_nav_bar.is_pos_inside_inventory_button(mouse_pos):
		_drop_into_inventory_button(item)
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
	if spawner.is_spawner_exhausted():
		spawner.animate_wobble()
		SoundManager.play_error()
		var cd_sec := int(ceil(spawner.current_cooldown))
		GameEvents.show_floating_text.emit("Exhausted! (%ds)" % cd_sec, spawner.global_position + Vector2(0, -50), Color(1.0, 0.5, 0.3))
		return

	if not EconomyManager.has_energy(spawner.data.energy_cost):
		spawner.animate_wobble()
		SoundManager.play_error()
		GameEvents.show_floating_text.emit("Need Energy!", spawner.global_position + Vector2(0, -50), Color(1.0, 0.4, 0.4))
		return

	var empty_cells := get_empty_cells()
	if empty_cells.is_empty():
		spawner.animate_wobble()
		SoundManager.play_error()
		GameEvents.show_floating_text.emit("Board is Full!", spawner.global_position + Vector2(0, -50), Color(1.0, 0.4, 0.4))
		return

	# Deduct energy, consume charge, and trigger animation
	EconomyManager.consume_energy(spawner.data.energy_cost)
	spawner.consume_spawn_charge()
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
		GameEvents.show_floating_text.emit("+%d Gold!" % amt, pos + Vector2(0, -40), Color(1.0, 0.85, 0.2))
	elif curr == "energy":
		EconomyManager.add_energy(amt)
		GameEvents.show_floating_text.emit("+%d Energy!" % amt, pos + Vector2(0, -40), Color(0.3, 1.0, 0.5))
	elif curr == "exp":
		ProgressionManager.add_exp(amt)
		GameEvents.show_floating_text.emit("+%d EXP!" % amt, pos + Vector2(0, -40), Color(0.85, 0.55, 1.0))
	elif curr == "gems" or curr == "diamond":
		EconomyManager.add_gems(amt)
		GameEvents.show_floating_text.emit("+%d Diamonds!" % amt, pos + Vector2(0, -40), Color(0.45, 0.85, 1.0))

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

	# Case 2: Target is Boxed -> cannot merge or swap, bounce back
	if target_item and target_item.is_boxed():
		target_item.animate_wobble()
		SoundManager.play_error()
		GameEvents.show_floating_text.emit(
			"Unlocks at Lv. %d" % target_item.unlock_level,
			target_item.global_position + Vector2(0, -45),
			Color(0.85, 0.85, 0.95)
		)
		_return_item_to_origin(dragged)
		return

	# Case 3: Target is Locked -> can only merge if same type and tier
	if target_item and target_item.is_locked():
		if _can_merge(dragged.data, target_item.data):
			_execute_merge(dragged, target_item)
		else:
			target_item.animate_wobble()
			SoundManager.play_error()
			GameEvents.show_floating_text.emit(
				"Locked",
				target_item.global_position + Vector2(0, -45),
				Color(0.85, 0.85, 0.9)
			)
			_return_item_to_origin(dragged)
		return

	# Case 4: Dropped onto merge target
	if target_item and _can_merge(dragged.data, target_item.data):
		_execute_merge(dragged, target_item)
		return

	# Case 5: Dropped onto empty board cell
	if not target_item:
		_clear_source_slot(dragged)
		set_item_at(target_coord, dragged)
		dragged.animate_snap_to(get_cell_center(target_coord.x, target_coord.y))
		GameEvents.board_changed.emit()
		return

	# Case 6: Dropped onto another item -> SWAP
	_execute_swap(dragged, target_item)

func _drop_into_inventory_button(item: ItemView) -> void:
	if not InventoryManager.has_free_slot():
		SoundManager.play_error()
		var text_pos: Vector2 = item.global_position
		if bottom_nav_bar:
			var inv_btn: Control = bottom_nav_bar.get_inventory_button()
			text_pos = inv_btn.global_position + Vector2(inv_btn.size.x * 0.5, -20)
		GameEvents.show_floating_text.emit("Backpack Full!", text_pos, Color(1.0, 0.4, 0.4))
		_return_item_to_origin(item)
		return

	var success := InventoryManager.add_item(item.data.id)
	if success:
		SoundManager.play_pickup()
		if bottom_nav_bar:
			bottom_nav_bar.play_inventory_pulse()
			var inv_btn: Control = bottom_nav_bar.get_inventory_button()
			var text_pos: Vector2 = inv_btn.global_position + Vector2(inv_btn.size.x * 0.5, -20)
			GameEvents.show_floating_text.emit("Stored %s!" % item.data.display_name, text_pos, Color(0.4, 0.85, 1.0))
		remove_item(item)
		item.queue_free()
		GameEvents.board_changed.emit()
	else:
		_return_item_to_origin(item)

func _execute_merge(source: ItemView, target: ItemView) -> void:
	var next_id := target.data.get_next_tier_id()
	var new_data := ItemDatabase.get_item(next_id)
	if not new_data:
		_return_item_to_origin(source)
		return

	var was_locked := target.is_locked()

	_clear_source_slot(source)
	source.queue_free()

	# If target was locked, it unlocks into normal item!
	target.setup(new_data, ItemView.ItemState.NORMAL)
	target.animate_merge_pop()

	var pop_pos := target.global_position + Vector2(0, -50)
	var text_msg := "%s (T%d)!" % [new_data.display_name, new_data.tier]
	if was_locked:
		text_msg = "Unlocked!\n%s (T%d)" % [new_data.display_name, new_data.tier]

	GameEvents.show_floating_text.emit(
		text_msg,
		pop_pos,
		Color(1.0, 0.9, 0.3)
	)
	ProgressionManager.unlock_item(next_id)
	GameEvents.item_merged.emit(source.data.id, target.data.id, next_id, target.global_position)
	GameEvents.board_changed.emit()
	GameEvents.inventory_changed.emit()

func _execute_swap(item_a: ItemView, item_b: ItemView) -> void:
	var a_coord := item_a.grid_coord
	var b_coord := item_b.grid_coord

	# Clear slots
	_clear_source_slot(item_a)
	_clear_source_slot(item_b)

	# Place A in B's old location
	set_item_at(b_coord, item_a)
	item_a.animate_snap_to(get_cell_center(b_coord.x, b_coord.y))

	# Place B in A's old location
	set_item_at(a_coord, item_b)
	item_b.animate_snap_to(get_cell_center(a_coord.x, a_coord.y))

	SoundManager.play_drop()
	GameEvents.board_changed.emit()

func _clear_source_slot(item: ItemView) -> void:
	var old_coord := item.grid_coord
	if is_valid_coord(old_coord):
		_grid[old_coord.x][old_coord.y] = null
		update_cell_lock_visual(old_coord)
	item.grid_coord = Vector2i(-1, -1)
	item.inventory_slot_idx = -1

func _return_item_to_origin(item: ItemView) -> void:
	if is_valid_coord(_item_start_coord):
		item.animate_bounce_back(get_cell_center(_item_start_coord.x, _item_start_coord.y))
	else:
		item.animate_bounce_back(_item_start_local_pos)

func _sell_item(item: ItemView) -> void:
	var value := item.data.sell_value
	EconomyManager.add_coins(value)
	SoundManager.play_consume()
	GameEvents.show_floating_text.emit("+%d Gold (Sold)" % value, item.global_position + Vector2(0, -40), Color(1.0, 0.85, 0.2))
	remove_item(item)
	item.queue_free()
	GameEvents.board_changed.emit()
	GameEvents.inventory_changed.emit()

func remove_item(item: ItemView) -> void:
	_clear_source_slot(item)

func clear_board() -> void:
	for c in range(cols):
		for r in range(rows):
			var it: ItemView = _grid[c][r]
			if it:
				it.queue_free()
				_grid[c][r] = null
	GameEvents.board_changed.emit()

func fill_board_random() -> void:
	var sample_pool := [
		"foodbox_1", "oven_1", "fridge_1", "rack_1",
		"egg_1", "leaf_1", "beef_1", "cake_1", "sandwich_1", "drink_1", "util_1",
		"gold_1", "energy_1", "exp_1", "diamond_1"
	]
	for c in range(cols):
		for r in range(rows):
			if _grid[c][r] == null:
				var rand_id: String = sample_pool[randi() % sample_pool.size()]
				spawn_item_at(Vector2i(c, r), rand_id)
	GameEvents.board_changed.emit()

func check_boxed_items_unlock(current_level: int) -> void:
	var any_unboxed := false
	for c in range(cols):
		for r in range(rows):
			var item: ItemView = _grid[c][r]
			if item and item.is_boxed() and item.unlock_level <= current_level:
				item.unbox_to_locked()
				var unbox_pos := item.global_position + Vector2(0, -45)
				GameEvents.show_floating_text.emit(
					"Unlocked! (Lv. %d)" % item.unlock_level,
					unbox_pos,
					Color(0.9, 0.75, 1.0)
				)
				any_unboxed = true
	if any_unboxed:
		GameEvents.board_changed.emit()

func get_all_items_on_board(only_usable: bool = false) -> Array[ItemView]:
	var items: Array[ItemView] = []
	for c in range(cols):
		for r in range(rows):
			var it: ItemView = _grid[c][r]
			if it != null:
				if only_usable and not it.is_normal():
					continue
				items.append(it)
	return items

func serialize_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for c in range(cols):
		for r in range(rows):
			var it: ItemView = _grid[c][r]
			if it and it.data:
				var dict := {
					"col": c,
					"row": r,
					"item_id": it.data.id,
					"item_state": int(it.item_state),
					"unlock_level": it.unlock_level
				}
				if it.data.is_spawner:
					dict["spawner_charges"] = it.current_charges
					dict["spawner_cooldown"] = it.current_cooldown
					dict["producer_status"] = int(it.producer_status)
				result.append(dict)
	return result

func load_items(items_data: Array) -> void:
	clear_board()
	for entry in items_data:
		var c: int = int(entry.get("col", -1))
		var r: int = int(entry.get("row", -1))
		var item_id: String = str(entry.get("item_id", ""))
		var state_val: int = int(entry.get("item_state", ItemView.ItemState.NORMAL))
		var req_level: int = int(entry.get("unlock_level", 1))
		if is_valid_coord(Vector2i(c, r)) and not item_id.is_empty():
			var spawned := spawn_item_at(Vector2i(c, r), item_id, state_val, req_level)
			if spawned and entry.has("spawner_charges"):
				var charges: int = int(entry.get("spawner_charges", spawned.max_charges))
				var cooldown: float = float(entry.get("spawner_cooldown", 0.0))
				var status_val: int = int(entry.get("producer_status", -1))
				spawned.restore_spawner_state(charges, cooldown, status_val)
	check_boxed_items_unlock(ProgressionManager.player_level)
	update_all_cells_lock_visuals()
	GameEvents.board_changed.emit()

func update_cell_lock_visual(coord: Vector2i) -> void:
	if not is_valid_coord(coord):
		return
	if _cells.is_empty() or coord.x >= _cells.size() or coord.y >= _cells[coord.x].size():
		return
	var cell: BoardCell = _cells[coord.x][coord.y]
	if not is_instance_valid(cell):
		return
	var item: ItemView = get_item_at(coord)
	var locked_status: bool = (item != null and item.is_locked())
	cell.set_locked(locked_status)

func update_all_cells_lock_visuals() -> void:
	for c in range(cols):
		for r in range(rows):
			update_cell_lock_visual(Vector2i(c, r))


