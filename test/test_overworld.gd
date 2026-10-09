extends Node

const OverworldGeometry = preload("res://scripts/experimental/overworld_geometry.gd")
const OverworldBuildingData = preload("res://scripts/experimental/overworld_building_data.gd")

func _ready() -> void:
	print("=== RUNNING OVERWORLD ISOMETRIC BOARD TESTS ===")
	test_geometry_calculations()
	test_board_spawning_and_occupancy()
	test_building_movement_and_collision()
	test_merging_progression()
	test_data_extensibility()
	test_hover_drag_merge_no_freed_instances()
	test_kitchen_building_data()
	test_kitchen_spawning_and_multi_size_occupancy()
	test_kitchen_merging_progression()
	test_item_selection_ui_and_spawning()
	test_tile_cursor_and_information_bar()
	test_improved_construction_smoke()
	test_tree_building_data()
	test_tree_instant_upgrade_after_merge()
	test_library_building_data()
	test_library_spawning_and_merging()
	print("=== ALL OVERWORLD TESTS PASSED SUCCESSFULLY! ===")
	get_tree().quit(0)

func test_geometry_calculations() -> void:
	print("1. Testing OverworldGeometry math...")
	
	# Test 1x1 footprint polygon
	var poly_1x1 := OverworldGeometry.get_footprint_polygon([Vector2i(0, 0)])
	assert(poly_1x1.size() == 4, "1x1 footprint should have 4 corners")
	print("  -> 1x1 footprint polygon: ", poly_1x1)

	# Test 1x2 footprint polygon
	var poly_1x2 := OverworldGeometry.get_footprint_polygon([Vector2i(0, 0), Vector2i(1, 0)])
	assert(poly_1x2.size() == 4, "1x2 footprint should form an exact 4-sided merged parallelogram")
	print("  -> 1x2 footprint polygon: ", poly_1x2)

	# Test 2x2 footprint polygon
	var poly_2x2 := OverworldGeometry.get_footprint_polygon([
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)
	])
	assert(poly_2x2.size() == 4, "2x2 footprint should form an exact 4-sided diamond")
	print("  -> 2x2 footprint polygon: ", poly_2x2)

	# Test 3x2 footprint polygon
	var cells_3x2: Array[Vector2i] = []
	for y in range(3):
		for x in range(2):
			cells_3x2.append(Vector2i(x, y))
	var poly_3x2 := OverworldGeometry.get_footprint_polygon(cells_3x2)
	print("  -> 3x2 footprint polygon pts: ", poly_3x2.size(), poly_3x2)
	assert(poly_3x2.size() >= 4, "3x2 footprint polygon should be valid")

	# Test 3x3 footprint polygon
	var cells_3x3: Array[Vector2i] = []
	for y in range(3):
		for x in range(3):
			cells_3x3.append(Vector2i(x, y))
	var poly_3x3 := OverworldGeometry.get_footprint_polygon(cells_3x3)
	print("  -> 3x3 footprint polygon pts: ", poly_3x3.size(), poly_3x3)
	assert(poly_3x3.size() >= 4, "3x3 footprint polygon should be valid")

	# Test 4x4 footprint polygon
	var cells_4x4: Array[Vector2i] = []
	for y in range(4):
		for x in range(4):
			cells_4x4.append(Vector2i(x, y))
	var poly_4x4 := OverworldGeometry.get_footprint_polygon(cells_4x4)
	print("  -> 4x4 footprint polygon pts: ", poly_4x4.size(), poly_4x4)
	assert(poly_4x4.size() >= 4, "4x4 footprint polygon should be valid")

	# Test inset calculation
	var inset_poly := OverworldGeometry.get_footprint_polygon([Vector2i(0, 0)], OverworldGeometry.DEFAULT_TILE_SIZE, 3.0)
	assert(inset_poly.size() == 4, "Inset polygon should maintain corner count")
	print("  [PASS] Geometry calculations verified.")

