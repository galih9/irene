extends Node

func _ready() -> void:
	print("=== RUNNING TEST: NEW MERGE GAME FEATURES ===")

	# 1. Test InventoryManager
	print("\n--- Testing InventoryManager ---")
	InventoryManager.clear_all()
	assert(InventoryManager.get_used_count() == 0, "Initial inventory should be empty")
	assert(InventoryManager.has_free_slot() == true, "Initial inventory should have free slots")

	var added := InventoryManager.add_item("egg_1")
	assert(added == true, "Should add egg_1")
	assert(InventoryManager.get_used_count() == 1, "Used slots should be 1")
	assert(InventoryManager.get_item_id_at(0) == "egg_1", "Slot 0 should have egg_1")

	# Fill inventory to 8
	for i in range(7):
		InventoryManager.add_item("leaf_%d" % (i % 3 + 1))
	assert(InventoryManager.get_used_count() == 8, "Inventory should be full at 8")
	assert(InventoryManager.has_free_slot() == false, "Inventory should not have free slots")
	assert(InventoryManager.add_item("beef_1") == false, "Adding to full inventory should fail")

	# Remove item
	var removed := InventoryManager.remove_item_at(0)
	assert(removed == "egg_1", "Removed item should be egg_1")
	assert(InventoryManager.get_used_count() == 7, "Used slots should be 7")
	assert(InventoryManager.has_free_slot() == true, "Inventory should now have a free slot")
	print("✔ InventoryManager test passed!")

	# 2. Test ProgressionManager & EXP / Leveling
	print("\n--- Testing ProgressionManager & Player Level ---")
	ProgressionManager.reset_all()
	assert(ProgressionManager.player_level == 1, "Initial player level must be 1")
	assert(ProgressionManager.player_exp == 0, "Initial player exp must be 0")
	assert(ProgressionManager.get_current_level_req() == 10, "Level 1 requirement should be 10 exp")

	# Add exp without leveling up
	ProgressionManager.add_exp(4)
	assert(ProgressionManager.player_level == 1, "Player should remain Level 1 at 4 exp")
	assert(ProgressionManager.player_exp == 4, "Player exp should be 4")

	# Add exp to trigger level up
	var prev_energy := EconomyManager.energy
	ProgressionManager.add_exp(8) # total 12 exp -> levels up to 2, 2 leftover
	assert(ProgressionManager.player_level == 2, "Player should level up to Level 2")
	assert(ProgressionManager.player_exp == 2, "Leftover exp should be 2")
	assert(EconomyManager.energy >= prev_energy, "Level up should reward energy")

	# Test discovery reward
	assert(ProgressionManager.is_unlocked("cake_1") == false, "cake_1 should initially be locked")
	var newly_unlocked := ProgressionManager.unlock_item("cake_1")
	assert(newly_unlocked == true, "unlock_item should return true on first unlock")
	assert(ProgressionManager.is_unlocked("cake_1") == true, "cake_1 should now be unlocked")
	assert(ProgressionManager.is_claimed("cake_1") == false, "Reward should not be claimed yet")

	var reward: Dictionary = ProgressionManager.claim_reward("cake_1")
	assert(reward.coins > 0, "Reward coins should be > 0")
	assert(reward.exp > 0, "Reward exp should be > 0")
	assert(ProgressionManager.is_claimed("cake_1") == true, "Reward should now be claimed")
	print("✔ ProgressionManager & Player Level test passed!")

	# 3. Test Shop Purchases
	print("\n--- Testing Shop Purchases ---")
	EconomyManager.coins = 100
	EconomyManager.energy = 20

	var spent := EconomyManager.spend_coins(25)
	assert(spent == true, "Spend coins should succeed")
	EconomyManager.add_energy(25)
	assert(EconomyManager.energy == 45, "Energy should be 45 after +25 refill")
	assert(EconomyManager.coins == 75, "Coins should be 75 after spending 25")
	print("✔ Shop economy test passed!")

	# 4. Test All 15 Item Chains Registration
	print("\n--- Testing 15 Item Chains & Textures ---")
	var chains_info := [
		{"id": "foodbox", "tiers": 6, "spawner": true},
		{"id": "oven", "tiers": 6, "spawner": true},
		{"id": "fridge", "tiers": 6, "spawner": true},
		{"id": "rack", "tiers": 7, "spawner": true},
		{"id": "egg", "tiers": 6, "spawner": false},
		{"id": "leaf", "tiers": 5, "spawner": false},
		{"id": "beef", "tiers": 7, "spawner": false},
		{"id": "cake", "tiers": 6, "spawner": false},
		{"id": "sandwich", "tiers": 6, "spawner": false},
		{"id": "drink", "tiers": 5, "spawner": false},
		{"id": "util", "tiers": 12, "spawner": false},
		{"id": "exp", "tiers": 10, "spawner": false, "consumable": true, "curr": "exp"},
		{"id": "gold", "tiers": 8, "spawner": false, "consumable": true, "curr": "coins"},
		{"id": "energy", "tiers": 8, "spawner": false, "consumable": true, "curr": "energy"},
		{"id": "diamond", "tiers": 7, "spawner": false, "consumable": true, "curr": "gems"}
	]

	var total_items_checked := 0
	for ch in chains_info:
		var chain_id: String = ch.id
		var max_t: int = ch.tiers
		for t in range(1, max_t + 1):
			var item_id := "%s_%d" % [chain_id, t]
			var it: ItemData = ItemDatabase.get_item(item_id)
			assert(it != null, "Item %s must be registered in ItemDatabase" % item_id)
			assert(it.icon_texture != null, "Item %s must have an icon_texture" % item_id)
			assert(it.icon_texture is Texture2D, "Item %s icon_texture must be Texture2D" % item_id)
			assert(it.icon_texture.resource_path != "res://icon.svg", "Item %s must not use godot icon.svg" % item_id)
			assert(it.chain_id == chain_id, "Item %s chain_id mismatch" % item_id)
			assert(it.tier == t, "Item %s tier mismatch" % item_id)
			assert(it.max_tier == max_t, "Item %s max_tier mismatch" % item_id)

			if ch.spawner:
				if t >= 3:
					assert(it.is_spawner == true, "%s (tier %d >= 3) must be a spawner" % [item_id, t])
					assert(it.spawn_pool.size() > 0, "%s spawn_pool must not be empty" % item_id)
				else:
					assert(it.is_spawner == false, "%s (tier %d < 3) must NOT be a spawner" % [item_id, t])

			if ch.get("consumable", false):
				assert(it.is_consumable == true, "%s must be consumable" % item_id)
				assert(it.consume_currency == ch.curr, "%s currency mismatch" % item_id)
				assert(it.consume_amount > 0, "%s consume amount must be > 0" % item_id)

			# Verify next tier ID
			if t < max_t:
				assert(it.get_next_tier_id() == "%s_%d" % [chain_id, t + 1], "Next tier mismatch for %s" % item_id)
			else:
				assert(it.get_next_tier_id() == "", "Max tier item %s must return empty next tier" % item_id)

			total_items_checked += 1

	assert(total_items_checked == 105, "Expected exactly 105 items, checked %d" % total_items_checked)
	print("✔ All 15 item chains (105 items) successfully verified!")

	# 5. Test HUD UI Currency & Level Sprites
	print("\n--- Testing HUD UI Elements & Sprites ---")
	var hud_scene: PackedScene = load("res://scenes/hud.tscn")
	var hud_inst: HUD = hud_scene.instantiate()
	add_child(hud_inst)

	var level_icon: TextureRect = hud_inst.get_node("Margin/HBox/LevelBox/Margin/HBox/Icon")
	assert(level_icon.texture != null, "Level icon texture must exist")
	assert(level_icon.texture.resource_path == "res://assets/exp/exp1.png", "Level symbol must be exp1.png")

	var energy_icon: TextureRect = hud_inst.get_node("Margin/HBox/EnergyBox/Margin/HBox/Icon")
	assert(energy_icon.texture != null, "Energy icon texture must exist")
	assert(energy_icon.texture.resource_path == "res://assets/energy/energy_1.png", "Energy symbol must be energy_1.png")

	var gold_icon: TextureRect = hud_inst.get_node("Margin/HBox/CoinsBox/Margin/HBox/Icon")
	assert(gold_icon.texture != null, "Gold icon texture must exist")
	assert(gold_icon.texture.resource_path == "res://assets/gold/gold1.png", "Gold symbol must be gold1.png")

	var diamond_icon: TextureRect = hud_inst.get_node("Margin/HBox/GemsBox/Margin/HBox/Icon")
	assert(diamond_icon.texture != null, "Diamond icon texture must exist")
	assert(diamond_icon.texture.resource_path == "res://assets/diamond/diamond_1.png", "Diamond symbol must be diamond_1.png")

	var shop_btn: Button = hud_inst.get_node("Margin/HBox/ButtonsBox/ShopBtn")
	assert(shop_btn.icon != null, "ShopBtn icon must exist")
	assert(shop_btn.icon.resource_path == "res://assets/icon/icon_shop.png", "ShopBtn must use icon_shop.png")

	var options_btn: Button = hud_inst.get_node("Margin/HBox/ButtonsBox/OptionsBtn")
	assert(options_btn.icon != null, "OptionsBtn icon must exist")
	assert(options_btn.icon.resource_path == "res://assets/icon/icon_gear.png", "OptionsBtn must use icon_gear.png")

	hud_inst.queue_free()
	print("✔ HUD UI & Currency indicators verified!")

	# 6. Test BottomNavBar Sprites
	print("\n--- Testing BottomNavBar Sprites ---")
	var nav_scene: PackedScene = load("res://scenes/bottom_nav_bar.tscn")
	var nav_inst: BottomNavBar = nav_scene.instantiate()
	add_child(nav_inst)

	var prog_icon: TextureRect = nav_inst.get_node("HBoxContainer/ProgressionBtn/Margin/VBox/Icon")
	assert(prog_icon.texture != null, "ProgressionBtn icon texture must exist")
	assert(prog_icon.texture.resource_path == "res://assets/icon/icon_progress.png", "ProgressionBtn must use icon_progress.png")

	var inv_icon: TextureRect = nav_inst.get_node("HBoxContainer/InventoryBtn/Margin/VBox/Icon")
	assert(inv_icon.texture != null, "InventoryBtn icon texture must exist")
	assert(inv_icon.texture.resource_path == "res://assets/icon/icon_inventory.png", "InventoryBtn must use icon_inventory.png")

	var nav_shop_icon: TextureRect = nav_inst.get_node("HBoxContainer/ShopBtn/Margin/VBox/Icon")
	assert(nav_shop_icon.texture != null, "ShopBtn icon texture must exist")
	assert(nav_shop_icon.texture.resource_path == "res://assets/icon/icon_shop.png", "ShopBtn must use icon_shop.png")

	nav_inst.queue_free()
	print("✔ BottomNavBar button sprites verified!")

	# 7. Test ItemView Visuals & Dynamic Scaling
	print("\n--- Testing ItemView Texture & Dynamic Scaling ---")
	var item_view_scene: PackedScene = load("res://scenes/item_view.tscn")
	var leaf_view: ItemView = item_view_scene.instantiate()
	add_child(leaf_view)
	leaf_view.setup(ItemDatabase.get_item("leaf_1"))
	var leaf_sprite: Sprite2D = leaf_view.get_node("Visuals/Sprite")
	assert(leaf_sprite.texture == ItemDatabase.get_item("leaf_1").icon_texture, "Leaf sprite texture must match leaf_1 icon_texture")
	assert(leaf_sprite.scale.x > 0.0 and leaf_sprite.scale.x < 0.3, "Leaf sprite scale must be dynamically scaled down for 500px textures")
	leaf_view.queue_free()
	print("✔ ItemView dynamic scaling verified!")

	# 8. Test Main Scene & Background Setup
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

	var trash_icon: TextureRect = main_inst.get_node_or_null("CanvasLayer/UI/BottomBar/SellBin/HBox/Icon")
	assert(trash_icon != null, "SellBin trash icon TextureRect must exist")
	assert(trash_icon.texture != null and trash_icon.texture.resource_path == "res://assets/icon/icon_trash.png", "SellBin must use icon_trash.png")

	main_inst.queue_free()
	print("✔ Main scene background & SellBin icon verified!")

	# 9. Test 7x9 Board & Visual Parameters
	print("\n--- Testing 7x9 Board & Visual Parameters ---")
	var board_scene: PackedScene = load("res://scenes/board.tscn")
	var test_board: Board = board_scene.instantiate()
	add_child(test_board)

	assert(test_board.cols == 7, "Board must have 7 columns")
	assert(test_board.rows == 9, "Board must have 9 rows")
	var cells_cnt: int = test_board.get_node("CellsContainer").get_child_count()
	assert(cells_cnt == 63, "Board must have 63 cells (7x9 = 63), got %d" % cells_cnt)

	test_board.queue_free()
	print("✔ 7x9 Board verified!")

	# 10. Test Persistence Save & Restore
	print("\n--- Testing Persistence Save & Restore ---")
	SaveManager.delete_save()
	assert(SaveManager.has_save() == false, "Save file should be deleted")

	# Prepare a test state
	ProgressionManager.reset_all()
	ProgressionManager.unlock_item("beef_3", true)
	ProgressionManager.claim_reward("beef_3")
	ProgressionManager.player_level = 4
	ProgressionManager.player_exp = 18
	EconomyManager.coins = 777
	EconomyManager.gems = 88
	EconomyManager.energy = 55
	InventoryManager.clear_all()
	InventoryManager.add_item("foodbox_1")
	InventoryManager.add_item("egg_1")
	InventoryManager.set_item_at(5, "leaf_2")

	var save_board: Board = board_scene.instantiate()
	add_child(save_board)
	save_board.clear_board()
	save_board.spawn_item_at(Vector2i(0, 0), "oven_1")
	save_board.spawn_item_at(Vector2i(5, 8), "leaf_3")
	save_board.spawn_item_at(Vector2i(2, 4), "fridge_1")
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
	assert(ProgressionManager.player_level == 1, "Player level should be reset")

	# Load game
	var load_ok := SaveManager.load_game(save_board)
	assert(load_ok == true, "SaveManager.load_game should succeed")

	assert(EconomyManager.coins == 777, "Restored coins should be 777")
	assert(EconomyManager.gems == 88, "Restored gems should be 88")
	assert(EconomyManager.energy == 55, "Restored energy should be 55")
	assert(ProgressionManager.player_level == 4, "Restored player level should be 4")
	assert(ProgressionManager.player_exp == 18, "Restored player exp should be 18")
	assert(InventoryManager.get_item_id_at(0) == "foodbox_1", "Slot 0 should be foodbox_1")
	assert(InventoryManager.get_item_id_at(1) == "egg_1", "Slot 1 should be egg_1")
	assert(InventoryManager.get_item_id_at(5) == "leaf_2", "Slot 5 should be leaf_2")
	assert(ProgressionManager.is_unlocked("beef_3") == true, "beef_3 should be unlocked")
	assert(ProgressionManager.is_claimed("beef_3") == true, "beef_3 reward should be claimed")

	assert(save_board.get_item_at(Vector2i(0, 0)).data.id == "oven_1", "Item at (0, 0) should be oven_1")
	assert(save_board.get_item_at(Vector2i(5, 8)).data.id == "leaf_3", "Item at (5, 8) should be leaf_3")
	assert(save_board.get_item_at(Vector2i(2, 4)).data.id == "fridge_1", "Item at (2, 4) should be fridge_1")

	save_board.queue_free()
	SaveManager.board_ref = null
	print("✔ Persistence Save & Restore verified!")

	# 11. Test Option Modal
	print("\n--- Testing Option Modal ---")
	var option_scene: PackedScene = load("res://scenes/option_modal.tscn")
	var option_inst: OptionModal = option_scene.instantiate()
	add_child(option_inst)

	var orig_sfx := SoundManager.sfx_enabled
	option_inst._on_sfx_pressed()
	assert(SoundManager.sfx_enabled == not orig_sfx, "SFX toggle must toggle SoundManager.sfx_enabled")
	option_inst._on_sfx_pressed()
	assert(SoundManager.sfx_enabled == orig_sfx, "SFX toggle must restore state")
	option_inst.queue_free()
	print("✔ Option Modal verified!")

	# 12. Test Main Menu Scene
	print("\n--- Testing Main Menu Scene ---")
	var menu_scene: PackedScene = load("res://scenes/main_menu.tscn")
	var menu_inst: MainMenu = menu_scene.instantiate()
	add_child(menu_inst)

	assert(menu_inst.continue_btn != null, "ContinueBtn must exist in MainMenu")
	assert(menu_inst.new_game_btn != null, "NewGameBtn must exist in MainMenu")
	assert(menu_inst.options_btn != null, "OptionsBtn must exist in MainMenu")
	assert(menu_inst.quit_btn != null, "QuitBtn must exist in MainMenu")

	menu_inst.queue_free()
	print("✔ Main Menu Scene verified!")

	# 13. Test Boxed & Locked Item Gameplay Mechanics
	print("\n--- Testing Boxed & Locked Item Mechanics ---")
	var mech_board: Board = board_scene.instantiate()
	add_child(mech_board)
	mech_board.clear_board()

	# 13.1 Boxed item validation
	var boxed_item := mech_board.spawn_item_at(Vector2i(0, 0), "beef_2", ItemView.ItemState.BOXED, 2)
	assert(boxed_item != null, "Boxed item should spawn")
	assert(boxed_item.is_boxed() == true, "Item must be boxed")
	assert(boxed_item.is_normal() == false, "Boxed item cannot be normal")
	assert(boxed_item.is_locked() == false, "Boxed item cannot be locked")
	assert(boxed_item.unlock_level == 2, "Boxed item unlock level should be 2")
	assert(boxed_item.tier_badge.visible == false, "Tier badge must be hidden on boxed item")
	assert(boxed_item.spawner_badge.visible == false, "Spawner badge must be hidden on boxed item")
	assert(boxed_item.status_badge.visible == true, "Status badge should be visible on boxed item")
	assert(boxed_item.status_label.text == "Lv.2", "Status badge should display Lv.2")

	# Verify interaction blocked
	var tracker := {"text": ""}
	var float_sub := func(t: String, _p: Vector2, _c: Color): tracker["text"] = t
	GameEvents.show_floating_text.connect(float_sub)

	mech_board._handle_press(mech_board.to_global(mech_board.get_cell_center(0, 0)))
	assert(mech_board._active_item == null, "Boxed item cannot be picked up")
	assert(tracker["text"].contains("Unlocks at Lv. 2"), "Should show floating text for boxed item unlock requirement")

	# 13.2 Locked item validation
	var locked_item := mech_board.spawn_item_at(Vector2i(4, 4), "egg_2", ItemView.ItemState.LOCKED)
	assert(locked_item != null, "Locked item should spawn")
	assert(locked_item.is_locked() == true, "Item must be locked")
	assert(locked_item.is_normal() == false, "Locked item cannot be normal")
	assert(locked_item.is_boxed() == false, "Locked item cannot be boxed")
	assert(locked_item.sprite.modulate.is_equal_approx(Color(0.38, 0.38, 0.42, 1.0)), "Locked item must have disabled dark gray modulate")
	assert(locked_item.tier_badge.visible == true, "Tier badge must be visible on locked item")
	assert(locked_item.status_badge.visible == false, "Status badge should be hidden on locked item (uses tile + item filter)")

	var locked_cell: BoardCell = mech_board._cells[4][4]
	assert(locked_cell.is_locked == true, "Whole tile cell at (4, 4) must be locked")

	# Interaction says "Locked"
	tracker["text"] = ""
	mech_board._handle_press(mech_board.to_global(mech_board.get_cell_center(4, 4)))
	assert(mech_board._active_item == null, "Locked item cannot be picked up")
	assert(tracker["text"] == "Locked", "Locked item interaction must say 'Locked'")

	# 13.3 Locked item cannot be swapped with normal item
	var other_item := mech_board.spawn_item_at(Vector2i(1, 1), "leaf_1", ItemView.ItemState.NORMAL)
	tracker["text"] = ""
	mech_board._drop_into_board(other_item, Vector2i(4, 4))
	assert(mech_board.get_item_at(Vector2i(4, 4)) == locked_item, "Locked item must stay in cell (4, 4)")
	assert(tracker["text"] == "Locked", "Dropping non-mergeable item on locked item must say 'Locked'")

	# Cannot drop on boxed item either
	tracker["text"] = ""
	mech_board._drop_into_board(other_item, Vector2i(0, 0))
	assert(mech_board.get_item_at(Vector2i(0, 0)) == boxed_item, "Boxed item must stay in cell (0, 0)")
	assert(tracker["text"].contains("Unlocks at Lv. 2"), "Dropping item on boxed item must bounce back and show unlock requirement")

	# 13.4 Merge-unlock mechanic (Exact prompt requirement)
	# "example locked egg tier 2 in cell 4,4 being merge with normal egg tier 2 in cell 4,5 so the locked egg in cell 4,4 will turned into normal egg tier 3"
	var normal_egg := mech_board.spawn_item_at(Vector2i(4, 5), "egg_2", ItemView.ItemState.NORMAL)
	mech_board._drop_into_board(normal_egg, Vector2i(4, 4))

	var merged_result := mech_board.get_item_at(Vector2i(4, 4))
	assert(merged_result != null, "Merged result must exist at cell (4, 4)")
	assert(merged_result.data.id == "egg_3", "Result at (4, 4) must be egg_3")
	assert(merged_result.data.tier == 3, "Result tier must be 3")
	assert(merged_result.is_normal() == true, "Result must now be a normal (unlocked) item")
	assert(merged_result.is_locked() == false, "Result must not be locked")
	assert(merged_result.status_badge.visible == false, "Status badge should be hidden on unlocked normal item")
	assert(mech_board.get_item_at(Vector2i(4, 5)) == null, "Cell (4, 5) source item should be cleared")

	var unlocked_cell: BoardCell = mech_board._cells[4][4]
	assert(unlocked_cell.is_locked == false, "Tile cell at (4, 4) must now be unlocked after merge")

	# 13.5 Progression level-up automatically unboxes boxed item to locked item
	ProgressionManager.player_level = 1
	var boxed_level_item := mech_board.spawn_item_at(Vector2i(0, 1), "beef_2", ItemView.ItemState.BOXED, 2)
	assert(boxed_level_item.is_boxed() == true, "Boxed item at (0, 1) should still be boxed at Level 1")
	# Level up to 2
	ProgressionManager.add_exp(20) # will level up to Level 2
	assert(ProgressionManager.player_level >= 2, "Player should now be at least Level 2")
	assert(boxed_level_item.is_locked() == true, "Boxed item should have unboxed into locked item on level-up to 2")
	assert(boxed_level_item.is_boxed() == false, "Item should no longer be boxed")
	assert(boxed_level_item.sprite.modulate.is_equal_approx(Color(0.38, 0.38, 0.42, 1.0)), "Unboxed item must now have disabled dark gray filter")

	# 13.6 Usable items on board filters out locked and boxed
	mech_board.clear_board()
	mech_board.spawn_item_at(Vector2i(0, 0), "cake_1", ItemView.ItemState.BOXED, 5)
	mech_board.spawn_item_at(Vector2i(1, 0), "egg_1", ItemView.ItemState.LOCKED)
	mech_board.spawn_item_at(Vector2i(2, 0), "leaf_1", ItemView.ItemState.NORMAL)

	var all_items := mech_board.get_all_items_on_board(false)
	var usable_items := mech_board.get_all_items_on_board(true)
	assert(all_items.size() == 3, "All items on board should be 3")
	assert(usable_items.size() == 1, "Only 1 item should be usable (normal)")
	assert(usable_items[0].data.id == "leaf_1", "Usable item must be leaf_1")

	# 13.7 Serialization preserves boxed and locked states
	var serialized := mech_board.serialize_items()
	assert(serialized.size() == 3, "Serialized items should have 3 entries")

	var restore_board: Board = board_scene.instantiate()
	add_child(restore_board)
	restore_board.load_items(serialized)

	var restored_boxed := restore_board.get_item_at(Vector2i(0, 0))
	var restored_locked := restore_board.get_item_at(Vector2i(1, 0))
	var restored_normal := restore_board.get_item_at(Vector2i(2, 0))

	assert(restored_boxed.is_boxed() == true, "Restored (0, 0) should be boxed")
	assert(restored_boxed.unlock_level == 5, "Restored (0, 0) unlock_level should be 5")
	assert(restored_locked.is_locked() == true, "Restored (1, 0) should be locked")
	assert(restored_normal.is_normal() == true, "Restored (2, 0) should be normal")

	GameEvents.show_floating_text.disconnect(float_sub)
	mech_board.queue_free()
	restore_board.queue_free()
	print("✔ Boxed & Locked Item Mechanics fully verified!")

	# 14. Test Producer Tier 3 & Stacking Cooldown Mechanics
	print("\n--- Testing Producer Tier 3 & Stacking Cooldown Mechanics ---")
	var spawner_board: Board = board_scene.instantiate()
	add_child(spawner_board)
	spawner_board.clear_board()

	# Tier 1 and 2 are NOT spawners
	var fb1 := spawner_board.spawn_item_at(Vector2i(0, 0), "foodbox_1")
	assert(fb1.data.is_spawner == false, "foodbox_1 must not be a spawner")
	assert(fb1.is_spawner_ready() == false, "foodbox_1 is not spawner ready")
	assert(fb1.spawner_badge.visible == false, "foodbox_1 spawner badge must be hidden")

	var fb2 := spawner_board.spawn_item_at(Vector2i(1, 0), "foodbox_2")
	assert(fb2.data.is_spawner == false, "foodbox_2 must not be a spawner")

	# Tier 3 IS a spawner with 10 charges and 5s cooldown
	var fb3 := spawner_board.spawn_item_at(Vector2i(2, 0), "foodbox_3")
	assert(fb3.data.is_spawner == true, "foodbox_3 must be a spawner")
	assert(fb3.max_charges == 10, "foodbox_3 max_charges must be 10")
	assert(fb3.cooldown_per_charge == 5.0, "foodbox_3 cooldown_per_charge must be 5.0s")
	assert(fb3.current_charges == 10, "foodbox_3 initial current_charges must be 10")
	assert(fb3.producer_status == ItemView.ProducerStatus.READY, "Initial status must be READY")
	assert(fb3.get_spawner_status_string() == "ready", "Status string must be 'ready'")
	assert(fb3.is_spawner_ready() == true, "foodbox_3 should be spawner ready")
	assert(fb3.spawner_badge.visible == true, "foodbox_3 spawner badge must be visible")
	assert(fb3._idle_tween != null and fb3._idle_tween.is_valid(), "Idle animation must be running when ready")

	# Rapidly spawn items: consume all 10 charges
	EconomyManager.energy = 100
	for i in range(10):
		assert(fb3.is_spawner_ready() == true, "Spawner should be ready at charge %d" % (10 - i))
		fb3.consume_spawn_charge()

	assert(fb3.current_charges == 0, "Current charges must be 0 after 10 spawns")
	assert(is_equal_approx(fb3.current_cooldown, 50.0), "Cooldown must be 50.0s after 10 spawns, got %f" % fb3.current_cooldown)
	assert(fb3.producer_status == ItemView.ProducerStatus.EXHAUST, "Status must be EXHAUST when depleted")
	assert(fb3.get_spawner_status_string() == "Exhaust", "Status string must be 'Exhaust'")
	assert(fb3.is_spawner_ready() == false, "Spawner must not be ready when exhausted")
	assert(fb3.is_spawner_exhausted() == true, "Spawner must report exhausted")
	assert(fb3.status_badge.visible == true, "Status badge showing cooldown must be visible")
	assert(fb3.status_label.text == "50s", "Cooldown label should show 50s")
	assert(fb3._idle_tween == null, "Idle animation must stop when exhausted")

	# Spawning while exhausted should be blocked
	var exhaust_msg := {"text": ""}
	var exh_sub := func(t: String, _p: Vector2, _c: Color): exhaust_msg["text"] = t
	GameEvents.show_floating_text.connect(exh_sub)
	spawner_board._trigger_spawner(fb3)
	assert(exhaust_msg["text"].contains("Exhausted!"), "Triggering exhausted spawner must show Exhausted message")
	GameEvents.show_floating_text.disconnect(exh_sub)

	# Simulate time recovery: 5.0 seconds pass
	fb3._process(5.0)
	assert(is_equal_approx(fb3.current_cooldown, 45.0), "Cooldown should decrease to 45.0s")
	assert(fb3.current_charges == 1, "1 charge should be recovered after 5 seconds")
	assert(fb3.producer_status == ItemView.ProducerStatus.READY, "Status must return to READY once charges > 0")
	assert(fb3.is_spawner_ready() == true, "Spawner must now be ready")
	assert(fb3._idle_tween != null and fb3._idle_tween.is_valid(), "Idle animation must resume when ready")

	# Simulate complete recovery
	fb3._process(45.0)
	assert(fb3.current_cooldown == 0.0, "Cooldown should be 0.0s after full recovery")
	assert(fb3.current_charges == 10, "Full charges (10) must be restored")

	spawner_board.queue_free()
	print("✔ Producer Tier 3 & Stacking Cooldown Mechanics verified!")

	# 15. Test Initial Board First Experience Layout
	print("\n--- Testing Initial Board First Experience Layout ---")
	var main_test_scene: PackedScene = load("res://main.tscn")
	var main_inst_test: MainGame = main_test_scene.instantiate()
	add_child(main_inst_test)

	var main_board: Board = main_inst_test.board
	assert(main_board.cols == 7, "Initial board must have 7 cols")
	assert(main_board.rows == 9, "Initial board must have 9 rows")

	# Check Perimeter: Rows 0, 1, 7, 8 and Cols 0, 6 must be BOXED
	for c in range(7):
		for r in range(9):
			var it := main_board.get_item_at(Vector2i(c, r))
			assert(it != null, "Cell (%d, %d) must contain an item" % [c, r])
			var is_perim: bool = (r == 0 or r == 1 or r == 7 or r == 8 or c == 0 or c == 6)
			if is_perim:
				assert(it.is_boxed() == true, "Perimeter cell (%d, %d) must be BOXED" % [c, r])
				assert(it.unlock_level >= 2, "Perimeter item must have unlock_level >= 2")
			else:
				# Inner 5x5
				if r == 4 and c == 3:
					# Scripted center green
					assert(it.is_normal() == true, "Cell (3, 4) must be NORMAL (Green)")
					assert(it.data.id == "foodbox_1", "Cell (3, 4) must be foodbox_1 (t1f)")
				elif r == 4 and c == 2:
					# Scripted center left locked
					assert(it.is_locked() == true, "Cell (2, 4) must be LOCKED (Orange)")
					assert(it.data.id == "foodbox_1", "Cell (2, 4) must be foodbox_1 (t1f)")
				elif r == 4 and c == 4:
					# Scripted center right locked
					assert(it.is_locked() == true, "Cell (4, 4) must be LOCKED (Orange)")
					assert(it.data.id == "foodbox_2", "Cell (4, 4) must be foodbox_2 (t2f)")
				else:
					assert(it.is_locked() == true, "Inner cell (%d, %d) must be LOCKED (Orange)" % [c, r])

	# Test the initial merge loop:
	# Step 1: Merge normal foodbox_1 (3, 4) with locked foodbox_1 (2, 4) -> unlocks into foodbox_2
	var normal_t1f := main_board.get_item_at(Vector2i(3, 4))
	main_board._drop_into_board(normal_t1f, Vector2i(2, 4))
	var unlocked_t2f := main_board.get_item_at(Vector2i(2, 4))
	assert(unlocked_t2f != null, "Unlocked item must exist at (2, 4)")
	assert(unlocked_t2f.data.id == "foodbox_2", "Unlocked item must be foodbox_2")
	assert(unlocked_t2f.is_normal() == true, "Merged foodbox_2 must be NORMAL")
	assert(main_board.get_item_at(Vector2i(3, 4)) == null, "Cell (3, 4) must now be empty")

	# Step 2: Merge created foodbox_2 (2, 4) with locked foodbox_2 (4, 4) -> unlocks into foodbox_3
	main_board._drop_into_board(unlocked_t2f, Vector2i(4, 4))
	var spawner_t3f := main_board.get_item_at(Vector2i(4, 4))
	assert(spawner_t3f != null, "Crafted spawner must exist at (4, 4)")
	assert(spawner_t3f.data.id == "foodbox_3", "Crafted spawner must be foodbox_3")
	assert(spawner_t3f.is_normal() == true, "Crafted spawner must be NORMAL")
	assert(spawner_t3f.data.is_spawner == true, "foodbox_3 must be a spawner")
	assert(spawner_t3f.current_charges == 10, "foodbox_3 must have 10 charges")
	assert(spawner_t3f.is_spawner_ready() == true, "foodbox_3 must be ready")
	assert(main_board.get_item_at(Vector2i(2, 4)) == null, "Cell (2, 4) must now be empty")

	print("✔ Initial Board First Experience Layout verified!")

	# 16. Test UI Custom Theme Colors & Matching
	print("\n--- Testing UI Custom Theme Colors & Matching ---")
	var nav_bar: BottomNavBar = main_inst_test.bottom_nav_bar
	assert(nav_bar != null, "BottomNavBar must exist")
	var nav_shop_sb: StyleBox = nav_bar.shop_btn.get_theme_stylebox("normal")
	assert(nav_shop_sb is StyleBoxFlat, "ShopBtn must have StyleBoxFlat")
	assert(nav_shop_sb.bg_color.is_equal_approx(main_board.board_bg_color), "ShopBtn color must match board_bg_color")

	var help_bar: Panel = main_inst_test.get_node("CanvasLayer/UI/HelpBar")
	var help_sb: StyleBox = help_bar.get_theme_stylebox("panel")
	assert(help_sb is StyleBoxFlat, "HelpBar must have StyleBoxFlat")
	assert(help_sb.bg_color.is_equal_approx(main_board.board_bg_color), "HelpBar color must match board_bg_color")

	var sell_bin_pnl: Panel = main_inst_test.sell_bin
	var sell_sb: StyleBox = sell_bin_pnl.get_theme_stylebox("panel")
	assert(sell_sb is StyleBoxFlat, "SellBin must have StyleBoxFlat")
	assert(sell_sb.bg_color.is_equal_approx(main_board.board_bg_color), "SellBin color must match board_bg_color")

	main_inst_test.queue_free()
	print("✔ UI Custom Theme Colors & Matching verified!")

	print("\n=== ALL TESTS PASSED SUCCESSFULLY! ===")
	get_tree().quit(0)
