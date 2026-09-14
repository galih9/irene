class_name Board
extends Node2D

@export_group("Grid Dimensions & Spacing")
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
			_reposition_items()

@export var cell_spacing: float = 5.0:
	set(val):
		cell_spacing = val
		if is_inside_tree():
			_apply_board_styling()
			_create_cells()
			_reposition_items()

@export var board_margin: float = 12.0:
	set(val):
		board_margin = val
		if is_inside_tree():
			_apply_board_styling()

@export var board_theme: String = "kitchen": # "kitchen" or "farm"
	set(val):
		board_theme = val
		_apply_theme_styling()
		_apply_theme_to_all_items()

func _apply_theme_styling() -> void:
	if board_theme == "farm":
		# Farm Board Styling: transparent dark green background, alternating light yellow and light brown tiles
		board_bg_color = Color(0.08, 0.22, 0.12, 0.78)
		board_border_color = Color(0.24, 0.44, 0.28, 0.85)
		tile_bg_color = Color(0.96, 0.91, 0.74, 0.90)       # Light yellow
		tile_bg_alt_color = Color(0.84, 0.74, 0.61, 0.90)   # Light brown
		tile_border_color = Color(0.65, 0.55, 0.42, 0.65)
		tile_locked_bg_color = Color(0.48, 0.45, 0.38, 0.85)
		tile_locked_bg_alt_color = Color(0.42, 0.39, 0.33, 0.85)
		tile_locked_border_color = Color(0.35, 0.32, 0.26, 0.7)
		tile_hover_empty_color = Color(0.55, 0.75, 0.50, 0.92)
		tile_hover_merge_color = Color(0.30, 0.80, 0.45, 0.95)
	else:
		# Kitchen Board Styling (slate blue cozy kitchen)
		board_bg_color = Color(0.1, 0.12, 0.16, 0.95)
		board_border_color = Color(0.2, 0.25, 0.32, 0.8)
		tile_bg_color = Color(0.18, 0.21, 0.27, 0.9)
		tile_bg_alt_color = Color(0.24, 0.28, 0.35, 0.9)
		tile_border_color = Color(0.28, 0.32, 0.4, 0.5)
		tile_locked_bg_color = Color(0.10, 0.11, 0.14, 0.95)
		tile_locked_bg_alt_color = Color(0.13, 0.14, 0.18, 0.95)
		tile_locked_border_color = Color(0.20, 0.22, 0.26, 0.6)
		tile_hover_empty_color = Color(0.28, 0.38, 0.52, 0.95)
		tile_hover_merge_color = Color(0.25, 0.65, 0.38, 0.95)

	if is_inside_tree():
		_apply_board_styling()
		_apply_cells_styling()

func _apply_theme_to_all_items() -> void:
	for c in range(_grid.size()):
		for r in range(_grid[c].size()):
			var it: ItemView = _grid[c][r]
			if is_instance_valid(it):
				it.board_theme = board_theme

var tile_margin: float:
	get:
		return cell_spacing
	set(val):
		cell_spacing = val

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
@export var use_chess_pattern: bool = true:
	set(val):
		use_chess_pattern = val
		_apply_cells_styling()

@export var tile_bg_color: Color = Color(0.18, 0.21, 0.27, 0.9):
	set(val):
		tile_bg_color = val
		_apply_cells_styling()

@export var tile_bg_alt_color: Color = Color(0.24, 0.28, 0.35, 0.9):
	set(val):
		tile_bg_alt_color = val
		_apply_cells_styling()

@export var tile_locked_bg_color: Color = Color(0.10, 0.11, 0.14, 0.95):
	set(val):
		tile_locked_bg_color = val
		_apply_cells_styling()

@export var tile_locked_bg_alt_color: Color = Color(0.13, 0.14, 0.18, 0.95):
	set(val):
		tile_locked_bg_alt_color = val
		_apply_cells_styling()

@export var tile_border_color: Color = Color(0.28, 0.32, 0.4, 0.5):
	set(val):
		tile_border_color = val
		_apply_cells_styling()

@export var tile_locked_border_color: Color = Color(0.20, 0.22, 0.26, 0.6):
	set(val):
		tile_locked_border_color = val
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

# Selection indicator state
var selected_item: ItemView = null
var _indicator_sprite: Sprite2D = null
var _indicator_tween: Tween = null
var _indicator_base_scale: Vector2 = Vector2.ONE

# Reference to bottom navigation bar
var bottom_nav_bar: BottomNavBar = null

func _ready() -> void:
	_apply_theme_styling()
	_apply_board_styling()
	_init_grid()
	_create_cells()
	_setup_indicator()
	GameEvents.player_leveled_up.connect(_on_player_leveled_up)
	GameEvents.board_changed.connect(update_all_cells_lock_visuals)
	GameEvents.board_changed.connect(func():
		if not _is_dragging and is_inside_tree():
			_update_hover_cursor(get_global_mouse_position())
	)

func _on_player_leveled_up(new_level: int) -> void:
	check_boxed_items_unlock(new_level)

func get_board_width() -> float:
	return cols * cell_size + (cols - 1) * cell_spacing

