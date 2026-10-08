class_name OverworldBoard
extends Node2D

## Manages overworld isometric board gameplay, multi-tile occupancy,
## camera pan/zoom, and Mergest Kingdom / Merge Dragons style merging.

signal building_spawned(building: OverworldBuilding)
signal building_merged(source: OverworldBuilding, target: OverworldBuilding, new_tier: int)
signal building_moved(building: OverworldBuilding, from_cell: Vector2i, to_cell: Vector2i)
signal building_clicked(building: OverworldBuilding)

const OverworldBuildingClass = preload("res://scripts/experimental/overworld_building.gd")
const OverworldBuildingDataClass = preload("res://scripts/experimental/overworld_building_data.gd")
const OverworldGeometryClass = preload("res://scripts/experimental/overworld_geometry.gd")
const FloatingTextScene = preload("res://scenes/floating_text.tscn")
const MergeSparklesScene = preload("res://scenes/fx/merge_sparkles.tscn")

@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var buildings_container: Node2D = $BuildingsContainer
@onready var highlighter: Node2D = $FootprintHighlighter
@onready var camera: Camera2D = $Camera2D

# UI Nodes
@onready var back_button: Button = $UI/TopBar/Margin/HBox/BackBtn
@onready var stats_label: Label = $UI/TopBar/Margin/HBox/VBox/StatsLabel
@onready var spawn_t1_btn: Button = $UI/BottomBar/Margin/VBox/HBox/SpawnT1Btn
@onready var spawn_t2_btn: Button = $UI/BottomBar/Margin/VBox/HBox/SpawnT2Btn
@onready var spawn_t3_btn: Button = $UI/BottomBar/Margin/VBox/HBox/SpawnT3Btn
@onready var reset_btn: Button = $UI/BottomBar/Margin/VBox/HBox/ResetBtn
@onready var center_cam_btn: Button = $UI/BottomBar/Margin/VBox/HBox/CenterCamBtn

# Board state
var _occupancy: Dictionary = {} # Vector2i -> OverworldBuilding
var _buildings: Array[OverworldBuilding] = []

# Drag & Pan state
var _active_building: OverworldBuilding = null
var _is_dragging: bool = false
var _drag_start_screen_pos: Vector2 = Vector2.ZERO
var _drag_offset: Vector2 = Vector2.ZERO

var _is_panning: bool = false
var _pan_start_screen_pos: Vector2 = Vector2.ZERO
var _pan_start_cam_pos: Vector2 = Vector2.ZERO

# Hover highlight state
var _hover_cells: Array[Vector2i] = []
var _hover_mode: int = 0 # 0=None, 1=Valid Empty, 2=Merge Target, 3=Blocked
var _hover_target_building: OverworldBuilding = null
var _hover_poly_center: Vector2 = Vector2.ZERO
var _hover_poly_offsets: Array[Vector2i] = []

# Board center & camera bounds
var board_center: Vector2 = Vector2(256, 1088)

func _ready() -> void:
	if not tile_map_layer:
		tile_map_layer = $TileMapLayer
	
	if buildings_container:
		buildings_container.y_sort_enabled = true

	if highlighter:
		highlighter.draw.connect(_on_highlighter_draw)

	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	if spawn_t1_btn:
		spawn_t1_btn.pressed.connect(func(): spawn_building_at_free_spot(1))
	if spawn_t2_btn:
		spawn_t2_btn.pressed.connect(func(): spawn_building_at_free_spot(2))
	if spawn_t3_btn:
		spawn_t3_btn.pressed.connect(func(): spawn_building_at_free_spot(3))
	if reset_btn:
		reset_btn.pressed.connect(reset_board_to_default)
	if center_cam_btn:
		center_cam_btn.pressed.connect(recenter_camera)

	reset_board_to_default()
	recenter_camera()

func recenter_camera() -> void:
	if camera:
		var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(camera, "position", board_center, 0.25)
		tw.parallel().tween_property(camera, "zoom", Vector2(0.75, 0.75), 0.25)

