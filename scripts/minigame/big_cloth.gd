class_name BigCloth
extends Control

## A single unified cloth piece drawn as one big grid of rows x columns.
## Each cell has its own color_id. Cells are consumed column-by-column from
## the bottom row upward, mimicking thread being unrolled off the cloth.
## Compatible drop-in interface replacement for ClothBlock for RollerSlot use.

signal rolling_started(cloth: BigCloth)
signal cell_rolled(cloth: BigCloth, remaining: int)
signal rolling_finished(cloth: BigCloth)

## col_index / stack_index kept for RollerSlot/RollerStation API compatibility.
var col_index: int = 0
var stack_index: int = 0

var is_rolling: bool = false
var is_cleared: bool = false

## color_id of the currently-active rolling session (matches spool color).
var color_id: String = "":
	set(val):
		color_id = val
		queue_redraw()

## 2D grid: _cells[row][col] = color_id string, or "" if consumed.
## Row 0 = TOP row, row (rows-1) = BOTTOM row.
var _cells: Array = []
var rows: int = 0
var cols: int = 0

## Tracks total and remaining cell counts.
var total_cells: int = 0
var remaining_cells: int = 0
var rolled_cells: int = 0

## Which column is currently being unrolled (bottom row first approach).
var _active_col: int = -1

var _roll_tween: Tween = null
var _fall_tween: Tween = null
var _drop_tween: Tween = null
var _current_target_pos: Vector2 = Vector2.ZERO

## Vertical pixel offset applied during the row-drop animation (rows slide down).
var _drop_offset: float = 0.0

## Cell visual config
const PAD := 5.0
const CELL_SPACE := 3.0
const BORDER_W := 2.5

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_PASS
	custom_minimum_size = Vector2(160, 100)
	pivot_offset = size * 0.5
	clip_contents = true  # Clip cells to cloth bounds during row-drop animation

## Builds the cloth grid from a 2D array of color_ids.
## p_grid[row][col] = color_id string (row 0 = top, row rows-1 = bottom).
func setup(p_grid: Array, p_size: Vector2) -> void:
	rows = p_grid.size()
	cols = p_grid[0].size() if rows > 0 else 0
	_cells = []
	for r in range(rows):
		var row_arr: Array = []
		for c in range(cols):
			row_arr.append(str(p_grid[r][c]))
		_cells.append(row_arr)
	total_cells = rows * cols
	remaining_cells = total_cells
	rolled_cells = 0
	is_rolling = false
	is_cleared = false
	_active_col = -1
	custom_minimum_size = p_size
	size = p_size
	pivot_offset = p_size * 0.5
	# Set color_id to the bottom-left cell as a reference color (for spool matching)
	if rows > 0 and cols > 0:
		color_id = _cells[rows - 1][0]
	queue_redraw()

## Returns color_id of the first non-empty cell in the bottom row for a given column.
## Returns "" if the column is fully consumed.
func get_bottom_cell_color(c: int) -> String:
	for r in range(rows - 1, -1, -1):
		if _cells[r][c] != "":
			return _cells[r][c]
	return ""

## Returns a list of (col_index, color_id) pairs for all currently exposed bottom cells.
func get_exposed_cells() -> Array:
	var exposed := []
	for c in range(cols):
		var color := get_bottom_cell_color(c)
		if color != "":
			exposed.append({"col": c, "color": color})
	return exposed

## Returns color of the first available exposed cell matching the given color_id.
## Returns -1 if not found.
func find_matching_exposed_col(p_color_id: String) -> int:
	for c in range(cols):
		if get_bottom_cell_color(c) == p_color_id:
			return c
	return -1

## Returns how many cells remain in a specific column.
func get_col_remaining(c: int) -> int:
	var count := 0
	for r in range(rows):
		if _cells[r][c] != "":
			count += 1
	return count

