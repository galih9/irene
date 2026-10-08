extends Node

const TEST_SAVE_PATH: String = "res://test_delete_save.json"

func _ready() -> void:
	print("=== RUNNING DELETE SAVE DATA TESTS ===")

	test_inventory_manager_reset()
	test_save_manager_reset_game_data()
	test_option_modal_button_and_confirmation()
	test_option_modal_delete_while_playing()
	test_option_modal_delete_in_main_menu()

	_cleanup_test_file()
	print("=== ALL DELETE SAVE DATA TESTS PASSED! ===")
	get_tree().quit(0)

func _cleanup_test_file() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))

func _ensure_test_save() -> void:
	var f := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	assert(f != null, "File must open for writing at: " + TEST_SAVE_PATH)
	f.store_string('{"test": true}')
	f.close()

func test_inventory_manager_reset() -> void:
	print("1. Testing InventoryManager.reset_all()...")
	InventoryManager.unlocked_rows = 5
	InventoryManager.set_item_at(0, "bread_1")
	assert(InventoryManager.unlocked_rows == 5, "Setup: unlocked_rows should be 5")
	assert(InventoryManager.get_item_id_at(0) == "bread_1", "Setup: slot 0 should have item")

	InventoryManager.reset_all()
	assert(InventoryManager.unlocked_rows == InventoryManager.INITIAL_ROWS, "unlocked_rows must be reset to INITIAL_ROWS (2)")
	assert(InventoryManager.get_max_slots() == 8, "get_max_slots() must be 8")
	assert(InventoryManager.get_item_id_at(0) == "", "slot 0 must be empty after reset")
	print("  -> InventoryManager.reset_all() verified.")

func test_save_manager_reset_game_data() -> void:
	print("2. Testing SaveManager.reset_game_data()...")
	SaveManager.save_file_path = TEST_SAVE_PATH
	_ensure_test_save()
	assert(FileAccess.file_exists(TEST_SAVE_PATH), "Test save file must exist before deletion")

	# Mutate runtime data
	EconomyManager.coins = 9999
	EconomyManager.gems = 888
	ProgressionManager.player_level = 10
	ProgressionManager.golden_scoops_collected = 15
	InventoryManager.unlocked_rows = 4
	SaveManager.kitchen_board_items = [{"id": "flour_1", "col": 0, "row": 0}]
	SaveManager.completed_quest_count = 12

	var signal_emitted := [false]
	var callable := func(): signal_emitted[0] = true
	SaveManager.save_deleted.connect(callable)

	var success := SaveManager.reset_game_data()
	SaveManager.save_deleted.disconnect(callable)

	assert(success == true, "reset_game_data must return true")
	assert(not FileAccess.file_exists(TEST_SAVE_PATH), "Save file must be deleted from disk")
	assert(signal_emitted[0] == true, "save_deleted signal must be emitted")
	assert(SaveManager.kitchen_board_items.is_empty(), "kitchen_board_items must be empty")
	assert(SaveManager.farm_board_items.is_empty(), "farm_board_items must be empty")
	assert(SaveManager.witch_board_items.is_empty(), "witch_board_items must be empty")
	assert(SaveManager.completed_quest_count == 0, "completed_quest_count must be reset to 0")
	assert(EconomyManager.coins == 150, "Coins must be reset to default 150")
	assert(EconomyManager.gems == 25, "Gems must be reset to default 25")
	assert(ProgressionManager.player_level == 1, "Player level must be reset to 1")
	assert(ProgressionManager.golden_scoops_collected == 0, "Golden scoops must be reset to 0")
	assert(InventoryManager.unlocked_rows == 2, "Inventory rows must be reset to 2")

	SaveManager.save_file_path = SaveManager.DEFAULT_SAVE_FILE_PATH
	print("  -> SaveManager.reset_game_data() verified.")

func test_option_modal_button_and_confirmation() -> void:
	print("3. Testing OptionModal button and confirmation mechanics...")
	var modal_scene: PackedScene = load("res://scenes/option_modal.tscn")
	var modal: OptionModal = modal_scene.instantiate()
	add_child(modal)

	assert(is_instance_valid(modal.delete_btn), "modal.delete_btn must exist")
	assert(modal.delete_btn.icon != null, "delete_btn must have an icon (icon_trash)")

	SaveManager.is_gameplay_active = true
	modal.open_modal()
	assert(modal.delete_btn.disabled == false, "Delete button must be enabled during gameplay")
	assert(modal.delete_btn.text == "  DELETE SAVE DATA", "Delete button text should be '  DELETE SAVE DATA'")

	modal._on_delete_pressed()
	assert(modal._is_delete_confirming == true, "Modal must be in confirming state after first press")
	assert(modal.delete_btn.text == "  CONFIRM: DELETE SAVE DATA?", "Button text must prompt confirmation")
	assert("Warning:" in modal.status_label.text, "Status label should show warning text")

	modal._disarm_delete_confirmation()
	assert(modal._is_delete_confirming == false, "Modal must be disarmed")
	assert(modal.delete_btn.text == "  DELETE SAVE DATA", "Button text must revert")
	assert(modal.status_label.text == "", "Status label warning must be cleared")

	modal._on_delete_pressed()
	assert(modal._is_delete_confirming == true, "Modal should be armed again")
	modal._on_bgm_pressed()
	assert(modal._is_delete_confirming == false, "Pressing another button must cancel confirmation")

	modal.queue_free()
	SaveManager.is_gameplay_active = false
	print("  -> OptionModal confirmation flow verified.")

func test_option_modal_delete_while_playing() -> void:
	print("4. Testing OptionModal delete while playing (redirects to menu)...")
	SaveManager.save_file_path = TEST_SAVE_PATH
	_ensure_test_save()

	var modal_scene: PackedScene = load("res://scenes/option_modal.tscn")
	var modal: OptionModal = modal_scene.instantiate()
	add_child(modal)

	SaveManager.is_gameplay_active = true
	modal.open_modal()

	modal._on_delete_pressed()
	assert(modal._is_delete_confirming == true, "Must be armed")

	modal._on_delete_pressed()

	assert(SaveManager.is_gameplay_active == false, "is_gameplay_active must be false after delete")
	assert(not FileAccess.file_exists(TEST_SAVE_PATH), "Save file must be deleted")

	modal.queue_free()
	SaveManager.save_file_path = SaveManager.DEFAULT_SAVE_FILE_PATH
	print("  -> OptionModal delete while playing verified.")

func test_option_modal_delete_in_main_menu() -> void:
	print("5. Testing OptionModal delete from main menu...")
	SaveManager.save_file_path = TEST_SAVE_PATH
	_ensure_test_save()

	var modal_scene: PackedScene = load("res://scenes/option_modal.tscn")
	var modal: OptionModal = modal_scene.instantiate()
	add_child(modal)

	SaveManager.is_gameplay_active = false
	modal.open_modal()
	assert(modal.delete_btn.disabled == false, "Delete button enabled since save exists")

	modal._on_delete_pressed()
	assert(modal._is_delete_confirming == true, "Must be armed")

	modal._on_delete_pressed()

	assert(not FileAccess.file_exists(TEST_SAVE_PATH), "Save file must be deleted")
	assert(modal.delete_btn.disabled == true, "Delete button must be disabled now that no save exists")
	assert(modal.delete_btn.text == "  NO SAVE DATA", "Delete button text should be '  NO SAVE DATA'")
	assert("deleted successfully" in modal.status_label.text, "Status label should show success")

	modal.queue_free()
	SaveManager.save_file_path = SaveManager.DEFAULT_SAVE_FILE_PATH
	print("  -> OptionModal delete in main menu verified.")