func _play_sound(sound_name: String) -> void:
	var sm = get_tree().root.get_node_or_null("SoundManager") if get_tree() and get_tree().root else null
	if sm:
		match sound_name:
			"pickup": sm.play_pickup()
			"drop": sm.play_drop()
			"merge": sm.play_merge()
			"click": sm.play_click()
			"spawn": sm.play_spawn()
			"error": sm.play_error()

func _on_back_pressed() -> void:
	_play_sound("click")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

# =========================================================================
# BOARD & OCCUPANCY MANAGEMENT
# =========================================================================

func reset_board_to_default() -> void:
	for b in _buildings:
		if is_instance_valid(b):
			b.queue_free()
	_buildings.clear()
	_occupancy.clear()
	_clear_hover_feedback()

	# Initial board layout: multiple 1x1 tier 1 bakery buildings around center
	var initial_t1_coords: Array[Vector2i] = [
		Vector2i(-9, 7), Vector2i(-8, 7), Vector2i(-7, 7),
		Vector2i(-9, 8), Vector2i(-8, 8), Vector2i(-7, 8),
		Vector2i(-9, 9), Vector2i(-8, 9), Vector2i(-7, 9),
		Vector2i(-8, 6)
	]

	for c in initial_t1_coords:
		if is_valid_ground_cell(c):
			spawn_building(1, c)

	_update_hud_stats()
	show_floating_text("Overworld Ready! Merge 1x1 into 1x2 and 2x2!", board_center + Vector2(0, -100), Color(1.0, 0.95, 0.4))

func is_valid_ground_cell(cell: Vector2i) -> bool:
	if not tile_map_layer:
		return false
	return tile_map_layer.get_cell_source_id(cell) >= 0

func get_building_at_cell(cell: Vector2i) -> OverworldBuilding:
	if not _occupancy.has(cell):
		return null
	var b = _occupancy[cell]
	if not is_instance_valid(b):
		_occupancy.erase(cell)
		return null
	return b

func get_building_under_cursor(world_pos: Vector2, ignore_b: OverworldBuilding = null) -> OverworldBuilding:
	# 1. Check if the cell directly under the cursor belongs to a building
	var map_c := tile_map_layer.local_to_map(tile_map_layer.to_local(world_pos))
	var direct_b := get_building_at_cell(map_c)
	if direct_b and direct_b != ignore_b and is_instance_valid(direct_b):
		return direct_b

	# 2. Check buildings whose visual sprites (which extend upward) contain this point
	# Pick the front-most building (highest global_position.y) without full array sorting
	var best_building: OverworldBuilding = null
	var best_y: float = -INF
	for b in _buildings:
		if b == ignore_b or not is_instance_valid(b):
			continue
		if b.is_point_inside(world_pos):
			if b.global_position.y > best_y:
				best_y = b.global_position.y
				best_building = b

	return best_building

func get_footprint_cells(root_c: Vector2i, p_tier: int, chain_id: String = "bakery") -> Array[Vector2i]:
	var data := OverworldBuildingDataClass.get_data(p_tier, chain_id)
	var res: Array[Vector2i] = []
	for off in data.get_footprint():
		res.append(root_c + off)
	return res

func get_footprint_world_center(root_c: Vector2i, p_tier: int, chain_id: String = "bakery") -> Vector2:
	var cells := get_footprint_cells(root_c, p_tier, chain_id)
	if cells.is_empty():
		return tile_map_layer.map_to_local(root_c)
	var sum := Vector2.ZERO
	for c in cells:
		sum += tile_map_layer.map_to_local(c)
	return sum / float(cells.size())

func can_place_at(root_c: Vector2i, p_tier: int, ignore_b: OverworldBuilding = null, chain_id: String = "bakery") -> bool:
	var cells := get_footprint_cells(root_c, p_tier, chain_id)
	for c in cells:
		if not is_valid_ground_cell(c):
			return false
		if _occupancy.has(c):
			var occ = _occupancy[c]
			if not is_instance_valid(occ):
				_occupancy.erase(c)
			elif occ != ignore_b:
				return false
	return true