## Returns how many consecutive cells of target_color exist in column c starting from the bottom upward.
## Stops as soon as a cell of a different color (or top of column) is encountered.
func get_consecutive_color_count(c: int, target_color: String) -> int:
	if c < 0 or c >= cols or target_color == "":
		return 0
	var count := 0
	for r in range(rows - 1, -1, -1):
		var cid: String = _cells[r][c]
		if cid == "":
			continue
		if cid == target_color:
			count += 1
		else:
			break
	return count

## Returns total remaining cells per color_id as a Dictionary.
func get_remaining_cells_by_color() -> Dictionary:
	var map: Dictionary = {}
	for r in range(rows):
		for c in range(cols):
			var cid: String = _cells[r][c]
			if cid != "":
				map[cid] = map.get(cid, 0) + 1
	return map

## Returns the Rect2 (in local coordinates) for the cell at [r][c],
## including any active _drop_offset animation shift.
func _get_cell_rect(r: int, c: int) -> Rect2:
	var avail_w := size.x - PAD * 2.0 - CELL_SPACE * float(cols - 1)
	var avail_h := size.y - PAD * 2.0 - CELL_SPACE * float(rows - 1)
	var cell_w := maxf(14.0, avail_w / float(cols))
	var cell_h := maxf(14.0, avail_h / float(rows))
	var cx := PAD + float(c) * (cell_w + CELL_SPACE)
	var cy := PAD + float(r) * (cell_h + CELL_SPACE) + _drop_offset
	return Rect2(cx, cy, cell_w, cell_h)

## Returns the global center of the bottom non-empty cell in the active rolling column.
## Includes the _drop_offset so the thread follows cells during the row-drop animation.
## Falls back to cloth center-bottom if no active column is set.
func get_attachment_point() -> Vector2:
	if _active_col >= 0 and _active_col < cols:
		# Find the bottom-most non-empty cell in the active column
		for r in range(rows - 1, -1, -1):
			if _cells[r][_active_col] != "":
				var cell_rect := _get_cell_rect(r, _active_col)
				return global_position + cell_rect.get_center()
	# Fallback: bottom-center of the cloth
	return global_position + Vector2(size.x * 0.5, size.y * 0.9)

## Rolls cells_to_roll cells from the specified column, bottom-up.
## color_id must match the column's bottom color. Calls on_cell_rolled every 1 second.
## Calls on_complete when done. Compatible with RollerSlot.start_rolling().
func roll_cells(cells_to_roll: int, target_global_pos: Vector2, on_cell_rolled: Callable = Callable(), on_complete: Callable = Callable()) -> void:
	if is_rolling or is_cleared:
		return

	var roll_color := color_id
	if roll_color == "" and rows > 0 and cols > 0:
		roll_color = get_bottom_cell_color(_active_col if _active_col >= 0 else 0)
	color_id = roll_color

	var available_matching := 0
	if _active_col >= 0 and _active_col < cols:
		available_matching = get_consecutive_color_count(_active_col, roll_color)
	if available_matching <= 0:
		for c in range(cols):
			var cnt := get_consecutive_color_count(c, roll_color)
			if cnt > 0:
				_active_col = c
				available_matching = cnt
				break

	if available_matching <= 0:
		return

	var actual_cells := clampi(cells_to_roll, 1, available_matching)

	is_rolling = true
	rolling_started.emit(self)

	if _roll_tween and _roll_tween.is_valid():
		_roll_tween.kill()

	# Calculate subtle tilt direction toward the roller
	var my_center := global_position + size * 0.5
	var pull_dir := (target_global_pos - my_center).normalized()

	_roll_tween = create_tween()

	for i in range(actual_cells):
		_roll_tween.tween_interval(1.0)
		_roll_tween.tween_callback(func():
			_consume_one_cell(roll_color)
			queue_redraw()
			remaining_cells = maxi(0, remaining_cells - 1)
			rolled_cells += 1
			cell_rolled.emit(self, remaining_cells)
			if on_cell_rolled.is_valid():
				on_cell_rolled.call()
		)

	_roll_tween.chain().tween_callback(func():
		is_rolling = false
		if remaining_cells <= 0:
			_animate_full_clear(pull_dir, on_complete)
		else:
			# Update exposed color reference for next roll
			_refresh_color_id()
			if on_complete.is_valid():
				on_complete.call()
	)