func get_board_height() -> float:
	return rows * cell_size + (rows - 1) * cell_spacing

func get_all_items() -> Array[ItemView]:
	var result: Array[ItemView] = []
	for c in range(cols):
		for r in range(rows):
			var it: ItemView = _grid[c][r]
			if it and is_instance_valid(it):
				result.append(it)
	return result

func _apply_board_styling() -> void:
	if not background_panel or not is_inside_tree():
		return
	var b_width := get_board_width()
	var b_height := get_board_height()
	background_panel.offset_left = -board_margin
	background_panel.offset_top = -board_margin
	background_panel.offset_right = b_width + board_margin
	background_panel.offset_bottom = b_height + board_margin

	if cells_container:
		cells_container.size = Vector2(b_width, b_height)
		cells_container.offset_right = b_width
		cells_container.offset_bottom = b_height

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

func _setup_indicator() -> void:
	if _indicator_sprite:
		return
	_indicator_sprite = Sprite2D.new()
	_indicator_sprite.name = "SelectionIndicator"
	_indicator_sprite.texture = preload("res://assets/ui/indicator.png")
	_indicator_sprite.z_index = 25 # Above normal items, below dragged item
	var tex_sz := _indicator_sprite.texture.get_size()
	var base_scale := (cell_size + 4.0) / tex_sz.x
	_indicator_base_scale = Vector2(base_scale, base_scale)
	_indicator_sprite.scale = _indicator_base_scale
	_indicator_sprite.visible = false
	add_child(_indicator_sprite)

func _start_indicator_bounce() -> void:
	if _indicator_tween and _indicator_tween.is_valid():
		_indicator_tween.kill()
	if not _indicator_sprite:
		return
	_indicator_sprite.scale = _indicator_base_scale * 0.94
	_indicator_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_indicator_tween.tween_property(_indicator_sprite, "scale", _indicator_base_scale * 1.08, 0.5)
	_indicator_tween.tween_property(_indicator_sprite, "scale", _indicator_base_scale * 0.94, 0.5)

func select_item(item: ItemView) -> void:
	if item and item.is_hidden():
		clear_selection()
		return
	selected_item = item
	if not _indicator_sprite:
		_setup_indicator()

	if item and is_instance_valid(item) and item.grid_coord != Vector2i(-1, -1):
		_indicator_sprite.position = get_cell_center(item.grid_coord.x, item.grid_coord.y)
		_indicator_sprite.visible = not _is_dragging
		_start_indicator_bounce()
		GameEvents.item_selected.emit(item)
	else:
		clear_selection()

func clear_selection() -> void:
	selected_item = null
	if _indicator_sprite:
		_indicator_sprite.visible = false
	if _indicator_tween and _indicator_tween.is_valid():
		_indicator_tween.kill()
	GameEvents.item_selected.emit(null)

func sell_selected_item() -> void:
	if not selected_item or not is_instance_valid(selected_item):
		return
	if not selected_item.is_normal():
		return
	var it := selected_item
	clear_selection()
	_sell_item(it)

func _style_cell(cell: BoardCell, c: int, r: int) -> void:
	var is_alt := (c + r) % 2 == 1
	var bg: Color = tile_bg_alt_color if (use_chess_pattern and is_alt) else tile_bg_color
	var locked_bg: Color = tile_locked_bg_alt_color if (use_chess_pattern and is_alt) else tile_locked_bg_color
	cell.setup_style(bg, tile_border_color, tile_hover_empty_color, tile_hover_merge_color, tile_corner_radius, locked_bg, tile_locked_border_color)

func _apply_cells_styling() -> void:
	for c in range(_cells.size()):
		for r in range(_cells[c].size()):
			var cell: BoardCell = _cells[c][r]
			if is_instance_valid(cell):
				_style_cell(cell, c, r)

func _reposition_items() -> void:
	for c in range(_grid.size()):
		for r in range(_grid[c].size()):
			var item: ItemView = _grid[c][r]
			if is_instance_valid(item) and not item.is_dragging:
				item.position = get_cell_center(c, r)
				item.target_slot_pos = item.position

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
			cells_container.add_child(cell)
			cell.position = get_cell_top_left(c, r)
			cell.set_cell_size(cell_size)
			_style_cell(cell, c, r)
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

func spawn_item_at(coord: Vector2i, item_id: String, state: int = ItemView.ItemState.NORMAL, req_level: int = 1, b_var: int = -1, w_var: int = -1) -> ItemView:
	if not is_valid_coord(coord):
		return null
	var data := ItemDatabase.get_item(item_id)
	if not data:
		return null

	# Safeguard: Do not allow consumable items in locked, boxed, or hidden state
	if state != ItemView.ItemState.NORMAL and data.is_consumable:
		push_warning("Attempted to spawn consumable item %s as locked/boxed/hidden. Falling back to egg_1." % item_id)
		item_id = "egg_1"
		data = ItemDatabase.get_item(item_id)

	# Remove existing if any
	var existing := get_item_at(coord)
	if existing:
		existing.queue_free()

	var item: ItemView = item_view_scene.instantiate()
	item.board_theme = board_theme
	items_container.add_child(item)
	item.scale = Vector2.ONE * (cell_size / 88.0)
	item.setup(data, state as ItemView.ItemState, req_level, b_var, w_var)
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
	item.board_theme = board_theme
	items_container.add_child(item)
	item.scale = Vector2.ONE * (cell_size / 88.0)
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
	elif event is InputEventMouseMotion:
		if _active_item:
			_handle_motion(event.global_position)
		else:
			_update_hover_cursor(event.global_position)