func register_building(building: OverworldBuilding) -> void:
	if not is_instance_valid(building):
		return
	for c in building.get_occupied_cells():
		_occupancy[c] = building

func unregister_building(building: OverworldBuilding) -> void:
	if not is_instance_valid(building):
		# Clean any stray invalid objects in _occupancy
		var to_erase: Array[Vector2i] = []
		for c in _occupancy:
			if not is_instance_valid(_occupancy[c]):
				to_erase.append(c)
		for c in to_erase:
			_occupancy.erase(c)
		return

	for c in building.get_occupied_cells():
		if _occupancy.get(c) == building:
			_occupancy.erase(c)
	
	# Extra safeguard: ensure this building isn't registered at any lingering cell
	for c in _occupancy.keys():
		if _occupancy[c] == building:
			_occupancy.erase(c)

func spawn_building(p_tier: int, root_c: Vector2i, chain_id: String = "bakery") -> OverworldBuilding:
	var b := OverworldBuildingClass.new()
	buildings_container.add_child(b)
	b.setup(p_tier, root_c, self, chain_id)
	b.global_position = get_footprint_world_center(root_c, p_tier, chain_id)
	_buildings.append(b)
	register_building(b)
	building_spawned.emit(b)
	return b

func spawn_building_at_free_spot(p_tier: int, chain_id: String = "bakery") -> OverworldBuilding:
	var root_c := find_free_spot(p_tier, Vector2i(-8, 8), chain_id)
	if root_c == Vector2i(999, 999):
		_play_sound("error")
		show_floating_text("No room for this building!", board_center, Color(1.0, 0.4, 0.4))
		return null
	var b := spawn_building(p_tier, root_c, chain_id)
	b.animate_merge_pop()
	_play_sound("spawn")
	show_floating_text("+ %s (%s)!" % [b.get_building_name(), b.get_footprint_desc()], b.global_position + Vector2(0, -60), Color(0.4, 1.0, 0.5))
	_update_hud_stats()
	return b

func find_free_spot(p_tier: int, near_coord: Vector2i, chain_id: String = "bakery") -> Vector2i:
	for radius in range(0, 16):
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				if maxi(absi(dx), absi(dy)) != radius:
					continue
				var cand := near_coord + Vector2i(dx, dy)
				if can_place_at(cand, p_tier, null, chain_id):
					return cand
	return Vector2i(999, 999)

func find_best_upgrade_root(target_cell: Vector2i, new_tier: int, chain_id: String = "bakery") -> Vector2i:
	var cands: Array[Vector2i] = []
	if new_tier == 2:
		# 1x2 footprint covers [(0,0), (1,0)]
		cands = [
			target_cell,
			target_cell - Vector2i(1, 0),
			target_cell + Vector2i(0, 1),
			target_cell - Vector2i(0, 1)
		]
	elif new_tier == 3:
		# 2x2 footprint covers [(0,0), (1,0), (0,1), (1,1)]
		cands = [
			target_cell,
			target_cell - Vector2i(1, 0),
			target_cell - Vector2i(0, 1),
			target_cell - Vector2i(1, 1),
			target_cell + Vector2i(1, 0),
			target_cell + Vector2i(0, 1)
		]
	
	for cand in cands:
		if can_place_at(cand, new_tier, null, chain_id):
			return cand
	
	# Spiral search nearby if tight
	for radius in range(1, 6):
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				var cand := target_cell + Vector2i(dx, dy)
				if can_place_at(cand, new_tier, null, chain_id):
					return cand
	return target_cell

# =========================================================================
# INPUT & INTERACTION HANDLING
# =========================================================================

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		var world_pos := get_global_mouse_position()
		
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_handle_press(mb.position, world_pos)
			else:
				_handle_release(world_pos)
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				_is_panning = true
				_pan_start_screen_pos = mb.position
				_pan_start_cam_pos = camera.position
			else:
				_is_panning = false
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_zoom_camera(1.1, world_pos)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_zoom_camera(0.9, world_pos)

	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		var world_pos := get_global_mouse_position()
		_handle_motion(mm.position, world_pos)