## Consumes one cell from the active column's bottom matching expected_color, moving up the column.
func _consume_one_cell(expected_color: String = "") -> void:
	if _active_col < 0 or _active_col >= cols:
		_active_col = 0

	# Find the lowest remaining matching cell in _active_col and blank it
	for r in range(rows - 1, -1, -1):
		if _cells[r][_active_col] != "":
			if expected_color == "" or _cells[r][_active_col] == expected_color:
				_cells[r][_active_col] = ""
				_check_and_drop_bottom_row()
				return
			break

	# If that column has no matching cell at the bottom, find next matching column
	for step in range(1, cols):
		var next_col := (_active_col + step) % cols
		for r in range(rows - 1, -1, -1):
			if _cells[r][next_col] != "":
				if expected_color == "" or _cells[r][next_col] == expected_color:
					_active_col = next_col
					_cells[r][next_col] = ""
					_check_and_drop_bottom_row()
					return
				break

## Begins rolling cells from a specific column (called by ClothGrid).
func start_column_roll(target_col: int, cells_to_roll: int, target_global_pos: Vector2, on_cell_rolled: Callable = Callable(), on_complete: Callable = Callable()) -> void:
	_active_col = target_col
	if is_rolling or is_cleared:
		return

	var roll_color := get_bottom_cell_color(target_col)
	if roll_color == "":
		return
	color_id = roll_color

	var matching_consecutive := get_consecutive_color_count(target_col, roll_color)
	if matching_consecutive <= 0:
		return

	var actual_cells := clampi(cells_to_roll, 1, matching_consecutive)

	is_rolling = true
	rolling_started.emit(self)

	if _roll_tween and _roll_tween.is_valid():
		_roll_tween.kill()

	var my_center := global_position + size * 0.5
	var pull_dir := (target_global_pos - my_center).normalized()

	_roll_tween = create_tween()

	for i in range(actual_cells):
		_roll_tween.tween_interval(1.0)
		_roll_tween.tween_callback(func():
			_consume_bottom_cell_in_col(target_col, roll_color)
			remaining_cells = maxi(0, remaining_cells - 1)
			rolled_cells += 1
			queue_redraw()
			cell_rolled.emit(self, remaining_cells)
			if on_cell_rolled.is_valid():
				on_cell_rolled.call()
		)

	_roll_tween.chain().tween_callback(func():
		is_rolling = false
		_refresh_color_id()
		if remaining_cells <= 0:
			_animate_full_clear(pull_dir, on_complete)
		else:
			if on_complete.is_valid():
				on_complete.call()
	)

func _consume_bottom_cell_in_col(c: int, expected_color: String = "") -> void:
	if c < 0 or c >= cols:
		return
	for r in range(rows - 1, -1, -1):
		if _cells[r][c] != "":
			if expected_color != "" and _cells[r][c] != expected_color:
				return # Safety guard: never consume non-matching cell
			_cells[r][c] = ""
			# After consuming, check if the whole bottom row is now empty
			_check_and_drop_bottom_row()
			return

## Checks if the bottom row is fully empty. If so, shifts rows down and animates the drop.
func _check_and_drop_bottom_row() -> void:
	if rows <= 1:
		return
	# Check bottom row (index rows-1)
	for c in range(cols):
		if _cells[rows - 1][c] != "":
			return  # Bottom row still has content — no drop needed

	# Bottom row is fully empty: shift all row data DOWN by one row
	# (each row moves from its current index to the next higher index)
	for r in range(rows - 1, 0, -1):
		_cells[r] = _cells[r - 1].duplicate()
	# Top row is now vacated
	for c in range(cols):
		_cells[0][c] = ""

	# Play the visual drop slide
	_animate_row_drop()

