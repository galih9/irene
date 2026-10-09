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
@onready var tile_cursor: Node2D = get_node_or_null("TileCursor")
@onready var camera: Camera2D = $Camera2D

# UI Nodes
@onready var back_button: Button = get_node_or_null("UI/TopBar/Margin/HBox/BackBtn")
@onready var stats_label: Label = get_node_or_null("UI/TopBar/Margin/HBox/VBox/StatsLabel")

# Information Bar UI Nodes
@onready var info_bar: PanelContainer = get_node_or_null("UI/InfoBar")
@onready var info_icon: TextureRect = get_node_or_null("UI/InfoBar/Margin/HBox/IconRect")
@onready var info_title_label: Label = get_node_or_null("UI/InfoBar/Margin/HBox/VBox/InfoTitle")
@onready var info_desc_label: Label = get_node_or_null("UI/InfoBar/Margin/HBox/VBox/InfoDesc")
@onready var info_status_label: Label = get_node_or_null("UI/InfoBar/Margin/HBox/VBox/InfoStatus")
@onready var info_deselect_btn: Button = get_node_or_null("UI/InfoBar/Margin/HBox/DeselectBtn")

# New Option & Spawn controls
@onready var item_option_btn: OptionButton = get_node_or_null("UI/BottomBar/Margin/VBox/ControlsHBox/ItemOptionBtn")
@onready var spawn_selected_btn: Button = get_node_or_null("UI/BottomBar/Margin/VBox/ControlsHBox/SpawnSelectedBtn")
@onready var reset_btn: Button = get_node_or_null("UI/BottomBar/Margin/VBox/ControlsHBox/ResetBtn")
@onready var center_cam_btn: Button = get_node_or_null("UI/BottomBar/Margin/VBox/ControlsHBox/CenterCamBtn")

# Quick buttons
@onready var spawn_tree_t1_btn: Button = get_node_or_null("UI/BottomBar/Margin/VBox/QuickHBox/SpawnTreeT1Btn")
@onready var spawn_library_t1_btn: Button = get_node_or_null("UI/BottomBar/Margin/VBox/QuickHBox/SpawnLibraryT1Btn")
@onready var spawn_kitchen_t1_btn: Button = get_node_or_null("UI/BottomBar/Margin/VBox/QuickHBox/SpawnKitchenT1Btn")
@onready var spawn_kitchen_t4_btn: Button = get_node_or_null("UI/BottomBar/Margin/VBox/QuickHBox/SpawnKitchenT4Btn")
@onready var spawn_kitchen_t8_btn: Button = get_node_or_null("UI/BottomBar/Margin/VBox/QuickHBox/SpawnKitchenT8Btn")
@onready var spawn_t1_btn: Button = get_node_or_null("UI/BottomBar/Margin/VBox/QuickHBox/SpawnT1Btn")
@onready var spawn_t2_btn: Button = get_node_or_null("UI/BottomBar/Margin/VBox/QuickHBox/SpawnT2Btn")
@onready var spawn_t3_btn: Button = get_node_or_null("UI/BottomBar/Margin/VBox/QuickHBox/SpawnT3Btn")

# Board state
var _occupancy: Dictionary = {} # Vector2i -> OverworldBuilding
var _buildings: Array[OverworldBuilding] = []

# Selected item state
var selected_building: OverworldBuilding = null
var _cursor_tween: Tween = null
var _cursor_poly: PackedVector2Array = []

