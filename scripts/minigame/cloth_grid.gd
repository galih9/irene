class_name ClothGrid
extends Control

## Manages a single unified BigCloth that fills the grid area.
## Each cell in the cloth has its own color_id, arranged in rows x cols.
## Exposes bottom-row cells for rolling; consumed cells disappear in place.
## All game queries (exposed blocks, color counts) forward to the BigCloth.

signal block_cleared(color_id: String, world_pos: Vector2)
signal all_blocks_cleared()

@export var cols: int = 4
@export var rows: int = 2
@export var spacing: Vector2 = Vector2(10.0, 10.0)  # kept for API compat, unused

# The single cloth piece
var cloth: BigCloth = null

# Mirrors the old API: columns_stacks is a flat wrapper so existing callers
# (tests, etc.) that probe grid.columns_stacks still work.
# Each entry is a one-element array containing the BigCloth or [].
var columns_stacks: Array = []

var block_size: Vector2 = Vector2(120, 80)   # kept for update_layout compat
@export var target_cell_height: float = 52.0
var total_starting_blocks: int = 0

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_PASS

# ─── Setup ───────────────────────────────────────────────────────────────────

## Initializes the cloth grid.
## colors_pool: available color_ids for procedural fill.
## custom_stacks: legacy column-stack format still accepted:
##   Array of cols, each col is Array of {color, rows, cols} dicts → flattened
##   into the single cloth grid.
func setup_grid(p_cols: int, p_rows: int, colors_pool: Array[String], custom_stacks: Array = []) -> void:
	clear_grid()
	cols = max(1, p_cols)
	rows = max(1, p_rows)
	total_starting_blocks = 0

	_recalculate_block_size()

	# Build the 2D color grid (rows x cols)
	var grid_colors: Array = _build_color_grid(colors_pool, custom_stacks)

	# Create the single BigCloth
	cloth = BigCloth.new()
	cloth.name = "BigCloth"
	add_child(cloth)

	var cloth_size := _get_cloth_size()
	cloth.setup(grid_colors, cloth_size)

	# Center the cloth in our area
	cloth.position = _get_cloth_origin(cloth_size)

	# Wire signals
	cloth.rolling_finished.connect(_on_cloth_rolling_finished)

	# Build columns_stacks compatibility shim: each "column" is [cloth]
	columns_stacks.resize(cols)
	for c in range(cols):
		columns_stacks[c] = [cloth]  # cloth acts as the exposed block for every column

	total_starting_blocks = rows * cols

func _build_color_grid(colors_pool: Array[String], custom_stacks: Array) -> Array:
	## Returns 2D array [row][col] of color_id strings.
	## Row 0 = top, row (rows-1) = bottom.
	var grid: Array = []
	for r in range(rows):
		var row_arr: Array = []
		for c in range(cols):
			row_arr.append("")
		grid.append(row_arr)

	var use_custom := custom_stacks.size() == cols

	if use_custom:
		# Legacy format: custom_stacks[col] = Array of {color, rows, cols} blocks
		# We map each block's cells into the cloth grid column by column.
		for c in range(cols):
			var col_blocks: Array = custom_stacks[c]
			# Each block occupies some rows in this column.
			# Flatten from bottom (highest row index) upward.
			var row_cursor := rows - 1
			for bi in range(col_blocks.size()):
				var block = col_blocks[bi]
				var bc: String = str(block.get("color", "green")) if block is Dictionary else str(block)
				var block_rows: int = int(block.get("rows", 1)) if block is Dictionary else 1
				for _br in range(block_rows):
					if row_cursor >= 0:
						grid[row_cursor][c] = bc
						row_cursor -= 1
	else:
		# Procedural: assign random colors from pool per cell
		for r in range(rows):
			for c in range(cols):
				grid[r][c] = colors_pool[randi() % colors_pool.size()]

	return grid

# ─── Layout ──────────────────────────────────────────────────────────────────

func _recalculate_block_size() -> void:
	var avail_w := size.x if size.x > 100.0 else (custom_minimum_size.x if custom_minimum_size.x > 100.0 else 600.0)
	var avail_h := size.y if size.y > 100.0 else (custom_minimum_size.y if custom_minimum_size.y > 100.0 else 240.0)
	block_size = Vector2(avail_w, avail_h)

func _get_cloth_size() -> Vector2:
	var avail_w := size.x if size.x > 100.0 else (custom_minimum_size.x if custom_minimum_size.x > 100.0 else 600.0)
	var avail_h := size.y if size.y > 100.0 else (custom_minimum_size.y if custom_minimum_size.y > 100.0 else 240.0)
	var target_w := avail_w - 16.0
	# Proportional, shorter cell height for rolling cloth strips (target 52px per row)
	var desired_h := BigCloth.PAD * 2.0 + float(rows) * target_cell_height + float(maxi(0, rows - 1)) * BigCloth.CELL_SPACE
	var target_h := minf(desired_h, avail_h - 16.0)
	return Vector2(target_w, target_h)