func test_board_spawning_and_occupancy() -> void:
	print("2. Testing board spawning and multi-tile occupancy...")
	var world_scene: PackedScene = load("res://scenes/experimental/world.tscn")
	var board: OverworldBoard = world_scene.instantiate()
	add_child(board)

	# Board initializes with default buildings
	assert(board._buildings.size() > 0, "Board should initialize with buildings")
	print("  -> Initial buildings count: ", board._buildings.size())

	# Clear for isolated tests
	for b in board._buildings:
		if is_instance_valid(b):
			b.queue_free()
	board._buildings.clear()
	board._occupancy.clear()

	# Spawn Tier 1 (1x1) at (-8, 8)
	var b1 := board.spawn_building(1, Vector2i(-8, 8))
	assert(b1 != null, "Building 1 must spawn successfully")
	assert(b1.tier == 1, "Building 1 tier must be 1")
	assert(board._occupancy.has(Vector2i(-8, 8)), "Occupancy must register cell (-8, 8)")
	assert(board._occupancy[Vector2i(-8, 8)] == b1, "Occupancy must map to building 1")

	# Spawn Tier 2 (1x2) at (-6, 8) -> covers (-6, 8) and (-5, 8)
	var b2 := board.spawn_building(2, Vector2i(-6, 8))
	assert(b2 != null, "Building 2 must spawn successfully")
	assert(b2.tier == 2, "Building 2 tier must be 2")
	assert(board._occupancy.has(Vector2i(-6, 8)), "Occupancy must register cell (-6, 8)")
	assert(board._occupancy.has(Vector2i(-5, 8)), "Occupancy must register cell (-5, 8)")
	assert(board._occupancy[Vector2i(-6, 8)] == b2, "Cell (-6, 8) must map to building 2")
	assert(board._occupancy[Vector2i(-5, 8)] == b2, "Cell (-5, 8) must map to building 2")

	# Spawn Tier 3 (2x2) at (-4, 8) -> covers 4 cells
	var b3 := board.spawn_building(3, Vector2i(-4, 8))
	assert(b3 != null, "Building 3 must spawn successfully")
	assert(b3.tier == 3, "Building 3 tier must be 3")
	assert(b3.get_occupied_cells().size() == 4, "Tier 3 must occupy 4 cells")
	for cell in b3.get_occupied_cells():
		assert(board._occupancy.has(cell), "Cell %s must be registered in occupancy" % [cell])
		assert(board._occupancy[cell] == b3, "Cell %s must map to building 3" % [cell])

	print("  [PASS] Spawning & multi-cell occupancy verified.")
	board.queue_free()

func test_building_movement_and_collision() -> void:
	print("3. Testing placement validity and collision checks...")
	var world_scene: PackedScene = load("res://scenes/experimental/world.tscn")
	var board: OverworldBoard = world_scene.instantiate()
	add_child(board)
	for b in board._buildings:
		if is_instance_valid(b):
			b.queue_free()
	board._buildings.clear()
	board._occupancy.clear()

	var b1 := board.spawn_building(1, Vector2i(-8, 8))
	# Cannot place at occupied cell
	assert(not board.can_place_at(Vector2i(-8, 8), 1), "Cannot place at occupied cell")
	# Can place at empty valid ground cell
	assert(board.can_place_at(Vector2i(-7, 8), 1), "Can place at free ground cell")

	# Multi-tile placement check: 1x2 at (-9, 8) covers (-9, 8) and (-8, 8)
	# Since (-8, 8) is occupied by b1, placing 1x2 at (-9, 8) should fail
	assert(not board.can_place_at(Vector2i(-9, 8), 2), "1x2 cannot overlap existing building")

	print("  [PASS] Movement & collision checks verified.")
	board.queue_free()

func test_merging_progression() -> void:
	print("4. Testing merging progression (1x1 -> 1x2 -> 2x2)...")
	var world_scene: PackedScene = load("res://scenes/experimental/world.tscn")
	var board: OverworldBoard = world_scene.instantiate()
	add_child(board)
	for b in board._buildings:
		if is_instance_valid(b):
			b.queue_free()
	board._buildings.clear()
	board._occupancy.clear()

	# Spawn two Tier 1 buildings
	var source := board.spawn_building(1, Vector2i(-8, 7))
	var target := board.spawn_building(1, Vector2i(-8, 8))

	# Merge source into target
	board._execute_merge(source, target)
	assert(target.tier == 2, "Target must upgrade to Tier 2 (1x2)")
	assert(target.get_occupied_cells().size() == 2, "Upgraded building must occupy 2 cells")
	assert(board._buildings.size() == 1, "Board should now contain 1 building")

	# Spawn another Tier 2 building
	var source_t2 := board.spawn_building(2, Vector2i(-6, 8))
	assert(source_t2.tier == 2, "Second building must be Tier 2")

	# Merge source_t2 into target (Tier 2 -> Tier 3)
	board._execute_merge(source_t2, target)
	assert(target.tier == 3, "Target must upgrade to Tier 3 (2x2)")
	assert(target.get_occupied_cells().size() == 4, "Upgraded Tier 3 building must occupy 4 cells")
	assert(board._buildings.size() == 1, "Board should now contain 1 building")

	print("  [PASS] Merging progression verified.")
	board.queue_free()