func _update_hover_cursor(mouse_pos: Vector2) -> void:
	if _is_dragging:
		CursorManager.set_drag_cursor()
		return

	var coord := world_to_grid(mouse_pos)
	if not is_valid_coord(coord):
		CursorManager.reset_cursor()
		return

	var item := get_item_at(coord)
	if not item or item.is_hidden():
		CursorManager.reset_cursor()
		return

	if item.is_boxed() or item.is_locked():
		CursorManager.set_forbidden_cursor()
		return

	if item.data and item.data.is_spawner:
		if item.is_spawner_exhausted():
			CursorManager.set_exclamation_cursor()
		else:
			CursorManager.set_pointing_cursor()
		return

	# Normal item
	CursorManager.set_can_drop_cursor()

func _handle_press(mouse_pos: Vector2) -> void:
	var coord := world_to_grid(mouse_pos)
	var item := get_item_at(coord)

	if not item or item.is_hidden():
		clear_selection()
		return

	# Select the tapped item and show indicator
	select_item(item)

	# Boxed item interaction: prevent interaction, display required unlock level
	if item.is_boxed():
		item.animate_click()
		SoundManager.play_error()
		GameEvents.show_floating_text.emit(
			"Unlocks at Lv. %d" % item.unlock_level,
			item.global_position + Vector2(0, -45),
			Color(0.85, 0.85, 0.95)
		)
		return

	# Locked item interaction: cannot move, says "Locked"
	if item.is_locked():
		item.animate_click()
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
			if _indicator_sprite:
				_indicator_sprite.visible = false
			_active_item.animate_pickup()
			GameEvents.item_drag_started.emit(_active_item)
			CursorManager.set_drag_cursor()
		else:
			return

	# Move item with mouse
	_active_item.global_position = mouse_pos

	# Hover preview feedback
	_update_hover_feedback(mouse_pos)

func _update_hover_feedback(mouse_pos: Vector2) -> void:
	CursorManager.set_drag_cursor()
	_clear_hover_feedback()

	# 1. Over board
	var coord := world_to_grid(mouse_pos)
	if is_valid_coord(coord):
		var target_cell: BoardCell = _cells[coord.x][coord.y]
		if target_cell.is_hidden_cell:
			return
		var target_item := get_item_at(coord)
		if target_item and target_item.is_hidden():
			return
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
		select_item(item)
		_handle_item_tap(item)
		_update_hover_cursor(mouse_pos)
		return

	# Finish drag
	item.animate_drop()
	GameEvents.item_drag_ended.emit(item)
	_is_dragging = false

	# Check Inventory dropzone button
	if bottom_nav_bar and bottom_nav_bar.is_pos_inside_inventory_button(mouse_pos):
		_drop_into_inventory_button(item)
		_update_hover_cursor(mouse_pos)
		return

	# Check Board drop
	var target_coord := world_to_grid(mouse_pos)
	if is_valid_coord(target_coord):
		_drop_into_board(item, target_coord)
		_update_hover_cursor(mouse_pos)
		return

	# Dropped outside: bounce back to origin
	_return_item_to_origin(item)
	select_item(item)
	_update_hover_cursor(mouse_pos)

func _handle_item_tap(item: ItemView) -> void:
	# 0. Cow Lv.3 Milking
	if item.data.id == "cow_3" and item.is_milked_ready:
		var empty_cells := get_empty_cells()
		if empty_cells.is_empty():
			item.animate_wobble()
			SoundManager.play_error()
			GameEvents.show_floating_text.emit("Board is Full!", item.global_position + Vector2(0, -50), Color(1.0, 0.4, 0.4))
			return
		item.is_milked_ready = false
		item.animate_spawner_tap()
		SoundManager.play_spawn()
		spawn_item_flight(item.global_position, empty_cells[0], "milk_1")
		GameEvents.show_floating_text.emit("Milked +1 Fresh Milk! 🥛", item.global_position + Vector2(0, -50), Color(0.95, 0.95, 0.8))
		item._update_visuals()
		select_item(item)
		GameEvents.board_changed.emit()
		return

	# 1. Spawner tap
	if item.data.is_spawner:
		_trigger_spawner(item)
		return

	# 2. Consumable tap
	if item.data.is_consumable:
		_trigger_consumable(item)
		return

	# 3. Normal item tap: juicy click bounce & info
	item.animate_click()
	SoundManager.play_pickup()
	GameEvents.show_floating_text.emit(
		item.data.display_name,
		item.global_position + Vector2(0, -50),
		Color(1.0, 0.9, 0.5)
	)