func _handle_press(screen_pos: Vector2, world_pos: Vector2) -> void:
	var clicked_b := get_building_under_cursor(world_pos)
	if clicked_b:
		if clicked_b.is_under_construction:
			clicked_b.animate_wobble()
			_play_sound("error")
			show_floating_text("Under construction! (%ds)" % int(ceilf(clicked_b.construction_timer)), clicked_b.global_position + Vector2(0, -60), Color(1.0, 0.8, 0.3))
			return
		_active_building = clicked_b
		_drag_start_screen_pos = screen_pos
		_drag_offset = clicked_b.global_position - world_pos
		_is_dragging = false
	else:
		_is_panning = true
		_pan_start_screen_pos = screen_pos
		_pan_start_cam_pos = camera.position

func _handle_motion(screen_pos: Vector2, world_pos: Vector2) -> void:
	if _active_building:
		if not _is_dragging:
			if screen_pos.distance_to(_drag_start_screen_pos) > 6.0:
				_is_dragging = true
				_active_building.animate_pickup()
				_play_sound("pickup")
		
		if _is_dragging:
			_active_building.global_position = world_pos + _drag_offset
			_update_hover_feedback(world_pos)

	elif _is_panning and camera:
		var delta_screen := screen_pos - _pan_start_screen_pos
		camera.position = _pan_start_cam_pos - (delta_screen / camera.zoom.x)
		_clamp_camera()

func _handle_release(world_pos: Vector2) -> void:
	if _active_building:
		var b := _active_building
		_active_building = null
		_clear_hover_feedback()

		if _is_dragging:
			_is_dragging = false
			_handle_building_drop(b, world_pos)
		else:
			b.animate_tap()
			_play_sound("click")
			_show_building_info(b)
			building_clicked.emit(b)

	if _is_panning:
		_is_panning = false

func _handle_building_drop(dragged_b: OverworldBuilding, world_pos: Vector2) -> void:
	var map_coord := tile_map_layer.local_to_map(tile_map_layer.to_local(world_pos))
	var target_b := get_building_under_cursor(world_pos, dragged_b)
	if not target_b:
		target_b = get_building_at_cell(map_coord)
		if target_b == dragged_b:
			target_b = null

	# --- 1. MERGE DROP CHECK ---
	if target_b and is_instance_valid(target_b) and target_b != dragged_b:
		if target_b.is_under_construction:
			dragged_b.animate_wobble()
			_play_sound("error")
			show_floating_text("Building is under construction!", target_b.global_position + Vector2(0, -60), Color(1.0, 0.8, 0.3))
			_return_building_to_origin(dragged_b)
			return
		if target_b.tier == dragged_b.tier and target_b.chain_id == dragged_b.chain_id:
			if target_b.tier < 3:
				_execute_merge(dragged_b, target_b)
				return
			else:
				dragged_b.animate_wobble()
				target_b.animate_wobble()
				_play_sound("error")
				show_floating_text("Max Tier! (Grand Bakery 2x2)", target_b.global_position + Vector2(0, -60), Color(1.0, 0.7, 0.3))
				_return_building_to_origin(dragged_b)
				return
		else:
			dragged_b.animate_wobble()
			_play_sound("error")
			show_floating_text("Only matching items can merge!", world_pos + Vector2(0, -50), Color(1.0, 0.5, 0.5))
			_return_building_to_origin(dragged_b)
			return

	# --- 2. MOVE TO EMPTY VALID SPOT ---
	if can_place_at(map_coord, dragged_b.tier, dragged_b, dragged_b.chain_id):
		var prev_cell := dragged_b.root_coord
		unregister_building(dragged_b)
		dragged_b.root_coord = map_coord
		register_building(dragged_b)
		var new_center := get_footprint_world_center(map_coord, dragged_b.tier, dragged_b.chain_id)
		dragged_b.animate_snap_to(new_center)
		dragged_b.animate_drop()
		_play_sound("drop")
		building_moved.emit(dragged_b, prev_cell, map_coord)
		_update_hud_stats()
		return

	# --- 3. INVALID / BLOCKED PLACEMENT -> RETURN ---
	dragged_b.animate_wobble()
	_play_sound("error")
	show_floating_text("Can't place here!", world_pos + Vector2(0, -50), Color(1.0, 0.4, 0.4))
	_return_building_to_origin(dragged_b)

