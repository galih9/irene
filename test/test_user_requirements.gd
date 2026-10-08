extends Node

func _ready() -> void:
	print("=== VERIFYING USER REQUIREMENTS ===")
	var board_scene: PackedScene = load("res://scenes/board.tscn")
	var board: Board = board_scene.instantiate()
	add_child(board)
	board.clear_board()

	# -------------------------------------------------------------
	# 1. Boxed item has dark tile cover like locked item
	# -------------------------------------------------------------
	print("1. Testing Boxed item dark cover...")
	var boxed_item := board.spawn_item_at(Vector2i(1, 1), "pantry_1", ItemView.ItemState.BOXED, 3)
	board.update_cell_lock_visual(Vector2i(1, 1))
	var cell_boxed: BoardCell = board._cells[1][1]
	assert(cell_boxed.is_locked == true, "Boxed cell must have is_locked = true")

	var locked_item := board.spawn_item_at(Vector2i(2, 2), "pantry_1", ItemView.ItemState.LOCKED)
	board.update_cell_lock_visual(Vector2i(2, 2))
	var cell_locked: BoardCell = board._cells[2][2]
	assert(cell_locked.is_locked == true, "Locked cell must have is_locked = true")

	var normal_item := board.spawn_item_at(Vector2i(3, 3), "pantry_1", ItemView.ItemState.NORMAL)
	board.update_cell_lock_visual(Vector2i(3, 3))
	var cell_normal: BoardCell = board._cells[3][3]
	assert(cell_normal.is_locked == false, "Normal cell must have is_locked = false")
	print("  -> Boxed item dark tile cover verified!")

	# -------------------------------------------------------------
	# 2. Consumable visuals use items_v2, HUD retains v1
	# -------------------------------------------------------------
	print("2. Testing Consumables items_v2 vs HUD v1...")
	for chain_id in ["exp", "gold", "energy", "diamond"]:
		var t1: ItemData = ItemDatabase.get_item("%s_1" % chain_id)
		assert(t1 != null, "Item %s_1 must exist" % chain_id)
		assert("items_v2" in t1.icon_texture.resource_path, "%s_1 must use items_v2 asset! Path: %s" % [chain_id, t1.icon_texture.resource_path])

	var hud_scene: PackedScene = load("res://scenes/hud.tscn")
	var hud: HUD = hud_scene.instantiate()
	add_child(hud)
	var coin_path: String = (hud.coin_icon.texture as AtlasTexture).atlas.resource_path if hud.coin_icon.texture is AtlasTexture else hud.coin_icon.texture.resource_path
	var gem_path: String = (hud.gem_icon.texture as AtlasTexture).atlas.resource_path if hud.gem_icon.texture is AtlasTexture else hud.gem_icon.texture.resource_path
	var energy_path: String = (hud.energy_icon.texture as AtlasTexture).atlas.resource_path if hud.energy_icon.texture is AtlasTexture else hud.energy_icon.texture.resource_path
	var level_path: String = (hud.level_icon.texture as AtlasTexture).atlas.resource_path if hud.level_icon.texture is AtlasTexture else hud.level_icon.texture.resource_path
	assert("items/rewards" in coin_path and not "items_v2" in coin_path, "HUD coin_icon must use items (v1), got: %s" % coin_path)
	assert("items/rewards" in gem_path and not "items_v2" in gem_path, "HUD gem_icon must use items (v1), got: %s" % gem_path)
	assert("items/rewards" in energy_path and not "items_v2" in energy_path, "HUD energy_icon must use items (v1), got: %s" % energy_path)
	assert("items/rewards" in level_path and not "items_v2" in level_path, "HUD level_icon must use items (v1), got: %s" % level_path)
	hud.queue_free()
	print("  -> Consumable visual updates & HUD v1 icons verified!")

	# -------------------------------------------------------------
	# 3. Visuals for pantry, oven, healthy, staple, bakery, sweets use items_v2
	# -------------------------------------------------------------
	print("3. Testing Kitchen Chains items_v2 visuals...")
	for chain_id in ["pantry", "oven", "healthy", "staples", "bakery", "sweets"]:
		var it: ItemData = ItemDatabase.get_item("%s_1" % chain_id)
		assert(it != null, "Item %s_1 must exist" % chain_id)
		assert("items_v2" in it.icon_texture.resource_path, "%s_1 must use items_v2 asset! Path: %s" % [chain_id, it.icon_texture.resource_path])
	print("  -> Kitchen chains items_v2 visuals verified!")

	# -------------------------------------------------------------
	# 4. Pantry 10 tiers & spawn pool progression
	# -------------------------------------------------------------
	print("4. Testing Pantry 10 tiers & spawn pools...")
	for t in range(1, 11):
		var p: ItemData = ItemDatabase.get_item("pantry_%d" % t)
		assert(p != null, "pantry_%d must exist" % t)
		assert(p.max_tier == 10, "pantry_%d max_tier must be 10" % t)
	
	# Pantry Tier 3: healthy only
	var p3: ItemData = ItemDatabase.get_item("pantry_3")
	assert(p3.is_spawner == true, "pantry_3 must be a spawner")
	for drop_id in p3.spawn_pool:
		var drop_item: ItemData = ItemDatabase.get_item(drop_id)
		assert(drop_item.chain_id == "healthy", "Pantry 3 must strictly spawn healthy! Got: %s" % drop_id)
		assert(drop_item.tier == 1, "Pantry 3 must spawn Tier 1 healthy")

	# Pantry Tier 4: primarily healthy, low chance staple
	var p4: ItemData = ItemDatabase.get_item("pantry_4")
	var p4_staple_count := 0
	for drop_id in p4.spawn_pool:
		var drop_item: ItemData = ItemDatabase.get_item(drop_id)
		if drop_item.chain_id == "staples":
			p4_staple_count += 1
	assert(p4_staple_count > 0, "Pantry 4 must have chance to spawn staple")
	var p4_staple_rate := float(p4_staple_count) / float(p4.spawn_pool.size())
	assert(p4_staple_rate <= 0.25, "Pantry 4 staple rate must be low (<= 25 percent), got %f" % p4_staple_rate)

	# Pantry Tier 5: moderate chance staple
	var p5: ItemData = ItemDatabase.get_item("pantry_5")
	var p5_staple_count := 0
	for drop_id in p5.spawn_pool:
		var drop_item: ItemData = ItemDatabase.get_item(drop_id)
		if drop_item.chain_id == "staples":
			p5_staple_count += 1
	var p5_staple_rate := float(p5_staple_count) / float(p5.spawn_pool.size())
	assert(p5_staple_rate >= 0.30 and p5_staple_rate <= 0.50, "Pantry 5 staple rate must be moderate (30-50 percent), got %f" % p5_staple_rate)

	# Pantry Tier 6+: low chance higher tier items
	var p6: ItemData = ItemDatabase.get_item("pantry_6")
	var p6_high_tier_count := 0
	for drop_id in p6.spawn_pool:
		var drop_item: ItemData = ItemDatabase.get_item(drop_id)
		if drop_item.tier >= 2:
			p6_high_tier_count += 1
	assert(p6_high_tier_count > 0, "Pantry 6 must have low chance to spawn high tier items")
	var p6_high_rate := float(p6_high_tier_count) / float(p6.spawn_pool.size())
	assert(p6_high_rate <= 0.30, "Pantry 6 high tier rate must be low (<= 30 percent), got %f" % p6_high_rate)
	print("  -> Pantry 10 tiers & spawn pool progression verified!")

	# -------------------------------------------------------------
	# 5. Oven (Bakery only, Auto-spawn 0 energy) & Bakery Tier 7+ Hybrid
	# -------------------------------------------------------------
	print("5. Testing Oven & Bakery Tier 7+ hybrid mechanics...")
	# 5.1 Oven spawns bakery only
	for ot in range(3, 11):
		var ov: ItemData = ItemDatabase.get_item("oven_%d" % ot)
		for drop_id in ov.spawn_pool:
			var drop_item: ItemData = ItemDatabase.get_item(drop_id)
			assert(drop_item.chain_id == "bakery" or drop_item.chain_id == "sourdough_starter", "Oven must only spawn bakery (or temp starter), got %s" % drop_id)
			assert(drop_item.chain_id != "sweets", "Oven must NOT spawn sweets! Got %s" % drop_id)

	# 5.2 Oven auto-spawns without energy if empty neighbor exists
	var oven_item := board.spawn_item_at(Vector2i(4, 4), "oven_3", ItemView.ItemState.NORMAL)
	assert(oven_item.data.has_auto_spawn == true, "Oven 3 must have auto spawn enabled")
	oven_item.auto_spawn_current_stack = 1 # 1 ready drop stack
	EconomyManager.energy = 5
	var pre_energy := EconomyManager.energy
	var did_autospawn := board.try_auto_spawn(oven_item)
	assert(did_autospawn == true, "Oven should auto-spawn into empty neighbor")
	assert(EconomyManager.energy == pre_energy, "Auto-spawn must NOT consume energy (0 energy cost)")

	# Verify the dropped item is bakery
	var neighbors := board.get_empty_neighbor_cells(Vector2i(4, 4))
	var spawned_bakery_found := false
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			var it := board.get_item_at(Vector2i(4 + dx, 4 + dy))
			if it != null and it.data.chain_id == "bakery":
				spawned_bakery_found = true
				break
	assert(spawned_bakery_found, "Oven must have auto-spawned a bakery item in neighbor cell")

	# 5.3 Bakery Tier 7+ is a hybrid spawner
	board.clear_board()
	var b7 := board.spawn_item_at(Vector2i(0, 0), "bakery_7", ItemView.ItemState.NORMAL)
	assert(b7.data.is_spawner == true, "Bakery 7 must be a spawner")
	assert(b7.max_charges == 6, "Bakery 7 must have max_charges = 6")
	assert(b7.current_charges == 6, "Bakery 7 must start with 6 charges")
	assert(b7.data.exhaust_conversion_id == "bakery_6", "Bakery 7 must convert back to bakery_6")

	# 5.4 Bakery Tier 7 can spawn sweets 6 times, then converts to bakery_6
	EconomyManager.energy = 20
	for charge_num in range(6, 1, -1):
		assert(b7.current_charges == charge_num, "Charge count should be %d" % charge_num)
		board._trigger_spawner(b7)
		assert(b7.current_charges == charge_num - 1, "Charge count should decrement to %d" % (charge_num - 1))

	# Last (6th) charge triggers conversion to bakery_6
	assert(b7.current_charges == 1, "Should have 1 charge left")
	board._trigger_spawner(b7)
	var converted_item := board.get_item_at(Vector2i(0, 0))
	assert(converted_item != null, "Item at (0, 0) must exist after exhaust")
	assert(converted_item.data.id == "bakery_6", "Depleted Bakery 7 must convert back to bakery_6! Got: %s" % converted_item.data.id)

	# 5.5 Bakery Tier 8 also converts back to bakery_6 when depleted
	var b8 := board.spawn_item_at(Vector2i(1, 0), "bakery_8", ItemView.ItemState.NORMAL)
	assert(b8.data.exhaust_conversion_id == "bakery_6", "Bakery 8 must also revert back to bakery_6")
	b8.current_charges = 1
	board._trigger_spawner(b8)
	var b8_converted := board.get_item_at(Vector2i(1, 0))
	assert(b8_converted.data.id == "bakery_6", "Depleted Bakery 8 must revert back to bakery_6! Got: %s" % b8_converted.data.id)

	# 5.6 Bakery Tier 7 can still be merged as long as it has charges
	board.clear_board()
	var merge_b7_a := board.spawn_item_at(Vector2i(2, 0), "bakery_7", ItemView.ItemState.NORMAL)
	var merge_b7_b := board.spawn_item_at(Vector2i(3, 0), "bakery_7", ItemView.ItemState.NORMAL)
	merge_b7_a.current_charges = 4 # partially used
	merge_b7_b.current_charges = 2 # partially used
	assert(board._can_merge(merge_b7_a, merge_b7_b) == true, "Bakery 7 with remaining charges must be mergeable")
	board._execute_merge(merge_b7_a, merge_b7_b)
	var merged_b8 := board.get_item_at(Vector2i(3, 0))
	assert(merged_b8 != null and merged_b8.data.id == "bakery_8", "Merged Bakery 7 items must become bakery_8")
	assert(merged_b8.current_charges == 6, "New Bakery 8 must have 6 charges")

	board.queue_free()
	print("  -> Oven & Bakery Tier 7+ hybrid mechanics fully verified!")
	print("\n=== ALL 5 USER REQUIREMENTS VERIFIED SUCCESSFULLY! ===")
	get_tree().quit(0)
