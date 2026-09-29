extends Node

const Library = preload("res://scripts/minigame/cloth_level_library.gd")

func _ready() -> void:
	SaveManager.save_file_path = "/tmp/irene-cloth-test-save.json"
	SaveManager.auto_save_enabled = false
	ProgressionManager.reset_all()
	var levels := Library.load_levels()
	assert(levels.size() == 10)
	assert(Library.validate_rows([[{"color": "#FFFFF0", "id": "custom"}]]).is_empty())
	for bad in [null, [], [[]], [[{}]], [[{"color": "red"}]], [[{"color": "#XYZ123"}]], [[{"color": "#FFFFF0"}], []]]:
		assert(not Library.validate_rows(bad).is_empty())
	assert(ThreadColorPalette.get_main_color("#FFFFF0").is_equal_approx(Color.html("#FFFFF0")))

	var cloth := BigCloth.new()
	add_child(cloth)
	cloth.setup([[{"color": "#FF0000", "id": "top"}, {"color": "#0000FF"}],
		[{"color": "#00FF00"}, {"color": "#0000FF"}]], Vector2(240, 120))
	cloth._consume_bottom_cell_in_col(0, "#00FF00")
	assert(cloth._cells[1][0] == "#FF0000", "Upper cell must fall before neighboring bottom cell rolls")
	assert(cloth._cells[0][0] == "")
	assert(cloth.cell_data[1][0]["id"] == "top", "Metadata moves with the cell")
	assert(cloth._cells[0][1] == "#0000FF" and cloth._cells[1][1] == "#0000FF")
	assert(cloth._drop_offsets[0] < 0 and cloth._drop_offsets[1] == 0)
	await get_tree().create_timer(0.4).timeout
	assert(is_zero_approx(cloth._drop_offsets[0]))
	cloth.queue_free()

	var game: ThreadRollerMinigame = load("res://scenes/minigame/thread_roller_minigame.tscn").instantiate()
	add_child(game)
	assert(game.level_select.visible and not game.is_game_active)
	assert(game.level_buttons.get_child_count() == 10)
	game.start_level(2)
	assert(not game.is_game_active, "Direct starts must not bypass payment")
	EconomyManager.coins = 0
	game._on_level_selected(1)
	assert(not game.is_level_unlocked(1))
	EconomyManager.coins = 200
	game._on_level_selected(1)
	assert(EconomyManager.coins == 150 and game.current_level == 2)
	assert(game.roller_station.slots.size() == 3)
	game.show_level_select()
	game._on_level_selected(1)
	assert(EconomyManager.coins == 150, "Replays are free")
	game.show_level_select()
	ProgressionManager.reset_all()
	assert(SaveManager.load_game())
	assert(game.is_level_unlocked(1) and EconomyManager.coins == 150)
	SaveManager.save_file_path = "/nonexistent/cloth-save.json"
	game._on_level_selected(2)
	assert(not game.is_level_unlocked(2) and EconomyManager.coins == 150, "Failed saves refund the purchase")
	SaveManager.save_file_path = "/tmp/irene-cloth-test-save.json"

	# Exercise actual docking, rolling, falling, partial spool ejection and win callbacks.
	Engine.time_scale = 30.0
	var wins := [0]
	game.level_completed.connect(func(_level, _score): wins[0] += 1)
	for i in range(levels.size()):
		ProgressionManager.cloth_unlocked_levels.append(levels[i]["id"])
		game.auto_dispatch = true
		game.start_level(i + 1)
		var elapsed := 0.0
		while game.is_game_active and elapsed < 150.0:
			await get_tree().create_timer(0.5).timeout
			elapsed += 0.5
		assert(not game.is_game_active, "Level %d must clear with default 3 slots" % (i + 1))
		assert(game.win_overlay.visible)
		assert(wins[0] == i + 1, "Exactly one completion event per level")
		print("[OK] Cloth level %d auto-cleared" % (i + 1))
	game.start_level(1)
	await get_tree().create_timer(0.7).timeout
	game.show_level_select()
	var coins_before := EconomyManager.coins
	await get_tree().create_timer(4.0).timeout
	assert(EconomyManager.coins == coins_before and not game.is_game_active, "Abandoned rolls must not reward gold")
	Engine.time_scale = 1.0
	game.queue_free()
	DirAccess.remove_absolute("/tmp/irene-cloth-test-save.json")
	print("[OK] Cloth JSON, gravity, unlock persistence, and all 10 levels passed")
	get_tree().quit()
