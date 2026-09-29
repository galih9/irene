extends Node

func _ready() -> void:
	SaveManager.auto_save_enabled = false
	SaveManager.save_file_path = "user://parallel-rolling-test-unused.json"
	Engine.time_scale = 10.0
	await _test_row_sweep()
	await _test_concurrent_slots()
	await _test_levels_and_restart()
	print("[OK] Parallel rolling, row sweep, capacity, all levels, and restart passed")
	get_tree().quit()

func _test_row_sweep() -> void:
	var cloth := BigCloth.new()
	add_child(cloth)
	cloth.setup([
		["blue", "red", "red", "red"],
		["blue", "red", "red", "red"],
		["blue", "blue", "blue", "blue"],
	], Vector2(400, 180))
	var filled := [0]
	for expected_col in range(4):
		var columns := cloth.start_exposed_roll("blue", 3, Vector2.ZERO, func(): filled[0] += 1)
		assert(columns == [expected_col], "One roller must consume one cell and advance across the row")
		assert(cloth.remaining_cells == 12 - expected_col, "Cells remain until their animation finishes")
		assert(not cloth.get_matching_exposed_columns("blue", 4).has(expected_col), "Reserved cells cannot be claimed twice")
		await get_tree().create_timer(2.0).timeout
		assert(filled[0] == expected_col + 1 and cloth.remaining_cells == 11 - expected_col)
		assert(cloth.get_col_remaining(0) == 2, "Must not drill down the blue column")
	assert(cloth.get_bottom_cell_color(1) == "red", "Other colors remain intact")
	assert(cloth.get_matching_exposed_columns("blue", 3) == [0], "Next sweep may use newly exposed cells")
	assert(cloth.start_exposed_roll("purple", 3, Vector2.ZERO).is_empty())
	assert(cloth.start_exposed_roll("blue", 0, Vector2.ZERO).is_empty())
	cloth.queue_free()
	print("[OK] Blue row/blue left column regression")

func _test_concurrent_slots() -> void:
	var cloth := BigCloth.new()
	add_child(cloth)
	cloth.setup([["blue", "blue", "blue", "red", "red", "green"]], Vector2(480, 100))
	var slots: Array[RollerSlot] = []
	var completions := [0]
	for color in ["blue", "blue", "red"]:
		var slot := RollerSlot.new()
		add_child(slot)
		var spool := RollerSpool.new()
		spool.setup(color, Vector2(56, 56), 4)
		slot.receive_spool(spool)
		slots.append(slot)
	# Each blue roller claims one cell, even though both can hold more.
	slots[0].current_spool.add_fill(2)
	for slot in slots:
		slot.start_rolling(cloth, 4, func(): completions[0] += 1)
	assert(slots[0].rolling_columns == [0])
	assert(slots[1].rolling_columns == [1])
	assert(slots[2].rolling_columns == [3])
	assert(cloth.is_rolling and cloth._active_batches == 3)
	for slot in slots:
		assert(slot.is_rolling, "All three slots must roll concurrently")
		slot._update_thread_geometry()
		assert(slot._thread_paths.size() == slot.rolling_columns.size())
	await get_tree().create_timer(2.0).timeout
	assert(completions[0] == 3 and cloth.remaining_cells == 3)
	assert(slots[0].current_spool.current_fill == 3)
	assert(slots[1].current_spool.current_fill == 1)
	assert(slots[2].current_spool.current_fill == 1)
	slots[0].start_rolling(cloth, 4)
	slots[2].start_rolling(cloth, 4)
	assert(slots[0].rolling_columns == [2])
	assert(slots[2].rolling_columns == [4])
	await get_tree().create_timer(2.0).timeout
	assert(cloth.remaining_cells == 1)
	assert(cloth.get_bottom_cell_color(5) == "green")
	assert(not slots[0].is_occupied, "Full spool must eject")
	assert(slots[1].current_spool.current_fill == 1)
	assert(slots[2].current_spool.current_fill == 2)
	assert(not cloth.is_rolling and cloth._reserved_columns.is_empty())
	for slot in slots:
		slot.queue_free()
	cloth.queue_free()
	await get_tree().create_timer(1.0).timeout
	print("[OK] Concurrent slots, duplicate colors, capacity, and thread paths")

func _test_levels_and_restart() -> void:
	var game: ThreadRollerMinigame = load("res://scenes/minigame/thread_roller_minigame.tscn").instantiate()
	add_child(game)
	Engine.time_scale = 1.0
	await get_tree().process_frame
	game.start_level(1)
	game.cloth_grid.setup_level([[{"color": "blue"}, {"color": "blue"}, {"color": "red"}, {"color": "red"}]])
	for i in range(2):
		var spool := RollerSpool.new()
		spool.setup("blue" if i == 0 else "red", Vector2(56, 56), 3)
		game.roller_station.slots[i].receive_spool(spool)
	assert(game.roller_station.slots[0].rolling_columns == [0])
	assert(game.roller_station.slots[1].rolling_columns == [2])
	assert(game.cloth_grid.cloth._active_batches == 2, "Controller must start both colors together")
	await get_tree().create_timer(0.5).timeout
	assert(game.cloth_grid.get_total_remaining_cells() == 4, "Cells cannot finish before one second")
	await get_tree().create_timer(0.8).timeout
	assert(game.cloth_grid.get_total_remaining_cells() == 2, "Each roller consumes only one cell in its first second")
	assert(game.roller_station.slots[0].rolling_columns == [1])
	assert(game.roller_station.slots[1].rolling_columns == [3])
	await get_tree().create_timer(1.3).timeout
	assert(game.win_overlay.visible and game.score == 200)
	assert(game.roller_station.get_occupied_slots().is_empty(), "Exhausted colors must eject partial spools")
	Engine.time_scale = 10.0
	var wins := [0]
	game.level_completed.connect(func(_level, _score): wins[0] += 1)
	game.auto_dispatch = true
	for i in range(game.levels.size()):
		ProgressionManager.cloth_unlocked_levels.append(game.levels[i]["id"])
		game.start_level(i + 1)
		var elapsed := 0.0
		while game.is_game_active and elapsed < 600.0:
			await get_tree().create_timer(0.5).timeout
			elapsed += 0.5
			# Large authored patterns can need the existing slot upgrade when
			# partial spools block access to another exposed color.
			if game.roller_station.is_jammed(game.cloth_grid):
				assert(game.purchased_slots < RollerUpgradeModal.MAX_SLOTS)
				game._on_slot_upgraded(game.purchased_slots + 1)
		assert(not game.is_game_active, "Level %d must auto-clear" % (i + 1))
		assert(game.win_overlay.visible and wins[0] == i + 1)
		print("[OK] Parallel rolling cleared level %d" % (i + 1))
	game.start_level(1)
	await get_tree().create_timer(0.7).timeout
	assert(not game.roller_station.is_all_idle())
	game.show_level_select()
	var coins_before := EconomyManager.coins
	var score_before := game.score
	await get_tree().create_timer(4.0).timeout
	assert(EconomyManager.coins == coins_before and game.score == score_before)
	assert(not game.is_game_active, "Abandoned rolls must not affect the next round")
	game.queue_free()
