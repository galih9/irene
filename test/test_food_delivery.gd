extends Node

const LevelDB = preload("res://scripts/minigame/delivery_level_database.gd")
const ItemComponent = preload("res://scripts/minigame/food_delivery_item.gd")
const MinigameScene = preload("res://scenes/minigame/food_delivery_minigame.tscn")

func _ready() -> void:
	SaveManager.save_file_path = "res://test_savegame.json"

	print("\n=======================================================")
	print("    RUNNING FOOD DELIVERY RUSH MINIGAME TEST SUITE")
	print("=======================================================\n")


	# 1. Test DeliveryLevelDatabase
	print("--- 1. Testing DeliveryLevelDatabase (10 Levels) ---")
	assert(LevelDB.get_total_levels() == 10, "Total levels must be exactly 10")
	var all_levels := LevelDB.get_all_levels()
	assert(all_levels.size() == 10, "get_all_levels must return 10 levels")

	for i in range(1, 11):
		var lvl: Dictionary = LevelDB.get_level(i)
		assert(lvl.get("level") == i, "Level %d must have matching level number" % i)
		assert(not lvl.get("title", "").is_empty(), "Level %d must have title" % i)
		assert(lvl.get("time_limit", 0) > 0, "Level %d must have positive time limit" % i)
		var orders: Array = lvl.get("orders", [])
		assert(not orders.is_empty(), "Level %d must have orders" % i)
		var stacks: Array = lvl.get("stacks", [])
		assert(not stacks.is_empty(), "Level %d must have stacks" % i)

		# Total items across all stacks must equal orders.size() * 3
		var total_items := 0
		for st in stacks:
			total_items += st.size()
		assert(total_items == orders.size() * 3, "Level %d item count (%d) must equal orders * 3 (%d)" % [i, total_items, orders.size() * 3])

		# For levels >= 2, columns must be distinct (no duplicate triplet clones)
		if i >= 2:
			for ci in range(stacks.size()):
				for cj in range(ci + 1, stacks.size()):
					assert(stacks[ci] != stacks[cj], "Level %d columns %d and %d must not be identical clones" % [i, ci, cj])

		# Verify mathematical solvability with built-in solver
		var solve_res: Dictionary = LevelDB.solve_level(orders, stacks, 7)
		assert(solve_res.get("solvable", false) == true, "Level %d must be 100%% mathematically solvable within 7 temp slots" % i)
		var peak_slots: int = solve_res.get("peak_temp", 0)

		print("  [✓] Level %d: '%s' (%d orders, %d stacks, %ds, peak temp: %d slots) verified solvable!" % [i, lvl["title"], orders.size(), stacks.size(), lvl["time_limit"], peak_slots])

	# Test Procedural Generator for higher level
	var lvl11: Dictionary = LevelDB.get_level(11)
	assert(lvl11.get("level") == 11, "Procedural level 11 must have level number 11")
	assert(lvl11.get("orders", []).size() >= 8, "Procedural level 11 must have at least 8 orders")
	assert(LevelDB.solve_level(lvl11["orders"], lvl11["stacks"], 7).get("solvable", false) == true, "Procedural level 11 must be solvable")
	print("  [✓] Procedural level generator beyond level 10 verified solvable!")

	# 2. Test Food Items in ItemDatabase
	print("\n--- 2. Testing Food Items Availability ---")
	var test_food_ids := [
		"bakery_6", "sweets_2", "healthy_3", "drinks_2",
		"grill_2", "bakery_3", "sweets_5", "grill_3"
	]
	for fid in test_food_ids:
		var it: ItemData = ItemDatabase.get_item(fid)
		assert(it != null, "Item %s must exist in ItemDatabase" % fid)
		assert(it.icon_texture != null, "Item %s must have icon_texture" % fid)
		print("  [✓] Food %s: '%s' (Texture OK)" % [fid, it.display_name])

	# 3. Test FoodDeliveryItem Component
	print("\n--- 3. Testing FoodDeliveryItem Component ---")
	var tile := ItemComponent.new("bakery_6")
	add_child(tile)
	assert(tile.item_id == "bakery_6", "Item ID must match")
	tile.set_topmost(true)
	assert(tile.is_topmost == true, "Tile must be marked topmost")
	assert(tile.mouse_filter == Control.MOUSE_FILTER_STOP, "Topmost item must stop mouse filter")
	tile.set_topmost(false)
	assert(tile.is_topmost == false, "Tile must be marked not topmost")
	assert(tile.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Dimmed item must ignore mouse filter")
	tile.queue_free()
	print("  [✓] FoodDeliveryItem component visual & interaction logic verified!")

	# 4. Test ProgressionManager Integration
	print("\n--- 4. Testing ProgressionManager Integration ---")
	assert(ProgressionManager.delivery_max_unlocked_level >= 1, "Default unlocked delivery level must be at least 1")
	ProgressionManager.unlock_delivery_level(2)
	assert(ProgressionManager.delivery_max_unlocked_level >= 2, "Level 2 should now be unlocked")
	print("  [✓] ProgressionManager delivery_max_unlocked_level = %d verified!" % ProgressionManager.delivery_max_unlocked_level)

	# 5. Test FoodDeliveryMinigame Scene & Gameplay
	print("\n--- 5. Testing FoodDeliveryMinigame Scene & Gameplay ---")
	var minigame: FoodDeliveryMinigame = MinigameScene.instantiate()
	add_child(minigame)
	assert(minigame != null, "Minigame must instantiate cleanly")

	# Start level 1
	minigame.start_level(1)
	assert(minigame.current_level == 1, "Current level must be 1")
	assert(minigame.is_game_active == true, "Game must be active")
	assert(minigame.current_order_item == "bakery_6", "Level 1 first order must be bakery_6")
	assert(minigame.delivery_slots.size() == 3, "Must have 3 delivery slots")
	assert(minigame.temp_slots.size() == 7, "Must have 7 temporary slots")
	assert(minigame.stack_columns.size() == 3, "Level 1 must have 3 stack columns")

	# In Level 1, each of the 3 stacks has bakery_6 on top
	var col0_top: FoodDeliveryItem = minigame.stack_columns[0].back()
	assert(col0_top.item_id == "bakery_6", "Top item of column 0 must be bakery_6")

	# Test Click on topmost item
	var mb_down := InputEventMouseButton.new()
	mb_down.button_index = MOUSE_BUTTON_LEFT
	mb_down.pressed = true
	mb_down.global_position = col0_top.global_position + Vector2(20, 20)
	col0_top._on_gui_input(mb_down)

	var mb_up := InputEventMouseButton.new()
	mb_up.button_index = MOUSE_BUTTON_LEFT
	mb_up.pressed = false
	mb_up.global_position = col0_top.global_position + Vector2(20, 20)
	col0_top._on_gui_input(mb_up)

	assert(minigame.current_order_filled == 1, "Clicking matching topmost item must fill delivery slot (current_order_filled should be 1)")
	print("  [✓] Direct click/tap on topmost item successfully delivered to box!")
	await get_tree().create_timer(0.3).timeout

	# Test Drag on topmost item of column 1
	var col1_top: FoodDeliveryItem = minigame.stack_columns[1].back()
	assert(col1_top.item_id == "bakery_6", "Top item of column 1 must be bakery_6")

	var drag_down := InputEventMouseButton.new()
	drag_down.button_index = MOUSE_BUTTON_LEFT
	drag_down.pressed = true
	drag_down.global_position = col1_top.global_position + Vector2(20, 20)
	col1_top._on_gui_input(drag_down)

	var drag_move := InputEventMouseMotion.new()
	drag_move.global_position = col1_top.global_position + Vector2(20, 40)
	col1_top._on_gui_input(drag_move)
	assert(col1_top.is_dragging == true, "Moving mouse past threshold must start dragging")

	# Release over delivery box
	var drag_up := InputEventMouseButton.new()
	drag_up.button_index = MOUSE_BUTTON_LEFT
	drag_up.pressed = false
	drag_up.global_position = minigame.delivery_box_panel.global_position + Vector2(50, 50)
	col1_top._on_gui_input(drag_up)

	assert(minigame.current_order_filled == 2, "Dragging matching item onto delivery box must fill slot (current_order_filled should be 2)")
	print("  [✓] Dragging item from stack onto delivery box successfully delivered to box!")

	await get_tree().create_timer(0.35).timeout

	# Complete the set with 3rd item from column 2
	var col2_top: FoodDeliveryItem = minigame.stack_columns[2].back()
	assert(col2_top.item_id == "bakery_6", "Top item of column 2 must be bakery_6")

	var mb2_down := InputEventMouseButton.new()
	mb2_down.button_index = MOUSE_BUTTON_LEFT
	mb2_down.pressed = true
	mb2_down.global_position = col2_top.global_position + Vector2(20, 20)
	col2_top._on_gui_input(mb2_down)

	var mb2_up := InputEventMouseButton.new()
	mb2_up.button_index = MOUSE_BUTTON_LEFT
	mb2_up.pressed = false
	mb2_up.global_position = col2_top.global_position + Vector2(20, 20)
	col2_top._on_gui_input(mb2_up)

	# Wait for delivery completion animation and sound
	await get_tree().create_timer(0.4).timeout
	assert(minigame.orders_completed_count == 1, "Completed order count must be 1")
	print("  [✓] Complete set packed without errors! _on_delivery_box_completed verified!")


	# 6. Test UX Polish: Modal Centering, Neat Board Layout & Top-To-Bottom Stacking
	print("\n--- 6. Testing UX Polish: Modal Centering, Neat Layout & Top-To-Bottom Stacking ---")
	minigame.start_level(1)

	# Verify Top-to-Bottom stacking & neat horizontal centering in column
	var col0: Array = minigame.stack_columns[0]
	assert(col0.size() == 3, "Column 0 must have 3 items initially")
	var top_item: FoodDeliveryItem = col0.back() # index 2
	var mid_item: FoodDeliveryItem = col0[1]     # index 1
	var bot_item: FoodDeliveryItem = col0[0]     # index 0

	assert(top_item.item_id == "bakery_6", "Top item must be bakery_6")
	assert(mid_item.item_id == "sweets_2", "Middle item must be sweets_2")
	assert(bot_item.item_id == "healthy_3", "Bottom item must be healthy_3")

	# Top item must be physically higher (lower Y) on screen than middle item, and middle higher than bottom
	assert(top_item.position.y < mid_item.position.y, "Top item must be vertically higher on screen than middle item (top-to-bottom)")
	assert(mid_item.position.y < bot_item.position.y, "Middle item must be vertically higher on screen than bottom item (top-to-bottom)")
	assert(top_item.z_index > mid_item.z_index, "Top item must have higher z_index than middle item to layer neatly")
	assert(mid_item.z_index > bot_item.z_index, "Middle item must have higher z_index than bottom item to layer neatly")

	# Items must be horizontally centered in column
	assert(is_equal_approx(top_item.position.x, 4.0), "Top item must be horizontally centered in 80px column (x=4)")
	assert(is_equal_approx(mid_item.position.x, 4.0), "Middle item must be horizontally centered in 80px column (x=4)")

	# Column must have track background
	var col_ctrl: Control = top_item.get_parent() as Control
	assert(col_ctrl.has_node("TrackBg"), "Column control must have TrackBg panel")

	# Stacks must be housed inside centered playfield board
	assert(minigame.stacks_container.get_parent().get_parent().name == "PlayfieldBoard", "StacksContainer must be framed in PlayfieldBoard")

	# Verify Modal Centering Architecture
	minigame._trigger_win()
	assert(minigame.win_modal_layer.visible == true, "Win modal layer must be visible when triggered")
	assert(minigame.win_modal.visible == true, "Win modal panel must be visible")
	assert(minigame.win_modal.get_parent() is CenterContainer, "Win modal must be inside CenterContainer for guaranteed centering")
	assert(minigame.win_modal_layer.has_node("Dimmer"), "Win modal layer must have a Dimmer backdrop")
	assert(minigame.game_over_modal.get_parent() is CenterContainer, "GameOverModal must be inside CenterContainer")
	assert(minigame.level_select_modal.has_node("Center"), "LevelSelectModal must have CenterContainer")
	print("  [✓] Top-to-bottom stacking, column centering, neat board tray & modal centering verified!")


	# Clean up
	minigame.queue_free()
	if FileAccess.file_exists("res://test_savegame.json"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("res://test_savegame.json"))

	print("\n=======================================================")
	print("    ALL TESTS PASSED SUCCESSFULLY! (100% OK)")
	print("=======================================================\n")
	get_tree().quit(0)

