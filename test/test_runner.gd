extends Node

func _ready() -> void:
	if is_instance_valid(OrientationManager):
		OrientationManager.set_landscape(false, false)

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

	var level_icon: TextureRect = hud_inst.level_icon
	assert(level_icon.texture != null, "Level icon texture must exist")

	var energy_icon: TextureRect = hud_inst.energy_icon
	assert(energy_icon.texture != null, "Energy icon texture must exist")

	var gold_icon: TextureRect = hud_inst.coin_icon
	assert(gold_icon.texture != null, "Gold icon texture must exist")

	var diamond_icon: TextureRect = hud_inst.gem_icon
	assert(diamond_icon.texture != null, "Diamond icon texture must exist")

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

	var prog_icon: TextureRect = nav_inst.get_node("HBoxContainer/ProgressionBtn/Margin/HBox/Icon")
	assert(prog_icon.texture != null, "ProgressionBtn icon texture must exist")
	assert(prog_icon.texture.resource_path == "res://assets/icon/icon_progress.png", "ProgressionBtn must use icon_progress.png")

	var inv_icon: TextureRect = nav_inst.get_node("HBoxContainer/InventoryBtn/Margin/HBox/Icon")
	assert(inv_icon.texture != null, "InventoryBtn icon texture must exist")
	assert(inv_icon.texture.resource_path == "res://assets/icon/icon_inventory.png", "InventoryBtn must use icon_inventory.png")

	var nav_shop_icon: TextureRect = nav_inst.get_node("HBoxContainer/ShopBtn/Margin/HBox/Icon")
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
	var expected_bg := "res://assets/background_landscape.jpg" if OrientationManager.is_landscape else "res://assets/background.jpeg"
	assert(bg_rect.texture.resource_path == expected_bg, "Background texture must match orientation background")

	var info_area: Panel = main_inst.get_node_or_null("CanvasLayer/UI/BottomBar/InfoArea")
	assert(info_area != null, "InfoArea Panel must exist in BottomBar")
	var info_btn: Button = info_area.get_node_or_null("Margin/HBox/InfoBtn")
	assert(info_btn != null, "InfoBtn must exist in InfoArea")
	var sell_btn: Button = info_area.get_node_or_null("Margin/HBox/SellBtn")
	assert(sell_btn != null, "SellBtn must exist in InfoArea")

	main_inst.queue_free()
	print("✔ Main scene background & InfoArea verified!")

	# 9. Test 7x9 Board & Visual Parameters
	print("\n--- Testing 7x9 Board & Visual Parameters ---")
	var board_scene: PackedScene = load("res://scenes/board.tscn")
	var test_board: Board = board_scene.instantiate()
	add_child(test_board)

	assert(test_board.cols == 7, "Board must have 7 columns")
	assert(test_board.rows == 9, "Board must have 9 rows")
	var cells_cnt: int = test_board.get_node("CellsContainer").get_child_count()
	assert(cells_cnt == 63, "Board must have 63 cells (7x9 = 63), got %d" % cells_cnt)
	assert(test_board.cell_spacing == 5.0, "Board default cell_spacing must be 5.0 (tiles closer)")
	assert(test_board.tile_margin == 5.0, "Board tile_margin alias must match cell_spacing")
	assert(test_board.use_chess_pattern == true, "use_chess_pattern must default to true")
	var cell_0_0: BoardCell = test_board._cells[0][0]
	var cell_1_0: BoardCell = test_board._cells[1][0]
	assert(cell_0_0.cell_bg_color.is_equal_approx(test_board.tile_bg_color), "Cell (0, 0) should use tile_bg_color")
	assert(cell_1_0.cell_bg_color.is_equal_approx(test_board.tile_bg_alt_color), "Cell (1, 0) should use tile_bg_alt_color (lighter tone)")

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

	assert(option_inst.bgm_btn != null, "BgmBtn must exist in OptionModal")
	var orig_bgm := SoundManager.bgm_enabled
	option_inst._on_bgm_pressed()
	assert(SoundManager.bgm_enabled == not orig_bgm, "BGM toggle must toggle SoundManager.bgm_enabled")
	option_inst._on_bgm_pressed()
	assert(SoundManager.bgm_enabled == orig_bgm, "BGM toggle must restore state")

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

	# Test opening options modal hides main menu UI
	assert(menu_inst.menu_container.visible == true, "Menu container should be visible initially")
	menu_inst._on_options_pressed()
	assert(menu_inst.menu_container.visible == false, "Menu container should hide when options opens")
	assert(menu_inst.option_modal.visible == true, "Option modal should be visible when opened")

	# Test closing options modal restores main menu UI
	menu_inst.option_modal.close_modal()
	menu_inst._on_options_closed()
	assert(menu_inst.menu_container.visible == true, "Menu container should be restored when options closes")

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
	assert(boxed_item.sprite.texture in ItemView.BOX_TEXTURES, "Boxed item must use a texture from BOX_TEXTURES")
	assert(boxed_item.web_sprite.visible == true, "Web sprite must be visible on boxed item")
	assert(boxed_item.web_sprite.texture in ItemView.WEB_TEXTURES, "Web sprite must use a texture from WEB_TEXTURES")

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
	assert(locked_item.sprite.modulate.is_equal_approx(ItemView.LOCKED_ITEM_MODULATE), "Locked item must have disabled dark gray modulate")
	assert(locked_item.web_sprite.visible == true, "Web sprite must be visible on locked item")
	assert(locked_item.web_sprite.texture in ItemView.WEB_TEXTURES, "Web sprite must use a texture from WEB_TEXTURES")
	assert(locked_item.tier_badge.visible == false, "Tier badge must be hidden on all items")
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
	assert(other_item.web_sprite.visible == false, "Normal item must hide web sprite")
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
	assert(merged_result.web_sprite.visible == false, "Web sprite must be hidden on unlocked item")
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
	assert(boxed_level_item.sprite.modulate.is_equal_approx(ItemView.LOCKED_ITEM_MODULATE), "Unboxed item must now have disabled dark gray filter")
	assert(boxed_level_item.web_sprite.visible == true, "Unboxed item must now have visible web sprite")

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

	# Check Board Zones: Small active 3x3 zone around (3, 4), and HIDDEN outward cells
	for c in range(7):
		for r in range(9):
			var it := main_board.get_item_at(Vector2i(c, r))
			assert(it != null, "Cell (%d, %d) must contain an item" % [c, r])
			var in_3x3: bool = (abs(c - 3) <= 1 and abs(r - 4) <= 1)
			if in_3x3:
				if r == 4 and c == 3:
					assert(it.is_normal() == true, "Cell (3, 4) must be NORMAL (Green)")
					assert(it.data.id == "foodbox_1", "Cell (3, 4) must be foodbox_1 (t1f)")
				elif r == 4 and c == 2:
					assert(it.is_locked() == true, "Cell (2, 4) must be LOCKED (Orange)")
					assert(it.data.id == "foodbox_1", "Cell (2, 4) must be foodbox_1 (t1f)")
				elif r == 4 and c == 4:
					assert(it.is_locked() == true, "Cell (4, 4) must be LOCKED (Orange)")
					assert(it.data.id == "foodbox_2", "Cell (4, 4) must be foodbox_2 (t2f)")
				else:
					assert(it.is_locked() == true, "Active 3x3 neighbor (%d, %d) must be LOCKED" % [c, r])
			else:
				assert(it.is_hidden() == true, "Cell outside 3x3 (%d, %d) must start as HIDDEN" % [c, r])
				var is_perim: bool = (r == 0 or r == 1 or r == 7 or r == 8 or c == 0 or c == 6)
				if is_perim:
					assert(it.unlock_level >= 2, "Perimeter hidden item must have unlock_level >= 2")

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

	# 16. Test UI Scene-Configured Styles & No Script Overwrite
	print("\n--- Testing UI Scene-Configured Styles & No Script Overwrite ---")
	var nav_bar: BottomNavBar = main_inst_test.bottom_nav_bar
	assert(nav_bar != null, "BottomNavBar must exist")
	var nav_shop_sb: StyleBox = nav_bar.shop_btn.get_theme_stylebox("normal")
	assert(nav_shop_sb != null, "ShopBtn must have StyleBox configured from scene")

	var nav_inv_sb: StyleBox = nav_bar.inventory_btn.get_theme_stylebox("normal")
	assert(nav_inv_sb != null, "InventoryBtn must have StyleBox configured from scene")

	var nav_prog_sb: StyleBox = nav_bar.progression_btn.get_theme_stylebox("normal")
	assert(nav_prog_sb != null, "ProgressionBtn must have StyleBox configured from scene")

	var info_area_pnl: Panel = main_inst_test.info_area
	var info_sb: StyleBox = info_area_pnl.get_theme_stylebox("panel")
	assert(info_sb is StyleBoxFlat, "InfoArea must have StyleBoxFlat configured from scene")

	var hud_shop_btn: Button = main_inst_test.hud.get_node("Margin/HBox/ButtonsBox/ShopBtn")
	var hud_shop_sb: StyleBox = hud_shop_btn.get_theme_stylebox("normal")
	assert(hud_shop_sb is StyleBoxFlat, "HUD ShopBtn must have StyleBoxFlat configured from scene")

	main_inst_test.queue_free()
	print("✔ UI Scene-Configured Styles verified!")

	# 17. Test Custom Cursor System
	print("\n--- Testing Custom Cursor System ---")
	assert(CursorManager != null, "CursorManager autoload must exist")
	assert(CursorManager.CURSOR_ARROW_TEX != null, "Arrow cursor texture must be loaded")
	assert(CursorManager.CURSOR_POINTING_HAND_TEX != null, "Pointing hand cursor texture must be loaded")
	assert(CursorManager.CURSOR_DRAG_TEX != null, "Drag hand cursor texture must be loaded")
	assert(CursorManager.CURSOR_CAN_DROP_TEX != null, "Can drop cursor texture must be loaded")
	assert(CursorManager.CURSOR_FORBIDDEN_TEX != null, "Forbidden cursor texture must be loaded")
	assert(CursorManager.CURSOR_EXCLAMATION_TEX != null, "Exclamation cursor texture must be loaded")

	CursorManager.set_drag_cursor()
	CursorManager.set_can_drop_cursor()
	CursorManager.set_forbidden_cursor()
	CursorManager.set_pointing_cursor()
	CursorManager.set_exclamation_cursor()
	CursorManager.reset_cursor()

	var test_btn := Button.new()
	add_child(test_btn)
	assert(test_btn.mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND, "Button must automatically receive POINTING_HAND cursor shape")
	test_btn.queue_free()

	# Test board hover cursor states
	var cursor_test_board: Board = board_scene.instantiate()
	add_child(cursor_test_board)
	cursor_test_board.clear_board()

	# Normal item -> hand open (CURSOR_CAN_DROP)
	cursor_test_board.spawn_item_at(Vector2i(1, 1), "beef_1", ItemView.ItemState.NORMAL)
	cursor_test_board._update_hover_cursor(cursor_test_board.to_global(cursor_test_board.get_cell_center(1, 1)))
	assert(CursorManager.current_cursor_shape == Input.CURSOR_CAN_DROP, "Hovering movable item must set CURSOR_CAN_DROP (hand open)")

	# Spawner ready to spawn -> pointing hand (CURSOR_POINTING_HAND)
	var spawner_item := cursor_test_board.spawn_item_at(Vector2i(4, 4), "foodbox_3", ItemView.ItemState.NORMAL)
	cursor_test_board._update_hover_cursor(cursor_test_board.to_global(cursor_test_board.get_cell_center(4, 4)))
	assert(CursorManager.current_cursor_shape == Input.CURSOR_POINTING_HAND, "Hovering ready spawner item must set CURSOR_POINTING_HAND (point hand)")

	# Spawner on exhaust -> mark exclamation cursor (CURSOR_EXCLAMATION)
	spawner_item.current_charges = 0
	spawner_item.producer_status = ItemView.ProducerStatus.EXHAUST
	cursor_test_board._update_hover_cursor(cursor_test_board.to_global(cursor_test_board.get_cell_center(4, 4)))
	assert(CursorManager.current_cursor_shape == CursorManager.CURSOR_EXCLAMATION, "Hovering exhausted spawner must set CURSOR_EXCLAMATION (mark exclamation)")

	# Locked item -> disabled cursor (CURSOR_FORBIDDEN)
	cursor_test_board.spawn_item_at(Vector2i(2, 2), "beef_2", ItemView.ItemState.LOCKED)
	cursor_test_board._update_hover_cursor(cursor_test_board.to_global(cursor_test_board.get_cell_center(2, 2)))
	assert(CursorManager.current_cursor_shape == Input.CURSOR_FORBIDDEN, "Hovering locked item must set CURSOR_FORBIDDEN")

	# Boxed item -> disabled cursor (CURSOR_FORBIDDEN)
	cursor_test_board.spawn_item_at(Vector2i(3, 3), "beef_3", ItemView.ItemState.BOXED, 5)
	cursor_test_board._update_hover_cursor(cursor_test_board.to_global(cursor_test_board.get_cell_center(3, 3)))
	assert(CursorManager.current_cursor_shape == Input.CURSOR_FORBIDDEN, "Hovering boxed item must set CURSOR_FORBIDDEN")

	# Empty cell -> arrow cursor (CURSOR_ARROW)
	cursor_test_board._update_hover_cursor(cursor_test_board.to_global(cursor_test_board.get_cell_center(0, 0)))
	assert(CursorManager.current_cursor_shape == Input.CURSOR_ARROW, "Hovering empty cell must reset to CURSOR_ARROW")

	# Dragging item -> hand closed (CURSOR_DRAG)
	cursor_test_board._active_item = cursor_test_board.get_item_at(Vector2i(1, 1))
	cursor_test_board._is_dragging = true
	cursor_test_board._update_hover_feedback(cursor_test_board.to_global(cursor_test_board.get_cell_center(0, 0)))
	assert(CursorManager.current_cursor_shape == Input.CURSOR_DRAG, "Dragging item over cell must keep CURSOR_DRAG (hand closed)")
	cursor_test_board._active_item = null
	cursor_test_board._is_dragging = false
	CursorManager.reset_cursor()

	cursor_test_board.queue_free()
	print("✔ Custom Cursor System verified!")

	# 18. Test Looped BGM System
	print("\n--- Testing Looped BGM System ---")
	assert(SoundManager._bgm_player != null, "BGM player must exist in SoundManager")
	assert(SoundManager._bgm_player.stream is AudioStreamMP3, "BGM stream must be AudioStreamMP3")
	var bgm_stream: AudioStreamMP3 = SoundManager._bgm_player.stream as AudioStreamMP3
	assert(bgm_stream.loop == true, "BGM stream loop property must be true")

	var initial_bgm := SoundManager.bgm_enabled
	SoundManager.set_bgm_enabled(false)
	assert(SoundManager.bgm_enabled == false, "set_bgm_enabled(false) must update state")
	assert(not SoundManager._bgm_player.playing, "BGM player must stop when disabled")
	SoundManager.set_bgm_enabled(true)
	assert(SoundManager.bgm_enabled == true, "set_bgm_enabled(true) must update state")
	SoundManager.set_bgm_enabled(initial_bgm)
	print("✔ Looped BGM System verified!")

	# 19. Test Sound Effects (Kenney SFX Audio Pool)
	print("\n--- Testing Kenney SFX Audio Pool ---")
	assert(SoundManager._sfx_players.size() == 8, "SFX player pool must have 8 players")
	assert(SoundManager.STREAM_PICKUP != null, "STREAM_PICKUP must be loaded")
	assert(SoundManager.STREAM_ERROR != null, "STREAM_ERROR must be loaded")
	assert(SoundManager.STREAM_CLICK != null, "STREAM_CLICK must be loaded")
	assert("error_004" in SoundManager.STREAM_ERROR.resource_path, "STREAM_ERROR must use error_004.ogg")
	assert(not "click" in SoundManager.STREAM_PICKUP.resource_path, "STREAM_PICKUP must not use click sound")
	assert(not "pluck" in SoundManager.STREAM_PICKUP.resource_path, "STREAM_PICKUP must not use pluck sound")
	assert("click" in SoundManager.STREAM_CLICK.resource_path, "STREAM_CLICK must use click sound")
	assert(not "pluck" in SoundManager.STREAM_CLICK.resource_path, "STREAM_CLICK must not use pluck sound")

	# Trigger all gameplay SFX methods to ensure no exceptions or missing streams
	SoundManager.play_pickup()
	SoundManager.play_drop()
	SoundManager.play_merge()
	SoundManager.play_spawn()
	SoundManager.play_consume()
	SoundManager.play_quest()
	SoundManager.play_error()
	SoundManager.play_click()
	SoundManager.play_open()
	SoundManager.play_close()
	print("✔ Kenney SFX Audio Pool verified!")

	# 20. Test Distinct Merge Sounds per Item & Chain
	print("\n--- Testing Distinct Merge Sounds per Item & Chain ---")
	assert(SoundManager.CHAIN_MERGE_SOUNDS.has("foodbox"), "Must have merge sound for foodbox")
	assert(SoundManager.CHAIN_MERGE_SOUNDS.has("oven"), "Must have merge sound for oven")
	assert(SoundManager.CHAIN_MERGE_SOUNDS.has("fridge"), "Must have merge sound for fridge")
	assert(SoundManager.CHAIN_MERGE_SOUNDS.has("egg"), "Must have merge sound for egg")
	assert(SoundManager.CHAIN_MERGE_SOUNDS.has("beef"), "Must have merge sound for beef")
	assert(SoundManager.CHAIN_MERGE_SOUNDS.has("cake"), "Must have merge sound for cake")
	assert(SoundManager.CHAIN_MERGE_SOUNDS.has("chest"), "Must have merge sound for chest")
	assert(SoundManager.CHAIN_MERGE_SOUNDS["chest"] != null, "Chest merge sound must be loaded")

	# Test calling play_merge with various item data instances
	var test_foodbox: ItemData = ItemDatabase.get_item("foodbox_3")
	var test_beef: ItemData = ItemDatabase.get_item("beef_5")
	var test_chest: ItemData = ItemDatabase.get_item("chest_1")
	assert(test_foodbox != null, "foodbox_3 must exist")
	assert(test_beef != null, "beef_5 must exist")
	assert(test_chest != null, "chest_1 must exist")

	SoundManager.play_merge(test_foodbox)
	SoundManager.play_merge(test_beef)
	SoundManager.play_merge(test_chest)
	SoundManager.play_merge(null) # Test fallback
	print("✔ Distinct Merge Sounds verified!")

	# 21. Test Chest Item Data & Producer Drops
	print("\n--- Testing Chest Item Data & Producer Drops ---")
	var chest_1 := ItemDatabase.get_item("chest_1")
	var chest_2 := ItemDatabase.get_item("chest_2")
	assert(chest_1 != null, "chest_1 must exist in ItemDatabase")
	assert(chest_2 != null, "chest_2 must exist in ItemDatabase")
	assert(chest_1.chain_id == "chest", "chest_1 chain_id must be chest")
	assert(chest_1.is_spawner == true, "chest_1 must be a spawner")
	assert(chest_1.max_charges == 5, "chest_1 must have 5 max charges")
	assert(chest_1.energy_cost == 0, "chest_1 must cost 0 energy")
	assert(chest_1.disappears_when_exhausted == true, "chest_1 must disappear when exhausted")
	assert(chest_1.spawn_pool.has("oven_1"), "chest_1 must spawn oven_1")
	assert(chest_1.spawn_pool.has("fridge_1"), "chest_1 must spawn fridge_1")
	assert(chest_2.spawn_pool.has("rack_1"), "chest_2 must spawn rack_1")
	assert(chest_2.spawn_pool.has("foodbox_1"), "chest_2 must spawn foodbox_1")
	print("✔ Chest Item Data & Producer Drops verified!")

	# 22. Test Chest Gameplay Mechanics (Exhaustion Disappearance & Merge Reset)
	print("\n--- Testing Chest Gameplay Mechanics ---")
	var test_board_2: Board = board_scene.instantiate()
	add_child(test_board_2)
	test_board_2.clear_board()

	# Test 5 spawn charges and disappearance on exhaust
	var chest_view: ItemView = test_board_2.spawn_item_at(Vector2i(2, 2), "chest_1", ItemView.ItemState.NORMAL)
	assert(chest_view != null, "chest_view must spawn")
	assert(chest_view.current_charges == 5, "Initial charges must be 5")
	assert(chest_view.spawner_label.text == "5", "Spawner badge must display remaining charges 5")

	# Tap chest 5 times
	for tap_idx in range(5):
		assert(test_board_2.get_item_at(Vector2i(2, 2)) != null, "Chest should be on board before 5th tap completes")
		test_board_2._trigger_spawner(chest_view)
		if tap_idx < 4:
			assert(chest_view.current_charges == (4 - tap_idx), "Charges should decrement properly")

	# After 5th tap, chest should be removed from board
	assert(test_board_2.get_item_at(Vector2i(2, 2)) == null, "Chest must vanish and be removed from board after 5 uses")

	# Test merging two chests resets spawn counter
	test_board_2.clear_board()
	var c_view_a: ItemView = test_board_2.spawn_item_at(Vector2i(1, 1), "chest_1", ItemView.ItemState.NORMAL)
	var c_view_b: ItemView = test_board_2.spawn_item_at(Vector2i(1, 2), "chest_1", ItemView.ItemState.NORMAL)
	
	# Tap A 3 times -> 2 charges left
	test_board_2._trigger_spawner(c_view_a)
	test_board_2._trigger_spawner(c_view_a)
	test_board_2._trigger_spawner(c_view_a)
	assert(c_view_a.current_charges == 2, "c_view_a should have 2 charges left")

	# Merge A onto B -> should merge into chest_2 with fresh 5 charges!
	test_board_2._execute_merge(c_view_a, c_view_b)
	var merged_chest := test_board_2.get_item_at(Vector2i(1, 2))
	assert(merged_chest != null, "Merged chest must exist at target cell")
	assert(merged_chest.data.id == "chest_2", "Merged chest must be chest_2")
	assert(merged_chest.current_charges == 5, "Merged chest charges must be reset to 5!")
	assert(merged_chest.spawner_label.text == "5", "Merged chest badge must display 5")

	test_board_2.queue_free()
	print("✔ Chest Gameplay Mechanics (Disappearance & Charge Reset) verified!")

	# 23. Test Temporary Reward Slot & FIFO Queue
	print("\n--- Testing Temporary Reward Slot & FIFO Queue ---")
	ProgressionManager.clear_reward_queue()
	assert(ProgressionManager.has_pending_rewards() == false, "Queue must start empty")
	assert(ProgressionManager.get_reward_count() == 0, "Queue count must be 0")

	# Push rewards
	ProgressionManager.push_reward("chest_1")
	assert(ProgressionManager.has_pending_rewards() == true, "Queue must have pending rewards")
	assert(ProgressionManager.get_reward_count() == 1, "Queue count must be 1")
	assert(ProgressionManager.peek_reward() == "chest_1", "Peek reward must be chest_1")

	ProgressionManager.push_reward("chest_2")
	assert(ProgressionManager.get_reward_count() == 2, "Queue count must be 2")
	assert(ProgressionManager.peek_reward() == "chest_1", "FIFO peek must still be chest_1")

	# Test BottomNavBar reward slot UI
	var nav_scene_2: PackedScene = load("res://scenes/bottom_nav_bar.tscn")
	var reward_nav_bar: BottomNavBar = nav_scene_2.instantiate()
	add_child(reward_nav_bar)

	# Initially with 2 rewards, reward button should be visible and badge count "2"
	reward_nav_bar.update_reward_slot_display()
	assert(reward_nav_bar.reward_btn.visible == true, "Reward button must be visible when queue has items")
	assert(reward_nav_bar.reward_badge.visible == true, "Badge must be visible when count > 1")
	assert(reward_nav_bar.reward_badge_label.text == "2", "Badge must show count 2")

	# Pop one reward
	var popped_first := ProgressionManager.pop_reward()
	assert(popped_first == "chest_1", "Popped first item must be chest_1 (FIFO)")
	assert(ProgressionManager.get_reward_count() == 1, "Queue count must be 1")
	assert(ProgressionManager.peek_reward() == "chest_2", "Next item must be chest_2")

	reward_nav_bar.update_reward_slot_display()
	assert(reward_nav_bar.reward_btn.visible == true, "Reward button must remain visible when 1 item left")
	assert(reward_nav_bar.reward_badge.visible == false, "Badge must be hidden when count == 1")

	# Test slot position layout ordering (leftmost vs rightmost)
	reward_nav_bar.reward_slot_on_left = true
	assert(reward_nav_bar.hbox.get_child(0) == reward_nav_bar.reward_btn, "When reward_slot_on_left is true, reward_btn must be child 0 (leftmost)")
	reward_nav_bar.reward_slot_on_left = false
	assert(reward_nav_bar.hbox.get_child(reward_nav_bar.hbox.get_child_count() - 1) == reward_nav_bar.reward_btn, "When reward_slot_on_left is false, reward_btn must be rightmost")
	reward_nav_bar.reward_slot_on_left = true # reset to leftmost

	# Pop second reward -> queue empty -> button hides
	var popped_second := ProgressionManager.pop_reward()
	assert(popped_second == "chest_2", "Popped second item must be chest_2")
	assert(ProgressionManager.get_reward_count() == 0, "Queue count must be 0")
	reward_nav_bar.update_reward_slot_display()
	assert(reward_nav_bar.reward_btn.visible == false, "Reward button must be hidden when queue is empty")

	reward_nav_bar.queue_free()
	print("✔ Temporary Reward Slot & FIFO Queue verified!")

	# 24. Test Codex Discovery Chest Rewards & Persistence
	print("\n--- Testing Codex Discovery Chest Rewards & Persistence ---")
	ProgressionManager.reset_all()

	# egg_4 is tier 4 -> discovery should grant chest_purple_1
	var chest_rew := ProgressionManager.get_chest_reward_for_item("egg_4")
	assert(chest_rew == "chest_purple_1", "egg_4 milestone discovery must reward chest_purple_1")

	# egg_6 is max tier -> discovery should grant higher tier color chest
	var max_chest_rew := ProgressionManager.get_chest_reward_for_item("egg_6")
	assert(not max_chest_rew.is_empty() and max_chest_rew.begins_with("chest_"), "egg_6 max tier discovery must reward color chest")

	# Unlock and claim egg_4
	ProgressionManager.unlock_item("egg_4")
	var claim_res := ProgressionManager.claim_reward("egg_4")
	assert(claim_res.has("chest"), "Claim result must include chest")
	assert(claim_res.chest == "chest_purple_1", "Claimed chest must be chest_purple_1")
	assert(ProgressionManager.get_reward_count() == 1, "Claiming must have added chest to reward queue")
	assert(ProgressionManager.peek_reward() == "chest_purple_1", "Reward queue must have chest_purple_1")

	# Test Save & Restore of Reward Queue
	SaveManager.save_game(false)
	ProgressionManager.clear_reward_queue()
	assert(ProgressionManager.get_reward_count() == 0, "Cleared queue must be empty")
	SaveManager.load_game()
	assert(ProgressionManager.get_reward_count() == 1, "Restored queue must have 1 reward")
	assert(ProgressionManager.peek_reward() == "chest_purple_1", "Restored reward must be chest_purple_1")
	print("✔ Codex Discovery Chest Rewards & Persistence verified!")

	# 25. Test 4 New Color Chest Chains (Purple, Green, Yellow, Blue)
	print("\n--- Testing 4 Color Chest Chains ---")
	var chest_colors := ["purple", "green", "yellow", "blue"]
	var expected_focus := {
		"purple": "exp",
		"green": "energy",
		"yellow": "gold",
		"blue": "diamond"
	}
	var expected_charges := [5, 8, 12, 18]

	for color_name in chest_colors:
		var chain_id := "chest_%s" % color_name
		var focus_prefix: String = expected_focus[color_name]

		for t in range(1, 5):
			var chest_id := "%s_%d" % [chain_id, t]
			assert(ItemDatabase.has_item(chest_id), "ItemDatabase must contain %s" % chest_id)
			var chest: ItemData = ItemDatabase.get_item(chest_id)
			assert(chest.chain_id == chain_id, "Chain id must be %s" % chain_id)
			assert(chest.tier == t, "Tier must match %d" % t)
			assert(chest.max_tier == 4, "Max tier must be 4")
			assert(chest.is_spawner == true, "Chest must be a spawner")
			assert(chest.energy_cost == 0, "Chest must cost 0 energy to tap")
			assert(chest.disappears_when_exhausted == true, "Chest must disappear when exhausted")
			assert(chest.max_charges == expected_charges[t - 1], "Charges must match tier progression")
			assert(chest.icon_texture != null, "Chest %s must have a loaded icon texture" % chest_id)
			assert(not chest.spawn_pool.is_empty(), "Chest %s must have a non-empty spawn pool" % chest_id)

			# Check next tier id
			if t < 4:
				assert(chest.get_next_tier_id() == "%s_%d" % [chain_id, t + 1], "Next tier must be %s_%d" % [chain_id, t + 1])
			else:
				assert(chest.get_next_tier_id() == "", "Max tier next tier must be empty")

			# Verify high probability of focus items vs low tier spawner
			var focus_count := 0
			var spawner_count := 0
			for drop in chest.spawn_pool:
				if drop.begins_with(focus_prefix):
					focus_count += 1
				elif drop in ["foodbox_1", "oven_1", "fridge_1", "rack_1"]:
					spawner_count += 1
			assert(focus_count > 0, "Chest %s must drop focus resource %s" % [chest_id, focus_prefix])
			assert(focus_count >= spawner_count, "Chest %s focus drops must exceed spawner drops" % chest_id)

	print("✔ 4 Color Chest chains (16 items) verified!")

	# 26. Test Irene Dialogue Modal & Toaster UI
	print("\n--- Testing Irene Dialogue Modal & Toaster UI ---")
	var modal_scene := preload("res://scenes/irene_popup_modal.tscn")
	var irene_modal: IrenePopupModal = modal_scene.instantiate()
	add_child(irene_modal)
	assert(irene_modal != null, "IrenePopupModal must instantiate")

	# Test all 6 emotions exist in EMOTION_TEXTURES
	for emo in ["greeting", "explain", "happy", "thinking", "shocked", "admire"]:
		assert(IrenePopupModal.EMOTION_TEXTURES.has(emo), "Modal must support emotion: %s" % emo)
		assert(IrenePopupModal.EMOTION_TEXTURES[emo] != null, "Emotion %s texture must not be null" % emo)

	# Test dialogue typewriter and skip typing
	irene_modal.show_dialogue("Hello chef! Welcome to the tutorial.", "greeting")
	assert(irene_modal.visible == true, "Modal must become visible")
	assert(irene_modal._is_typing == true, "Modal must be in typing state")
	irene_modal.skip_typing()
	assert(irene_modal._is_typing == false, "skip_typing must end typing immediately")
	assert(irene_modal.continue_btn.visible == true, "Continue button must be visible after skip")

	# Test toaster
	var toast_scene := preload("res://scenes/irene_toast.tscn")
	var irene_toast: IreneToast = toast_scene.instantiate()
	add_child(irene_toast)
	assert(irene_toast != null, "IreneToast must instantiate")
	assert(not IreneToast.AMBIENT_TIPS.is_empty(), "Ambient tips must not be empty")
	irene_toast.show_toast("Here is a helpful tip!", "happy", 3.0)
	assert(irene_toast.visible == true, "Toast must become visible")
	irene_toast.dismiss_immediately()
	assert(irene_toast.visible == false, "dismiss_immediately must hide toast")

	irene_modal.queue_free()
	irene_toast.queue_free()
	print("✔ Irene Dialogue Modal & Toaster verified!")

	# 27. Test TutorialManager Step Progression & Reward Delivery
	print("\n--- Testing TutorialManager Step Progression & Reward Delivery ---")
	ProgressionManager.clear_reward_queue()
	var tut := TutorialManager.new()
	add_child(tut)

	assert(tut.current_step == TutorialManager.TutorialStep.NONE, "Initial step should be NONE")
	assert(tut.is_completed == false, "Tutorial should not be completed initially")

	# Step 1: Merge Left
	tut._set_step(TutorialManager.TutorialStep.MERGE_LEFT)
	assert(tut.current_step == TutorialManager.TutorialStep.MERGE_LEFT, "Step must be MERGE_LEFT")

	# Simulate merging center foodbox left -> produces foodbox_2
	tut._on_item_merged("foodbox_1", "foodbox_1", "foodbox_2", Vector2.ZERO)

	# Step 2: Merge Right
	tut._set_step(TutorialManager.TutorialStep.MERGE_RIGHT)
	assert(tut.current_step == TutorialManager.TutorialStep.MERGE_RIGHT, "Step must be MERGE_RIGHT")

	# Simulate merging foodbox_2 right -> produces foodbox_3
	tut._on_item_merged("foodbox_2", "foodbox_2", "foodbox_3", Vector2.ZERO)

	# Step 3: Spawn Item
	tut._set_step(TutorialManager.TutorialStep.SPAWN_ITEM)
	assert(tut.current_step == TutorialManager.TutorialStep.SPAWN_ITEM, "Step must be SPAWN_ITEM")

	# Step 4: Unlock First Item
	tut._set_step(TutorialManager.TutorialStep.UNLOCK_FIRST_ITEM)
	assert(tut.current_step == TutorialManager.TutorialStep.UNLOCK_FIRST_ITEM, "Step must be UNLOCK_FIRST_ITEM")

	# Step 5: Unlock 3 More Slots
	tut._set_step(TutorialManager.TutorialStep.UNLOCK_THREE_SLOTS)
	assert(tut.current_step == TutorialManager.TutorialStep.UNLOCK_THREE_SLOTS, "Step must be UNLOCK_THREE_SLOTS")
	assert(tut.locked_cleared_count == 0, "Cleared count must start at 0")

	tut._on_locked_item_cleared(Vector2i(2, 4), "egg_2")
	assert(tut.locked_cleared_count == 1, "Cleared count should be 1")
	tut._on_locked_item_cleared(Vector2i(3, 3), "leaf_2")
	assert(tut.locked_cleared_count == 2, "Cleared count should be 2")
	tut._on_locked_item_cleared(Vector2i(4, 3), "egg_3")
	assert(tut.locked_cleared_count == 3, "Cleared count should be 3")

	# Step 6: Deliver Quests
	tut._set_step(TutorialManager.TutorialStep.DELIVER_QUESTS)
	assert(tut.current_step == TutorialManager.TutorialStep.DELIVER_QUESTS, "Step must be DELIVER_QUESTS")

	# Step 7: Claim Reward
	tut._set_step(TutorialManager.TutorialStep.CLAIM_REWARD)
	assert(tut.current_step == TutorialManager.TutorialStep.CLAIM_REWARD, "Step must be CLAIM_REWARD")
	assert(ProgressionManager.get_reward_count() == 1, "Reward queue must have 1 reward")
	assert(ProgressionManager.peek_reward() == "chest_yellow_1", "Tutorial reward chest must be chest_yellow_1")

	# Step 8: Consume Reward
	tut._set_step(TutorialManager.TutorialStep.CONSUME_REWARD)
	assert(tut.current_step == TutorialManager.TutorialStep.CONSUME_REWARD, "Step must be CONSUME_REWARD")

	# Step 9: Store in Inventory
	tut._set_step(TutorialManager.TutorialStep.STORE_IN_INVENTORY)
	assert(tut.current_step == TutorialManager.TutorialStep.STORE_IN_INVENTORY, "Step must be STORE_IN_INVENTORY")

	# Step 10: Complete Tutorial
	tut._finish_tutorial()
	assert(tut.is_completed == true, "Tutorial should be marked completed")
	assert(tut.current_step == TutorialManager.TutorialStep.COMPLETED, "Step must be COMPLETED")

	# Test Serialization / Deserialization
	var tut_serialized := tut.serialize_data()
	assert(tut_serialized.is_completed == true, "Serialized completed must be true")
	assert(tut_serialized.locked_cleared_count == 3, "Serialized count must be 3")

	var tut2 := TutorialManager.new()
	tut2.load_data(tut_serialized)
	assert(tut2.is_completed == true, "Deserialized completed must be true")
	assert(tut2.locked_cleared_count == 3, "Deserialized count must be 3")

	tut.queue_free()
	tut2.queue_free()
	print("✔ TutorialManager Step Progression & Reward Delivery verified!")

	# 28. Test UI/UX Overhaul: Indicator, InfoArea, 3-Tab Codex, Board-like Inventory, Light Theme
	print("\n--- Testing UI/UX Overhaul Features ---")
	
	# 28.1 Selection Indicator & InfoArea Selling
	var overhaul_board: Board = board_scene.instantiate()
	add_child(overhaul_board)
	overhaul_board.clear_board()

	assert(overhaul_board._indicator_sprite != null, "Board must have _indicator_sprite")
	assert(overhaul_board._indicator_sprite.visible == false, "Indicator sprite must be hidden initially")
	assert(overhaul_board._indicator_sprite.texture != null, "Indicator sprite must have a texture loaded")

	var beef_item := overhaul_board.spawn_item_at(Vector2i(2, 2), "beef_1", ItemView.ItemState.NORMAL)
	overhaul_board.select_item(beef_item)
	assert(overhaul_board.selected_item == beef_item, "selected_item must be beef_item")
	assert(overhaul_board._indicator_sprite.visible == true, "Indicator must become visible when item selected")
	assert(overhaul_board._indicator_tween != null and overhaul_board._indicator_tween.is_valid(), "Indicator bounce tween must be running")

	# Test selling via board.sell_selected_item()
	var coins_before := EconomyManager.coins
	var sell_val := beef_item.data.sell_value
	overhaul_board.sell_selected_item()
	assert(EconomyManager.coins == coins_before + sell_val, "Selling item must credit sell_value to coins")
	assert(overhaul_board.get_item_at(Vector2i(2, 2)) == null, "Sold item must be removed from board")
	assert(overhaul_board.selected_item == null, "Selection must be cleared after sell")
	assert(overhaul_board._indicator_sprite.visible == false, "Indicator must hide after sell")

	overhaul_board.queue_free()

	# 28.2 Item Click Bounce Animation
	var click_item_view: ItemView = item_view_scene.instantiate()
	add_child(click_item_view)
	click_item_view.setup(ItemDatabase.get_item("egg_1"))
	assert(click_item_view.has_method("animate_click"), "ItemView must have animate_click method")
	click_item_view.animate_click()
	click_item_view.queue_free()

	# 28.3 Progression Modal 3 Tabs & focus_chain
	var prog_scene: PackedScene = load("res://scenes/progression_modal.tscn")
	var prog_inst: ProgressionModal = prog_scene.instantiate()
	add_child(prog_inst)

	assert(prog_inst.TABS.size() == 3, "Progression modal must have exactly 3 tabs")
	assert(prog_inst.TABS[0].id == "kitchen", "Tab 0 must be kitchen")
	assert(prog_inst.TABS[1].id == "chests", "Tab 1 must be chests")
	assert(prog_inst.TABS[2].id == "achievements", "Tab 2 must be achievements")

	# Test focus_chain
	prog_inst.focus_chain("chest_yellow")
	assert(prog_inst._current_tab_id == "chests", "focus_chain for chest_yellow must switch to chests tab")
	prog_inst.focus_chain("oven")
	assert(prog_inst._current_tab_id == "kitchen", "focus_chain for oven must switch to kitchen tab")

	# Verify light theme modal panel background
	var prog_panel: Panel = prog_inst.get_node("Panel")
	var prog_style: StyleBoxFlat = prog_panel.get_theme_stylebox("panel") as StyleBoxFlat
	assert(prog_style != null, "Progression modal must have StyleBoxFlat")
	assert(prog_style.bg_color.r > 0.85 and prog_style.bg_color.g > 0.85 and prog_style.bg_color.b > 0.85, "Progression modal must use light background tone")

	prog_inst.queue_free()

	# 28.4 Inventory Modal: Compact Board-like Tile Grid & Light Theme
	var inv_scene: PackedScene = load("res://scenes/inventory_modal.tscn")
	var inv_inst: InventoryModal = inv_scene.instantiate()
	add_child(inv_inst)

	var inv_panel: Panel = inv_inst.get_node("Panel")
	var inv_style: StyleBoxFlat = inv_panel.get_theme_stylebox("panel") as StyleBoxFlat
	assert(inv_style != null, "Inventory modal must have StyleBoxFlat")
	assert(inv_style.bg_color.r > 0.85 and inv_style.bg_color.g > 0.85 and inv_style.bg_color.b > 0.85, "Inventory modal must use light background tone")

	# Verify slot card generates 80x80 board-like cell with visible icon
	var empty_card := inv_inst._create_slot_card(0, "")
	assert(empty_card.custom_minimum_size == Vector2(80, 80), "Empty slot card must be 80x80")
	empty_card.queue_free()

	var occupied_card := inv_inst._create_slot_card(1, "foodbox_1")
	assert(occupied_card.custom_minimum_size == Vector2(80, 80), "Occupied slot card must be 80x80")
	var occ_btn: Button = occupied_card as Button
	assert(occ_btn != null, "Occupied card must be Button")
	assert(occ_btn.icon != null, "Occupied card button must have icon texture set")
	assert(occ_btn.expand_icon == true, "Occupied card button must have expand_icon set to true")
	occupied_card.queue_free()

	inv_inst.queue_free()

	# Test SoundManager.play_buy()
	assert(SoundManager.has_method("play_buy"), "SoundManager must have play_buy method")
	SoundManager.play_buy()

	# 28.5 Light Theme Modals & Quest Card: Option Modal, Shop Modal, Irene Popup Modal, Quest Card
	var opt_inst: OptionModal = option_scene.instantiate()
	add_child(opt_inst)
	var opt_style: StyleBoxFlat = opt_inst.get_node("Panel").get_theme_stylebox("panel") as StyleBoxFlat
	assert(opt_style != null and opt_style.bg_color.r > 0.85, "Option modal must use light background tone")
	opt_inst.queue_free()

	var shop_scene: PackedScene = load("res://scenes/shop_modal.tscn")
	var shop_inst: ShopModal = shop_scene.instantiate()
	add_child(shop_inst)
	var shop_style: StyleBoxFlat = shop_inst.get_node("Panel").get_theme_stylebox("panel") as StyleBoxFlat
	assert(shop_style != null and shop_style.bg_color.r > 0.85, "Shop modal must use light background tone")
	shop_inst.queue_free()

	var irene_inst: IrenePopupModal = modal_scene.instantiate()
	add_child(irene_inst)
	var irene_style: StyleBoxFlat = irene_inst.get_node("CenterContainer/PanelContainer").get_theme_stylebox("panel") as StyleBoxFlat
	assert(irene_style != null and irene_style.bg_color.r > 0.85, "Irene modal must use light background tone")
	irene_inst.queue_free()

	var quest_card_scene: PackedScene = load("res://scenes/quest_card.tscn")
	var qc_inst: QuestCard = quest_card_scene.instantiate()
	add_child(qc_inst)
	var qc_bg: Panel = qc_inst.get_node("Background")
	var qc_style: StyleBoxFlat = qc_bg.get_theme_stylebox("panel") as StyleBoxFlat
	assert(qc_style != null and qc_style.bg_color.r > 0.85, "QuestCard must use light background tone")
	qc_inst.queue_free()

	print("✔ UI/UX Overhaul Features verified!")

	# 29. Test Landscape Orientation System & 7x9 <-> 9x7 Board Rotation & Adaptive UI
	print("\n--- Testing Landscape Orientation System & 7x9 <-> 9x7 Board Rotation ---")
	assert(OrientationManager != null, "OrientationManager autoload must exist")
	assert(OrientationManager.has_method("set_landscape"), "OrientationManager must have set_landscape")
	assert(OrientationManager.has_method("toggle_orientation"), "OrientationManager must have toggle_orientation")
	assert(OrientationManager.has_method("detect_device_screen_landscape"), "OrientationManager must have detect_device_screen_landscape")

	# Test 29.1: Bijective 63-cell coordinate mapping
	var mapped_coords: Dictionary = {}
	for c in range(7):
		for r in range(9):
			var orig := Vector2i(c, r)
			var ls_coord := test_board.map_coord_for_orientation(orig, true)
			assert(ls_coord.x >= 0 and ls_coord.x < 9, "Mapped landscape col must be within 0..8, got %d" % ls_coord.x)
			assert(ls_coord.y >= 0 and ls_coord.y < 7, "Mapped landscape row must be within 0..6, got %d" % ls_coord.y)
			assert(not mapped_coords.has(ls_coord), "Collision detected in landscape mapping at %s" % str(ls_coord))
			mapped_coords[ls_coord] = orig

			var restored := test_board.map_coord_for_orientation(ls_coord, false)
			assert(restored == orig, "Restored coordinate %s must match original %s" % [str(restored), str(orig)])

	assert(mapped_coords.size() == 63, "All 63 cells must map uniquely without collision")

	# Center cell check
	assert(test_board.map_coord_for_orientation(Vector2i(3, 4), true) == Vector2i(4, 3), "Center cell (3, 4) in 7x9 must map to center (4, 3) in 9x7")
	assert(test_board.map_coord_for_orientation(Vector2i(4, 3), false) == Vector2i(3, 4), "Center cell (4, 3) in 9x7 must map back to center (3, 4) in 7x9")

	# Test 29.2: Dynamic board rotation with live items
	var rot_board: Board = board_scene.instantiate()
	add_child(rot_board)
	rot_board.clear_board()
	assert(rot_board.cols == 7 and rot_board.rows == 9, "Initial board must be 7x9")

	# Spawn items in portrait
	var center_item := rot_board.spawn_item_at(Vector2i(3, 4), "foodbox_3", ItemView.ItemState.NORMAL)
	center_item.current_charges = 7
	var locked_item_29 := rot_board.spawn_item_at(Vector2i(2, 4), "foodbox_1", ItemView.ItemState.LOCKED)
	var boxed_item_29 := rot_board.spawn_item_at(Vector2i(0, 0), "beef_1", ItemView.ItemState.BOXED, 4)
	rot_board.select_item(center_item)

	# Rotate to landscape (9x7)
	rot_board.rotate_board(true)
	assert(rot_board.cols == 9 and rot_board.rows == 7, "Board cols must be 9 and rows must be 7 in landscape")
	assert(rot_board.get_item_at(Vector2i(4, 3)) == center_item, "Center item must rotate from (3, 4) to (4, 3)")
	assert(center_item.current_charges == 7, "Charges must be preserved across rotation")
	assert(rot_board.get_item_at(Vector2i(4, 2)) == locked_item_29, "Locked item must rotate from (2, 4) to (4, 2)")
	assert(locked_item_29.is_locked() == true, "Locked status must be preserved")
	assert(rot_board.get_item_at(Vector2i(8, 0)) == boxed_item_29, "Boxed item at (0, 0) must rotate to (8, 0)")
	assert(boxed_item_29.is_boxed() == true and boxed_item_29.unlock_level == 4, "Boxed status & level must be preserved")
	assert(rot_board.selected_item == center_item, "Selected item reference must be maintained after rotation")

	# Rotate back to portrait (7x9)
	rot_board.rotate_board(false)
	assert(rot_board.cols == 7 and rot_board.rows == 9, "Board must return to 7x9")
	assert(rot_board.get_item_at(Vector2i(3, 4)) == center_item, "Center item must return to (3, 4)")
	assert(rot_board.get_item_at(Vector2i(2, 4)) == locked_item_29, "Locked item must return to (2, 4)")
	assert(rot_board.get_item_at(Vector2i(0, 0)) == boxed_item_29, "Boxed item must return to (0, 0)")

	rot_board.queue_free()
	print("✔ Board 7x9 <-> 9x7 rotation & lossless coordinate mapping verified!")

	# Test 29.3: Option Modal Orientation Button
	var opt_test: OptionModal = option_scene.instantiate()
	add_child(opt_test)
	opt_test.open_modal()
	assert(opt_test.orientation_btn != null, "OrientationBtn must exist in OptionModal")

	OrientationManager.set_landscape(false)
	opt_test._update_orientation_button()
	assert(opt_test.orientation_btn.text.contains("PORTRAIT"), "Button must show PORTRAIT when in portrait")

	opt_test._on_orientation_pressed()
	assert(OrientationManager.is_landscape == true, "OrientationBtn pressed must toggle to landscape")
	assert(opt_test.orientation_btn.text.contains("LANDSCAPE"), "Button must show LANDSCAPE when in landscape")

	opt_test._on_orientation_pressed()
	assert(OrientationManager.is_landscape == false, "OrientationBtn pressed again must toggle to portrait")
	assert(opt_test.orientation_btn.text.contains("PORTRAIT"), "Button must show PORTRAIT again")

	opt_test.queue_free()
	print("✔ Option Modal Orientation Button verified!")

	# Test 29.4: Main Scene Adaptive Layout in Landscape and Portrait
	var main_orient_scene: PackedScene = load("res://main.tscn")
	var main_orient_inst: MainGame = main_orient_scene.instantiate()
	add_child(main_orient_inst)

	# Apply Landscape Mode
	main_orient_inst.apply_orientation(true)
	assert(main_orient_inst.background_rect.texture.resource_path.contains("background_landscape"), "Landscape must use background_landscape.jpg")
	assert(main_orient_inst.board.cols == 9 and main_orient_inst.board.rows == 7, "Board must be 9x7 in landscape")
	assert(is_equal_approx(main_orient_inst.board.position.x, 438.0), "Board must be centered horizontally in landscape (x ~ 438)")
	assert(main_orient_inst.quest_container.offset_left == 32.0, "Quests must be on the left in landscape")
	assert(main_orient_inst.quest_container.offset_right <= 350.0, "Quests must stay on left side in landscape")
	assert(main_orient_inst.quest_manager.is_vertical == true, "QuestManager must have vertical layout in landscape")
	assert(main_orient_inst.bottom_nav_bar.offset_left >= 1200.0, "BottomNavBar must be on the right in landscape (x >= 1200)")
	assert(main_orient_inst.bottom_nav_bar.is_vertical == true, "BottomNavBar must have vertical layout in landscape")
	assert(main_orient_inst.bottom_bar.offset_top >= 650.0, "Information Area must be at the bottom in landscape (y >= 650)")
	assert(is_equal_approx(main_orient_inst.bottom_bar.offset_left, 440.0) and is_equal_approx(main_orient_inst.bottom_bar.offset_right, 1160.0), "Information area width must match board width in landscape")
	assert(main_orient_inst.hud.offset_bottom <= 90.0, "HUD must be at the top in landscape")
	assert(main_orient_inst.irene_toast.offset_top <= 100.0, "Irene toast must be at the top in landscape")
	assert(main_orient_inst.irene_toast.offset_left >= 400.0, "Irene toast must be centered at the top in landscape")

	# Apply Portrait Mode
	main_orient_inst.apply_orientation(false)
	assert(main_orient_inst.background_rect.texture.resource_path.contains("background.jpeg"), "Portrait must use background.jpeg")
	assert(main_orient_inst.board.cols == 7 and main_orient_inst.board.rows == 9, "Board must be 7x9 in portrait")
	assert(is_equal_approx(main_orient_inst.board.position.x, 37.0), "Board must be centered horizontally in portrait (x ~ 37)")
	assert(main_orient_inst.quest_container.offset_top == 114.0, "Quests must be at top in portrait")
	assert(main_orient_inst.quest_manager.is_vertical == false, "QuestManager must have horizontal layout in portrait")
	assert(main_orient_inst.bottom_nav_bar.offset_top == 1166.0, "BottomNavBar must be at bottom in portrait")
	assert(main_orient_inst.bottom_nav_bar.is_vertical == false, "BottomNavBar must have horizontal layout in portrait")
	assert(main_orient_inst.bottom_bar.offset_top == 1296.0, "Information Area must be at bottom in portrait")

	main_orient_inst.queue_free()
	print("✔ Main Scene Adaptive Layout in Landscape and Portrait verified!")

	# Test 29.5: Main Menu Background Switching
	var mm_scene: PackedScene = load("res://scenes/main_menu.tscn")
	var mm_inst: MainMenu = mm_scene.instantiate()
	add_child(mm_inst)

	mm_inst._on_orientation_changed(true)
	assert(mm_inst.background_rect.texture.resource_path.contains("background_landscape"), "MainMenu must use background_landscape in landscape")
	mm_inst._on_orientation_changed(false)
	assert(mm_inst.background_rect.texture.resource_path.contains("background.jpeg"), "MainMenu must use background.jpeg in portrait")

	mm_inst.queue_free()
	print("✔ Main Menu Background Switching verified!")

	# Test 29.6: SaveManager Orientation Persistence
	SaveManager.delete_save()
	OrientationManager.set_landscape(true, false)
	var save_res := SaveManager.save_game(false, false)
	assert(save_res == true, "Save game must succeed")

	OrientationManager.set_landscape(false, false)
	assert(OrientationManager.is_landscape == false, "Orientation reset to false")

	var load_res := SaveManager.load_game()
	assert(load_res == true, "Load game must succeed")
	assert(OrientationManager.is_landscape == true, "Saved landscape orientation must be restored on load")

	# Restore default portrait
	OrientationManager.set_landscape(false, true)
	print("✔ SaveManager Orientation Persistence verified!")

	# 30. Test Quest Generation Chain Filtering & Starter Quests
	print("\n--- Testing Quest Generation Chain Filtering & Starter Quests ---")
	var quest_scene: PackedScene = load("res://scenes/quest_manager.tscn")
	var qm: QuestManager = quest_scene.instantiate()
	add_child(qm)
	qm.setup(null)

	# 30.1 Verify starter quests 1, 2, 3 only require egg and leaf (reachable from Foodbox)
	assert(qm.active_quests.size() == 3, "Must have 3 quest slots")
	var all_starter_quests: Array[QuestData] = []
	for q in qm.active_quests:
		if q != null:
			all_starter_quests.append(q)
	for q in qm._pending_starter_quests:
		if q != null:
			all_starter_quests.append(q)
	assert(all_starter_quests.size() == 3, "Must have 3 starter quests total")
	for q in all_starter_quests:
		for req_id in q.required_item_ids:
			assert(req_id.begins_with("egg_") or req_id.begins_with("leaf_"), "Starter quest items must only be egg or leaf, got: %s" % req_id)

	# 30.2 Test quest generation when only egg/leaf are unlocked
	ProgressionManager.reset_all()
	ProgressionManager.unlock_item("foodbox_1", true)
	ProgressionManager.unlock_item("egg_1", true)
	ProgressionManager.unlock_item("leaf_1", true)

	for i in range(10):
		var generated_q: QuestData = qm._generate_new_quest()
		for req_id in generated_q.required_item_ids:
			assert(req_id.begins_with("egg_") or req_id.begins_with("leaf_"), "When only egg/leaf unlocked, quests must only pick egg/leaf, got: %s" % req_id)

	# 30.3 Test quest generation when beef is unlocked
	ProgressionManager.unlock_item("beef_1", true)
	var generated_beef_chain := false
	for i in range(50):
		var gen_q: QuestData = qm._generate_new_quest()
		for req_id in gen_q.required_item_ids:
			if req_id.begins_with("beef_"):
				generated_beef_chain = true
				break
		if generated_beef_chain:
			break
	assert(generated_beef_chain == true, "Once beef_1 is unlocked, beef items should appear in quest pools")

	qm.queue_free()
	print("✔ Quest Generation Chain Filtering & Starter Quests verified!")

	# 31. Test Quest Milestone Progression & BottomNavBar Gating
	print("\n--- Testing Quest Milestone Progression & BottomNavBar Gating ---")
	var qm_prog: QuestManager = quest_scene.instantiate()
	add_child(qm_prog)
	qm_prog.setup(null)
	qm_prog.completed_quest_count = 0

	var nav_test: BottomNavBar = nav_scene.instantiate()
	add_child(nav_test)
	nav_test.update_milestone_locks()

	# Initially at 0 quests completed: Backpack & Shop are locked
	assert(qm_prog.completed_quest_count == 0, "Initial completed count must be 0")
	assert(qm_prog.is_backpack_unlocked() == false, "Backpack must be locked initially")
	assert(qm_prog.is_shop_unlocked() == false, "Shop must be locked initially")
	assert(nav_test.inventory_btn.disabled == true, "InventoryBtn must be disabled when locked")
	assert(nav_test.shop_btn.disabled == true, "ShopBtn must be disabled when locked")
	assert(nav_test.is_inventory_unlocked() == false, "BottomNavBar must report inventory locked")
	assert(nav_test.is_shop_unlocked() == false, "BottomNavBar must report shop locked")
	assert(nav_test.is_pos_inside_inventory_button(Vector2(100, 100)) == false, "Dropping into locked inventory button must return false")

	# Complete 4 quests -> Backpack and Shop still locked
	var milestone_tracker := {"milestones": []}
	var milestone_sub := func(m: String): milestone_tracker["milestones"].append(m)
	GameEvents.quest_milestone_unlocked.connect(milestone_sub)

	qm_prog.complete_active_quest_debug() # 1
	qm_prog.complete_active_quest_debug() # 2
	qm_prog.complete_active_quest_debug() # 3
	qm_prog.complete_active_quest_debug() # 4
	assert(qm_prog.completed_quest_count == 4, "Completed count should be 4")
	assert(qm_prog.is_backpack_unlocked() == false, "Backpack still locked at 4")
	assert(qm_prog.is_shop_unlocked() == false, "Shop still locked at 4")
	assert(nav_test.inventory_btn.disabled == true, "InventoryBtn must be disabled at 4")
	assert(nav_test.shop_btn.disabled == true, "ShopBtn must be disabled at 4")

	# Complete 5th quest -> Both Backpack and Shop unlock!
	qm_prog.complete_active_quest_debug() # 5
	assert(qm_prog.completed_quest_count == 5, "Completed count should be 5")
	assert(qm_prog.is_backpack_unlocked() == true, "Backpack must be unlocked at 5")
	assert(qm_prog.is_shop_unlocked() == true, "Shop must be unlocked at 5")
	assert(milestone_tracker["milestones"].has("backpack"), "Milestone signal must broadcast 'backpack'")
	assert(milestone_tracker["milestones"].has("shop"), "Milestone signal must broadcast 'shop'")
	assert(nav_test.is_inventory_unlocked() == true, "BottomNavBar must report backpack unlocked")
	assert(nav_test.is_shop_unlocked() == true, "BottomNavBar must report shop unlocked")
	assert(nav_test.inventory_btn.disabled == false, "InventoryBtn must be enabled when unlocked")
	assert(nav_test.shop_btn.disabled == false, "ShopBtn must be enabled when unlocked")

	GameEvents.quest_milestone_unlocked.disconnect(milestone_sub)

	# Test Save & Restore of completed_quest_count
	SaveManager.quest_manager_ref = qm_prog
	SaveManager.save_game(false)
	qm_prog.completed_quest_count = 0
	assert(qm_prog.completed_quest_count == 0, "Reset completed count to 0")
	SaveManager.load_game(null, qm_prog)
	assert(qm_prog.completed_quest_count == 5, "Restored completed count must be 5")
	assert(qm_prog.is_backpack_unlocked() == true, "Restored backpack must remain unlocked")
	assert(qm_prog.is_shop_unlocked() == true, "Restored shop must remain unlocked")

	qm_prog.queue_free()
	nav_test.queue_free()
	SaveManager.quest_manager_ref = null
	print("✔ Quest Milestone Progression & BottomNavBar Gating verified!")

	# 32. Test Extended Event-Driven Tutorial Triggers & Flags Persistence
	print("\n--- Testing Extended Event-Driven Tutorial Triggers & Flags Persistence ---")
	var tut_ext := TutorialManager.new()
	add_child(tut_ext)
	tut_ext.setup(null, null, null, null)

	assert(tut_ext._shown_flags.is_empty(), "_shown_flags must start empty")

	# Test FIRST_QUEST trigger
	var test_q := QuestData.new()
	test_q.id = "test_q"
	tut_ext._on_quest_completed(test_q)
	assert(tut_ext._shown_flags.get("first_quest", false) == true, "first_quest flag must be set")

	# Test FIRST_PRODUCER_UNBOX trigger
	tut_ext._on_item_unboxed("oven_1")
	assert(tut_ext._shown_flags.get("first_producer_unbox", false) == true, "first_producer_unbox flag must be set")

	# Test FIRST_SPAWNER_EXHAUST trigger
	tut_ext._on_spawner_exhausted("foodbox_3")
	assert(tut_ext._shown_flags.get("first_spawner_exhaust", false) == true, "first_spawner_exhaust flag must be set")

	# Test FIRST_SELL trigger
	tut_ext._on_item_sold("egg_1", 5)
	assert(tut_ext._shown_flags.get("first_sell", false) == true, "first_sell flag must be set")

	# Test FIRST_BACKPACK_STORE trigger
	tut_ext._on_item_stored_in_inventory("egg_1")
	assert(tut_ext._shown_flags.get("first_backpack_store", false) == true, "first_backpack_store flag must be set")

	# Test serialization of _shown_flags
	var serialized_tut := tut_ext.serialize_data()
	assert(serialized_tut.has("shown_flags"), "Serialized data must include shown_flags")
	assert(serialized_tut["shown_flags"].size() == 5, "All 5 shown flags must be serialized")

	var tut_ext_2 := TutorialManager.new()
	tut_ext_2.load_data(serialized_tut)
	assert(tut_ext_2._shown_flags.get("first_quest", false) == true, "Restored first_quest must be true")
	assert(tut_ext_2._shown_flags.get("first_producer_unbox", false) == true, "Restored first_producer_unbox must be true")
	assert(tut_ext_2._shown_flags.get("first_spawner_exhaust", false) == true, "Restored first_spawner_exhaust must be true")
	assert(tut_ext_2._shown_flags.get("first_sell", false) == true, "Restored first_sell must be true")
	assert(tut_ext_2._shown_flags.get("first_backpack_store", false) == true, "Restored first_backpack_store must be true")

	tut_ext.queue_free()
	tut_ext_2.queue_free()
	print("✔ Extended Event-Driven Tutorial Triggers & Flags Persistence verified!")

	# 33. Test Radial Tier Bias & Preview Locked Spawners
	print("\n--- Testing Radial Tier Bias & Preview Locked Spawners ---")
	var main_rb_scene: PackedScene = load("res://main.tscn")
	var main_rb_inst: MainGame = main_rb_scene.instantiate()
	add_child(main_rb_inst)

	# Verify preview items in portrait (1, 2) = oven_1, (5, 2) = fridge_1, (3, 6) = rack_1 in LOCKED state
	var oven_preview := main_rb_inst.board.get_item_at(Vector2i(1, 2))
	var fridge_preview := main_rb_inst.board.get_item_at(Vector2i(5, 2))
	var rack_preview := main_rb_inst.board.get_item_at(Vector2i(3, 6))

	assert(oven_preview != null and oven_preview.data.id == "oven_1", "Cell (1, 2) must be oven_1 preview")
	assert(oven_preview.is_hidden() == true, "oven_1 preview outside 3x3 must start in HIDDEN state")
	oven_preview.reveal(false)
	assert(oven_preview.is_locked() == true, "oven_1 preview must reveal into LOCKED state")

	assert(fridge_preview != null and fridge_preview.data.id == "fridge_1", "Cell (5, 2) must be fridge_1 preview")
	assert(fridge_preview.is_hidden() == true, "fridge_1 preview outside 3x3 must start in HIDDEN state")
	fridge_preview.reveal(false)
	assert(fridge_preview.is_locked() == true, "fridge_1 preview must reveal into LOCKED state")

	assert(rack_preview != null and rack_preview.data.id == "rack_1", "Cell (3, 6) must be rack_1 preview")
	assert(rack_preview.is_hidden() == true, "rack_1 preview outside 3x3 must start in HIDDEN state")
	rack_preview.reveal(false)
	assert(rack_preview.is_locked() == true, "rack_1 preview must reveal into LOCKED state")

	# Test _get_tiered_drop helper
	var t1_count := 0
	var t2_count := 0
	for i in range(100):
		var near_item := main_rb_inst._get_tiered_drop(1.0)
		if near_item.ends_with("_1"):
			t1_count += 1
		var far_item := main_rb_inst._get_tiered_drop(2.5)
		if far_item.ends_with("_2"):
			t2_count += 1
	assert(t1_count > 65, "Distance <= 1.5 must be biased toward tier 1, got %d/100" % t1_count)
	assert(t2_count > 65, "Distance > 1.5 must be biased toward tier 2, got %d/100" % t2_count)

	main_rb_inst.queue_free()
	print("✔ Radial Tier Bias & Preview Locked Spawners verified!")

	# 34. Test Boxed Perimeter Item Color/Identity Cue
	print("\n--- Testing Boxed Perimeter Item Color/Identity Cue ---")
	var tint_board: Board = board_scene.instantiate()
	add_child(tint_board)
	tint_board.clear_board()

	# Spawn boxed beef item (data.color is reddish-orange)
	var boxed_beef := tint_board.spawn_item_at(Vector2i(0, 0), "beef_1", ItemView.ItemState.BOXED, 2)
	assert(boxed_beef != null, "Boxed beef item must spawn")
	var beef_data := ItemDatabase.get_item("beef_1")
	var expected_modulate := Color.WHITE.lerp(beef_data.color, 0.3)
	assert(boxed_beef.sprite.modulate.is_equal_approx(expected_modulate), "Boxed sprite must be modulated subtly toward data.color")
	assert(boxed_beef.sprite.modulate != Color.WHITE, "Boxed sprite must not be full white")

	# Spawn boxed drink item (data.color is blue)
	var boxed_drink := tint_board.spawn_item_at(Vector2i(0, 1), "drink_1", ItemView.ItemState.BOXED, 2)
	var drink_data := ItemDatabase.get_item("drink_1")
	var expected_drink_modulate := Color.WHITE.lerp(drink_data.color, 0.3)
	assert(boxed_drink.sprite.modulate.is_equal_approx(expected_drink_modulate), "Boxed drink sprite must be modulated toward drink data.color")
	assert(boxed_drink.sprite.modulate != boxed_beef.sprite.modulate, "Different chain boxed items must have distinct tints")

	tint_board.queue_free()
	print("✔ Boxed Perimeter Item Color/Identity Cue verified!")

	# 35. Test ItemState.HIDDEN, Cell Hiding, and Progressive Outward Reveal
	print("\n--- Testing ItemState.HIDDEN & Progressive Outward Reveal ---")
	var fog_board: Board = board_scene.instantiate()
	add_child(fog_board)
	fog_board.clear_board()

	# Spawn a hidden item at (1, 1)
	var hidden_item := fog_board.spawn_item_at(Vector2i(1, 1), "egg_1", ItemView.ItemState.HIDDEN, 1)
	assert(hidden_item != null, "Hidden item must spawn")
	assert(hidden_item.is_hidden() == true, "item.is_hidden() must be true")
	assert(hidden_item.visible == false, "Hidden item must not be visible")

	# Check corresponding cell
	fog_board.update_cell_lock_visual(Vector2i(1, 1))
	var cell_1_1: BoardCell = fog_board._cells[1][1]
	assert(cell_1_1.is_hidden_cell == true, "Cell with hidden item must have is_hidden_cell true")
	assert(cell_1_1.visible == false, "Cell with hidden item must be invisible")

	# Test reveal() method on item
	hidden_item.reveal(false)
	assert(hidden_item.is_hidden() == false, "item.is_hidden() must be false after reveal")
	assert(hidden_item.is_locked() == true, "Item with req_level 1 must reveal to LOCKED")
	assert(hidden_item.visible == true, "Item must be visible after reveal")
	fog_board.update_cell_lock_visual(Vector2i(1, 1))
	assert(cell_1_1.visible == true, "Cell must become visible after item reveal")

	# Test reveal_surrounding_items
	var hidden_nbr1 := fog_board.spawn_item_at(Vector2i(1, 2), "leaf_1", ItemView.ItemState.HIDDEN, 1)
	var hidden_nbr2 := fog_board.spawn_item_at(Vector2i(2, 2), "beef_1", ItemView.ItemState.HIDDEN, 2)
	assert(hidden_nbr1.is_hidden() == true, "Neighbor 1 must be hidden")
	assert(hidden_nbr2.is_hidden() == true, "Neighbor 2 must be hidden")

	var revealed_items := fog_board.reveal_surrounding_items(Vector2i(1, 1))
	assert(revealed_items.has(hidden_nbr1), "hidden_nbr1 must be in revealed_items")
	assert(revealed_items.has(hidden_nbr2), "hidden_nbr2 must be in revealed_items")
	assert(hidden_nbr1.is_hidden() == false and hidden_nbr1.is_locked() == true, "hidden_nbr1 must reveal to LOCKED")
	assert(hidden_nbr2.is_hidden() == false and hidden_nbr2.is_boxed() == true, "hidden_nbr2 with req_level 2 must reveal to BOXED")

	fog_board.queue_free()
	print("✔ ItemState.HIDDEN & Progressive Outward Reveal verified!")

	# 36. Test Non-Consumable Guarantee in Populated Board Items
	print("\n--- Testing Non-Consumable Guarantee in Populated Board Items ---")
	var main_pop_scene: PackedScene = load("res://main.tscn")
	var main_pop: MainGame = main_pop_scene.instantiate()
	add_child(main_pop)
	main_pop._setup_initial_board()

	var pop_items := main_pop.board.get_all_items_on_board(false)
	var consumable_count := 0
	for it in pop_items:
		if it and it.data and it.data.is_consumable:
			consumable_count += 1
	assert(consumable_count == 0, "Populated board must NOT have any consumable items (gold/diamond/exp/energy), found %d" % consumable_count)

	# Verify active 3x3 starting island
	var visible_cell_count := 0
	for c in range(main_pop.board.cols):
		for r in range(main_pop.board.rows):
			var cell: BoardCell = main_pop.board._cells[c][r]
			if is_instance_valid(cell) and cell.visible:
				visible_cell_count += 1
	assert(visible_cell_count == 9, "Initial starting active island must have exactly 9 visible cells, got %d" % visible_cell_count)

	main_pop.queue_free()
	print("✔ Non-Consumable Guarantee & 3x3 Starting Island verified!")

	# 37. Test Behavioral Guidance Watchers (Coin Spending & Board Full Selling)
	print("\n--- Testing Behavioral Guidance Watchers ---")
	var tut_bg := TutorialManager.new()
	add_child(tut_bg)
	tut_bg.setup(null, null, null, null)
	tut_bg.is_completed = true # Simulating post-tutorial active gameplay
	if is_instance_valid(QuestManager.instance):
		QuestManager.instance.completed_quest_count = 5

	# Test coin consumed watcher
	assert(tut_bg._shown_flags.get("first_coin_spent_guide", false) == false, "first_coin_spent_guide starts false")
	GameEvents.coin_consumed.emit(25)
	assert(tut_bg._shown_flags.get("first_coin_spent_guide", false) == true, "first_coin_spent_guide must trigger upon coin consumed")

	# Test board full 3 times watcher
	assert(tut_bg._shown_flags.get("board_full_sell_guide", false) == false, "board_full_sell_guide starts false")
	assert(tut_bg.board_full_count == 0, "board_full_count starts 0")
	GameEvents.board_full_attempted.emit()
	assert(tut_bg.board_full_count == 1, "board_full_count should be 1")
	assert(tut_bg._shown_flags.get("board_full_sell_guide", false) == false, "board_full_sell_guide should not trigger at 1")
	GameEvents.board_full_attempted.emit()
	assert(tut_bg.board_full_count == 2, "board_full_count should be 2")
	assert(tut_bg._shown_flags.get("board_full_sell_guide", false) == false, "board_full_sell_guide should not trigger at 2")
	GameEvents.board_full_attempted.emit()
	assert(tut_bg.board_full_count == 3, "board_full_count should be 3")
	assert(tut_bg._shown_flags.get("board_full_sell_guide", false) == true, "board_full_sell_guide must trigger at 3 board-full events")

	tut_bg.queue_free()
	print("✔ Behavioral Guidance Watchers verified!")

	# 38. Test Tutorial Progression Claim & First Quest Delivery Highlight
	print("\n--- Testing Tutorial Progression Claim & Delivery Highlight ---")
	var tut_test := TutorialManager.new()
	add_child(tut_test)
	tut_test.setup(null, null, null, null)
	assert(TutorialManager.TutorialStep.CLAIM_PROGRESSION == 16, "CLAIM_PROGRESSION enum must exist")
	tut_test._set_step(TutorialManager.TutorialStep.CLAIM_PROGRESSION)
	assert(tut_test.current_step == TutorialManager.TutorialStep.CLAIM_PROGRESSION, "Current step must be CLAIM_PROGRESSION")

	var feat38_qc_scene: PackedScene = load("res://scenes/quest_card.tscn")
	var feat3_qc: QuestCard = feat38_qc_scene.instantiate()
	add_child(feat3_qc)
	var feat3_q := QuestData.new()
	feat3_q.id = "feat3_q"
	feat3_q.customer_name = "Chef Luigi"
	feat3_q.required_item_ids = ["egg_1"]
	feat3_qc.setup(feat3_q, true, ["egg_1"])
	assert(feat3_qc.is_ready_to_deliver == true, "QuestCard should be ready to deliver")
	feat3_qc.set_delivery_highlight(true)
	assert(feat3_qc._highlight_tween != null and feat3_qc._highlight_tween.is_valid(), "Delivery highlight tween must be active")
	feat3_qc.set_delivery_highlight(false)
	assert(feat3_qc._highlight_tween == null, "Delivery highlight tween must be cleared")
	feat3_qc.queue_free()
	tut_test.queue_free()
	print("✔ Tutorial Progression Claim & First Quest Delivery Highlight verified!")

	# 39. Test Temporary Slot Tile Styling & Shine Shader
	print("\n--- Testing Temporary Slot Tile Styling & Shine ---")
	assert(FileAccess.file_exists("res://shaders/shine_gleam.gdshader"), "Shine gleam shader must exist")
	var feat39_nav_scene: PackedScene = load("res://scenes/bottom_nav_bar.tscn")
	var feat39_nav_bar: BottomNavBar = feat39_nav_scene.instantiate()
	add_child(feat39_nav_bar)
	assert(is_instance_valid(feat39_nav_bar.reward_btn), "RewardBtn must exist in BottomNavBar")
	assert(is_instance_valid(feat39_nav_bar.shine_overlay), "ShineOverlay must exist in RewardBtn")
	ProgressionManager.clear_reward_queue()
	feat39_nav_bar.update_reward_slot_display()
	assert(feat39_nav_bar.reward_btn.visible == false, "Reward slot should be hidden when queue is empty")
	ProgressionManager.push_reward("chest_yellow_1")
	feat39_nav_bar.update_reward_slot_display()
	assert(feat39_nav_bar.reward_btn.visible == true, "Reward slot should be visible when item is in queue")
	assert(feat39_nav_bar.shine_overlay.visible == true, "ShineOverlay must be active when item is in queue")
	ProgressionManager.clear_reward_queue()
	feat39_nav_bar.update_reward_slot_display()
	feat39_nav_bar.queue_free()
	print("✔ Temporary Slot Tile Styling & Shine verified!")

	# 40. Test Extra Inventory Expansion System
	print("\n--- Testing Extra Inventory Expansion System ---")
	InventoryManager.unlocked_rows = 2
	InventoryManager.clear_all()
	assert(InventoryManager.get_max_slots() == 8, "Initial slots must be 8 (2 rows * 4)")
	assert(InventoryManager.MAX_ROWS == 9, "MAX_ROWS must be 9")
	assert(InventoryManager.unlocked_rows == 2, "Initial unlocked_rows must be 2")

	# Cost for Row 3: 200 Gold
	var feat40_cost_r3 := InventoryManager.get_next_row_cost()
	assert(feat40_cost_r3.currency == "coins" and feat40_cost_r3.amount == 200, "Row 3 must cost 200 Gold Coins")
	EconomyManager.coins = 100
	assert(InventoryManager.can_unlock_next_row() == false, "Cannot unlock Row 3 with 100 coins")
	EconomyManager.coins = 250
	assert(InventoryManager.can_unlock_next_row() == true, "Can unlock Row 3 with 250 coins")
	var feat40_unlocked_r3 := InventoryManager.unlock_next_row()
	assert(feat40_unlocked_r3 == true, "Unlocking Row 3 must succeed")
	assert(InventoryManager.unlocked_rows == 3, "unlocked_rows should now be 3")
	assert(InventoryManager.get_max_slots() == 12, "Max slots should now be 12 (3 rows * 4)")
	assert(EconomyManager.coins == 50, "Coins must be deducted (250 - 200 = 50)")

	# Cost for Row 4: 5 Diamonds
	var feat40_cost_r4 := InventoryManager.get_next_row_cost()
	assert(feat40_cost_r4.currency == "gems" and feat40_cost_r4.amount == 5, "Row 4 must cost 5 Diamonds (gems)")
	EconomyManager.gems = 2
	assert(InventoryManager.can_unlock_next_row() == false, "Cannot unlock Row 4 with 2 gems")
	EconomyManager.gems = 10
	assert(InventoryManager.can_unlock_next_row() == true, "Can unlock Row 4 with 10 gems")
	var feat40_unlocked_r4 := InventoryManager.unlock_next_row()
	assert(feat40_unlocked_r4 == true, "Unlocking Row 4 must succeed")
	assert(InventoryManager.unlocked_rows == 4, "unlocked_rows should now be 4")
	assert(InventoryManager.get_max_slots() == 16, "Max slots should now be 16")
	assert(EconomyManager.gems == 5, "Gems must be deducted (10 - 5 = 5)")

	# Test serialization
	var feat40_inv_data := InventoryManager.serialize_data()
	assert(feat40_inv_data.get("unlocked_rows", 0) == 4, "Serialized data must preserve unlocked_rows")
	InventoryManager.unlocked_rows = 2
	InventoryManager.load_data(feat40_inv_data)
	assert(InventoryManager.unlocked_rows == 4, "load_data must restore unlocked_rows to 4")
	assert(InventoryManager.get_max_slots() == 16, "Max slots restored to 16")
	print("✔ Extra Inventory Expansion System verified!")

	# 41. Test Quest System Pacing, Cooldowns & Ultimate Quest
	print("\n--- Testing Quest Pacing, Cooldowns & Ultimate Quest ---")
	var feat41_qm_scene: PackedScene = load("res://scenes/quest_manager.tscn")
	var feat41_qm: QuestManager = feat41_qm_scene.instantiate()
	add_child(feat41_qm)
	feat41_qm.setup(null, null)
	assert(feat41_qm.active_quests.size() == 3, "QuestManager must track 3 quest slots")
	assert(feat41_qm.active_quests[0] != null, "Slot 0 should have initial active quest")
	assert(feat41_qm._slot_cooldowns[1] > 0.0, "Slot 1 should arrive with a gap / cooldown")
	assert(feat41_qm._slot_cooldowns[2] > feat41_qm._slot_cooldowns[1], "Slot 2 cooldown should be greater than Slot 1")

	# Test Cooldown after delivering quest
	var feat41_q0: QuestData = feat41_qm.active_quests[0]
	feat41_qm._on_deliver_pressed(feat41_q0)
	assert(feat41_qm.active_quests[0] == null, "Delivered slot should be null during cooldown")
	assert(feat41_qm._slot_cooldowns[0] > 0.0, "Delivered slot must have a positive cooldown timer")

	# Test Board has_locked_or_boxed_items
	var feat41_b_scene: PackedScene = load("res://scenes/board.tscn")
	var feat41_test_b: Board = feat41_b_scene.instantiate()
	add_child(feat41_test_b)
	assert(feat41_test_b.has_locked_or_boxed_items() == false, "Empty board has no locked or boxed items")
	feat41_test_b.spawn_item_at(Vector2i(1, 1), "egg_1", ItemView.ItemState.LOCKED)
	assert(feat41_test_b.has_locked_or_boxed_items() == true, "Board with locked item must report true")
	feat41_test_b.clear_board()
	assert(feat41_test_b.has_locked_or_boxed_items() == false, "Cleared board must report false")
	feat41_test_b.spawn_item_at(Vector2i(0, 0), "foodbox_1", ItemView.ItemState.NORMAL)

	# Test Ultimate Quest Trigger
	feat41_qm.board_ref = feat41_test_b
	feat41_qm.ultimate_quest_active = false
	feat41_qm.ultimate_quest_completed = false
	feat41_qm.check_ultimate_quest_trigger()
	assert(feat41_qm.ultimate_quest_active == true, "Ultimate quest must trigger when board is completely clear")
	var feat41_uq: QuestData = feat41_qm.active_quests[0]
	assert(feat41_uq != null and feat41_uq.id == "ultimate_quest", "Slot 0 must contain ultimate_quest")
	var feat41_expected_reqs := ["egg_6", "leaf_5", "beef_7", "cake_6", "sandwich_6", "drink_5", "util_12"]
	for req in feat41_expected_reqs:
		assert(feat41_uq.required_item_ids.has(req), "Ultimate quest must require normal maxed item %s" % req)
	assert(feat41_uq.required_item_ids.size() == 7, "Ultimate quest must require exactly 7 maxed normal items")

	feat41_test_b.queue_free()
	feat41_qm.queue_free()
	print("✔ Quest Pacing, Cooldowns & Ultimate Quest verified!")

	print("\n=== ALL TESTS PASSED SUCCESSFULLY! ===")
	get_tree().quit(0)