## Plays the row-drop animation: renders rows shifted up by one cell height,
## then tweens them back to their final position with a soft bounce.
func _animate_row_drop() -> void:
	if _drop_tween and _drop_tween.is_valid():
		_drop_tween.kill()

	# Calculate one cell height to know the slide distance
	var avail_h := size.y - PAD * 2.0 - CELL_SPACE * float(rows - 1)
	var cell_h := maxf(14.0, avail_h / float(rows))
	var one_row_h := cell_h + CELL_SPACE

	# Start with content appearing one row ABOVE final position
	_drop_offset = -one_row_h
	queue_redraw()

	_drop_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_drop_tween.tween_property(self, "_drop_offset", 0.0, 0.30)
	_drop_tween.tween_callback(queue_redraw)

func _refresh_color_id() -> void:
	# Update the reference color_id to the first non-empty exposed cell
	for c in range(cols):
		var bc := get_bottom_cell_color(c)
		if bc != "":
			color_id = bc
			return
	color_id = ""

func _animate_full_clear(pull_dir: Vector2, on_complete: Callable) -> void:
	is_cleared = true
	var exit_tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	exit_tween.tween_property(self, "scale", Vector2(0.1, 0.1), 0.22)
	exit_tween.tween_property(self, "modulate:a", 0.0, 0.22)
	exit_tween.tween_property(self, "position", position + pull_dir * 35.0, 0.22)
	exit_tween.chain().tween_callback(func():
		rolling_finished.emit(self)
		if on_complete.is_valid():
			on_complete.call()
		queue_free()
	)

## Fall-to animation for compatibility (not used but kept for API parity).
func animate_fall_to(_new_pos: Vector2, _delay: float = 0.0, _duration: float = 0.26) -> void:
	pass

# ─── Drawing ─────────────────────────────────────────────────────────────────

