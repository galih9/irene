class_name ClothBlock
extends Control

## A cloth block in the stack grid composed of smaller rows and columns (cells).
## Each cell represents 1 second of rolling time (the bigger the cloth, the longer the rolling time).
## Features soft rounded styling, dashed quilted stitching, cell-by-cell unrolling,
## and gravity falling when lower blocks are unrolled.

signal rolling_started(block: ClothBlock)
signal cell_rolled(block: ClothBlock, remaining: int)
signal rolling_finished(block: ClothBlock)

@export var color_id: String = "green":
	set(val):
		color_id = val
		queue_redraw()

var col_index: int = 0
var stack_index: int = 0 # 0 = bottom exposed block, 1+ = stacked above
var is_rolling: bool = false
var is_cleared: bool = false

# Sub-grid cell configuration
var cell_rows: int = 1
var cell_cols: int = 1
var total_cells: int = 1
var remaining_cells: int = 1
var rolled_cells: int = 0

var _fall_tween: Tween = null
var _roll_tween: Tween = null
var _current_target_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_PASS
	custom_minimum_size = Vector2(100, 80)
	pivot_offset = size * 0.5

## Configures the cloth block with color, stack position, size, and sub-grid cell dimensions.
func setup(p_color_id: String, p_col: int, p_stack: int, p_size: Vector2, p_cell_rows: int = 1, p_cell_cols: int = 1) -> void:
	color_id = p_color_id
	col_index = p_col
	stack_index = p_stack
	custom_minimum_size = p_size
	size = p_size
	pivot_offset = p_size * 0.5
	cell_rows = maxi(1, p_cell_rows)
	cell_cols = maxi(1, p_cell_cols)
	total_cells = cell_rows * cell_cols
	remaining_cells = total_cells
	rolled_cells = 0
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var c_data := ThreadColorPalette.get_color_data(color_id)
	var main_c: Color = c_data.get("main", Color.WHITE)
	var dark_c: Color = c_data.get("dark", Color.BLACK)
	var light_c: Color = c_data.get("light", Color.WHITE)

	# 1. Subtle drop shadow for whole cloth piece
	var shadow_rect := Rect2(Vector2(0, 4), size)
	draw_rect(shadow_rect, Color(0, 0, 0, 0.2), true, -1, false)

	# 2. Main cloth backplate
	var bg_plate_c := dark_c
	bg_plate_c.a = 0.55
	draw_rect(rect, bg_plate_c, true, -1, false)
	draw_rect(rect, dark_c, false, 2.5, false)

	# 3. Render individual sub-grid cells (rows x cols)
	var pad := 4.0
	var cell_space := 3.0
	var avail_w := size.x - (pad * 2.0) - (cell_space * float(cell_cols - 1))
	var avail_h := size.y - (pad * 2.0) - (cell_space * float(cell_rows - 1))
	var cell_w := maxf(12.0, avail_w / float(cell_cols))
	var cell_h := maxf(12.0, avail_h / float(cell_rows))

	var active_cell_idx := 0
	for r in range(cell_rows):
		for c in range(cell_cols):
			var idx := r * cell_cols + c
			var cx := pad + float(c) * (cell_w + cell_space)
			var cy := pad + float(r) * (cell_h + cell_space)
			var cell_rect := Rect2(cx, cy, cell_w, cell_h)

			if idx < rolled_cells:
				# Cell already rolled up: draw faded empty weave socket
				var empty_bg := Color(0, 0, 0, 0.25)
				draw_rect(cell_rect, empty_bg, true, -1, false)
				draw_rect(cell_rect, Color(1, 1, 1, 0.12), false, 1.0, false)
				# Thread trace line
				draw_line(
					Vector2(cell_rect.position.x + 4, cell_rect.get_center().y),
					Vector2(cell_rect.end.x - 4, cell_rect.get_center().y),
					Color(1, 1, 1, 0.15),
					1.5
				)
			else:
				# Active remaining cell: rich quilted fabric cell
				draw_rect(cell_rect, main_c, true, -1, false)
				draw_rect(cell_rect, dark_c, false, 1.8, false)

				# Inner stitching around the cell
				var inset := 3.0
				var inner_c := cell_rect.grow(-inset)
				if inner_c.size.x > 4.0 and inner_c.size.y > 4.0:
					var stitch_c := light_c
					stitch_c.a = 0.55
					draw_rect(inner_c, stitch_c, false, 1.0, false)

				# Top soft shine
				var shine_rect := Rect2(cell_rect.position + Vector2(2, 2), Vector2(maxf(2.0, cell_rect.size.x - 4), maxf(2.0, cell_rect.size.y * 0.3)))
				var shine_c := light_c
				shine_c.a = 0.35
				draw_rect(shine_rect, shine_c, true, -1, false)

				# Center stitch cross
				var cell_center := cell_rect.get_center()
				var cross_size := minf(cell_w, cell_h) * 0.16
				draw_line(cell_center - Vector2(cross_size, 0), cell_center + Vector2(cross_size, 0), light_c, 1.2)
				draw_line(cell_center - Vector2(0, cross_size), cell_center + Vector2(0, cross_size), light_c, 1.2)

	# 4. Cute pill badge showing remaining seconds (1 cell = 1 second)
	if remaining_cells > 0:
		var badge_w := 34.0
		var badge_h := 18.0
		var badge_pos := Vector2(size.x - badge_w - 4.0, size.y - badge_h - 4.0)
		var badge_rect := Rect2(badge_pos, Vector2(badge_w, badge_h))
		# Shadow
		draw_rect(Rect2(badge_pos + Vector2(0, 1), Vector2(badge_w, badge_h)), Color(0, 0, 0, 0.35), true, -1, false)
		# Badge body
		draw_rect(badge_rect, Color(0.12, 0.14, 0.18, 0.88), true, -1, false)
		draw_rect(badge_rect, light_c, false, 1.2, false)

		# Text: e.g. "3s"
		var font := ThemeDB.fallback_font
		var text_str := "%ds" % remaining_cells
		var font_size := 11
		var text_size := font.get_string_size(text_str, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var text_pos := badge_pos + Vector2((badge_w - text_size.x) * 0.5, (badge_h + text_size.y) * 0.5 - 2.0)
		draw_string(font, text_pos, text_str, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.WHITE)

func _draw_dashed_segment(from: Vector2, to: Vector2, col: Color, dash_len: float) -> void:
	var total_len := from.distance_to(to)
	if total_len <= 0.001:
		return
	var dir := (to - from).normalized()
	var pts := PackedVector2Array()
	var curr := 0.0
	var draw_dash := true
	while curr < total_len:
		var next_curr := minf(curr + dash_len, total_len)
		if draw_dash:
			pts.append(from + dir * curr)
			pts.append(from + dir * next_curr)
		curr = next_curr
		draw_dash = not draw_dash
	if pts.size() >= 2:
		draw_multiline(pts, col, 1.5)

func animate_fall_to(new_pos: Vector2, delay: float = 0.0, duration: float = 0.26) -> void:
	if is_rolling or is_cleared:
		return
	_current_target_pos = new_pos
	if _fall_tween and _fall_tween.is_valid():
		_fall_tween.kill()

	_fall_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if delay > 0.0:
		_fall_tween.tween_interval(delay)
	_fall_tween.tween_property(self, "position", new_pos, duration)
	# Gentle squash and stretch on landing
	_fall_tween.tween_property(self, "scale", Vector2(1.05, 0.95), 0.06)
	_fall_tween.tween_property(self, "scale", Vector2.ONE, 0.1)

## Rolls a specific number of cells (1 second per cell).
## Triggers on_cell_rolled callback every 1 second as each cell unravels.
## When all remaining cells are rolled, clears the cloth block.
func roll_cells(cells_to_roll: int, target_global_pos: Vector2, on_cell_rolled: Callable = Callable(), on_complete: Callable = Callable()) -> void:
	if is_rolling or is_cleared:
		return

	is_rolling = true
	rolling_started.emit(self)

	if _fall_tween and _fall_tween.is_valid():
		_fall_tween.kill()
	if _roll_tween and _roll_tween.is_valid():
		_roll_tween.kill()

	var actual_cells := clampi(cells_to_roll, 1, remaining_cells)

	# Calculate pull direction to slightly tilt towards roller
	var my_center := global_position + size * 0.5
	var pull_dir := (target_global_pos - my_center).normalized()
	var target_rot := pull_dir.x * 0.18

	_roll_tween = create_tween()

	# Unroll cell-by-cell (1 second per cell)
	for i in range(actual_cells):
		# 1.0 second per cell rolling interval
		_roll_tween.tween_interval(1.0)
		_roll_tween.tween_callback(func():
			remaining_cells = maxi(0, remaining_cells - 1)
			rolled_cells += 1
			queue_redraw()
			cell_rolled.emit(self, remaining_cells)
			if on_cell_rolled.is_valid():
				on_cell_rolled.call()
		)

	_roll_tween.chain().tween_callback(func():
		is_rolling = false
		if remaining_cells <= 0:
			# Cloth is fully unrolled: play quick unravel exit
			_animate_full_clear(pull_dir, on_complete)
		else:
			# Partially rolled: remains on board with updated cell count
			if on_complete.is_valid():
				on_complete.call()
	)

func _animate_full_clear(pull_dir: Vector2, on_complete: Callable) -> void:
	is_cleared = true
	var exit_tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	exit_tween.tween_property(self, "scale", Vector2(0.1, 0.1), 0.22)
	exit_tween.tween_property(self, "modulate:a", 0.0, 0.22)
	exit_tween.tween_property(self, "position", position + (pull_dir * 35.0), 0.22)

	exit_tween.chain().tween_callback(func():
		rolling_finished.emit(self)
		if on_complete.is_valid():
			on_complete.call()
		queue_free()
	)

## Backwards-compatible rolling helper (rolls all remaining cells).
func animate_roll_out(target_global_pos: Vector2, _duration: float = 0.55, on_complete: Callable = Callable()) -> void:
	roll_cells(remaining_cells, target_global_pos, Callable(), on_complete)

func get_attachment_point() -> Vector2:
	# Bottom center of the cloth block in global coordinates
	return global_position + Vector2(size.x * 0.5, size.y * 0.9)