func _get_cloth_origin(cloth_size: Vector2) -> Vector2:
	var avail_w := size.x if size.x > 100.0 else (custom_minimum_size.x if custom_minimum_size.x > 100.0 else 600.0)
	var avail_h := size.y if size.y > 100.0 else (custom_minimum_size.y if custom_minimum_size.y > 100.0 else 240.0)
	return Vector2((avail_w - cloth_size.x) * 0.5, (avail_h - cloth_size.y) * 0.5)

# ─── Game Queries ─────────────────────────────────────────────────────────────

## Returns how many consecutive cells of color_id exist from the bottom of column c.
func get_consecutive_color_count(c: int, color_id: String) -> int:
	if not is_instance_valid(cloth) or cloth.is_cleared:
		return 0
	return cloth.get_consecutive_color_count(c, color_id)

## Returns the BigCloth node for each non-empty column's exposed (bottom) cell,
## mirroring the old ClothBlock array interface.
## Used by ThreadRollerMinigame and RollerStation.
func get_exposed_blocks() -> Array[BigCloth]:
	var exposed: Array[BigCloth] = []
	if not is_instance_valid(cloth) or cloth.is_cleared or cloth.is_rolling:
		return exposed
	for c in range(cols):
		var color := cloth.get_bottom_cell_color(c)
		if color != "":
			exposed.append(cloth)
			break  # Only include the cloth once; callers iterate per-color
	return exposed

## Returns a list of structs: {col, color} for each exposed column bottom cell.
func get_exposed_cells() -> Array:
	if not is_instance_valid(cloth):
		return []
	return cloth.get_exposed_cells()

## Returns the BigCloth if any exposed column bottom matches color_id.
func find_matching_exposed_block(color_id: String) -> BigCloth:
	if not is_instance_valid(cloth) or cloth.is_cleared or cloth.is_rolling:
		return null
	var col := cloth.find_matching_exposed_col(color_id)
	if col >= 0:
		return cloth
	return null

## Returns the column index that has an exposed bottom cell matching color_id.
## -1 if not found.
func find_matching_col(color_id: String) -> int:
	if not is_instance_valid(cloth) or cloth.is_cleared:
		return -1
	return cloth.find_matching_exposed_col(color_id)

## Called when rolling finishes in a column. Checks win condition.
func _on_cloth_rolling_finished(_c: BigCloth) -> void:
	if get_remaining_blocks_count() == 0:
		all_blocks_cleared.emit()

## Returns how many cloth "blocks" (cells) remain. For the new single-cloth
## model this is the number of remaining cells total.
func get_remaining_blocks_count() -> int:
	if not is_instance_valid(cloth):
		return 0
	return cloth.remaining_cells

func get_total_remaining_cells() -> int:
	if not is_instance_valid(cloth):
		return 0
	return cloth.remaining_cells

func get_remaining_cells_by_color() -> Dictionary:
	if not is_instance_valid(cloth):
		return {}
	return cloth.get_remaining_cells_by_color()

## Called by ThreadRollerMinigame after a spool finishes on a column.
## Emits block_cleared and checks win.
func consume_block_and_apply_gravity(block: BigCloth) -> void:
	if not is_instance_valid(block):
		return
	# In the single-cloth model, "consuming" just means one cell was already
	# blanked during roll_cells. We emit the signal for the score system.
	block_cleared.emit(block.color_id, block.global_position + block.size * 0.5)
	if get_remaining_blocks_count() == 0:
		all_blocks_cleared.emit()

## Slot position shim — kept for compatibility (unused in new model).
func get_slot_position(_c: int, _s: int) -> Vector2:
	return cloth.position if is_instance_valid(cloth) else Vector2.ZERO

func clear_grid() -> void:
	if is_instance_valid(cloth):
		cloth.queue_free()
		cloth = null
	columns_stacks.clear()

## Refreshes cloth size if the container is resized.
func update_layout() -> void:
	_recalculate_block_size()
	if is_instance_valid(cloth) and not cloth.is_cleared:
		var cloth_size := _get_cloth_size()
		cloth.custom_minimum_size = cloth_size
		cloth.size = cloth_size
		cloth.pivot_offset = cloth_size * 0.5
		cloth.position = _get_cloth_origin(cloth_size)
		cloth.queue_redraw()