func test_data_extensibility() -> void:
	print("5. Testing OverworldBuildingData extensibility...")
	var t1: Resource = OverworldBuildingData.get_data(1, "bakery")
	assert(t1 != null, "Bakery Tier 1 data must exist")
	assert(t1.tier == 1, "Tier must match")
	assert(t1.scale > 0.0, "Scale must be positive")
	assert(t1.sprite_offset != Vector2.ZERO, "Sprite offset must be defined")

	var t2: Resource = OverworldBuildingData.get_data(2, "bakery")
	assert(t2 != null, "Bakery Tier 2 data must exist")
	assert(t2.footprint.size() == 2, "Tier 2 footprint must have 2 cells")

	print("  [PASS] Data extensibility verified.")

func test_hover_drag_merge_no_freed_instances() -> void:
	print("6. Testing hover feedback, clearing, and merge without freed instance leaks...")
	var world_scene: PackedScene = load("res://scenes/experimental/world.tscn")
	var board: OverworldBoard = world_scene.instantiate()
	add_child(board)
	for b in board._buildings:
		if is_instance_valid(b):
			b.queue_free()
	board._buildings.clear()
	board._occupancy.clear()

	# Spawn two Tier 1 buildings
	var b1 := board.spawn_building(1, Vector2i(-8, 7))
	var b2 := board.spawn_building(1, Vector2i(-8, 8))

	# Simulate dragging b1 over b2
	board._active_building = b1
	board._is_dragging = true
	board._update_hover_feedback(b2.global_position)
	assert(board._hover_mode == 2, "Hover mode should be Merge Gold (2)")
	assert(board._hover_poly_offsets.size() > 0, "Hover poly offsets should not be empty")

	# Simulate release & drop merge
	board._handle_release(b2.global_position)

	# Crucial assertion: footprint data must NOT be cleared by hover clear
	var b_data: Resource = OverworldBuildingData.get_data(1, "bakery")
	assert(b_data.footprint.size() > 0, "BuildingData footprint must NOT be mutated/cleared by hover feedback!")

	# Check that _occupancy contains no freed instances
	for cell in board._occupancy.keys():
		var occ = board._occupancy[cell]
		assert(is_instance_valid(occ), "Occupancy must never contain freed instances at cell %s" % [cell])
		var retrieved = board.get_building_at_cell(cell)
		assert(is_instance_valid(retrieved), "get_building_at_cell must return valid building at cell %s" % [cell])

	# Now drag the newly merged Tier 2 building
	var t2_building = board._buildings[0]
	assert(t2_building.tier == 2, "Building should be tier 2")
	board._active_building = t2_building
	board._is_dragging = true
	board._update_hover_feedback(t2_building.global_position + Vector2(100, 50))
	board._clear_hover_feedback()
	board._active_building = null
	board._is_dragging = false

	var b_data_t2: Resource = OverworldBuildingData.get_data(2, "bakery")
	assert(b_data_t2.footprint.size() == 2, "Tier 2 footprint must remain intact after hover clear!")

	print("  [PASS] Hover, drag, and merge occupancy safety verified.")
	board.queue_free()

func test_kitchen_building_data() -> void:
	print("7. Testing Kitchen building data registration & {tier}_{tilesize} information...")
	var max_tier := OverworldBuildingData.get_max_tier("kitchen")
	assert(max_tier == 8, "Kitchen chain must have 8 tiers! Got: %d" % max_tier)

	var expected_info := {
		1: {"size": "1x1", "cells": 1, "next": 2, "tex": "res://assets/world/kitchen/1_1x1.png"},
		2: {"size": "1x2", "cells": 2, "next": 3, "tex": "res://assets/world/kitchen/2_1x2.png"},
		3: {"size": "2x2", "cells": 4, "next": 4, "tex": "res://assets/world/kitchen/3_2x2.png"},
		4: {"size": "3x2", "cells": 6, "next": 5, "tex": "res://assets/world/kitchen/4_3x2.png"},
		5: {"size": "3x2", "cells": 6, "next": 6, "tex": "res://assets/world/kitchen/5_3x2.png"},
		6: {"size": "3x3", "cells": 9, "next": 7, "tex": "res://assets/world/kitchen/6_3x3.png"},
		7: {"size": "3x3", "cells": 9, "next": 8, "tex": "res://assets/world/kitchen/7_3x3.png"},
		8: {"size": "4x4", "cells": 16, "next": 0, "tex": "res://assets/world/kitchen/8_4x4.png"},
	}

	for t in range(1, 9):
		var k_data: Resource = OverworldBuildingData.get_data(t, "kitchen")
		assert(k_data != null, "Kitchen Tier %d data must exist" % t)
		assert(k_data.chain_id == "kitchen", "Chain ID must be 'kitchen'")
		assert(k_data.tier == t, "Tier must be %d" % t)
		
		var exp_info: Dictionary = expected_info[t]
		assert(k_data.footprint_desc == exp_info["size"], "Tier %d size must be %s" % [t, exp_info["size"]])
		assert(k_data.tilesize == exp_info["size"], "Tier %d tilesize must be %s" % [t, exp_info["size"]])
		assert(k_data.get_info() == "%d_%s" % [t, exp_info["size"]], "Tier %d get_info() must return {tier}_{tilesize}" % t)
		assert(k_data.get_footprint().size() == exp_info["cells"], "Tier %d must occupy %d cells" % [t, exp_info["cells"]])
		assert(k_data.next_tier == exp_info["next"], "Tier %d next_tier must be %d" % [t, exp_info["next"]])
		assert(ResourceLoader.exists(k_data.texture_path), "Texture must exist at %s" % k_data.texture_path)
		print("  -> Kitchen Tier %d verified: info=%s cells=%d tex=%s" % [t, k_data.get_info(), k_data.get_footprint().size(), k_data.texture_path])

	print("  [PASS] Kitchen data registration & {tier}_{tilesize} verified.")

