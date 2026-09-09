extends Node

func _ready() -> void:
	print("=== RUNNING TEST: NEW MERGE GAME FEATURES ===")

	# 1. Test InventoryManager
	print("\n--- Testing InventoryManager ---")
	InventoryManager.clear_all()
	assert(InventoryManager.get_used_count() == 0, "Initial inventory should be empty")
	assert(InventoryManager.has_free_slot() == true, "Initial inventory should have free slots")

	var added := InventoryManager.add_item("tools_1")
	assert(added == true, "Should add tools_1")
	assert(InventoryManager.get_used_count() == 1, "Used slots should be 1")
	assert(InventoryManager.get_item_id_at(0) == "tools_1", "Slot 0 should have tools_1")

	# Fill inventory to 8
	for i in range(7):
		InventoryManager.add_item("plant_%d" % (i % 3 + 1))
	assert(InventoryManager.get_used_count() == 8, "Inventory should be full at 8")
	assert(InventoryManager.has_free_slot() == false, "Inventory should not have free slots")
	assert(InventoryManager.add_item("gem_1") == false, "Adding to full inventory should fail")

	# Remove item
	var removed := InventoryManager.remove_item_at(0)
	assert(removed == "tools_1", "Removed item should be tools_1")
	assert(InventoryManager.get_used_count() == 7, "Used slots should be 7")
	assert(InventoryManager.has_free_slot() == true, "Inventory should now have a free slot")
	print("✔ InventoryManager test passed!")

	# 2. Test ProgressionManager
	print("\n--- Testing ProgressionManager ---")
	assert(ProgressionManager.is_unlocked("tools_1") == false, "tools_1 should initially be locked")
	var newly_unlocked := ProgressionManager.unlock_item("tools_1")
	assert(newly_unlocked == true, "unlock_item should return true on first unlock")
	assert(ProgressionManager.is_unlocked("tools_1") == true, "tools_1 should now be unlocked")
	assert(ProgressionManager.is_claimed("tools_1") == false, "Reward should not be claimed yet")
	assert(ProgressionManager.get_unclaimed_count() >= 1, "Unclaimed count should be >= 1")

	# Claim reward
	var initial_coins: int = EconomyManager.coins
	var reward: Dictionary = ProgressionManager.claim_reward("tools_1")
	assert(reward.coins > 0, "Reward coins should be > 0")
	assert(EconomyManager.coins == initial_coins + reward.coins, "Coins should be credited to EconomyManager")
	assert(ProgressionManager.is_claimed("tools_1") == true, "Reward should now be claimed")
	print("✔ ProgressionManager test passed!")

	# 3. Test Shop purchases
	print("\n--- Testing Shop Purchases ---")
	EconomyManager.coins = 100
	EconomyManager.energy = 20

	# Refill energy with coins
	var spent := EconomyManager.spend_coins(25)
	assert(spent == true, "Spend coins should succeed")
	EconomyManager.add_energy(25)
	assert(EconomyManager.energy == 45, "Energy should be 45 after +25 refill")
	assert(EconomyManager.coins == 75, "Coins should be 75 after spending 25")
	print("✔ Shop economy test passed!")

	# 4. Test New Egg and Leaf Item Registrations
	print("\n--- Testing Egg & Leaf Item Registrations ---")
	var leaf_ids := ["leaf_1", "leaf_2", "leaf_3", "leaf_4", "leaf_5"]
	for id in leaf_ids:
		var it: ItemData = ItemDatabase.get_item(id)
		assert(it != null, "Item %s must be registered in ItemDatabase" % id)
		assert(it.icon_texture != null, "Item %s must have an icon_texture" % id)
		assert(it.icon_texture is Texture2D, "Item %s icon_texture must be a Texture2D" % id)
		assert(it.chain_id == "leaf", "Item %s chain_id must be 'leaf'" % id)

	assert(ItemDatabase.get_item("leaf_1").get_next_tier_id() == "leaf_2", "leaf_1 next tier should be leaf_2")
	assert(ItemDatabase.get_item("leaf_4").get_next_tier_id() == "leaf_5", "leaf_4 next tier should be leaf_5")
	assert(ItemDatabase.get_item("leaf_5").get_next_tier_id() == "", "leaf_5 is max tier, next should be empty")

	var egg_ids := ["egg_1", "egg_2", "egg_3", "egg_4", "egg_5", "egg_6"]
	for id in egg_ids:
		var it: ItemData = ItemDatabase.get_item(id)
		assert(it != null, "Item %s must be registered in ItemDatabase" % id)
		assert(it.icon_texture != null, "Item %s must have an icon_texture" % id)
		assert(it.icon_texture is Texture2D, "Item %s icon_texture must be a Texture2D" % id)
		assert(it.chain_id == "egg", "Item %s chain_id must be 'egg'" % id)

	assert(ItemDatabase.get_item("egg_1").get_next_tier_id() == "egg_2", "egg_1 next tier should be egg_2")
	assert(ItemDatabase.get_item("egg_5").get_next_tier_id() == "egg_6", "egg_5 next tier should be egg_6")
	assert(ItemDatabase.get_item("egg_6").get_next_tier_id() == "", "egg_6 is max tier, next should be empty")

	var egg_tub: ItemData = ItemDatabase.get_item("egg_6")
	assert(egg_tub.is_spawner == true, "egg_6 (Egg Tub) should be a spawner")
	assert(egg_tub.energy_cost == 1, "egg_6 should consume 1 energy")
	assert(egg_tub.spawn_pool.has("egg_1"), "egg_6 spawn pool should have egg_1")
	assert(egg_tub.spawn_pool.has("leaf_1"), "egg_6 spawn pool should have leaf_1")
	print("✔ Egg and Leaf item registrations verified!")

	# 5. Test ItemView Visuals & Dynamic Scaling
	print("\n--- Testing ItemView Texture and Dynamic Scaling ---")
	var item_view_scene: PackedScene = load("res://scenes/item_view.tscn")
	var leaf_view: ItemView = item_view_scene.instantiate()
	add_child(leaf_view)
	leaf_view.setup(ItemDatabase.get_item("leaf_1"))
	var leaf_sprite: Sprite2D = leaf_view.get_node("Visuals/Sprite")
	assert(leaf_sprite.texture == ItemDatabase.get_item("leaf_1").icon_texture, "Leaf sprite texture must match leaf_1 icon_texture")
	assert(leaf_sprite.scale.x > 0.0 and leaf_sprite.scale.x < 0.3, "Leaf sprite scale must be dynamically scaled down for 500px textures")
	leaf_view.queue_free()
	print("✔ ItemView dynamic scaling verified!")

	# 6. Test Main Scene & Background Setup
	print("\n--- Testing Main Scene Background Setup ---")
	var main_scene: PackedScene = load("res://main.tscn")
	var main_inst: Node = main_scene.instantiate()
	add_child(main_inst)

	var bg_layer: CanvasLayer = main_inst.get_node_or_null("BackgroundLayer")
	assert(bg_layer != null, "BackgroundLayer must exist in main.tscn")
	assert(bg_layer.layer == -1, "BackgroundLayer should have layer = -1")

	var bg_rect: TextureRect = bg_layer.get_node_or_null("Background")
	assert(bg_rect != null, "Background TextureRect must exist in BackgroundLayer")
	assert(bg_rect.texture != null, "Background texture must not be null")
	assert(bg_rect.texture.resource_path == "res://assets/background.jpeg", "Background texture must be background.jpeg")
	assert(bg_rect.expand_mode == TextureRect.EXPAND_IGNORE_SIZE, "Background expand mode should be EXPAND_IGNORE_SIZE")
	assert(bg_rect.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED, "Background stretch mode should be STRETCH_KEEP_ASPECT_COVERED")

	var overlay: ColorRect = bg_layer.get_node_or_null("Overlay")
	assert(overlay != null, "Overlay scrim must exist for mobile readability")

	main_inst.queue_free()
	print("✔ Main scene background verified!")

	# 7. Test 6x9 Board Dimensions & Configurable Parameters
	print("\n--- Testing 6x9 Board & Visual Parameters ---")
	var board_scene: PackedScene = load("res://scenes/board.tscn")
	var test_board: Board = board_scene.instantiate()
	add_child(test_board)

	assert(test_board.cols == 6, "Board must have 6 columns")
	assert(test_board.rows == 9, "Board must have 9 rows")
	var cells_cnt: int = test_board.get_node("CellsContainer").get_child_count()
	assert(cells_cnt == 54, "Board must have 54 cells (6x9 = 54), got %d" % cells_cnt)

	# Test bounds checking on 6x9 board
	assert(test_board.is_valid_coord(Vector2i(0, 0)) == true, "(0, 0) must be valid")
	assert(test_board.is_valid_coord(Vector2i(5, 8)) == true, "(5, 8) must be valid (max index)")
	assert(test_board.is_valid_coord(Vector2i(6, 0)) == false, "Column 6 must be out of bounds")
	assert(test_board.is_valid_coord(Vector2i(0, 9)) == false, "Row 9 must be out of bounds")
	assert(test_board.is_valid_coord(Vector2i(-1, 0)) == false, "Negative coord must be out of bounds")

	# Test configurable color and opacity parameters
	var initial_board_alpha := test_board.board_bg_color.a
	assert(initial_board_alpha > 0.0, "Board bg color opacity must be configurable")
	test_board.board_bg_color = Color(0.2, 0.3, 0.4, 0.8)
	assert(is_equal_approx(test_board.board_bg_color.a, 0.8), "Board bg alpha must be set to 0.8")

	test_board.tile_bg_color = Color(0.1, 0.5, 0.3, 0.75)
	assert(is_equal_approx(test_board.tile_bg_color.a, 0.75), "Tile bg alpha must be set to 0.75")
	var first_cell: BoardCell = test_board.get_node("CellsContainer").get_child(0)
	assert(first_cell.cell_bg_color == Color(0.1, 0.5, 0.3, 0.75), "BoardCell must receive tile_bg_color")

	test_board.queue_free()
	print("✔ 6x9 Board & Visual Parameters verified!")

	# 8. Test Persistence Save & Restore
	print("\n--- Testing Persistence Save & Restore ---")
	SaveManager.delete_save()
	assert(SaveManager.has_save() == false, "Save file should be deleted")

	# Prepare a test state
	ProgressionManager.unlock_item("tools_3", true)
	ProgressionManager.claim_reward("tools_3")
	EconomyManager.coins = 777
	EconomyManager.gems = 88
	EconomyManager.energy = 55
	InventoryManager.clear_all()
	InventoryManager.add_item("tools_1")
	InventoryManager.add_item("egg_1")
	InventoryManager.set_item_at(5, "leaf_2")

	var save_board: Board = board_scene.instantiate()
	add_child(save_board)
	save_board.clear_board()
	save_board.spawn_item_at(Vector2i(0, 0), "tools_4")
	save_board.spawn_item_at(Vector2i(5, 8), "leaf_3")
	save_board.spawn_item_at(Vector2i(2, 4), "plant_5")
	SaveManager.board_ref = save_board

	# Save game
	var save_ok := SaveManager.save_game(false, false)
	assert(save_ok == true, "SaveManager.save_game should succeed")
	assert(SaveManager.has_save() == true, "Save file should now exist")

	var save_info := SaveManager.get_save_info()
	assert(save_info.coins == 777, "Saved coins should match 777")
	assert(save_info.gems == 88, "Saved gems should match 88")
	assert(save_info.energy == 55, "Saved energy should match 55")

	# Reset state to test restore
	EconomyManager.reset_all()
	InventoryManager.clear_all()
	ProgressionManager.reset_all()
	save_board.clear_board()

	assert(EconomyManager.coins != 777, "Coins should be reset")
	assert(InventoryManager.get_used_count() == 0, "Inventory should be empty after reset")
	assert(save_board.get_all_items_on_board().is_empty(), "Board should be empty after clear")

	# Load game
	var load_ok := SaveManager.load_game(save_board)
	assert(load_ok == true, "SaveManager.load_game should succeed")

	assert(EconomyManager.coins == 777, "Restored coins should be 777")
	assert(EconomyManager.gems == 88, "Restored gems should be 88")
	assert(EconomyManager.energy == 55, "Restored energy should be 55")
	assert(InventoryManager.get_item_id_at(0) == "tools_1", "Slot 0 should be tools_1")
	assert(InventoryManager.get_item_id_at(1) == "egg_1", "Slot 1 should be egg_1")
	assert(InventoryManager.get_item_id_at(5) == "leaf_2", "Slot 5 should be leaf_2")
	assert(ProgressionManager.is_unlocked("tools_3") == true, "tools_3 should be unlocked")
	assert(ProgressionManager.is_claimed("tools_3") == true, "tools_3 reward should be claimed")

	assert(save_board.get_item_at(Vector2i(0, 0)) != null, "Item at (0, 0) should exist")
	assert(save_board.get_item_at(Vector2i(0, 0)).data.id == "tools_4", "Item at (0, 0) should be tools_4")
	assert(save_board.get_item_at(Vector2i(5, 8)) != null, "Item at (5, 8) should exist")
	assert(save_board.get_item_at(Vector2i(5, 8)).data.id == "leaf_3", "Item at (5, 8) should be leaf_3")
	assert(save_board.get_item_at(Vector2i(2, 4)) != null, "Item at (2, 4) should exist")
	assert(save_board.get_item_at(Vector2i(2, 4)).data.id == "plant_5", "Item at (2, 4) should be plant_5")

	save_board.queue_free()
	SaveManager.board_ref = null
	print("✔ Persistence Save & Restore verified!")

	# 9. Test Auto-Save & Toast Notification
	print("\n--- Testing Auto-Save & Toast Notification ---")
	assert(SaveManager.AUTO_SAVE_INTERVAL == 900.0, "Auto-save interval must be 15 minutes (900 seconds)")
	var toast_received := {"msg": ""}
	var on_toast := func(msg: String, _dur: float):
		toast_received["msg"] = msg
	SaveManager.toast_requested.connect(on_toast)

	SaveManager.trigger_auto_save()
	assert(toast_received["msg"].begins_with("Saving, please do not exit the game"), "Auto-save toast message must say 'Saving, please do not exit the game...', got '%s'" % toast_received["msg"])
	SaveManager.toast_requested.disconnect(on_toast)
	print("✔ Auto-Save & Toast Notification verified!")

	# 10. Test Option Modal & SFX
	print("\n--- Testing Option Modal & SFX Toggle ---")
	var option_scene: PackedScene = load("res://scenes/option_modal.tscn")
	var option_inst: OptionModal = option_scene.instantiate()
	add_child(option_inst)

	var orig_sfx := SoundManager.sfx_enabled
	option_inst._on_sfx_pressed()
	assert(SoundManager.sfx_enabled == not orig_sfx, "SFX toggle must toggle SoundManager.sfx_enabled")
	option_inst._on_sfx_pressed()
	assert(SoundManager.sfx_enabled == orig_sfx, "SFX toggle must restore state")

	# Test manual save from OptionModal
	option_inst._on_save_pressed()
	assert(option_inst.status_label.text.contains("successfully"), "Option modal status label should indicate success")

	option_inst.queue_free()
	print("✔ Option Modal & SFX Toggle verified!")

	# 11. Test Main Menu Scene
	print("\n--- Testing Main Menu Scene ---")
	var menu_scene: PackedScene = load("res://scenes/main_menu.tscn")
	var menu_inst: MainMenu = menu_scene.instantiate()
	add_child(menu_inst)

	assert(menu_inst.continue_btn != null, "ContinueBtn must exist in MainMenu")
	assert(menu_inst.new_game_btn != null, "NewGameBtn must exist in MainMenu")
	assert(menu_inst.options_btn != null, "OptionsBtn must exist in MainMenu")
	assert(menu_inst.quit_btn != null, "QuitBtn must exist in MainMenu")
	assert(menu_inst.continue_btn.disabled == false, "Continue button should be enabled when save exists")

	# Verify with no save
	SaveManager.delete_save()
	menu_inst._update_save_state()
	assert(menu_inst.continue_btn.disabled == true, "Continue button should be disabled when no save exists")

	menu_inst.queue_free()
	print("✔ Main Menu Scene verified!")

	print("\n=== ALL TESTS PASSED SUCCESSFULLY! ===")
	get_tree().quit(0)