func _draw() -> void:
	if rows == 0 or cols == 0:
		return

	var avail_w := size.x - PAD * 2.0 - CELL_SPACE * float(cols - 1)
	var avail_h := size.y - PAD * 2.0 - CELL_SPACE * float(rows - 1)
	var cell_w := maxf(14.0, avail_w / float(cols))
	var cell_h := maxf(14.0, avail_h / float(rows))

	# 1. Drop shadow for the whole cloth
	draw_rect(Rect2(Vector2(0, 4), size), Color(0, 0, 0, 0.18), true)

	# 2. Dark backing plate (clipping rect — cells will be masked to this)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.12, 0.12, 0.15, 0.6), true)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.1, 0.1, 0.13, 1.0), false, BORDER_W)

	# 3. Draw all cells (apply _drop_offset to Y for row-drop animation)
	var cloth_bounds := Rect2(Vector2.ZERO, size)
	for r in range(rows):
		for c in range(cols):
			var cx := PAD + float(c) * (cell_w + CELL_SPACE)
			var cy := PAD + float(r) * (cell_h + CELL_SPACE) + _drop_offset
			var cell_rect := Rect2(cx, cy, cell_w, cell_h)
			# Skip cells that are fully outside the cloth bounds during animation
			if not cloth_bounds.intersects(cell_rect):
				continue
			var cid: String = _cells[r][c]

			if cid == "":
				# Consumed cell: empty weave socket
				draw_rect(cell_rect, Color(0, 0, 0, 0.30), true)
				draw_rect(cell_rect, Color(1, 1, 1, 0.10), false, 1.0)
				draw_line(
					Vector2(cell_rect.position.x + 4, cell_rect.get_center().y),
					Vector2(cell_rect.end.x - 4, cell_rect.get_center().y),
					Color(1, 1, 1, 0.12), 1.5
				)
			else:
				# Active fabric cell with color
				var c_data := ThreadColorPalette.get_color_data(cid)
				var main_c: Color = c_data.get("main", Color.WHITE)
				var dark_c: Color = c_data.get("dark", Color.BLACK)
				var light_c: Color = c_data.get("light", Color.WHITE)

				# Cell fill
				draw_rect(cell_rect, main_c, true)
				draw_rect(cell_rect, dark_c, false, 1.8)

				# Inner stitching
				var inset := 3.0
				var inner := cell_rect.grow(-inset)
				if inner.size.x > 4.0 and inner.size.y > 4.0:
					var stitch_c := light_c
					stitch_c.a = 0.75
					_draw_dashed_segment(inner.position, Vector2(inner.end.x, inner.position.y), stitch_c, 4.0)
					_draw_dashed_segment(Vector2(inner.position.x, inner.end.y), inner.end, stitch_c, 4.0)
					_draw_dashed_segment(inner.position, Vector2(inner.position.x, inner.end.y), stitch_c, 4.0)
					_draw_dashed_segment(Vector2(inner.end.x, inner.position.y), inner.end, stitch_c, 4.0)

				# Shine highlight
				var shine_c := light_c
				shine_c.a = 0.30
				draw_rect(Rect2(cell_rect.position + Vector2(2, 2), Vector2(maxf(2.0, cell_w - 4), maxf(2.0, cell_h * 0.28))), shine_c, true)

				# Center cross stitch
				var cc := cell_rect.get_center()
				var cs := minf(cell_w, cell_h) * 0.14
				draw_line(cc - Vector2(cs, 0), cc + Vector2(cs, 0), light_c, 1.1)
				draw_line(cc - Vector2(0, cs), cc + Vector2(0, cs), light_c, 1.1)

				# Bold border between cells of DIFFERENT colors (check right + bottom neighbor)
				if c < cols - 1 and _cells[r][c + 1] != "" and _cells[r][c + 1] != cid:
					# Right neighbor is different color → draw separator
					var sep_x := cell_rect.end.x + CELL_SPACE * 0.5
					draw_line(Vector2(sep_x, cell_rect.position.y - 1), Vector2(sep_x, cell_rect.end.y + 1), Color(0, 0, 0, 0.7), 2.0)
				if r < rows - 1 and _cells[r + 1][c] != "" and _cells[r + 1][c] != cid:
					# Bottom neighbor is different color → draw separator
					var sep_y := cell_rect.end.y + CELL_SPACE * 0.5
					draw_line(Vector2(cell_rect.position.x - 1, sep_y), Vector2(cell_rect.end.x + 1, sep_y), Color(0, 0, 0, 0.7), 2.0)

	# 4. Remaining cells badge (bottom-right)
	if remaining_cells > 0:
		var badge_w := 36.0
		var badge_h := 18.0
		var badge_pos := Vector2(size.x - badge_w - 4.0, size.y - badge_h - 4.0)
		draw_rect(Rect2(badge_pos + Vector2(0, 1), Vector2(badge_w, badge_h)), Color(0, 0, 0, 0.35), true)
		draw_rect(Rect2(badge_pos, Vector2(badge_w, badge_h)), Color(0.12, 0.14, 0.18, 0.90), true)
		draw_rect(Rect2(badge_pos, Vector2(badge_w, badge_h)), Color(0.8, 0.85, 0.95, 0.7), false, 1.2)
		var font := ThemeDB.fallback_font
		var text_str := "%d" % remaining_cells
		var font_size := 11
		var text_size := font.get_string_size(text_str, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var text_pos := badge_pos + Vector2((badge_w - text_size.x) * 0.5, (badge_h + text_size.y) * 0.5 - 2.0)
		draw_string(font, text_pos, text_str, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.WHITE)

func _draw_dashed_segment(from: Vector2, to: Vector2, col: Color, dash_len: float) -> void:
	var total_len := from.distance_to(to)
	if total_len <= 0.001:
		return
	var dir := (to - from).normalized()
	var curr := 0.0
	var draw_dash := true
	while curr < total_len:
		var next_curr := minf(curr + dash_len, total_len)
		if draw_dash:
			draw_line(from + dir * curr, from + dir * next_curr, col, 1.5)
		curr = next_curr
		draw_dash = not draw_dash
