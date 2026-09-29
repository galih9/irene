extends Node

func _ready() -> void:
	print("=== RUNNING THREAD ROLLER MINIGAME TESTS ===")

	# 1. Test ThreadColorPalette
	print("\n--- Testing ThreadColorPalette ---")
	var red_data := ThreadColorPalette.get_color_data("red")
	assert(red_data != null and not red_data.is_empty(), "Red color data must exist")
	assert(red_data.has("main") and red_data.has("thread"), "Red must define main and thread colors")
	assert(ThreadColorPalette.get_all_color_keys().size() >= 6, "Palette should support at least 6 colors")
	var subset := ThreadColorPalette.get_palette_subset(4)
	assert(subset.size() == 4, "Palette subset should return requested count")
	print("[OK] ThreadColorPalette verified!")

	# 2. Test BigCloth Multi-Cell Grid (Rows x Cols) & per-cell colors
	print("\n--- Testing BigCloth Multi-Cell Architecture ---")
	var big_cloth := BigCloth.new()
	big_cloth.custom_minimum_size = Vector2(200, 100)
	big_cloth.size = Vector2(200, 100)
	add_child(big_cloth)
	# Setup 2 rows x 3 cols grid
	var test_grid: Array = [
		["red", "blue", "green"],
		["green", "red", "blue"]
	]
	big_cloth.setup(test_grid, Vector2(200, 100))
	assert(big_cloth.rows == 2, "BigCloth rows must be 2")
	assert(big_cloth.cols == 3, "BigCloth cols must be 3")
	assert(big_cloth.total_cells == 6, "BigCloth must have 6 total cells (2x3)")
	assert(big_cloth.remaining_cells == 6, "Initial remaining cells must be 6")
	assert(big_cloth.is_rolling == false, "Initial rolling state must be false")
	assert(big_cloth.is_cleared == false, "Initial cleared state must be false")
	assert(big_cloth.get_col_remaining(0) == 2, "Col 0 must have 2 remaining cells")
	assert(big_cloth.get_bottom_cell_color(0) == "green", "Col 0 bottom cell must be green (row 1)")
	assert(big_cloth.get_bottom_cell_color(1) == "red", "Col 1 bottom cell must be red (row 1)")
	assert(big_cloth.get_bottom_cell_color(2) == "blue", "Col 2 bottom cell must be blue (row 1)")
	assert(big_cloth.find_matching_exposed_col("green") == 0, "Green must be found at col 0")
	assert(big_cloth.find_matching_exposed_col("red") == 1, "Red must be found at col 1")
	assert(big_cloth.find_matching_exposed_col("purple") == -1, "Purple must not be found")
	var attach_pt := big_cloth.get_attachment_point()
	assert(attach_pt != Vector2.ZERO, "Attachment point must be non-zero")
	big_cloth.queue_free()
	print("[OK] BigCloth Multi-Cell verified!")

	# 3. Test ClothGrid (single BigCloth)
	print("\n--- Testing ClothGrid (single BigCloth) ---")
	var grid := ClothGrid.new()
	grid.custom_minimum_size = Vector2(500, 300)
	grid.size = Vector2(500, 300)
	add_child(grid)

	grid.setup_level([
		[{"color": "red"}, {"color": "blue"}, {"color": "green"}, {"color": "green"}],
		[{"color": "red"}, {"color": "blue"}, {"color": "green"}, {"color": "green"}]
	])
	assert(grid.cols == 4, "Grid cols must be 4")
	assert(grid.rows == 2, "Grid rows must be 2")
	assert(grid.get_total_remaining_cells() == 8, "Total cells must be 8 (4 cols x 2 rows)")

	var color_cells := grid.get_remaining_cells_by_color()
	assert(color_cells.has("red"), "Must have red cells")
	assert(color_cells.has("blue"), "Must have blue cells")
	assert(color_cells.has("green"), "Must have green cells")

	# Exposed cells: one per column (bottom row)
	var exposed_cells := grid.get_exposed_cells()
	assert(exposed_cells.size() == 4, "Must have 4 exposed cells (one per column)")

	# Matching query
	var matched_green := grid.find_matching_exposed_block("green")
	assert(matched_green != null, "Must find matching green exposed block")
	var green_col := grid.find_matching_col("green")
	assert(green_col >= 0, "Must find a column with green exposed cell")

	# Consuming emits block_cleared
	var cleared_signal := [false]
	grid.block_cleared.connect(func(_cid, _pos): cleared_signal[0] = true)
	grid.consume_block_and_apply_gravity(matched_green)
	assert(cleared_signal[0] == true, "block_cleared signal must fire")

	grid.queue_free()
	print("[OK] ClothGrid (single BigCloth) verified!")



	# 4. Test RollerSpool Capacity (Default 3) & RollerSlot
	print("\n--- Testing RollerSpool Capacity (Default 3) & RollerSlot ---")
	var spool := RollerSpool.new()
	# Default roller capacity is 3 seconds / 3 cells
	spool.setup("green", Vector2(56, 56), 3)
	assert(spool.color_id == "green", "Spool color must be green")
	assert(spool.capacity == 3, "Spool capacity must default to 3")
	assert(spool.current_fill == 0, "Initial fill must be 0")
	assert(spool.is_full() == false, "Initial spool not full")
	assert(spool.get_available_capacity() == 3, "Initial available capacity must be 3")

	add_child(spool)
	spool.add_fill(1)
	assert(spool.current_fill == 1, "Fill must be 1")
	assert(spool.is_full() == false, "Spool should not be full after 1 cell")
	assert(spool.get_available_capacity() == 2, "Available capacity should be 2")

	spool.add_fill(2)
	assert(spool.current_fill == 3, "Fill must be 3")
	assert(spool.is_full() == true, "Spool should now be full at capacity 3")
	assert(spool.get_available_capacity() == 0, "Available capacity should be 0 when full")

	var slot := RollerSlot.new()
	add_child(slot)
	slot.slot_id = 0
	assert(slot.is_occupied == false, "Slot must initially be unoccupied")
	slot.receive_spool(spool)
	assert(slot.is_occupied == true, "Slot must now be occupied")
	assert(slot.is_docking == false, "Slot docking should complete immediately when no flight vector")
	assert(slot.current_spool == spool, "Slot current spool must match")

	slot.clear_slot()
	assert(slot.is_occupied == false, "Slot should be empty after clear")
	slot.queue_free()
	print("[OK] RollerSpool Capacity & RollerSlot verified!")

	# 5. Test RollerStation Starting at 1 Slot & Upgrades
	print("\n--- Testing RollerStation Starting at 1 Slot ---")
	var station := RollerStation.new()
	add_child(station)
	# Requirement 3: first section where the roller slot is one
	station.setup_station(1)
	assert(station.max_slots == 1, "First section slots must be 1")
	assert(station.slots.size() == 1, "Station must have 1 slot")
	assert(station.has_empty_slot() == true, "Station must have empty slot")

	# Test upgrade to 2 slots
	station.upgrade_slots(2)
	assert(station.max_slots == 2, "Upgraded slots must be 2")
	assert(station.slots.size() == 2, "Station must now have 2 slots")

	# Test add_slot to 3
	station.add_slot()
	assert(station.max_slots == 3, "Slots after add_slot must be 3")
	assert(station.slots.size() == 3, "Station must now have 3 slots")

	station.queue_free()
	print("[OK] RollerStation Starting at 1 Slot & Upgrades verified!")

	# 6. Test RollerQueue with Capacity 3 Spools
	print("\n--- Testing RollerQueue FIFO with Capacity 3 ---")
	var queue := RollerQueue.new()
	add_child(queue)
	var q_colors: Array[String] = ["green", "blue", "red"]
	queue.setup_queue(q_colors, 3)
	assert(queue.get_remaining_count() == 3, "Queue count must be 3")
	var front := queue.peek_front_spool()
	assert(front.color_id == "green", "Front spool must be green")
	assert(front.capacity == 3, "Spool capacity in queue must be 3")

	var p1: RollerSpool = queue.pop_front_spool()
	assert(p1.color_id == "green", "Popped spool must be green")
	assert(p1.capacity == 3, "Popped spool capacity must be 3")
	assert(queue.get_remaining_count() == 2, "Queue count must be 2")

	var p2: RollerSpool = queue.pop_front_spool()
	var p3: RollerSpool = queue.pop_front_spool()
	assert(queue.has_spools() == false, "Queue must now be empty")

	p1.queue_free()
	p2.queue_free()
	p3.queue_free()
	queue.queue_free()
	print("[OK] RollerQueue FIFO verified!")

	# 7. Test Upgrade Modal & Coin Spending
	print("\n--- Testing Upgrade Modal & Coin Economy ---")
	EconomyManager.coins = 200

	var up_modal := RollerUpgradeModal.new()
	var up_panel := Panel.new()
	up_panel.name = "Panel"
	up_modal.add_child(up_panel)
	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	up_panel.add_child(vbox)

	var header_box := HBoxContainer.new()
	header_box.name = "HeaderBox"
	vbox.add_child(header_box)
	var coin_lbl := Label.new()
	coin_lbl.name = "CoinLabel"
	header_box.add_child(coin_lbl)
	var close_b := Button.new()
	close_b.name = "CloseBtn"
	header_box.add_child(close_b)

	var cards_box := VBoxContainer.new()
	cards_box.name = "CardsBox"
	vbox.add_child(cards_box)

	# Slot Card
	var slot_card := PanelContainer.new()
	slot_card.name = "SlotCard"
	cards_box.add_child(slot_card)
	var sc_margin := MarginContainer.new()
	sc_margin.name = "Margin"
	slot_card.add_child(sc_margin)
	var sc_vbox := VBoxContainer.new()
	sc_vbox.name = "VBox"
	sc_margin.add_child(sc_vbox)
	var sc_hbox := HBoxContainer.new()
	sc_hbox.name = "InfoHBox"
	sc_vbox.add_child(sc_hbox)
	var sc_curr := Label.new()
	sc_curr.name = "CurrentLabel"
	sc_hbox.add_child(sc_curr)
	var sc_desc := Label.new()
	sc_desc.name = "DescLabel"
	sc_vbox.add_child(sc_desc)
	var sc_buy := Button.new()
	sc_buy.name = "BuyBtn"
	sc_vbox.add_child(sc_buy)

	# Cap Card
	var cap_card := PanelContainer.new()
	cap_card.name = "CapCard"
	cards_box.add_child(cap_card)
	var cc_margin := MarginContainer.new()
	cc_margin.name = "Margin"
	cap_card.add_child(cc_margin)
	var cc_vbox := VBoxContainer.new()
	cc_vbox.name = "VBox"
	cc_margin.add_child(cc_vbox)
	var cc_hbox := HBoxContainer.new()
	cc_hbox.name = "InfoHBox"
	cc_vbox.add_child(cc_hbox)
	var cc_curr := Label.new()
	cc_curr.name = "CurrentLabel"
	cc_hbox.add_child(cc_curr)
	var cc_desc := Label.new()
	cc_desc.name = "DescLabel"
	cc_vbox.add_child(cc_desc)
	var cc_buy := Button.new()
	cc_buy.name = "BuyBtn"
	cc_vbox.add_child(cc_buy)

	add_child(up_modal)
	up_modal.open_modal(1, 3)

	# Verify modal opened and coins displayed
	assert(up_modal.visible == true, "Upgrade modal must be visible")
	assert(coin_lbl.text.contains("200"), "Coin label must show 200 coins")
	assert(sc_curr.text.contains("1"), "Slot label must show current slots 1")
	assert(cc_curr.text.contains("3s"), "Capacity label must show current capacity 3s")

	# Test purchasing Slot upgrade (cost 50 coins)
	var prev_coins := EconomyManager.coins
	var slot_upgraded_val := [0]
	up_modal.slot_upgrade_purchased.connect(func(val): slot_upgraded_val[0] = val)
	up_modal._on_buy_slot_pressed()

	assert(EconomyManager.coins == prev_coins - 50, "Coins must decrease by 50 after slot upgrade")
	assert(slot_upgraded_val[0] == 2, "Slot should upgrade to 2")
	assert(up_modal.current_slots == 2, "Modal current_slots must now be 2")

	# Test purchasing Capacity upgrade (cost 40 coins)
	prev_coins = EconomyManager.coins
	var cap_upgraded_val := [0]
	up_modal.capacity_upgrade_purchased.connect(func(val): cap_upgraded_val[0] = val)
	up_modal._on_buy_capacity_pressed()

	assert(EconomyManager.coins == prev_coins - 40, "Coins must decrease by 40 after capacity upgrade")
	assert(cap_upgraded_val[0] == 4, "Capacity should upgrade to 4")
	assert(up_modal.current_capacity == 4, "Modal current_capacity must now be 4")

	up_modal.close_modal()
	up_modal.queue_free()
	print("[OK] Upgrade Modal & Coin Economy verified!")

	# 8. Test ThreadRollerMinigame Scene, Level Select & Ejection
	print("\n--- Testing ThreadRollerMinigame Scene (3 Slots & Capacity 3) ---")
	var minigame_scene: PackedScene = load("res://scenes/minigame/thread_roller_minigame.tscn")
	assert(minigame_scene != null, "ThreadRollerMinigame scene must load")
	var mg_inst: ThreadRollerMinigame = minigame_scene.instantiate()
	add_child(mg_inst)

	assert(mg_inst.level_select.visible, "Open on level select")
	mg_inst.start_level(1)
	assert(mg_inst.current_level == 1, "Initial level must be 1")
	assert(mg_inst.cloth_grid.get_total_remaining_cells() == 6, "Level 1 must have 6 cells")
	assert(mg_inst.roller_station.max_slots == 3, "Default station must have 3 slots")
	assert(mg_inst.roller_capacity == 3, "Default capacity must be 3")

	# Dispatch from queue to empty slot
	var front_spool: RollerSpool = mg_inst.roller_queue.pop_front_spool()
	assert(front_spool != null, "Must pop front spool")
	assert(front_spool.capacity == 3, "Front spool capacity must be 3")
	var slot0: RollerSlot = mg_inst.roller_station.slots[0]
	slot0.receive_spool(front_spool)
	assert(slot0.is_occupied == true, "Slot 0 must be occupied")

	# Test Level 2 scaling (4x3, 4 colors)
	ProgressionManager.cloth_unlocked_levels.append("level_02.json")
	mg_inst.start_level(2)
	assert(mg_inst.current_level == 2, "Level must be 2")
	assert(mg_inst.cloth_grid.cols == 4 and mg_inst.cloth_grid.rows == 3, "Level 2 must be 4x3")
	assert(mg_inst.cloth_grid.get_total_remaining_cells() == 12, "Level 2 must have 12 cloth cells (4x3)")

	# Test slot upgrade on minigame instance
	mg_inst._on_slot_upgraded(4)
	assert(mg_inst.roller_station.max_slots == 4, "Slots should be 4 after upgrade")
	assert(mg_inst.purchased_slots == 4, "purchased_slots must be 4")

	# Test capacity upgrade on minigame instance
	mg_inst._on_capacity_upgraded(4)
	assert(mg_inst.roller_capacity == 4, "roller_capacity must be 4 after upgrade")

	mg_inst.queue_free()
	print("[OK] ThreadRollerMinigame Scene verified!")

	# 9. Test BottomNavBar Minigame Button
	print("\n--- Testing BottomNavBar Minigame Button ---")
	var nav_scene: PackedScene = load("res://scenes/bottom_nav_bar.tscn")
	var nav_inst: BottomNavBar = nav_scene.instantiate()
	add_child(nav_inst)

	assert(is_instance_valid(nav_inst.minigame_btn), "BottomNavBar must have minigame_btn")
	var mini_icon: TextureRect = nav_inst.get_node("HBoxContainer/MinigameBtn/Margin/HBox/Icon")
	assert(is_instance_valid(mini_icon) and mini_icon.texture != null, "MinigameBtn icon texture must exist")
	assert(mini_icon.texture.resource_path == "res://assets/items/farm/wool/6.png", "MinigameBtn must use wool/6.png")

	var signal_emitted := [false]
	nav_inst.minigame_pressed.connect(func(): signal_emitted[0] = true)
	nav_inst.minigame_btn.pressed.emit()
	assert(signal_emitted[0] == true, "Pressing MinigameBtn must emit minigame_pressed")

	nav_inst.queue_free()
	print("[OK] BottomNavBar Minigame Button verified!")

	# 10. Test Main Scene Board Toggle & Minigame Switching
	print("\n--- Testing Main Scene Board Toggle & Minigame Switching ---")
	var main_scene: PackedScene = load("res://main.tscn")
	var main_inst: MainGame = main_scene.instantiate()
	add_child(main_inst)

	assert(main_inst.board.visible == true, "Normal merge board must initially be visible")
	assert(main_inst.is_minigame_active == false, "Initial minigame active state must be false")

	# Toggle minigame ON
	main_inst.toggle_minigame()
	assert(main_inst.is_minigame_active == true, "Minigame must be active after toggle")
	assert(main_inst.board.visible == false, "Merge board must be hidden when minigame is active")
	assert(main_inst.quest_container.visible == false, "Quest container must be hidden")
	assert(main_inst.bottom_bar.visible == false, "Item bottom info bar must be hidden")
	assert(is_instance_valid(main_inst.minigame_instance), "Minigame instance must be created")
	assert(main_inst.minigame_instance.visible == true, "Minigame instance must be visible")

	# Toggle minigame OFF
	main_inst.toggle_minigame()
	assert(main_inst.is_minigame_active == false, "Minigame must be inactive after second toggle")
	assert(main_inst.board.visible == true, "Merge board must be restored")
	assert(main_inst.quest_container.visible == true, "Quest container must be restored")
	assert(main_inst.bottom_bar.visible == true, "Item bottom info bar must be restored")
	assert(main_inst.minigame_instance.visible == false, "Minigame instance must be hidden")

	# Test MinigameBtn Tap on BottomNavBar -> opens MinigameSelectionModal
	main_inst.bottom_nav_bar.minigame_btn.pressed.emit()
	assert(is_instance_valid(main_inst.minigame_selection_modal), "Minigame selection modal must exist")
	assert(main_inst.minigame_selection_modal.visible == true, "Selection modal must be open after clicking minigame_btn")

	# Verify 'more coming soon' text is present
	var soon_label: Label = main_inst.minigame_selection_modal.get_node("Panel/VBox/ComingSoonBanner/Center/MoreComingSoonLabel")
	assert(is_instance_valid(soon_label), "More coming soon label must exist")
	assert(soon_label.text.to_lower().contains("more") and soon_label.text.to_lower().contains("coming soon"), "Must display 'more coming soon' text")

	# Clicking Play on Thread Roller starts minigame
	main_inst.minigame_selection_modal.thread_roller_btn.pressed.emit()
	assert(main_inst.is_minigame_active == true, "Minigame must be active after clicking Play on thread roller")
	assert(main_inst.minigame_selection_modal.visible == false, "Selection modal must close when starting minigame")

	var back_btn: Button = main_inst.minigame_instance.get_node("TopBar/Margin/HBox/BackBtn")
	back_btn.pressed.emit()
	assert(main_inst.is_minigame_active == false, "Minigame must be inactive after clicking BackBtn")
	assert(main_inst.minigame_instance.visible == false, "Minigame must be hidden after clicking BackBtn")

	main_inst.queue_free()
	print("[OK] Main Scene Board Toggle, MinigameSelectionModal & Switching verified!")

	# 11. Test Consecutive Matching Color Rolling Logic (Bugfix Verification)
	print("\n--- Testing Consecutive Matching Color Rolling Fix ---")
	var mixed_cloth := BigCloth.new()
	mixed_cloth.custom_minimum_size = Vector2(200, 100)
	add_child(mixed_cloth)
	# Col 0: row 0 (top) = "red", row 1 (bottom) = "green"
	# Col 1: row 0 = "green", row 1 = "green"
	var mixed_grid: Array = [
		["red", "green"],
		["green", "green"]
	]
	mixed_cloth.setup(mixed_grid, Vector2(200, 100))
	assert(mixed_cloth.get_bottom_cell_color(0) == "green", "Col 0 bottom must be green")
	assert(mixed_cloth.get_consecutive_color_count(0, "green") == 1, "Col 0 has only 1 consecutive green cell at bottom")
	assert(mixed_cloth.get_consecutive_color_count(1, "green") == 2, "Col 1 has 2 consecutive green cells")

	# Verify consuming green consumes ONLY the green cell, NOT the red cell above it!
	mixed_cloth._consume_bottom_cell_in_col(0, "green")
	assert(mixed_cloth.get_bottom_cell_color(0) == "red", "After consuming green cell, bottom cell of col 0 must now be red")
	assert(mixed_cloth.get_consecutive_color_count(0, "green") == 0, "No green cells remain at bottom of col 0")
	assert(mixed_cloth.get_consecutive_color_count(0, "red") == 1, "Red cell is preserved and not rolled by green")

	# Attempting to consume green from col 0 again must do nothing (safeguarded)
	mixed_cloth._consume_bottom_cell_in_col(0, "green")
	assert(mixed_cloth.get_bottom_cell_color(0) == "red", "Red cell must NOT be consumed by green spool")
	mixed_cloth.queue_free()
	print("[OK] Consecutive Matching Color Rolling Fix verified!")

	# 12. Test Shorter Cell Height
	print("\n--- Testing Shorter Cell Height ---")
	var test_grid_sizing := ClothGrid.new()
	test_grid_sizing.custom_minimum_size = Vector2(600, 360)
	test_grid_sizing.size = Vector2(600, 360)
	add_child(test_grid_sizing)
	test_grid_sizing.setup_level([[{"color": "red"}, {"color": "blue"}], [{"color": "red"}, {"color": "blue"}]])
	var c_size := test_grid_sizing._get_cloth_size()
	# Height should be based on target_cell_height (~52px), not stretched to 344px!
	assert(c_size.y < 200.0, "Cloth height with 2 rows must be compact (< 200px), got %f" % c_size.y)
	var expected_cell_h: float = (c_size.y - BigCloth.PAD * 2.0 - BigCloth.CELL_SPACE) / 2.0
	assert(is_equal_approx(expected_cell_h, 52.0), "Individual cell height must be around 52px, got %f" % expected_cell_h)
	test_grid_sizing.queue_free()
	print("[OK] Shorter Cell Height verified!")

	print("\n=== ALL THREAD ROLLER MINIGAME TESTS PASSED! ===")
	get_tree().quit(0)
