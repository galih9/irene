extends Node

const LiquidBottle = preload("res://scripts/minigame/liquid_bottle.gd")
const LiquidColorPalette = preload("res://scripts/minigame/liquid_color_palette.gd")
const LiquidSortLevelGenerator = preload("res://scripts/minigame/liquid_sort_level_generator.gd")
const LiquidStream = preload("res://scripts/minigame/liquid_stream.gd")
const LiquidSortMinigame = preload("res://scripts/minigame/liquid_sort_minigame.gd")

func _ready() -> void:
	print("=== RUNNING SORT THE LIQUID MINIGAME TESTS ===")

	# 1. Test LiquidColorPalette
	print("\n--- 1. Testing LiquidColorPalette ---")
	var orange_col := LiquidColorPalette.get_color("orange")
	assert(orange_col != Color.WHITE and orange_col.a == 1.0, "Orange color must exist and be opaque")
	var sky_blue_data := LiquidColorPalette.get_color_data("sky_blue")
	assert(sky_blue_data.has("main") and sky_blue_data.has("highlight"), "Color data must have main and highlight")
	assert(LiquidColorPalette.ORDERED_KEYS.size() >= 8, "Palette must define at least 8 colors")

	var lvl1_colors := LiquidColorPalette.get_colors_for_level(3)
	assert(lvl1_colors.size() == 3, "Level 1 must have exactly 3 colors")
	print("[OK] LiquidColorPalette verified!")

	# 2. Test LiquidBottle Data & Rules
	print("\n--- 2. Testing LiquidBottle Mechanics ---")
	var b1 := LiquidBottle.new()
	add_child(b1)
	b1.setup(3, ["orange", "sky_blue", "sky_blue"])

	assert(b1.capacity == 3, "Bottle 1 capacity must be 3")
	assert(b1.layers.size() == 3, "Bottle 1 must have 3 layers")
	assert(b1.is_full() == true, "Bottle 1 must be full")
	assert(b1.is_empty_bottle() == false, "Bottle 1 is not empty")
	assert(b1.get_top_color() == "sky_blue", "Top color must be sky_blue")
	assert(b1.get_top_consecutive_count() == 2, "Top consecutive sky_blue count must be 2")
	assert(b1.get_available_space() == 0, "Full bottle space must be 0")
	assert(b1.check_is_complete() == false, "Mixed bottle must not be complete")

	# Test Empty Bottle
	var b_empty := LiquidBottle.new()
	add_child(b_empty)
	b_empty.setup(3, [])
	assert(b_empty.is_empty_bottle() == true, "Empty bottle must report is_empty")
	assert(b_empty.get_top_color() == "", "Empty bottle top color must be empty string")
	assert(b_empty.get_available_space() == 3, "Empty bottle with cap 3 must have 3 spaces")
	assert(b_empty.check_is_complete() == false, "Empty bottle is not complete")

	# Test Pour Rules
	# b1 has top "sky_blue" (2 units). Can b_empty receive from b1?
	assert(b_empty.can_receive_from(b1) == true, "Empty bottle can receive from non-empty bottle")
	assert(b1.can_receive_from(b_empty) == false, "Full bottle cannot receive from empty bottle")
	assert(b1.can_receive_from(b1) == false, "Bottle cannot receive from itself")

	# Test Completed Bottle
	var b_complete := LiquidBottle.new()
	add_child(b_complete)
	b_complete.setup(3, ["orange", "orange", "orange"])
	assert(b_complete.check_is_complete() == true, "Bottle with all 3 identical colors must be complete")
	assert(b_complete.cork_rect.visible == true, "Completed bottle must display cork stopper")
	assert(b_complete.cork_rect.texture != null, "Cork rect must have texture")
	assert(b_complete.cork_rect.texture.resource_path.ends_with("cork.png"), "Cork rect must use cork.png asset")

	# Test 1-Row Remaining Visuals & Tilt Bug Fix
	var b_single := LiquidBottle.new()
	add_child(b_single)
	b_single.setup(3, ["orange"])
	assert(b_single.layers.size() == 1, "Single row bottle must have 1 layer")
	assert(is_equal_approx(b_single.fluid_material.get_shader_parameter("tilt_angle"), 0.0), "Upright single row bottle tilt_angle must be 0.0")

	# Simulate tilting during pour
	b_single.rotation = 1.32
	b_single._process(0.016)
	assert(is_equal_approx(b_single.fluid_material.get_shader_parameter("tilt_angle"), 1.32), "Shader tilt_angle must dynamically follow rotation when tilted")

	# Simulate returning upright
	b_single.rotation = 0.0
	b_single._process(0.016)
	b_single.update_visuals()
	assert(is_equal_approx(b_single.fluid_material.get_shader_parameter("tilt_angle"), 0.0), "Shader tilt_angle must be exactly 0.0 when returned upright")
	assert(b_single.fluid_material.get_shader_parameter("layer_count") == 1, "Layer count must remain 1")
	var heights: Array = b_single.fluid_material.get_shader_parameter("layer_heights")
	assert(is_equal_approx(heights[0], 1.0) and is_equal_approx(heights[1], 0.0), "Layer 0 height must be 1.0 and other layers 0.0")

	# Test Lip & Neck Coordinate Alignment
	var lip_pos := b_single.get_lip_position_global()
	var neck_pos := b_single.get_neck_position_global()
	assert(lip_pos.y < neck_pos.y, "Lip mouth position must be above neck entry in upright bottle")

	# Clean up test bottles
	b1.queue_free()
	b_empty.queue_free()
	b_complete.queue_free()
	b_single.queue_free()
	print("[OK] LiquidBottle Mechanics & Fluid Visuals verified!")

	# 3. Test Level Generator: Level 1 Requirements
	print("\n--- 3. Testing LiquidSortLevelGenerator ---")
	var l1_config := LiquidSortLevelGenerator.generate_level(1)
	assert(l1_config.level_number == 1, "Level must be 1")
	assert(l1_config.total_bottles == 8, "Level 1 must start with 8 bottles")
	assert(l1_config.capacity == 3, "Level 1 bottle capacity must be 3 rows")
	assert(l1_config.color_count == 3, "Level 1 must have 3 colors amount")
	assert(l1_config.bottle_data.size() == 8, "Level 1 bottle_data must contain 8 bottles")

	# Count filled vs empty
	var filled_count := 0
	var empty_count := 0
	var color_counts: Dictionary = {}
	for b_arr in l1_config.bottle_data:
		if b_arr.is_empty():
			empty_count += 1
		else:
			filled_count += 1
			assert(b_arr.size() == 3, "Filled bottle in level 1 must have 3 rows")
			for col in b_arr:
				color_counts[col] = color_counts.get(col, 0) + 1

	assert(filled_count == 6, "Level 1 must have 6 filled bottles")
	assert(empty_count == 2, "Level 1 must have 2 empty bottles")
	assert(color_counts.size() == 3, "Level 1 must contain exactly 3 unique colors")
	for col in color_counts:
		assert(color_counts[col] == 6, "Each of the 3 colors must have 6 units (2 full bottles)")

	# Verify Level 1 is Solvable via BFS
	var solve_depth := LiquidSortLevelGenerator._solve_bfs(l1_config.bottle_data, l1_config.capacity, 40)
	assert(solve_depth > 0, "Level 1 puzzle must be solvable, found in %d steps" % solve_depth)
	print("[OK] Level 1 generated and verified solvable in %d moves!" % solve_depth)

	# Verify Level 2, 3, 4 scaling (more bottles, rows, and colors)
	var l2_params := LiquidSortLevelGenerator.get_level_params(2)
	assert(l2_params["color_count"] >= 4, "Level 2 must scale to 4 colors")
	var l3_params := LiquidSortLevelGenerator.get_level_params(3)
	assert(l3_params["capacity"] >= 4, "Level 3 must scale to 4 rows")
	assert(l3_params["total_bottles"] >= 9, "Level 3 must scale to >= 9 bottles")
	var l6_params := LiquidSortLevelGenerator.get_level_params(6)
	assert(l6_params["total_bottles"] == 12, "Level 6 must have 12 bottles")
	assert(l6_params["color_count"] == 6, "Level 6 must have 6 colors")
	print("[OK] Level scaling progression verified!")

	# 4. Test LiquidStream Rendering
	print("\n--- 4. Testing LiquidStream ---")
	var stream := LiquidStream.new()
	add_child(stream)
	var test_color := Color(0.96, 0.52, 0.08)
	stream.set_flow_path(Vector2(100, 100), Vector2(150, 300), test_color)
	assert(stream.visible == true, "Stream must be visible when active")
	assert(stream.is_active == true, "Stream state must be active")
	assert(stream.line.points.size() > 2, "Stream must generate curve points")
	assert(stream.stream_color == test_color, "Stream must match the liquid color being poured")
	stream.stop()
	stream.queue_free()
	print("[OK] LiquidStream verified!")

	# 5. Test LiquidSortMinigame Scene
	print("\n--- 5. Testing LiquidSortMinigame Scene ---")
	var minigame_scene: PackedScene = load("res://scenes/minigame/liquid_sort_minigame.tscn")
	assert(minigame_scene != null, "liquid_sort_minigame.tscn must exist and load")
	var minigame: LiquidSortMinigame = minigame_scene.instantiate()
	add_child(minigame)

	assert(minigame.current_level == 1, "Initial level must be 1")
	assert(minigame.bottles.size() == 8, "Minigame must have 8 bottles in level 1")
	assert(minigame.bottles[0].capacity == 3, "Level 1 bottle capacity must be 3 rows")

	# Test Selection
	var b_src: LiquidBottle = minigame.bottles[0] # filled bottle
	minigame._on_bottle_clicked(b_src)
	assert(minigame.selected_bottle == b_src, "Tapped filled bottle must be selected")
	assert(b_src.is_selected == true, "Bottle selection state must be true")

	# Deselect
	minigame._on_bottle_clicked(b_src)
	assert(minigame.selected_bottle == null, "Tapping same bottle must deselect")
	assert(b_src.is_selected == false, "Bottle selection state must be false")

	# Test Pour to Empty Bottle
	var b_dst: LiquidBottle = minigame.bottles[6] # empty bottle
	minigame._on_bottle_clicked(b_src)
	var top_c: String = b_src.get_top_color()
	var prev_src_size: int = b_src.layers.size()

	# Execute instant pour logic test
	assert(b_dst.can_receive_from(b_src) == true, "b_dst should be able to receive from b_src")
	minigame._execute_pour(b_src, b_dst)
	assert(minigame.undo_stack.size() == 1, "Move must be recorded on undo_stack")
	minigame.is_pouring = false


	# Test Undo
	# Wait brief frame for simulation then test undo
	minigame.undo_stack.clear()
	var test_record: Dictionary = {
		"source_idx": 0,
		"target_idx": 6,
		"source_layers": ["orange", "sky_blue", "lime_green"],
		"target_layers": []
	}
	minigame.undo_stack.append(test_record)
	minigame._on_undo_pressed()
	assert(minigame.bottles[0].layers.size() == 3, "Source layers must be restored after undo")
	assert(minigame.bottles[6].layers.is_empty(), "Target layers must be restored to empty after undo")

	# Test Adding Extra Bottle (+1 Bottle tool)
	var initial_b_count: int = minigame.bottles.size()
	minigame._on_add_bottle_pressed()
	assert(minigame.bottles.size() == initial_b_count + 1, "Adding bottle must increase bottle count by 1")
	assert(minigame.bottles[minigame.bottles.size() - 1].is_empty_bottle() == true, "New bottle must be empty")


	# Test Orientation change
	minigame.apply_orientation(true) # Landscape
	assert(minigame.is_landscape_mode == true, "Minigame must support landscape mode")
	minigame.apply_orientation(false) # Portrait
	assert(minigame.is_landscape_mode == false, "Minigame must support portrait mode")

	minigame.queue_free()
	print("[OK] LiquidSortMinigame Scene verified!")

	# 6. Test MinigameSelectionModal & Integration with MainGame
	print("\n--- 6. Testing MinigameSelectionModal & MainGame Integration ---")
	var modal_scene: PackedScene = load("res://scenes/minigame_selection_modal.tscn")
	var modal: MinigameSelectionModal = modal_scene.instantiate()
	add_child(modal)

	assert(is_instance_valid(modal.liquid_sort_btn), "Selection modal must have liquid_sort_btn")
	var liquid_card_label: Label = modal.get_node("Panel/VBox/ScrollContainer/CardsContainer/LiquidSortCard/Margin/HBox/InfoVBox/Name")
	assert(liquid_card_label.text == "Sort the Liquid", "Card name must be 'Sort the Liquid'")
	var liquid_portrait: TextureRect = modal.get_node("Panel/VBox/ScrollContainer/CardsContainer/LiquidSortCard/Margin/HBox/Portrait")
	assert(liquid_portrait.texture != null and liquid_portrait.texture.resource_path.contains("bottle/normal.png"), "Card must use bottle/normal.png")

	# Test signal firing on Play button
	var liquid_signal_fired := [false]
	GameEvents.request_liquid_sort_open.connect(func(): liquid_signal_fired[0] = true)
	modal.liquid_sort_btn.pressed.emit()
	assert(liquid_signal_fired[0] == true, "Pressing liquid sort Play button must emit request_liquid_sort_open")
	modal.queue_free()

	# Test Main Scene Launching Liquid Sort
	var main_scene: PackedScene = load("res://main.tscn")
	var main_inst: MainGame = main_scene.instantiate()
	add_child(main_inst)

	assert(main_inst.board.visible == true, "Normal merge board must initially be visible")
	assert(main_inst.is_minigame_active == false, "Minigame must initially be inactive")

	# Open Sort the Liquid via GameEvents
	GameEvents.request_liquid_sort_open.emit()
	assert(main_inst.is_minigame_active == true, "Minigame must be active after requesting liquid sort")
	assert(main_inst.active_minigame_id == "liquid_sort", "Active minigame ID must be 'liquid_sort'")
	assert(main_inst.board.visible == false, "Merge board must be hidden")
	assert(is_instance_valid(main_inst.minigame_instance), "Minigame instance must be created")
	assert(main_inst.minigame_instance is LiquidSortMinigame, "Minigame instance must be LiquidSortMinigame")

	# Test exiting minigame
	main_inst.minigame_instance.exit_requested.emit()
	assert(main_inst.is_minigame_active == false, "Minigame must be closed after exit_requested")
	assert(main_inst.board.visible == true, "Merge board must be restored")

	main_inst.queue_free()
	print("[OK] MinigameSelectionModal & MainGame Integration verified!")

	print("\n=== ALL SORT THE LIQUID TESTS PASSED SUCCESSFULLY! ===")
	get_tree().quit(0)