func _execute_merge(source_b: OverworldBuilding, target_b: OverworldBuilding) -> void:
	var next_tier: int = target_b.tier + 1
	var target_root: Vector2i = target_b.root_coord
	var chain: String = target_b.chain_id

	unregister_building(source_b)
	unregister_building(target_b)

	var best_root := find_best_upgrade_root(target_root, next_tier, chain)

	building_merged.emit(source_b, target_b, next_tier)

	_buildings.erase(source_b)
	source_b.queue_free()

	target_b.setup(next_tier, best_root, self, chain)
	register_building(target_b)
	target_b.global_position = get_footprint_world_center(best_root, next_tier, chain)
	target_b.start_construction(10.0)

	spawn_sparkles(target_b.global_position)
	_play_sound("merge")

	var new_name: String = target_b.get_building_name()
	var new_desc: String = target_b.get_footprint_desc()
	show_floating_text("+ %s (%s)!" % [new_name, new_desc], target_b.global_position + Vector2(0, -70), Color(1.0, 0.9, 0.3))
	_update_hud_stats()

func _return_building_to_origin(b: OverworldBuilding) -> void:
	var origin_center := get_footprint_world_center(b.root_coord, b.tier, b.chain_id)
	b.animate_snap_to(origin_center)
	b.animate_drop()

func _show_building_info(b: OverworldBuilding) -> void:
	var msg: String = "%s (%s)" % [b.get_building_name(), b.get_footprint_desc()]
	if b.is_under_construction:
		msg += " · Under construction (%ds remaining)" % int(ceilf(b.construction_timer))
	elif b.tier < 3:
		msg += " · Drag onto matching to merge!"
	else:
		msg += " · Max Tier Masterpiece!"
	show_floating_text(msg, b.global_position + Vector2(0, -60), Color(1.0, 0.95, 0.7))

# =========================================================================
# HOVER FEEDBACK & HIGHLIGHTING
# =========================================================================

func _update_hover_feedback(world_pos: Vector2) -> void:
	if not _active_building:
		_clear_hover_feedback()
		return

	var map_coord := tile_map_layer.local_to_map(tile_map_layer.to_local(world_pos))
	var target_b := get_building_under_cursor(world_pos, _active_building)
	if not target_b:
		target_b = get_building_at_cell(map_coord)
		if target_b == _active_building:
			target_b = null

	# Check merge candidate
	if target_b and is_instance_valid(target_b) and target_b.tier == _active_building.tier and target_b.tier < 3 and target_b.chain_id == _active_building.chain_id:
		if _hover_target_building != target_b:
			if _hover_target_building:
				_hover_target_building.set_merge_highlight(false)
			_hover_target_building = target_b
			_hover_target_building.set_merge_highlight(true)
		
		_hover_cells = target_b.get_occupied_cells()
		_hover_poly_center = target_b.global_position
		_hover_poly_offsets = target_b.get_footprint_offsets().duplicate()
		_hover_mode = 2 # Merge Gold
		_queue_highlighter_redraw()
		return

	if _hover_target_building:
		_hover_target_building.set_merge_highlight(false)
		_hover_target_building = null

	# Normal footprint placement check
	_hover_cells = get_footprint_cells(map_coord, _active_building.tier, _active_building.chain_id)
	_hover_poly_center = get_footprint_world_center(map_coord, _active_building.tier, _active_building.chain_id)
	_hover_poly_offsets = _active_building.get_footprint_offsets().duplicate()

	if can_place_at(map_coord, _active_building.tier, _active_building, _active_building.chain_id):
		_hover_mode = 1 # Valid Green
	else:
		_hover_mode = 3 # Blocked Red
	_queue_highlighter_redraw()