# Selected item state for spawning
var _selected_chain: String = "kitchen"
var _selected_tier: int = 1

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

	_setup_tile_cursor()
	_setup_item_options()

	if info_deselect_btn:
		info_deselect_btn.pressed.connect(clear_selection)
	_update_information_bar(null)

	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	if spawn_selected_btn:
		spawn_selected_btn.pressed.connect(_on_spawn_selected_pressed)
	if spawn_tree_t1_btn:
		spawn_tree_t1_btn.pressed.connect(func(): spawn_building_at_free_spot(1, "tree"))
	if spawn_library_t1_btn:
		spawn_library_t1_btn.pressed.connect(func(): spawn_building_at_free_spot(1, "library"))
	if spawn_kitchen_t1_btn:
		spawn_kitchen_t1_btn.pressed.connect(func(): spawn_building_at_free_spot(1, "kitchen"))
	if spawn_kitchen_t4_btn:
		spawn_kitchen_t4_btn.pressed.connect(func(): spawn_building_at_free_spot(4, "kitchen"))
	if spawn_kitchen_t8_btn:
		spawn_kitchen_t8_btn.pressed.connect(func(): spawn_building_at_free_spot(8, "kitchen"))
	if spawn_t1_btn:
		spawn_t1_btn.pressed.connect(func(): spawn_building_at_free_spot(1, "bakery"))
	if spawn_t2_btn:
		spawn_t2_btn.pressed.connect(func(): spawn_building_at_free_spot(2, "bakery"))
	if spawn_t3_btn:
		spawn_t3_btn.pressed.connect(func(): spawn_building_at_free_spot(3, "bakery"))
	if reset_btn:
		reset_btn.pressed.connect(reset_board_to_default)
	if center_cam_btn:
		center_cam_btn.pressed.connect(recenter_camera)

	reset_board_to_default()
	recenter_camera()

func _setup_item_options() -> void:
	if not item_option_btn:
		return
	item_option_btn.clear()
	var all_items := OverworldBuildingDataClass.get_all_items()
	for i in range(all_items.size()):
		var data = all_items[i]
		var label := "[%s] T%d (%s) - %s" % [
			data.chain_id.capitalize(),
			data.tier,
			data.footprint_desc,
			data.name
		]
		var thumb: Texture2D = null
		if ResourceLoader.exists(data.texture_path):
			var full_tex: Texture2D = load(data.texture_path)
			thumb = _create_thumbnail(full_tex, Vector2i(32, 32))
		if thumb:
			item_option_btn.add_icon_item(thumb, label, i)
		else:
			item_option_btn.add_item(label, i)
		item_option_btn.set_item_metadata(i, {
			"chain": data.chain_id,
			"tier": data.tier
		})

	if not item_option_btn.item_selected.is_connected(_on_item_option_selected):
		item_option_btn.item_selected.connect(_on_item_option_selected)

	# Default selection to Kitchen T1 if available
	for idx in range(item_option_btn.item_count):
		var meta = item_option_btn.get_item_metadata(idx)
		if meta and meta.get("chain") == "kitchen" and meta.get("tier") == 1:
			item_option_btn.select(idx)
			_on_item_option_selected(idx)
			break

