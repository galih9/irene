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

	# -------------------------------------------------------------
	# 6. Test SFX System & Oven Spawnspray
	# -------------------------------------------------------------
	print("\n6. Testing SFX System & Oven Spawnspray...")
	assert(SoundManager != null, "SoundManager autoload must exist")
	assert(SoundManager.STREAM_SPAWN != null, "STREAM_SPAWN must be loaded")
	assert(SoundManager.STREAM_SPAWN_SPRAY != null, "STREAM_SPAWN_SPRAY must be loaded")
	assert(SoundManager.STREAM_TOAST != null, "STREAM_TOAST must be loaded")
	assert(SoundManager.STREAM_BUBBLE != null, "STREAM_BUBBLE must be loaded")
	assert(SoundManager.STREAM_ATTENTION != null, "STREAM_ATTENTION must be loaded")
	assert(SoundManager.STREAM_POURING != null, "STREAM_POURING must be loaded")
	assert(SoundManager.STREAM_FABRIC_ROLL != null, "STREAM_FABRIC_ROLL must be loaded")
	assert(SoundManager.STREAM_CONSTRUCTION != null, "STREAM_CONSTRUCTION must be loaded")

	SoundManager.play_spawnspray()
	SoundManager.play_toast()
	SoundManager.play_pouring()
	SoundManager.play_fabric_roll()
	SoundManager.play_attention()

	# Test Oven autospawn uses spawnspray
	var test_board_sfx: Board = board_scene.instantiate()
	add_child(test_board_sfx)
	test_board_sfx.clear_board()
	var test_oven := test_board_sfx.spawn_item_at(Vector2i(3, 3), "oven_3")
	test_oven.auto_spawn_current_stack = 1
	var res := test_board_sfx.try_auto_spawn(test_oven)
	assert(res == true, "try_auto_spawn on oven_3 must succeed")
	var last_player_idx := (SoundManager._sfx_index - 1 + SoundManager._sfx_players.size()) % SoundManager._sfx_players.size()
	assert(SoundManager._sfx_players[last_player_idx].stream == SoundManager.STREAM_SPAWN_SPRAY, "Oven autospawn must play STREAM_SPAWN_SPRAY")

	# Test non-oven autospawn uses normal spawn
	var test_barn := test_board_sfx.spawn_item_at(Vector2i(1, 1), "barn_3")
	if test_barn and test_barn.data.has_auto_spawn:
		test_barn.auto_spawn_current_stack = 1
		test_board_sfx.try_auto_spawn(test_barn)
		var barn_player_idx := (SoundManager._sfx_index - 1 + SoundManager._sfx_players.size()) % SoundManager._sfx_players.size()
		assert(SoundManager._sfx_players[barn_player_idx].stream == SoundManager.STREAM_SPAWN, "Non-oven spawner must play STREAM_SPAWN")

	test_board_sfx.queue_free()
	print("  -> SFX & Oven Spawnspray verified!")

	# -------------------------------------------------------------
	# 7. Test Item Interaction VFX (Light, Sparkles, Cell Spark/Magic, Shine Circle, Trail)
	# -------------------------------------------------------------
	print("\n7. Testing Item Interaction VFX...")
	var test_board_vfx: Board = board_scene.instantiate()
	add_child(test_board_vfx)
	test_board_vfx.clear_board()

	# 7.1 Maxed item has light effect
	var max_item := test_board_vfx.spawn_item_at(Vector2i(0, 0), "healthy_16")
	assert(max_item.is_max_tier() == true, "healthy_16 must be max tier")
	assert(max_item.max_light_sprite != null, "max_light_sprite must exist")
	assert(max_item.max_light_sprite.visible == true, "Maxed item must have light effect visible")

	var non_max_item := test_board_vfx.spawn_item_at(Vector2i(1, 0), "healthy_1")
	assert(non_max_item.is_max_tier() == false, "healthy_1 must not be max tier")
	assert(non_max_item.max_light_sprite == null or non_max_item.max_light_sprite.visible == false, "Non-maxed item must not have light effect visible")

	# 7.2 Merged item has sparkling effect
	var spark_fx_scene: PackedScene = load("res://scenes/fx/merge_sparkles.tscn")
	var spark_fx: MergeSparkles = spark_fx_scene.instantiate()
	add_child(spark_fx)
	assert(spark_fx.particles.texture.resource_path == "res://assets/vfx/star_02.png", "MergeSparkles must use star_02.png")
	spark_fx.queue_free()

	# 7.3 Energy consumable triggers cell spark effect
	var energy_item := test_board_vfx.spawn_item_at(Vector2i(2, 0), "energy_1")
	test_board_vfx._trigger_consumable(energy_item)
	var found_spark := false
	for ch in test_board_vfx.get_children():
		if ch.name == "CellSparkEffect":
			found_spark = true
			break
	assert(found_spark == true, "Consuming energy item must spawn CellSparkEffect inside cell")

	# 7.4 Exp consumable triggers cell magic effect
	var exp_item := test_board_vfx.spawn_item_at(Vector2i(3, 0), "exp_1")
	test_board_vfx._trigger_consumable(exp_item)
	var found_magic := false
	for ch in test_board_vfx.get_children():
		if ch.name == "CellMagicEffect":
			found_magic = true
			break
	assert(found_magic == true, "Consuming exp item must spawn CellMagicEffect inside cell")

	# 7.5 Hovering merge partner displays shining circle effect instead of green border
	var target_merge_item := test_board_vfx.spawn_item_at(Vector2i(4, 0), "pantry_1")
	target_merge_item.set_merge_highlight(true)
	assert(target_merge_item.merge_circle_sprite != null, "merge_circle_sprite must exist")
	assert(target_merge_item.merge_circle_sprite.visible == true, "Merge hover must display shining circle effect")
	var sm: ShaderMaterial = target_merge_item.sprite.material as ShaderMaterial
	assert(sm.get_shader_parameter("outline_color") != Color(0.35, 1.0, 0.55, 1.0), "Merge hover outline must not be green")

	var target_cell: BoardCell = test_board_vfx._cells[4][0]
	target_cell.set_highlight(2)
	assert(target_cell.shining_circle != null and target_cell.shining_circle.visible == true, "Board cell highlight state 2 must display shining circle")
	var cell_sb: StyleBoxFlat = target_cell.background.get_theme_stylebox("panel")
	assert(cell_sb.border_color != Color(0.6, 1.0, 0.6, 1.0), "Cell border must not be green on merge hover")

	target_merge_item.set_merge_highlight(false)
	target_cell.set_highlight(0)
	assert(target_merge_item.merge_circle_sprite.visible == false, "Merge circle must hide when merge hover is cleared")
	assert(target_cell.shining_circle.visible == false, "Cell shining circle must hide when highlight is reset")

	# 7.6 Spawn flight animation creates trail effect
	var flight_item := test_board_vfx.spawn_item_flight(Vector2(100, 100), Vector2i(5, 0), "leaf_1")
	assert(flight_item != null, "Flight item must spawn")
	var found_trail := false
	for ch in flight_item.get_children():
		if ch.name == "FlightTrail" and ch is CPUParticles2D:
			found_trail = true
			assert(ch.local_coords == false, "Flight trail must use local_coords = false")
			break
	assert(found_trail == true, "Spawn flight must attach FlightTrail particles to item")

	test_board_vfx.queue_free()
	print("  -> Item Interaction VFX verified!")

	# -------------------------------------------------------------
	# 8. Test Overworld Construction System
	# -------------------------------------------------------------
	print("\n8. Testing Overworld Construction System...")
	var world_scene: PackedScene = load("res://scenes/experimental/world.tscn")
	var world: OverworldBoard = world_scene.instantiate()
	add_child(world)
	world._buildings.clear()
	world._occupancy.clear()

	var b_source := world.spawn_building(1, Vector2i(-8, 7))
	var b_target := world.spawn_building(1, Vector2i(-8, 8))

	# Merge buildings
	world._execute_merge(b_source, b_target)
	assert(b_target.tier == 2, "Building must upgrade to Tier 2")
	assert(b_target.is_under_construction == true, "Merged building must enter construction status")
	assert(is_equal_approx(b_target.construction_timer, 10.0), "Default construction duration must be 10.0s")
	assert(b_target.construction_timer_panel != null, "Construction timer panel must exist")
	assert(b_target.construction_timer_panel.visible == true, "Construction timer panel must be visible")
	assert("10s" in b_target.construction_timer_label.text, "Timer label must display countdown seconds")
	assert(b_target.construction_progress_bar != null, "Construction progress bar must exist")
	assert(b_target.construction_audio != null, "Construction audio player must exist")
	assert(b_target.construction_audio.stream == preload("res://assets/sfx/construction.mp3"), "Audio stream must be construction.mp3")
	assert(b_target.smoke_container != null, "Smoke container must exist")
	assert(b_target.smoke_container.get_child_count() > 0, "Smoke container must contain animated smoke puffs")

	# Test distance volume attenuation
	world.camera.global_position = b_target.global_position # Camera directly on building (close)
	b_target._update_audio_volume()
	var close_vol := b_target.construction_audio.volume_db

	world.camera.global_position = b_target.global_position + Vector2(1500, 1500) # Camera far away
	b_target._update_audio_volume()
	var far_vol := b_target.construction_audio.volume_db
	assert(close_vol > far_vol, "Construction audio must be louder when camera is closer and lower when farther! Close: %f, Far: %f" % [close_vol, far_vol])

	# Test finish construction
	b_target.finish_construction()
	assert(b_target.is_under_construction == false, "Construction status must be cleared when finished")
	assert(b_target.construction_timer_panel.visible == false, "Timer panel must hide after construction finishes")
	assert(b_target.badge_panel.visible == false, "Item name indicator badge must remain hidden so only tile cursor and info bar identify buildings")

	world.queue_free()
	print("  -> Overworld Construction System verified!")

	# -------------------------------------------------------------
	# 9. Test Overworld Tile Cursor & Information Bar
	# -------------------------------------------------------------
	print("\n9. Testing Overworld Tile Cursor & Information Bar...")
	var world2: OverworldBoard = world_scene.instantiate()
	add_child(world2)
	world2._buildings.clear()
	world2._occupancy.clear()
	var b_t3 := world2.spawn_building(3, Vector2i(0, 0)) # 2x2 building
	assert(world2.tile_cursor != null, "world must have tile_cursor node")
	assert(world2.info_bar != null, "world must have info_bar node")
	assert(world2.info_title_label.text == "Select a Building", "info_title_label must start with prompt")
	assert(world2.tile_cursor.visible == false, "tile_cursor must start hidden")

	# Select building
	world2.select_building(b_t3)
	assert(world2.selected_building == b_t3, "Building must be selected")
	assert(world2.tile_cursor.visible == true, "tile_cursor must be visible when building selected")
	assert("Tier 3" in world2.info_title_label.text, "InfoBar title must show building tier")
	assert(world2.info_desc_label.text != "", "InfoBar description must not be empty")

	# Deselect
	world2.clear_selection()
	assert(world2.selected_building == null, "Selection must be cleared")
	assert(world2.tile_cursor.visible == false, "tile_cursor must hide after deselect")
	assert(world2.info_title_label.text == "Select a Building", "InfoBar must return to prompt")

	world2.queue_free()
	print("  -> Overworld Tile Cursor & InfoBar verified!")

	# -------------------------------------------------------------
	# 10. Test Improved Construction Smoke Size, Opacity & Variation
	# -------------------------------------------------------------
	print("\n10. Testing Improved Construction Smoke...")
	var test_smoke_b := OverworldBuilding.new()
	test_smoke_b.setup(3, Vector2i(0, 0), null, "kitchen")
	add_child(test_smoke_b)
	test_smoke_b.start_construction(5.0)
	assert(test_smoke_b.smoke_container.get_child_count() >= 12, "Large multi-tile building must start with abundant smoke puffs")
	var has_high_opacity := false
	var tints_found: Array[Color] = []
	for p in test_smoke_b.smoke_container.get_children():
		if p is Sprite2D:
			if p.modulate.a >= 0.8:
				has_high_opacity = true
			if not tints_found.has(p.modulate):
				tints_found.append(p.modulate)
	assert(has_high_opacity == true, "Smoke puffs must have high opacity covering the site")
	assert(tints_found.size() >= 2, "Smoke puffs must have color variation")
	test_smoke_b.queue_free()
	print("  -> Improved Construction Smoke verified!")

	# -------------------------------------------------------------
	# 11. Test Quest Margin, Horizontal Scroll, Dynamic Max Quests & 20 Starter Quests
	# -------------------------------------------------------------
	print("\n11. Testing Quest Margins, Scroll, Dynamic Level Slots & 20 Starter Quests...")
	var qm_scene: PackedScene = load("res://scenes/quest_manager.tscn")
	var qm: QuestManager = qm_scene.instantiate()
	add_child(qm)
	
	# Margin and scroll verification
	var margin_container: MarginContainer = qm.get_node_or_null("MarginContainer")
	assert(margin_container != null, "QuestManager must have MarginContainer root for separation")
	assert(margin_container.get_theme_constant("margin_bottom") >= 10, "Margin bottom must be at least 10px")
	assert(qm.cards_scroll != null, "cards_scroll must exist")
	assert(qm.cards_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "CardsScroll must enable horizontal scroll")
	assert(qm.cards_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "CardsScroll must disable vertical scroll in horizontal mode")

	# Max quests calculation formula: clampi(2 + level, 3, 10)
	assert(qm.get_max_quests_for_level(1) == 3, "Level 1 must give 3 quests")
	assert(qm.get_max_quests_for_level(2) == 4, "Level 2 must give 4 quests")
	assert(qm.get_max_quests_for_level(3) == 5, "Level 3 must give 5 quests")
	assert(qm.get_max_quests_for_level(7) == 9, "Level 7 must give 9 quests")
	assert(qm.get_max_quests_for_level(8) == 10, "Level 8 must give 10 quests (capped)")
	assert(qm.get_max_quests_for_level(15) == 10, "Level 15 must give 10 quests (capped)")

	# Setup with Level 1
	ProgressionManager.reset_all()
	ProgressionManager.player_level = 1
	qm.setup(null)
	assert(qm.active_quests.size() == 3, "Initial active_quests must have 3 slots at level 1")
	assert(qm._cards.size() == 3, "Initial cards count must match 3 slots")

	# Verify 20 manual kitchen quests
	var manual_20 := qm._get_manual_kitchen_quests_20()
	assert(manual_20.size() == 20, "Must have exactly 20 manual quests")
	assert(manual_20[0].id == "quest_1", "Q1 ID matches")
	assert(manual_20[0].required_item_ids == ["egg_1", "leaf_1"], "Q1 requires egg_1 and leaf_1")
	assert(manual_20[1].id == "quest_2", "Q2 ID matches")
	assert(manual_20[1].required_item_ids == ["egg_2"], "Q2 requires egg_2")
	assert(manual_20[2].id == "quest_3", "Q3 ID matches")
	assert(manual_20[2].required_item_ids == ["egg_2", "leaf_2"], "Q3 requires egg_2 and leaf_2")
	assert(manual_20[19].id == "quest_20", "Q20 ID matches")
	assert(manual_20[19].customer_name == "Royal Food Critic Irene", "Q20 is Irene")
	assert(manual_20[19].reward_chest == "chest_purple_1", "Q20 gives purple chest")

	# Test Level Up expansion
	qm._on_player_leveled_up(2)
	assert(qm.active_quests.size() == 4, "Active quests must expand to 4 on level 2")
	assert(qm._cards.size() == 4, "Cards count must expand to 4")

	qm._on_player_leveled_up(8)
	assert(qm.active_quests.size() == 10, "Active quests must expand to 10 on level 8")
	assert(qm._cards.size() == 10, "Cards count must expand to 10")

	qm.queue_free()
	print("  -> Quest Margins, Scroll, Dynamic Level Slots & 20 Starter Quests verified!")

	print("\n=== ALL USER REQUIREMENTS FULLY VERIFIED! ===")
	get_tree().quit(0)

