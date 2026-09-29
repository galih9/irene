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
	resized.connect(update_layout)

# ─── Setup ───────────────────────────────────────────────────────────────────

## Rows are ordered top to bottom; each cell dictionary keeps future metadata.
func setup_level(level_rows: Array) -> void:
	clear_grid()
	rows = level_rows.size()
	cols = level_rows[0].size() if rows > 0 else 0
	_recalculate_block_size()
	cloth = BigCloth.new()
	cloth.name = "BigCloth"
	add_child(cloth)
	var cloth_size := _get_cloth_size()
	cloth.setup(level_rows, cloth_size)
	cloth.position = _get_cloth_origin(cloth_size)
	columns_stacks.resize(cols)
	for c in range(cols):
		columns_stacks[c] = [cloth]
	total_starting_blocks = rows * cols

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
	if not is_instance_valid(cloth) or cloth.is_cleared:
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
	if not is_instance_valid(cloth) or cloth.is_cleared:
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