func test_kitchen_spawning_and_multi_size_occupancy() -> void:
	print("8. Testing Kitchen spawning across various multi-tile sizes...")
	var world_scene: PackedScene = load("res://scenes/experimental/world.tscn")
	var board: OverworldBoard = world_scene.instantiate()
	add_child(board)
	for b in board._buildings:
		if is_instance_valid(b):
			b.queue_free()
	board._buildings.clear()
	board._occupancy.clear()

	# 1. Spawn Kitchen T1 (1x1)
	var k1 := board.spawn_building(1, Vector2i(-8, 8), "kitchen")
	assert(k1 != null, "Kitchen T1 must spawn")
	assert(k1.chain_id == "kitchen", "Chain must be kitchen")
	assert(k1.get_occupied_cells().size() == 1, "Kitchen T1 must occupy 1 cell")

	# 2. Spawn Kitchen T4 (3x2 -> 6 cells)
	var k4 := board.spawn_building(4, Vector2i(-5, 8), "kitchen")
	assert(k4 != null, "Kitchen T4 must spawn")
	assert(k4.get_occupied_cells().size() == 6, "Kitchen T4 must occupy 6 cells")
	for cell in k4.get_occupied_cells():
		assert(board._occupancy.has(cell) and board._occupancy[cell] == k4, "Occupancy must map to Kitchen T4")

	# Collision check: Cannot place overlapping Kitchen T4
	assert(not board.can_place_at(Vector2i(-5, 8), 1, null, "kitchen"), "Cannot place over Kitchen T4")
	assert(not board.can_place_at(Vector2i(-4, 8), 1, null, "kitchen"), "Cannot place inside Kitchen T4 cells")

	# 3. Spawn Kitchen T8 (4x4 -> 16 cells)
	var k8 := board.spawn_building(8, Vector2i(-9, 12), "kitchen")
	assert(k8 != null, "Kitchen T8 must spawn")
	assert(k8.get_occupied_cells().size() == 16, "Kitchen T8 must occupy 16 cells")
	for cell in k8.get_occupied_cells():
		assert(board._occupancy.has(cell) and board._occupancy[cell] == k8, "Occupancy must map to Kitchen T8")

	print("  [PASS] Kitchen multi-size spawning & occupancy verified.")
	board.queue_free()

