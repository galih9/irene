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
				assert(it.is_spawner == true, "%s must be a spawner" % item_id)
				assert(it.spawn_pool.size() > 0, "%s spawn_pool must not be empty" % item_id)

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

	# 9. Test 6x9 Board & Visual Parameters
	print("\n--- Testing 6x9 Board & Visual Parameters ---")
	var board_scene: PackedScene = load("res://scenes/board.tscn")
	var test_board: Board = board_scene.instantiate()
	add_child(test_board)

	assert(test_board.cols == 6, "Board must have 6 columns")
	assert(test_board.rows == 9, "Board must have 9 rows")
	var cells_cnt: int = test_board.get_node("CellsContainer").get_child_count()
	assert(cells_cnt == 54, "Board must have 54 cells (6x9 = 54), got %d" % cells_cnt)

	test_board.queue_free()
	print("✔ 6x9 Board verified!")

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

	print("\n=== ALL TESTS PASSED SUCCESSFULLY! ===")
	get_tree().quit(0)
