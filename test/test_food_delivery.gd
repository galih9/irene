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
		print("  [✓] Level %d: '%s' (%d orders, %d stacks, %ds, %d items) verified!" % [i, lvl["title"], orders.size(), stacks.size(), lvl["time_limit"], total_items])

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


	# Test reward queue filling (Requirement 5)
	var prev_reward_count := ProgressionManager.get_reward_count()
	var test_reward := minigame._roll_random_reward()
	assert(not test_reward.is_empty(), "Rolled reward must not be empty")
	ProgressionManager.push_reward(test_reward)
	assert(ProgressionManager.get_reward_count() == prev_reward_count + 1, "Reward queue count must increment")
	assert(ProgressionManager.peek_reward() != "", "Reward queue must have pending item")
	print("  [✓] Reward roll and temporary slot push (%s) verified!" % test_reward)


	# Clean up
	minigame.queue_free()
	if FileAccess.file_exists("res://test_savegame.json"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("res://test_savegame.json"))

	print("\n=======================================================")
	print("    ALL TESTS PASSED SUCCESSFULLY! (100% OK)")
	print("=======================================================\n")
	get_tree().quit(0)