func test_kitchen_merging_progression() -> void:
	print("9. Testing Kitchen merging progression (T1 -> T2 -> T3 -> T4 -> T5 -> T6 -> T7 -> T8)...")
	var world_scene: PackedScene = load("res://scenes/experimental/world.tscn")
	var board: OverworldBoard = world_scene.instantiate()
	add_child(board)
	for b in board._buildings:
		if is_instance_valid(b):
			b.queue_free()
	board._buildings.clear()
	board._occupancy.clear()

	# Start by merging two Kitchen T1s
	var k_source := board.spawn_building(1, Vector2i(-8, 7), "kitchen")
	var k_target := board.spawn_building(1, Vector2i(-8, 8), "kitchen")

	board._execute_merge(k_source, k_target)
	assert(k_target.tier == 2, "Target must become Kitchen T2 (1x2)")
	assert(k_target.get_occupied_cells().size() == 2, "Kitchen T2 must occupy 2 cells")

	# Merge with another T2 -> T3 (2x2)
	var k2_b := board.spawn_building(2, Vector2i(-5, 8), "kitchen")
	board._execute_merge(k2_b, k_target)
	assert(k_target.tier == 3, "Target must become Kitchen T3 (2x2)")
	assert(k_target.get_occupied_cells().size() == 4, "Kitchen T3 must occupy 4 cells")

	# Merge with another T3 -> T4 (3x2)
	var k3_b := board.spawn_building(3, Vector2i(-5, 6), "kitchen")
	board._execute_merge(k3_b, k_target)
	assert(k_target.tier == 4, "Target must become Kitchen T4 (3x2)")
	assert(k_target.get_occupied_cells().size() == 6, "Kitchen T4 must occupy 6 cells")

	# Test Max Tier behavior: Kitchen T8 cannot merge further
	for b in board._buildings:
		if is_instance_valid(b):
			b.queue_free()
	board._buildings.clear()
	board._occupancy.clear()

	var k8_a := board.spawn_building(8, Vector2i(-9, 8), "kitchen")
	var k8_b := board.spawn_building(8, Vector2i(-9, 13), "kitchen")
	# Simulate drop of T8 on T8
	board._handle_building_drop(k8_a, k8_b.global_position)
	assert(k8_a.tier == 8 and k8_b.tier == 8, "Max Tier buildings must not merge")
	assert(board._buildings.size() == 2, "Both Max Tier buildings must remain intact")

	print("  [PASS] Kitchen merging progression verified.")
	board.queue_free()

func test_item_selection_ui_and_spawning() -> void:
	print("10. Testing OptionButton display, selection, and Spawn Selected button...")
	var world_scene: PackedScene = load("res://scenes/experimental/world.tscn")
	var board: OverworldBoard = world_scene.instantiate()
	add_child(board)

	# Verify UI controls exist
	assert(board.item_option_btn != null, "ItemOptionBtn must exist in board")
	assert(board.spawn_selected_btn != null, "SpawnSelectedBtn must exist in board")
	assert(board.item_option_btn.item_count >= 11, "ItemOptionBtn should contain at least 11 items (3 bakery + 8 kitchen), got: %d" % board.item_option_btn.item_count)

	# Clear existing buildings to test spawning
	for b in board._buildings:
		if is_instance_valid(b):
			b.queue_free()
	board._buildings.clear()
	board._occupancy.clear()

	# Find index for Kitchen T4 (3x2)
	var k4_index := -1
	for i in range(board.item_option_btn.item_count):
		var meta = board.item_option_btn.get_item_metadata(i)
		if meta and meta.get("chain") == "kitchen" and meta.get("tier") == 4:
			k4_index = i
			break
	assert(k4_index >= 0, "Kitchen T4 must be available in ItemOptionBtn")

	# Select Kitchen T4
	board.item_option_btn.select(k4_index)
	board._on_item_option_selected(k4_index)
	assert(board._selected_chain == "kitchen", "Selected chain must be 'kitchen'")
	assert(board._selected_tier == 4, "Selected tier must be 4")

	# Press Spawn Selected button
	board._on_spawn_selected_pressed()
	assert(board._buildings.size() == 1, "One building should have spawned")
	var spawned_b := board._buildings[0]
	assert(spawned_b.chain_id == "kitchen", "Spawned building must be kitchen")
	assert(spawned_b.tier == 4, "Spawned building must be tier 4")
	assert(spawned_b.get_footprint_desc() == "3x2", "Spawned building footprint must be 3x2")
	assert(spawned_b.get_occupied_cells().size() == 6, "Spawned building must occupy 6 cells")
	print("  -> Successfully spawned selected item: %s (%s) occupying %d cells" % [
		spawned_b.get_building_name(),
		spawned_b.get_footprint_desc(),
		spawned_b.get_occupied_cells().size()
	])

	# Now select Kitchen T8 (4x4)
	var k8_index := -1
	for i in range(board.item_option_btn.item_count):
		var meta = board.item_option_btn.get_item_metadata(i)
		if meta and meta.get("chain") == "kitchen" and meta.get("tier") == 8:
			k8_index = i
			break
	assert(k8_index >= 0, "Kitchen T8 must be available in ItemOptionBtn")
	board.item_option_btn.select(k8_index)
	board._on_item_option_selected(k8_index)
	board._on_spawn_selected_pressed()

	assert(board._buildings.size() == 2, "Two buildings should now be on the board")
	var spawned_k8 := board._buildings[1]
	assert(spawned_k8.tier == 8, "Second building must be tier 8")
	assert(spawned_k8.get_footprint_desc() == "4x4", "Footprint must be 4x4")
	assert(spawned_k8.get_occupied_cells().size() == 16, "Footprint must occupy 16 cells")
	print("  -> Successfully spawned selected item: %s (%s) occupying %d cells" % [
		spawned_k8.get_building_name(),
		spawned_k8.get_footprint_desc(),
		spawned_k8.get_occupied_cells().size()
	])

	print("  [PASS] OptionButton selection and Spawn Selected button verified.")
	board.queue_free()