func _clear_hover_feedback() -> void:
	if _hover_target_building:
		_hover_target_building.set_merge_highlight(false)
		_hover_target_building = null
	_hover_cells.clear()
	_hover_poly_offsets.clear()
	_hover_mode = 0
	_queue_highlighter_redraw()

func _queue_highlighter_redraw() -> void:
	if highlighter:
		highlighter.queue_redraw()

func _on_highlighter_draw() -> void:
	if _hover_cells.is_empty() or _hover_mode == 0:
		return

	var fill_col: Color
	var border_col: Color
	match _hover_mode:
		1: # Valid Green
			fill_col = Color(0.2, 0.88, 0.45, 0.42)
			border_col = Color(0.5, 1.0, 0.65, 0.9)
		2: # Merge Gold
			fill_col = Color(1.0, 0.86, 0.22, 0.55)
			border_col = Color(1.0, 0.98, 0.55, 0.95)
		3: # Blocked Red
			fill_col = Color(0.92, 0.25, 0.25, 0.42)
			border_col = Color(1.0, 0.45, 0.45, 0.9)

	# Draw unified merged footprint polygon
	var poly := OverworldGeometryClass.get_footprint_polygon(_hover_poly_offsets, OverworldGeometryClass.DEFAULT_TILE_SIZE)
	if poly.size() >= 3:
		var world_pts := PackedVector2Array()
		for pt in poly:
			world_pts.append(_hover_poly_center + pt)
		highlighter.draw_colored_polygon(world_pts, fill_col)
		var outline := PackedVector2Array()
		for pt in world_pts:
			outline.append(pt)
		outline.append(world_pts[0])
		highlighter.draw_polyline(outline, border_col, 3.5, true)
	else:
		# Fallback: draw individual diamonds
		for c in _hover_cells:
			var center: Vector2 = tile_map_layer.map_to_local(c)
			var pts := OverworldGeometryClass.get_tile_diamond(center)
			highlighter.draw_colored_polygon(pts, fill_col)
			var outline := PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]])
			highlighter.draw_polyline(outline, border_col, 3.0, true)

# =========================================================================
# CAMERA ZOOM & CLAMP
# =========================================================================

func _zoom_camera(factor: float, _mouse_world: Vector2) -> void:
	if not camera:
		return
	var new_zoom: float = clampf(camera.zoom.x * factor, 0.45, 1.8)
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(camera, "zoom", Vector2(new_zoom, new_zoom), 0.12)

func _clamp_camera() -> void:
	if not camera:
		return
	camera.position.x = clampf(camera.position.x, -1600.0, 2200.0)
	camera.position.y = clampf(camera.position.y, 200.0, 2100.0)

# =========================================================================
# JUICE: PARTICLES, TEXT & STATS
# =========================================================================

func spawn_sparkles(world_pos: Vector2) -> void:
	if MergeSparklesScene:
		var fx: Node2D = MergeSparklesScene.instantiate()
		fx.global_position = world_pos
		add_child(fx)

func show_floating_text(text: String, world_pos: Vector2, color: Color = Color.WHITE) -> void:
	if FloatingTextScene:
		var ft = FloatingTextScene.instantiate()
		ft.global_position = world_pos
		add_child(ft)
		ft.setup(text, color)

func _update_hud_stats() -> void:
	if not stats_label:
		return
	var count_t1 := 0
	var count_t2 := 0
	var count_t3 := 0
	for b in _buildings:
		if is_instance_valid(b):
			match b.tier:
				1: count_t1 += 1
				2: count_t2 += 1
				3: count_t3 += 1
	stats_label.text = "Buildings: %d   (Tier 1 1x1: %d  |  Tier 2 1x2: %d  |  Tier 3 2x2: %d)" % [
		_buildings.size(), count_t1, count_t2, count_t3
	]