func _create_thumbnail(tex: Texture2D, target_size: Vector2i = Vector2i(32, 32)) -> Texture2D:
	if not tex:
		return null
	var img: Image = null
	if tex is AtlasTexture:
		var atlas_tex := tex as AtlasTexture
		if atlas_tex.atlas:
			var atlas_img := atlas_tex.atlas.get_image()
			if atlas_img:
				var reg := atlas_tex.region
				if reg.size.x > 0 and reg.size.y > 0:
					img = atlas_img.get_region(Rect2i(int(reg.position.x), int(reg.position.y), int(reg.size.x), int(reg.size.y)))
	if not img:
		img = tex.get_image()
	if not img:
		return tex
	var copy: Image = img.duplicate()
	copy.resize(target_size.x, target_size.y, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(copy)

func _on_item_option_selected(idx: int) -> void:
	if not item_option_btn:
		return
	var meta = item_option_btn.get_item_metadata(idx)
	if meta:
		_selected_chain = meta.get("chain", "kitchen")
		_selected_tier = meta.get("tier", 1)

func _on_spawn_selected_pressed() -> void:
	spawn_building_at_free_spot(_selected_tier, _selected_chain)

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
	clear_selection()

	# Initial bakery layout: 1x1 tier 1 bakery buildings around center
	var initial_bakery_coords: Array[Vector2i] = [
		Vector2i(-9, 7), Vector2i(-8, 7), Vector2i(-7, 7),
		Vector2i(-9, 8), Vector2i(-8, 8), Vector2i(-7, 8)
	]
	for c in initial_bakery_coords:
		if is_valid_ground_cell(c):
			spawn_building(1, c, "bakery")

	# Initial kitchen layout: 1x1 tier 1 kitchen buildings to play with immediately!
	var initial_kitchen_coords: Array[Vector2i] = [
		Vector2i(-9, 10), Vector2i(-8, 10), Vector2i(-7, 10),
		Vector2i(-9, 11), Vector2i(-8, 11)
	]
	for c in initial_kitchen_coords:
		if is_valid_ground_cell(c):
			spawn_building(1, c, "kitchen")

	# Initial tree layout: 1x1 tier 1 tree items ready to merge immediately
	var initial_tree_coords: Array[Vector2i] = [
		Vector2i(-5, 7), Vector2i(-4, 7), Vector2i(-3, 7),
		Vector2i(-5, 8), Vector2i(-4, 8)
	]
	for c in initial_tree_coords:
		if is_valid_ground_cell(c) and not _occupancy.has(c):
			spawn_building(1, c, "tree")

	# Initial library layout: 2x2 tier 1 library items ready to merge
	var initial_library_coords: Array[Vector2i] = [
		Vector2i(-5, 10), Vector2i(-3, 10)
	]
	for c in initial_library_coords:
		if can_place_at(c, 1, null, "library"):
			spawn_building(1, c, "library")

	_update_hud_stats()
	show_floating_text("Overworld Ready! Select item & Spawn to test!", board_center + Vector2(0, -100), Color(1.0, 0.95, 0.4))

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
	for radius in range(0, 24):
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				if maxi(absi(dx), absi(dy)) != radius:
					continue
				var cand := near_coord + Vector2i(dx, dy)
				if can_place_at(cand, p_tier, null, chain_id):
					return cand
	return Vector2i(999, 999)

func find_best_upgrade_root(target_cell: Vector2i, new_tier: int, chain_id: String = "bakery") -> Vector2i:
	var data = OverworldBuildingDataClass.get_data(new_tier, chain_id)
	var offsets: Array[Vector2i] = []
	if data and data.has_method("get_footprint"):
		offsets = data.get_footprint()
	elif data and "footprint" in data:
		for v in data.footprint:
			offsets.append(v)
	else:
		offsets = [Vector2i(0, 0)]
	
	# Priority 1: Candidate roots that keep target_cell within the upgraded building's footprint
	var cands: Array[Vector2i] = []
	cands.append(target_cell)
	for off in offsets:
		var cand: Vector2i = target_cell - off
		if not cands.has(cand):
			cands.append(cand)
	
	for cand in cands:
		if can_place_at(cand, new_tier, null, chain_id):
			return cand
	
	# Priority 2: Nearby spiral search if surrounding area is congested
	for radius in range(1, 10):
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				if maxi(absi(dx), absi(dy)) != radius:
					continue
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
			select_building(clicked_b)
			return
		_active_building = clicked_b
		_drag_start_screen_pos = screen_pos
		_drag_offset = clicked_b.global_position - world_pos
		_is_dragging = false
	else:
		clear_selection()
		_is_panning = true
		_pan_start_screen_pos = screen_pos
		_pan_start_cam_pos = camera.position

func _handle_motion(screen_pos: Vector2, world_pos: Vector2) -> void:
	if _active_building:
		if not _is_dragging:
			if screen_pos.distance_to(_drag_start_screen_pos) > 6.0:
				_is_dragging = true
				if tile_cursor:
					tile_cursor.visible = false
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
			select_building(b)

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
			select_building(dragged_b)
			return
		if target_b.tier == dragged_b.tier and target_b.chain_id == dragged_b.chain_id:
			var max_t := OverworldBuildingDataClass.get_max_tier(target_b.chain_id)
			if target_b.tier < max_t:
				_execute_merge(dragged_b, target_b)
				return
			else:
				dragged_b.animate_wobble()
				target_b.animate_wobble()
				_play_sound("error")
				show_floating_text("Max Tier! (%s)" % target_b.get_building_name(), target_b.global_position + Vector2(0, -60), Color(1.0, 0.7, 0.3))
				_return_building_to_origin(dragged_b)
				select_building(dragged_b)
				return
		else:
			dragged_b.animate_wobble()
			_play_sound("error")
			show_floating_text("Only matching items can merge!", world_pos + Vector2(0, -50), Color(1.0, 0.5, 0.5))
			_return_building_to_origin(dragged_b)
			select_building(dragged_b)
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
		select_building(dragged_b)
		return

	# --- 3. INVALID / BLOCKED PLACEMENT -> RETURN ---
	dragged_b.animate_wobble()
	_play_sound("error")
	show_floating_text("Can't place here!", world_pos + Vector2(0, -50), Color(1.0, 0.4, 0.4))
	_return_building_to_origin(dragged_b)
	select_building(dragged_b)

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

	var is_instant_upgrade: bool = false
	if chain == "tree":
		is_instant_upgrade = true
	elif target_b.building_data:
		if "requires_construction" in target_b.building_data and not target_b.building_data.requires_construction:
			is_instant_upgrade = true
		elif "construction_time" in target_b.building_data and target_b.building_data.construction_time <= 0.0:
			is_instant_upgrade = true

	if is_instant_upgrade:
		# Tree item does not need construction time, instantly upgraded to the next tier after merge
		target_b.is_under_construction = false
		target_b.animate_merge_pop()
	else:
		var duration: float = 10.0
		if target_b.building_data and "construction_time" in target_b.building_data and target_b.building_data.construction_time > 0.0:
			duration = target_b.building_data.construction_time
		target_b.start_construction(duration)

	spawn_sparkles(target_b.global_position)
	_play_sound("merge")

	var new_name: String = target_b.get_building_name()
	var new_desc: String = target_b.get_footprint_desc()
	show_floating_text("+ %s (%s)!" % [new_name, new_desc], target_b.global_position + Vector2(0, -70), Color(1.0, 0.9, 0.3))
	_update_hud_stats()
	select_building(target_b)

func _return_building_to_origin(b: OverworldBuilding) -> void:
	var origin_center := get_footprint_world_center(b.root_coord, b.tier, b.chain_id)
	b.animate_snap_to(origin_center)
	b.animate_drop()

# =========================================================================
# TILE CURSOR & INFORMATION BAR
# =========================================================================

func _setup_tile_cursor() -> void:
	if not tile_cursor:
		tile_cursor = Node2D.new()
		tile_cursor.name = "TileCursor"
		tile_cursor.z_index = 10
		add_child(tile_cursor)
	if not tile_cursor.draw.is_connected(_on_tile_cursor_draw):
		tile_cursor.draw.connect(_on_tile_cursor_draw)
	tile_cursor.visible = false

func _on_tile_cursor_draw() -> void:
	if not selected_building or not is_instance_valid(selected_building) or _cursor_poly.is_empty():
		return
	
	# Gentle translucent footprint fill
	var fill_color := Color(0.2, 0.72, 1.0, 0.22)
	tile_cursor.draw_colored_polygon(_cursor_poly, fill_color)

	# Selection boundary polyline
	var outline := PackedVector2Array(_cursor_poly)
	outline.append(_cursor_poly[0])
	var border_color := Color(0.35, 0.9, 1.0, 0.95)
	tile_cursor.draw_polyline(outline, border_color, 3.5, true)

	# Isometric corner markers / accent dots
	for pt in _cursor_poly:
		tile_cursor.draw_circle(pt, 4.0, Color(1.0, 0.92, 0.45, 0.95))
		tile_cursor.draw_circle(pt, 2.0, Color.WHITE)

func select_building(b: OverworldBuilding) -> void:
	if b == null or not is_instance_valid(b):
		clear_selection()
		return

	selected_building = b
	_cursor_poly = OverworldGeometryClass.get_footprint_polygon(b.get_footprint_offsets(), OverworldGeometryClass.DEFAULT_TILE_SIZE)
	var center := get_footprint_world_center(b.root_coord, b.tier, b.chain_id)
	
	if not tile_cursor:
		_setup_tile_cursor()
		
	tile_cursor.position = center
	tile_cursor.visible = not _is_dragging
	tile_cursor.queue_redraw()
	_start_cursor_bounce()
	_update_information_bar(b)
	building_clicked.emit(b)

func clear_selection() -> void:
	selected_building = null
	_cursor_poly.clear()
	if tile_cursor:
		tile_cursor.visible = false
		tile_cursor.queue_redraw()
	if _cursor_tween and _cursor_tween.is_valid():
		_cursor_tween.kill()
	_update_information_bar(null)

func _start_cursor_bounce() -> void:
	if _cursor_tween and _cursor_tween.is_valid():
		_cursor_tween.kill()
	if not tile_cursor:
		return
	tile_cursor.scale = Vector2(0.96, 0.96)
	_cursor_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_cursor_tween.tween_property(tile_cursor, "scale", Vector2(1.04, 1.04), 0.55)
	_cursor_tween.tween_property(tile_cursor, "scale", Vector2(0.96, 0.96), 0.55)

func _show_building_info(b: OverworldBuilding) -> void:
	select_building(b)

func _update_information_bar(b: OverworldBuilding) -> void:
	if not info_title_label:
		return
	if b == null or not is_instance_valid(b):
		info_title_label.text = "Select a Building"
		if info_desc_label:
			info_desc_label.text = "Tap any building to view info. Drag matching buildings together to merge."
		if info_status_label:
			info_status_label.visible = false
		if info_icon:
			info_icon.texture = null
			info_icon.visible = false
		if info_deselect_btn:
			info_deselect_btn.visible = false
		return

	if info_deselect_btn:
		info_deselect_btn.visible = true

	var b_name := b.get_building_name()
	var f_desc := b.get_footprint_desc()
	var cell_count := b.get_occupied_cells().size()
	info_title_label.text = "%s (Tier %d)" % [b_name, b.tier]

	if info_desc_label:
		info_desc_label.text = "Footprint: %s (%d %s) · %s Chain" % [
			f_desc,
			cell_count,
			"cell" if cell_count == 1 else "cells",
			b.chain_id.capitalize()
		]

	var max_t := OverworldBuildingDataClass.get_max_tier(b.chain_id)
	if info_status_label:
		info_status_label.visible = true
		if b.is_under_construction:
			info_status_label.text = "🔨 Under construction (%ds remaining)" % int(ceilf(b.construction_timer))
			info_status_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.3))
		elif b.tier < max_t:
			info_status_label.text = "✨ Ready to merge: Drag onto matching Tier %d to upgrade!" % b.tier
			info_status_label.add_theme_color_override("font_color", Color(0.4, 0.92, 0.55))
		else:
			info_status_label.text = "👑 Max Tier Masterpiece!"
			info_status_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))

	if info_icon:
		if b.building_data and ResourceLoader.exists(b.building_data.texture_path):
			info_icon.texture = load(b.building_data.texture_path)
			info_icon.visible = true
		else:
			info_icon.texture = null
			info_icon.visible = false

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
	var max_t := OverworldBuildingDataClass.get_max_tier(_active_building.chain_id)
	if target_b and is_instance_valid(target_b) and target_b.tier == _active_building.tier and target_b.tier < max_t and target_b.chain_id == _active_building.chain_id:
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
	var counts_by_chain: Dictionary = {}
	for b in _buildings:
		if is_instance_valid(b):
			var ch = b.chain_id
			if not counts_by_chain.has(ch):
				counts_by_chain[ch] = 0
			counts_by_chain[ch] += 1

	var desc_parts: Array[String] = []
	for ch in counts_by_chain.keys():
		desc_parts.append("%s: %d" % [ch.capitalize(), counts_by_chain[ch]])

	var detail := "  |  ".join(desc_parts) if not desc_parts.is_empty() else "Empty"
	stats_label.text = "Buildings: %d   (%s)" % [_buildings.size(), detail]
