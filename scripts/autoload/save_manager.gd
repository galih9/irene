extends Node

signal save_started(is_auto_save: bool)
signal save_completed(success: bool, is_auto_save: bool)
signal toast_requested(message: String, duration: float)

const SAVE_FILE_PATH: String = "user://savegame.json"
const AUTO_SAVE_INTERVAL: float = 15.0 * 60.0 # 900 seconds (15 minutes)

var auto_save_interval: float = AUTO_SAVE_INTERVAL
var auto_save_enabled: bool = true
var _auto_save_timer: float = 0.0

var is_gameplay_active: bool = false
var should_load_on_start: bool = false

var board_ref: Board = null
var quest_manager_ref: QuestManager = null

func _process(delta: float) -> void:
	if is_gameplay_active and auto_save_enabled:
		_auto_save_timer += delta
		if _auto_save_timer >= auto_save_interval:
			_auto_save_timer = 0.0
			save_game(true, true)

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_FILE_PATH)

func get_save_info() -> Dictionary:
	if not has_save():
		return {}
	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if not file:
		return {}
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		return {}
	var data: Dictionary = json.data
	return {
		"timestamp": data.get("timestamp_string", ""),
		"coins": int(data.get("currencies", {}).get("coins", 0)),
		"gems": int(data.get("currencies", {}).get("gems", 0)),
		"energy": int(data.get("currencies", {}).get("energy", 0))
	}

func delete_save() -> bool:
	if not has_save():
		return true
	var err := DirAccess.remove_absolute(SAVE_FILE_PATH)
	should_load_on_start = false
	return err == OK

func save_game(show_toast: bool = true, is_auto_save: bool = false) -> bool:
	save_started.emit(is_auto_save)

	var save_data := {
		"version": 1,
		"timestamp": int(Time.get_unix_time_from_system()),
		"timestamp_string": Time.get_datetime_string_from_system(),
		"currencies": EconomyManager.serialize_data(),
		"progression": ProgressionManager.serialize_data(),
		"inventory": {
			"slots": InventoryManager.get_slots()
		},
		"board": {
			"cols": board_ref.cols if is_instance_valid(board_ref) else 7,
			"rows": board_ref.rows if is_instance_valid(board_ref) else 9,
			"items": board_ref.serialize_items() if is_instance_valid(board_ref) else []
		},
		"quests": quest_manager_ref.serialize_quests() if is_instance_valid(quest_manager_ref) else [],
		"settings": {
			"sfx_enabled": SoundManager.sfx_enabled,
			"bgm_enabled": SoundManager.bgm_enabled
		}
	}

	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if not file:
		push_error("Failed to open save file for writing: %s" % SAVE_FILE_PATH)
		save_completed.emit(false, is_auto_save)
		return false

	var json_str := JSON.stringify(save_data, "\t")
	file.store_string(json_str)
	file.close()

	if show_toast:
		if is_auto_save:
			toast_requested.emit("Saving, please do not exit the game...", 3.2)
		else:
			toast_requested.emit("Game Saved Successfully!", 2.2)

	save_completed.emit(true, is_auto_save)
	return true

func load_game(target_board: Board = null, target_quest_mgr: QuestManager = null) -> bool:
	if not has_save():
		return false

	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if not file:
		push_error("Failed to open save file for reading: %s" % SAVE_FILE_PATH)
		return false

	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_err := json.parse(text)
	if parse_err != OK:
		push_error("Failed to parse save game JSON: %s" % json.get_error_message())
		return false

	var data: Dictionary = json.data

	# 1. Restore Currencies
	if data.has("currencies"):
		EconomyManager.load_data(data["currencies"])

	# 2. Restore Progression
	if data.has("progression"):
		var prog: Dictionary = data["progression"]
		ProgressionManager.load_data(
			prog.get("unlocked_items", {}),
			prog.get("claimed_rewards", {}),
			int(prog.get("player_level", 1)),
			int(prog.get("player_exp", 0))
		)

	# 3. Restore Inventory
	if data.has("inventory"):
		var inv: Dictionary = data["inventory"]
		InventoryManager.load_slots(inv.get("slots", []))

	# 4. Restore Board
	var b := target_board if is_instance_valid(target_board) else board_ref
	if is_instance_valid(b) and data.has("board"):
		var board_dict: Dictionary = data["board"]
		var items_list: Array = board_dict.get("items", [])
		b.load_items(items_list)

	# 5. Restore Quests
	var q := target_quest_mgr if is_instance_valid(target_quest_mgr) else quest_manager_ref
	if is_instance_valid(q) and data.has("quests"):
		var quests_list: Array = data.get("quests", [])
		q.load_quests(quests_list)

	# 6. Restore Settings
	if data.has("settings"):
		var settings: Dictionary = data["settings"]
		SoundManager.sfx_enabled = settings.get("sfx_enabled", true)
		SoundManager.set_bgm_enabled(settings.get("bgm_enabled", true))

	GameEvents.board_changed.emit()
	GameEvents.inventory_changed.emit()
	GameEvents.progression_changed.emit()
	return true

func trigger_auto_save() -> void:
	save_game(true, true)
