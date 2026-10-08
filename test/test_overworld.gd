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