func test_tile_cursor_and_information_bar() -> void:
	print("11. Testing tile cursor and Information Bar on clicking building...")
	var world_scene: PackedScene = load("res://scenes/experimental/world.tscn")
	var board: OverworldBoard = world_scene.instantiate()
	add_child(board)

	# Verify tile cursor node exists and starts invisible
	assert(board.tile_cursor != null, "TileCursor node must exist on board")
	assert(board.tile_cursor.visible == false, "TileCursor should initially be invisible")
	assert(board.info_bar != null, "InfoBar PanelContainer must exist in UI")
	assert(board.info_title_label != null, "InfoTitle Label must exist")
	assert(board.info_desc_label != null, "InfoDesc Label must exist")
	assert(board.info_title_label.text == "Select a Building", "Initial info bar title must prompt selection")

	# Pick a building and click it
	assert(board._buildings.size() > 0, "Board should have buildings")
	var b := board._buildings[0]
	board.select_building(b)

	# Verify building is selected
	assert(board.selected_building == b, "selected_building must be set to clicked building")
	assert(board.tile_cursor.visible == true, "TileCursor must become visible when item is selected")
	assert(board._cursor_poly.size() >= 4, "Tile cursor polygon must match building footprint")
	
	# Verify Information Bar updated with building information instead of floating text
	var expected_title := "%s (Tier %d)" % [b.get_building_name(), b.tier]
	assert(board.info_title_label.text == expected_title, "InfoTitle must match building name and tier")
	assert(b.chain_id.capitalize() in board.info_desc_label.text, "InfoDesc must include chain name")
	assert(b.get_footprint_desc() in board.info_desc_label.text, "InfoDesc must include footprint description")

	# Test Deselect button
	if board.info_deselect_btn:
		board.info_deselect_btn.emit_signal("pressed")
		assert(board.selected_building == null, "Clicking deselect should clear selection")
		assert(board.tile_cursor.visible == false, "TileCursor must become invisible after clearing selection")
		assert(board.info_title_label.text == "Select a Building", "Info title must reset after deselecting")

	print("  [PASS] Tile cursor and Information Bar verified successfully.")
	board.queue_free()

func test_improved_construction_smoke() -> void:
	print("12. Testing improved construction smoke size, opacity, and variation...")
	var world_scene: PackedScene = load("res://scenes/experimental/world.tscn")
	var board: OverworldBoard = world_scene.instantiate()
	add_child(board)

	var b := board.spawn_building(4, Vector2i(-5, 5), "kitchen")
	assert(b != null, "Building should spawn")
	b.start_construction(10.0)

	assert(b.is_under_construction == true, "Building must be under construction")
	assert(b.smoke_container != null, "SmokeContainer must exist")
	assert(b.smoke_container.get_child_count() >= 8, "Initial burst should spawn at least 8 smoke puffs covering the site")

	# Check puff opacity, scales, and variation
	var puffs = b.smoke_container.get_children()
	var scales: Array[float] = []
	var tints: Array[Color] = []
	for p in puffs:
		if p is Sprite2D:
			assert(p.modulate.a >= 0.88, "Smoke initial opacity must be high/dense (>= 0.88), got %f" % p.modulate.a)
			scales.append(p.scale.x)
			tints.append(Color(p.modulate.r, p.modulate.g, p.modulate.b))

	assert(scales.size() >= 8, "Should have tracked puff scales")
	var has_large_puff := false
	for sc in scales:
		if sc >= 0.15:
			has_large_puff = true
			break
	assert(has_large_puff, "Should contain large voluminous puffs covering the site")
	print("  -> Smoke puffs spawned: %d, verified high opacity & voluminous size coverage" % puffs.size())

	b.finish_construction()
	assert(b.is_under_construction == false, "Construction should be finished")
	print("  [PASS] Improved construction smoke verified successfully.")
	board.queue_free()