func _try_spawn_from_item(item: ItemView) -> bool:
	if not item or not item.data or not item.data.is_spawner:
		return false
	_trigger_spawner(item)
	return true

func _trigger_spawner(spawner: ItemView) -> void:
	if spawner.is_spawner_exhausted():
		spawner.animate_wobble()
		SoundManager.play_error()
		var cd_sec := int(ceil(spawner.current_cooldown))
		GameEvents.show_floating_text.emit("Exhausted! (%ds)" % cd_sec, spawner.global_position + Vector2(0, -50), Color(1.0, 0.5, 0.3))
		GameEvents.spawner_exhausted.emit(spawner.data.id if spawner.data else "")
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
		GameEvents.board_full_attempted.emit()
		return

	# Deduct energy, consume charge, and trigger animation
	EconomyManager.consume_energy(spawner.data.energy_cost)
	spawner.consume_spawn_charge()
	spawner.animate_spawner_tap()
	SoundManager.play_spawn()

	# Pick drop item
	var drop_id := ItemDatabase.get_spawner_drop(spawner.data.id, board_theme)
	if spawner.data.id.begins_with("foodbox"):
		if SaveManager and SaveManager.tutorial_manager_ref and SaveManager.tutorial_manager_ref.current_step == TutorialManager.TutorialStep.SPAWN_ITEM:
			drop_id = "egg_1"

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

	# Special Producer Boosting
	# 1. Barn Boost: tool boosted barn increases drop level & extra spawn
	if spawner.data.chain_id == "barn" and spawner.is_boosted:
		spawner.boost_charges = maxi(0, spawner.boost_charges - 1)
		if spawner.boost_charges <= 0:
			spawner.is_boosted = false
		var extra_cells := get_empty_cells()
		if not extra_cells.is_empty():
			var extra_drop := ItemDatabase.get_spawner_drop(spawner.data.id, board_theme)
			var it_d := ItemDatabase.get_item(extra_drop)
			if it_d and it_d.tier < it_d.max_tier:
				var next_id := it_d.get_next_tier_id()
				if ItemDatabase.has_item(next_id):
					extra_drop = next_id
			spawn_item_flight(spawner.global_position, extra_cells[0], extra_drop)

	# 2. Tree Boost: Compost boosted fruit tree drops 2 (Tier 3) or 4 (Tier 4) fruits
	if spawner.data.chain_id == "tree" and spawner.is_boosted:
		var target_count := 2 if spawner.data.tier == 3 else 4
		for f in range(target_count - 1):
			var extra_cells := get_empty_cells()
			if not extra_cells.is_empty():
				var f_drop := ItemDatabase.get_spawner_drop(spawner.data.id, board_theme)
				spawn_item_flight(spawner.global_position, extra_cells[0], f_drop)

	# If the spawner is consumable (e.g. Chest) and exhausted, it vanishes!
	if spawner.data.disappears_when_exhausted and spawner.current_charges <= 0:
		remove_item(spawner)
		SoundManager.play_consume()
		GameEvents.show_floating_text.emit("Chest Emptied!", spawner.global_position + Vector2(0, -45), Color(1.0, 0.85, 0.35))
		var vanish_tween := spawner.create_tween().set_parallel(true)
		vanish_tween.tween_property(spawner, "scale", Vector2.ZERO, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		vanish_tween.tween_property(spawner, "modulate:a", 0.0, 0.25)
		vanish_tween.finished.connect(func():
			if is_instance_valid(spawner):
				spawner.queue_free()
		)
		GameEvents.board_changed.emit()

func _trigger_consumable(item: ItemView) -> void:
	var amt := item.data.consume_amount
	var curr := item.data.consume_currency
	var pos := item.global_position

	if curr == "coins":
		EconomyManager.add_coins(amt)
		GameEvents.show_floating_text.emit("+%d Gold!" % amt, pos + Vector2(0, -40), Color(1.0, 0.85, 0.2))
		GameEvents.coin_consumed.emit(amt)
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

func _try_special_interaction(dragged: ItemView, target_item: ItemView) -> bool:
	if not dragged or not target_item or not dragged.data or not target_item.data:
		return false
	if not dragged.is_normal() or not target_item.is_normal():
		return false

	# 0. Tapping Milked Cow Lv.3 to Collect Milk
	if target_item.data.id == "cow_3" and target_item.is_milked_ready and dragged == target_item:
		target_item.is_milked_ready = false
		target_item.animate_merge_pop()
		SoundManager.play_consume()
		var empty_cells := get_empty_cells()
		if not empty_cells.is_empty():
			spawn_item_flight(target_item.global_position, empty_cells[0], "milk_1")
		target_item._update_visuals()
		select_item(target_item)
		GameEvents.show_floating_text.emit("Milked +1 Fresh Milk! 🥛", target_item.global_position + Vector2(0, -45), Color(1.0, 1.0, 1.0))
		GameEvents.board_changed.emit()
		return true

	# 1. Shearing Sheep with Tool Lv.4
	if target_item.can_be_sheared(dragged):
		_clear_source_slot(dragged)
		dragged.queue_free()
		target_item.shear_cooldown = 10.0
		target_item.animate_merge_pop()
		SoundManager.play_consume()

		var wool_count := 1
		match target_item.data.tier:
			1: wool_count = 1
			2: wool_count = 3
			3: wool_count = 6
			4: wool_count = 8
			_: wool_count = 1

		for i in range(wool_count):
			var empty_cells := get_empty_cells()
			if not empty_cells.is_empty():
				spawn_item_flight(target_item.global_position, empty_cells[0], "wool_1")

		target_item._update_visuals()
		select_item(target_item)
		GameEvents.show_floating_text.emit("Sheared +%d Wool! ✂️" % wool_count, target_item.global_position + Vector2(0, -45), Color(0.9, 0.85, 1.0))
		GameEvents.board_changed.emit()
		return true

	# 2. Feeding Animals, Cow Milking Feed, and Tree Compost
	if target_item.can_accept_feed(dragged):
		# Cow 3 milk ready feed (Hay Lv.5)
		if target_item.data.id == "cow_3" and dragged.data.id == "hay_5":
			_clear_source_slot(dragged)
			dragged.queue_free()
			target_item.is_milked_ready = true
			target_item.animate_merge_pop()
			SoundManager.play_consume()
			GameEvents.show_floating_text.emit("Fed! Cow Ready to Milk! 🥛", target_item.global_position + Vector2(0, -45), Color(0.9, 1.0, 0.4))
			target_item._update_visuals()
			select_item(target_item)
			GameEvents.board_changed.emit()
			return true

		# Tree 3/4 Fruit Boost feed (Hay Lv.7 Compost)
		if target_item.data.id in ["tree_3", "tree_4"] and dragged.data.id == "hay_7":
			_clear_source_slot(dragged)
			dragged.queue_free()
			var bonus := 2 if target_item.data.id == "tree_3" else 4
			target_item.is_boosted = true
			target_item.boost_charges = bonus
			target_item.animate_merge_pop()
			SoundManager.play_consume()
			GameEvents.show_floating_text.emit("Tree Boosted! (+%d Fruit Drop) 🍎" % bonus, target_item.global_position + Vector2(0, -45), Color(0.4, 1.0, 0.4))
			target_item._update_visuals()
			select_item(target_item)
			GameEvents.board_changed.emit()
			return true

		# Regular animal feeding
		_clear_source_slot(dragged)
		dragged.queue_free()
		target_item.fed_count += 1
		target_item.animate_merge_pop()
		SoundManager.play_consume()
		var req_cnt := target_item.get_required_feed_count()
		if target_item.fed_count >= req_cnt:
			GameEvents.show_floating_text.emit("Fully Fed! Ready to Merge! ⭐", target_item.global_position + Vector2(0, -45), Color(1.0, 0.85, 0.2))
		else:
			GameEvents.show_floating_text.emit("Fed! (%d/%d)" % [target_item.fed_count, req_cnt], target_item.global_position + Vector2(0, -45), Color(0.5, 1.0, 0.5))
		target_item._update_visuals()
		select_item(target_item)
		GameEvents.board_changed.emit()
		return true

	# 3. Boosting Barn with Tools (Tool Lv.3+)
	if target_item.can_be_boosted_by_tool(dragged):
		_clear_source_slot(dragged)
		dragged.queue_free()
		target_item.is_boosted = true
		target_item.boost_charges += 5
		target_item.current_charges = target_item.max_charges
		target_item.producer_status = ItemView.ProducerStatus.READY
		target_item.animate_merge_pop()
		SoundManager.play_consume()
		GameEvents.show_floating_text.emit("Barn Boosted! (+Drop Tier & Spawns) 🛠️", target_item.global_position + Vector2(0, -45), Color(1.0, 0.75, 0.3))
		target_item._update_visuals()
		select_item(target_item)
		GameEvents.board_changed.emit()
		return true

	# 4. Watering Plants (Hay, Tree, Pine)
	if target_item.can_be_watered(dragged):
		_clear_source_slot(dragged)
		dragged.queue_free()
		target_item.is_boosted = true
		target_item.boost_charges += 5
		if target_item.data.is_spawner:
			target_item.current_cooldown = 0.0
			target_item.current_charges = target_item.max_charges
			target_item.producer_status = ItemView.ProducerStatus.READY
		target_item.animate_merge_pop()
		SoundManager.play_consume()
		GameEvents.show_floating_text.emit("Watered & Boosted! 💧", target_item.global_position + Vector2(0, -45), Color(0.3, 0.85, 1.0))
		target_item._update_visuals()
		select_item(target_item)
		GameEvents.board_changed.emit()
		return true

	return false

func _drop_into_board(dragged: ItemView, target_coord: Vector2i) -> void:
	var target_item := get_item_at(target_coord)
	var is_hidden_target: bool = (target_item and target_item.is_hidden())
	if not is_hidden_target and is_valid_coord(target_coord) and _cells.size() > target_coord.x and _cells[target_coord.x].size() > target_coord.y:
		is_hidden_target = _cells[target_coord.x][target_coord.y].is_hidden_cell

	# Case 0: Dropped onto hidden tile -> bounce back
	if is_hidden_target:
		_return_item_to_origin(dragged)
		select_item(dragged)
		return

	# Case 1: Dropped onto same cell
	if target_item == dragged:
		dragged.animate_snap_to(get_cell_center(target_coord.x, target_coord.y))
		select_item(dragged)
		return

	# Case 1.5: Special Interaction (Feeding, Shearing, Tool Boosting, Watering)
	if target_item and not target_item.is_boxed() and not target_item.is_locked():
		if _try_special_interaction(dragged, target_item):
			_update_hover_cursor(get_global_mouse_position())
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
		select_item(dragged)
		return

	# Case 3: Target is Locked -> can only merge if same type and tier
	if target_item and target_item.is_locked():
		if _can_merge(dragged.data, target_item.data):
			if dragged.needs_feeding_to_upgrade() and not dragged.is_fully_fed():
				dragged.animate_wobble()
				SoundManager.play_error()
				GameEvents.show_floating_text.emit(
					"Feed animal before merging! (%d/%d)" % [dragged.fed_count, dragged.get_required_feed_count()],
					target_item.global_position + Vector2(0, -45),
					Color(1.0, 0.45, 0.45)
				)
				_return_item_to_origin(dragged)
				select_item(dragged)
				return
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
			select_item(dragged)
		return

	# Case 4: Dropped onto merge target
	if target_item and _can_merge(dragged.data, target_item.data):
		if target_item.needs_feeding_to_upgrade() or dragged.needs_feeding_to_upgrade():
			if not target_item.is_fully_fed() or not dragged.is_fully_fed():
				target_item.animate_wobble()
				dragged.animate_wobble()
				SoundManager.play_error()
				var msg := "Feed both animals to merge!"
				if not target_item.is_fully_fed() and not dragged.is_fully_fed():
					msg = "Feed both animals first!"
				elif not target_item.is_fully_fed():
					msg = "Target needs feed (%d/%d)" % [target_item.fed_count, target_item.get_required_feed_count()]
				else:
					msg = "Dragged animal needs feed (%d/%d)" % [dragged.fed_count, dragged.get_required_feed_count()]
				GameEvents.show_floating_text.emit(msg, target_item.global_position + Vector2(0, -45), Color(1.0, 0.45, 0.45))
				_return_item_to_origin(dragged)
				select_item(dragged)
				return
		_execute_merge(dragged, target_item)
		return

	# Case 5: Dropped onto empty board cell
	if not target_item:
		_clear_source_slot(dragged)
		set_item_at(target_coord, dragged)
		dragged.animate_snap_to(get_cell_center(target_coord.x, target_coord.y))
		select_item(dragged)
		GameEvents.board_changed.emit()
		return

	# Case 6: Dropped onto another item -> SWAP
	_execute_swap(dragged, target_item)
	select_item(dragged)

func _drop_into_inventory_button(item: ItemView) -> void:
	if bottom_nav_bar and not bottom_nav_bar.is_inventory_unlocked():
		SoundManager.play_error()
		var inv_btn: Control = bottom_nav_bar.get_inventory_button()
		var text_pos: Vector2 = inv_btn.global_position + Vector2(inv_btn.size.x * 0.5, -20)
		GameEvents.show_floating_text.emit("Unlock Backpack First! (3 Quests)", text_pos, Color(1.0, 0.4, 0.4))
		_return_item_to_origin(item)
		return

	if not InventoryManager.has_free_slot():
		SoundManager.play_error()
		var text_pos: Vector2 = item.global_position
		if bottom_nav_bar:
			var inv_btn: Control = bottom_nav_bar.get_inventory_button()
			text_pos = inv_btn.global_position + Vector2(inv_btn.size.x * 0.5, -20)
		GameEvents.show_floating_text.emit("Backpack Full!", text_pos, Color(1.0, 0.4, 0.4))
		_return_item_to_origin(item)
		return

	var item_id := item.data.id
	var success := InventoryManager.add_item(item_id)
	if success:
		SoundManager.play_pickup()
		if bottom_nav_bar:
			bottom_nav_bar.play_inventory_pulse()
			var inv_btn: Control = bottom_nav_bar.get_inventory_button()
			var text_pos: Vector2 = inv_btn.global_position + Vector2(inv_btn.size.x * 0.5, -20)
			GameEvents.show_floating_text.emit("Stored %s!" % item.data.display_name, text_pos, Color(0.4, 0.85, 1.0))
		remove_item(item)
		item.queue_free()
		GameEvents.item_stored_in_inventory.emit(item_id)
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
	target.board_theme = board_theme
	target.fed_count = 0
	target.shear_cooldown = 0.0
	target.is_boosted = false
	target.boost_charges = 0
	target.is_milked_ready = false
	target.animate_merge_pop()

	var pop_pos := target.global_position + Vector2(0, -50)
	var text_msg := "%s!" % [new_data.display_name]
	if was_locked:
		text_msg = "Unlocked!\n%s" % [new_data.display_name]
		GameEvents.locked_item_cleared.emit(target.grid_coord, new_data.id)
		reveal_surrounding_items(target.grid_coord)
		check_map_unlock_milestone()

	GameEvents.show_floating_text.emit(
		text_msg,
		pop_pos,
		Color(1.0, 0.9, 0.3)
	)
	ProgressionManager.unlock_item(next_id)
	select_item(target)
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
	var item_id := item.data.id

	# Special case: Wild Boar sells for Diamonds!
	if item_id == "pig_5":
		var diamond_value := 50
		EconomyManager.add_gems(diamond_value)
		SoundManager.play_consume()
		GameEvents.show_floating_text.emit("+%d Diamonds (Boar Sold) 💎" % diamond_value, item.global_position + Vector2(0, -40), Color(0.45, 0.88, 1.0))
		remove_item(item)
		item.queue_free()
		GameEvents.item_sold.emit(item_id, diamond_value)
		GameEvents.board_changed.emit()
		GameEvents.inventory_changed.emit()
		return

	EconomyManager.add_coins(value)
	SoundManager.play_consume()
	GameEvents.show_floating_text.emit("+%d Gold (Sold)" % value, item.global_position + Vector2(0, -40), Color(1.0, 0.85, 0.2))
	remove_item(item)
	item.queue_free()
	GameEvents.item_sold.emit(item_id, value)
	GameEvents.board_changed.emit()
	GameEvents.inventory_changed.emit()

func remove_item(item: ItemView) -> void:
	if selected_item == item:
		clear_selection()
	_clear_source_slot(item)

func clear_board(emit_change: bool = true) -> void:
	clear_selection()
	for c in range(cols):
		for r in range(rows):
			var it: ItemView = _grid[c][r]
			if it:
				it.queue_free()
				_grid[c][r] = null
	if emit_change:
		GameEvents.board_changed.emit()

func fill_board_random() -> void:
	var sample_pool := [
		"foodbox_1", "oven_1", "fridge_1", "rack_1",
		"egg_1", "leaf_1", "beef_1", "cake_1", "sandwich_1", "drink_1", "util_1"
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
				var unbox_id: String = item.data.id if item.data else ""
				item.unbox_to_locked()
				var unbox_pos := item.global_position + Vector2(0, -45)
				GameEvents.show_floating_text.emit(
					"Unlocked! (Lv. %d)" % item.unlock_level,
					unbox_pos,
					Color(0.9, 0.75, 1.0)
				)
				if not unbox_id.is_empty():
					GameEvents.item_unboxed.emit(unbox_id)
				any_unboxed = true
	if any_unboxed:
		check_map_unlock_milestone()
		GameEvents.board_changed.emit()

func get_unlocked_tile_count() -> int:
	var count: int = 0
	for c in range(cols):
		for r in range(rows):
			if c < _grid.size() and r < _grid[c].size():
				var it: ItemView = _grid[c][r]
				if it == null:
					if _cells.size() > c and _cells[c].size() > r and not _cells[c][r].is_hidden_cell:
						count += 1
				elif it.is_normal():
					count += 1
	return count

func check_map_unlock_milestone() -> void:
	if board_theme != "kitchen":
		return
	var unlocked_count := get_unlocked_tile_count()
	if unlocked_count >= 50:
		if is_instance_valid(ProgressionManager) and not ProgressionManager.is_map_unlocked:
			ProgressionManager.unlock_map()

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

func has_locked_or_boxed_items() -> bool:
	for c in range(cols):
		for r in range(rows):
			var it: ItemView = _grid[c][r]
			if it != null:
				if it.is_locked() or it.is_boxed() or it.is_hidden():
					return true
	return false

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
					"unlock_level": it.unlock_level,
					"box_variant": it.box_variant,
					"web_variant": it.web_variant,
					"fed_count": it.fed_count,
					"shear_cooldown": it.shear_cooldown,
					"is_boosted": it.is_boosted,
					"boost_charges": it.boost_charges,
					"is_milked_ready": it.is_milked_ready,
					"board_theme": it.board_theme
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
		var b_var: int = int(entry.get("box_variant", -1))
		var w_var: int = int(entry.get("web_variant", -1))
		if is_valid_coord(Vector2i(c, r)) and not item_id.is_empty():
			var spawned := spawn_item_at(Vector2i(c, r), item_id, state_val, req_level, b_var, w_var)
			if spawned:
				spawned.board_theme = board_theme
				if entry.has("spawner_charges"):
					var charges: int = int(entry.get("spawner_charges", spawned.max_charges))
					var cooldown: float = float(entry.get("spawner_cooldown", 0.0))
					var status_val: int = int(entry.get("producer_status", -1))
					spawned.restore_spawner_state(charges, cooldown, status_val)
				spawned.restore_interaction_state(
					int(entry.get("fed_count", 0)),
					float(entry.get("shear_cooldown", 0.0)),
					bool(entry.get("is_boosted", false)),
					int(entry.get("boost_charges", 0)),
					bool(entry.get("is_milked_ready", false))
				)
	check_boxed_items_unlock(ProgressionManager.player_level)
	check_map_unlock_milestone()
	update_all_cells_lock_visuals()
	GameEvents.board_changed.emit()
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
	if item != null and item.is_hidden():
		cell.set_cell_hidden(true)
	else:
		cell.set_cell_hidden(false)
		var locked_status: bool = (item != null and item.is_locked())
		cell.set_locked(locked_status)

func reveal_surrounding_items(center_coord: Vector2i, ring_radius: int = 1) -> Array[ItemView]:
	var revealed: Array[ItemView] = []
	for dx in range(-ring_radius, ring_radius + 1):
		for dy in range(-ring_radius, ring_radius + 1):
			if dx == 0 and dy == 0:
				continue
			var neighbor_coord := center_coord + Vector2i(dx, dy)
			if is_valid_coord(neighbor_coord):
				var neighbor_item := get_item_at(neighbor_coord)
				if neighbor_item and neighbor_item.is_hidden():
					neighbor_item.reveal(true)
					update_cell_lock_visual(neighbor_coord)
					revealed.append(neighbor_item)
	if not revealed.is_empty():
		check_map_unlock_milestone()
		GameEvents.board_changed.emit()
	return revealed

func update_all_cells_lock_visuals() -> void:
	for c in range(cols):
		for r in range(rows):
			update_cell_lock_visual(Vector2i(c, r))

var _highlighted_tutorial_cells: Array[Vector2i] = []

func highlight_tutorial_cell(coord: Vector2i, enabled: bool = true) -> void:
	if not is_valid_coord(coord):
		return
	if _cells.is_empty() or coord.x >= _cells.size() or coord.y >= _cells[coord.x].size():
		return
	var cell: BoardCell = _cells[coord.x][coord.y]
	if is_instance_valid(cell):
		cell.set_highlight(3 if enabled else 0)
		if enabled:
			if not _highlighted_tutorial_cells.has(coord):
				_highlighted_tutorial_cells.append(coord)
		else:
			_highlighted_tutorial_cells.erase(coord)

func clear_tutorial_highlights() -> void:
	for coord in _highlighted_tutorial_cells:
		if is_valid_coord(coord) and coord.x < _cells.size() and coord.y < _cells[coord.x].size():
			var cell: BoardCell = _cells[coord.x][coord.y]
			if is_instance_valid(cell):
				cell.set_highlight(0)
	_highlighted_tutorial_cells.clear()

func map_coord_for_orientation(coord: Vector2i, to_landscape: bool) -> Vector2i:
	if to_landscape:
		return Vector2i(8 - coord.y, coord.x)
	else:
		return Vector2i(coord.y, 8 - coord.x)

func rotate_board(to_landscape: bool) -> void:
	var target_cols := 9 if to_landscape else 7
	var target_rows := 7 if to_landscape else 9
	var target_cell_size := 76.0 if to_landscape else 88.0
	var target_cell_spacing := 5.0
	var target_board_margin := 10.0 if to_landscape else 12.0
	var target_corner_radius := 10 if to_landscape else 12

	if cols == target_cols and rows == target_rows and cell_size == target_cell_size and cell_spacing == target_cell_spacing:
		return

	# 1. Collect all existing items and their rotated coordinates
	var item_entries: Array[Dictionary] = []
	for c in range(cols):
		for r in range(rows):
			var it: ItemView = _grid[c][r]
			if it != null and is_instance_valid(it):
				var new_coord := map_coord_for_orientation(Vector2i(c, r), to_landscape)
				item_entries.append({"item": it, "coord": new_coord})

	# 2. Update grid dimensions and cell sizes
	cols = target_cols
	rows = target_rows
	cell_size = target_cell_size
	cell_spacing = target_cell_spacing
	board_margin = target_board_margin
	tile_corner_radius = target_corner_radius

	_apply_board_styling()
	_init_grid()
	_create_cells()

	# 3. Update indicator scale base for new cell size
	if _indicator_sprite and _indicator_sprite.texture:
		var tex_sz := _indicator_sprite.texture.get_size()
		var base_scale := (cell_size * 0.95) / maxf(tex_sz.x, tex_sz.y)
		_indicator_base_scale = Vector2(base_scale, base_scale)
		_indicator_sprite.scale = _indicator_base_scale

	# 4. Restore items into new grid positions with proportionate scale
	var item_scale_factor := cell_size / 88.0
	for entry in item_entries:
		var it: ItemView = entry["item"]
		var coord: Vector2i = entry["coord"]
		if is_valid_coord(coord):
			_grid[coord.x][coord.y] = it
			it.grid_coord = coord
			it.scale = Vector2.ONE * item_scale_factor
			it.position = get_cell_center(coord.x, coord.y)
			it.target_slot_pos = it.position

	# 5. Update selection indicator if any item was selected
	if selected_item and is_instance_valid(selected_item):
		select_item(selected_item)

	# 6. Re-map tutorial highlights if any
	var old_tutorial := _highlighted_tutorial_cells.duplicate()
	_highlighted_tutorial_cells.clear()
	for old_coord in old_tutorial:
		var new_coord := map_coord_for_orientation(old_coord, to_landscape)
		highlight_tutorial_cell(new_coord, true)

	# 7. Refresh cell lock visual status & notify
	update_all_cells_lock_visuals()
	GameEvents.board_changed.emit()