func test_tree_building_data() -> void:
	print("13. Testing Tree building data registration (9 tiers) & no construction time...")
	var max_tier := OverworldBuildingData.get_max_tier("tree")
	assert(max_tier == 9, "Tree chain must have 9 tiers! Got: %d" % max_tier)

	var expected_trees := {
		1: {"size": "1x1", "cells": 1, "next": 2, "tex": "res://assets/world/tree/1_1x1.tres"},
		2: {"size": "1x1", "cells": 1, "next": 3, "tex": "res://assets/world/tree/2_1x1.tres"},
		3: {"size": "1x1", "cells": 1, "next": 4, "tex": "res://assets/world/tree/3_1x1.tres"},
		4: {"size": "1x1", "cells": 1, "next": 5, "tex": "res://assets/world/tree/4_1x1.tres"},
		5: {"size": "2x2", "cells": 4, "next": 6, "tex": "res://assets/world/tree/5_2x2.tres"},
		6: {"size": "2x2", "cells": 4, "next": 7, "tex": "res://assets/world/tree/6_2x2.tres"},
		7: {"size": "3x3", "cells": 9, "next": 8, "tex": "res://assets/world/tree/7_3x3.tres"},
		8: {"size": "4x4", "cells": 16, "next": 9, "tex": "res://assets/world/tree/8_4x4.tres"},
		9: {"size": "5x5", "cells": 25, "next": 0, "tex": "res://assets/world/tree/9_5x5.tres"},
	}

	for t in range(1, 10):
		var t_data: Resource = OverworldBuildingData.get_data(t, "tree")
		assert(t_data != null, "Tree Tier %d data must exist" % t)
		assert(t_data.chain_id == "tree", "Chain ID must be 'tree'")
		assert(t_data.tier == t, "Tier must be %d" % t)
		
		var exp_info: Dictionary = expected_trees[t]
		assert(t_data.footprint_desc == exp_info["size"], "Tree Tier %d size must be %s" % [t, exp_info["size"]])
		assert(t_data.get_info() == "%d_%s" % [t, exp_info["size"]], "Tree Tier %d get_info() must return {tier}_{tilesize}" % t)
		assert(t_data.get_footprint().size() == exp_info["cells"], "Tree Tier %d must occupy %d cells" % [t, exp_info["cells"]])
		assert(t_data.next_tier == exp_info["next"], "Tree Tier %d next_tier must be %d" % [t, exp_info["next"]])
		assert(ResourceLoader.exists(t_data.texture_path), "Texture must exist at %s" % t_data.texture_path)
		assert(t_data.requires_construction == false, "Tree Tier %d must NOT require construction!" % t)
		assert(t_data.construction_time == 0.0, "Tree Tier %d construction_time must be 0.0!" % t)
		print("  -> Tree Tier %d verified: info=%s cells=%d tex=%s" % [t, t_data.get_info(), t_data.get_footprint().size(), t_data.texture_path])

	print("  [PASS] Tree building data registration (9 tiers) & no construction time verified.")

func test_tree_instant_upgrade_after_merge() -> void:
	print("14. Testing Tree merge instant upgrade without construction time...")
	var world_scene: PackedScene = load("res://scenes/experimental/world.tscn")
	var board: OverworldBoard = world_scene.instantiate()
	add_child(board)
	for b in board._buildings:
		if is_instance_valid(b):
			b.queue_free()
	board._buildings.clear()
	board._occupancy.clear()

	# Spawn two Tier 1 trees
	var tree_a := board.spawn_building(1, Vector2i(-8, 7), "tree")
	var tree_b := board.spawn_building(1, Vector2i(-8, 8), "tree")
	assert(tree_a.is_under_construction == false, "Tree A must not be under construction")
	assert(tree_b.is_under_construction == false, "Tree B must not be under construction")

	# Merge tree_a onto tree_b
	board._execute_merge(tree_a, tree_b)

	# Verify instant upgrade: Tier 2, NOT under construction, construction_timer == 0.0
	assert(tree_b.tier == 2, "Merged tree must instantly upgrade to Tier 2")
	assert(tree_b.is_under_construction == false, "Tree item must NOT enter construction after merge!")
	assert(tree_b.construction_timer == 0.0, "Tree construction timer must be 0.0!")
	assert(tree_b.construction_timer_panel == null or tree_b.construction_timer_panel.visible == false, "Timer panel must NOT be visible on tree")
	assert(tree_b.construction_audio == null or not tree_b.construction_audio.playing, "Construction audio must NOT be playing for tree")

	# Merge Tier 2 with another Tier 2 tree -> instantly Tier 3
	var tree_c := board.spawn_building(2, Vector2i(-6, 7), "tree")
	board._execute_merge(tree_c, tree_b)
	assert(tree_b.tier == 3, "Merged tree must instantly upgrade to Tier 3")
	assert(tree_b.is_under_construction == false, "Tree item must remain NOT under construction!")

	# Merge Tier 4 with Tier 4 -> Tier 5 (2x2)
	for b in board._buildings:
		if is_instance_valid(b):
			b.queue_free()
	board._buildings.clear()
	board._occupancy.clear()

	var t4_a := board.spawn_building(4, Vector2i(-8, 7), "tree")
	var t4_b := board.spawn_building(4, Vector2i(-8, 8), "tree")
	board._execute_merge(t4_a, t4_b)
	assert(t4_b.tier == 5, "Merged tree must upgrade to Tier 5")
	assert(t4_b.get_occupied_cells().size() == 4, "Tier 5 tree must occupy 4 cells (2x2)")
	assert(t4_b.is_under_construction == false, "Tier 5 tree must NOT undergo construction!")

	print("  [PASS] Tree merge instant upgrade verified.")
	board.queue_free()

func test_library_building_data() -> void:
	print("15. Testing Library building data registration (6 tiers)...")
	var max_tier := OverworldBuildingData.get_max_tier("library")
	assert(max_tier == 6, "Library chain must have 6 tiers! Got: %d" % max_tier)

	var expected_libs := {
		1: {"size": "2x2", "cells": 4, "next": 2, "tex": "res://assets/world/library/1_2x2.tres"},
		2: {"size": "2x2", "cells": 4, "next": 3, "tex": "res://assets/world/library/2_2x2.tres"},
		3: {"size": "2x2", "cells": 4, "next": 4, "tex": "res://assets/world/library/3_2x2.tres"},
		4: {"size": "3x3", "cells": 9, "next": 5, "tex": "res://assets/world/library/4_3x3.tres"},
		5: {"size": "4x3", "cells": 12, "next": 6, "tex": "res://assets/world/library/5_4x3.tres"},
		6: {"size": "4x3", "cells": 12, "next": 0, "tex": "res://assets/world/library/6_4x3.tres"},
	}

	for t in range(1, 7):
		var l_data: Resource = OverworldBuildingData.get_data(t, "library")
		assert(l_data != null, "Library Tier %d data must exist" % t)
		assert(l_data.chain_id == "library", "Chain ID must be 'library'")
		assert(l_data.tier == t, "Tier must be %d" % t)
		
		var exp_info: Dictionary = expected_libs[t]
		assert(l_data.footprint_desc == exp_info["size"], "Library Tier %d size must be %s" % [t, exp_info["size"]])
		assert(l_data.get_info() == "%d_%s" % [t, exp_info["size"]], "Library Tier %d get_info() must return {tier}_{tilesize}" % t)
		assert(l_data.get_footprint().size() == exp_info["cells"], "Library Tier %d must occupy %d cells" % [t, exp_info["cells"]])
		assert(l_data.next_tier == exp_info["next"], "Library Tier %d next_tier must be %d" % [t, exp_info["next"]])
		assert(ResourceLoader.exists(l_data.texture_path), "Texture must exist at %s" % l_data.texture_path)
		assert(l_data.requires_construction == true, "Library Tier %d requires construction!" % t)
		print("  -> Library Tier %d verified: info=%s cells=%d tex=%s" % [t, l_data.get_info(), l_data.get_footprint().size(), l_data.texture_path])

	print("  [PASS] Library building data registration (6 tiers) verified.")

func test_library_spawning_and_merging() -> void:
	print("16. Testing Library spawning and merging (with construction)...")
	var world_scene: PackedScene = load("res://scenes/experimental/world.tscn")
	var board: OverworldBoard = world_scene.instantiate()
	add_child(board)
	for b in board._buildings:
		if is_instance_valid(b):
			b.queue_free()
	board._buildings.clear()
	board._occupancy.clear()

	# Spawn two Tier 1 libraries (2x2 -> 4 cells each)
	var lib_a := board.spawn_building(1, Vector2i(-8, 7), "library")
	var lib_b := board.spawn_building(1, Vector2i(-4, 7), "library")
	assert(lib_a.get_occupied_cells().size() == 4, "Library T1 occupies 4 cells")
	assert(lib_b.get_occupied_cells().size() == 4, "Library T1 occupies 4 cells")

	# Merge lib_a onto lib_b
	board._execute_merge(lib_a, lib_b)
	assert(lib_b.tier == 2, "Library upgraded to Tier 2")
	assert(lib_b.is_under_construction == true, "Library building must enter construction status after merge")
	assert(lib_b.construction_timer > 0.0, "Library construction timer must be positive")

	# Finish construction
	lib_b.finish_construction()
	assert(lib_b.is_under_construction == false, "Construction status must be cleared")

	print("  [PASS] Library spawning and merging verified.")
	board.queue_free()



