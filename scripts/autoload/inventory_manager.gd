extends Node

const SLOTS_PER_ROW: int = 4
const INITIAL_ROWS: int = 2
const MAX_ROWS: int = 9 # 2 initial + 7 expandable = 9 rows (36 slots total)

const ROW_EXPANSION_COSTS: Dictionary = {
	3: {"currency": "coins", "amount": 200},
	4: {"currency": "gems", "amount": 5},
	5: {"currency": "gems", "amount": 10},
	6: {"currency": "gems", "amount": 20},
	7: {"currency": "gems", "amount": 35},
	8: {"currency": "gems", "amount": 55},
	9: {"currency": "gems", "amount": 80}
}

var unlocked_rows: int = INITIAL_ROWS

# Array of item_ids ("" represents an empty slot)
var _slots: Array[String] = []

func _ready() -> void:
	_slots.resize(get_max_slots())
	_slots.fill("")

func get_max_slots() -> int:
	return unlocked_rows * SLOTS_PER_ROW

func get_max_possible_slots() -> int:
	return MAX_ROWS * SLOTS_PER_ROW

func has_free_slot() -> bool:
	var max_s := get_max_slots()
	for i in range(mini(_slots.size(), max_s)):
		if _slots[i] == "":
			return true
	return false

func get_first_empty_slot() -> int:
	var max_s := get_max_slots()
	for i in range(mini(_slots.size(), max_s)):
		if _slots[i] == "":
			return i
	return -1

func add_item(item_id: String) -> bool:
	if item_id.is_empty():
		return false
	var idx := get_first_empty_slot()
	if idx == -1:
		return false
	_slots[idx] = item_id
	GameEvents.inventory_changed.emit()
	return true

func set_item_at(slot_idx: int, item_id: String) -> bool:
	if slot_idx < 0 or slot_idx >= get_max_slots():
		return false
	_slots[slot_idx] = item_id
	GameEvents.inventory_changed.emit()
	return true

func remove_item_at(slot_idx: int) -> String:
	if slot_idx < 0 or slot_idx >= get_max_slots():
		return ""
	var item_id := _slots[slot_idx]
	_slots[slot_idx] = ""
	if not item_id.is_empty():
		GameEvents.inventory_changed.emit()
	return item_id

func remove_item_by_id(item_id: String) -> bool:
	var max_s := get_max_slots()
	for i in range(mini(_slots.size(), max_s)):
		if _slots[i] == item_id:
			_slots[i] = ""
			GameEvents.inventory_changed.emit()
			return true
	return false

func get_item_id_at(slot_idx: int) -> String:
	if slot_idx < 0 or slot_idx >= get_max_slots():
		return ""
	return _slots[slot_idx]

func get_used_count() -> int:
	var count := 0
	var max_s := get_max_slots()
	for i in range(mini(_slots.size(), max_s)):
		if not _slots[i].is_empty():
			count += 1
	return count

func get_all_item_ids() -> Array[String]:
	var result: Array[String] = []
	var max_s := get_max_slots()
	for i in range(mini(_slots.size(), max_s)):
		if not _slots[i].is_empty():
			result.append(_slots[i])
	return result

func clear_all() -> void:
	_slots.resize(get_max_slots())
	_slots.fill("")
	GameEvents.inventory_changed.emit()

func get_slots() -> Array[String]:
	var max_s := get_max_slots()
	var result: Array[String] = []
	for i in range(mini(_slots.size(), max_s)):
		result.append(_slots[i])
	return result

func get_next_row_cost() -> Dictionary:
	var next_row := unlocked_rows + 1
	if ROW_EXPANSION_COSTS.has(next_row):
		return ROW_EXPANSION_COSTS[next_row]
	return {}

func can_unlock_next_row() -> bool:
	if unlocked_rows >= MAX_ROWS:
		return false
	var cost := get_next_row_cost()
	if cost.is_empty():
		return false
	if cost.currency == "coins":
		return EconomyManager.coins >= cost.amount
	elif cost.currency == "gems":
		return EconomyManager.gems >= cost.amount
	return false

func unlock_next_row() -> bool:
	if not can_unlock_next_row():
		return false
	var cost := get_next_row_cost()
	if cost.currency == "coins":
		if not EconomyManager.spend_coins(cost.amount):
			return false
	elif cost.currency == "gems":
		if not EconomyManager.spend_gems(cost.amount):
			return false

	unlocked_rows += 1
	_slots.resize(get_max_slots())
	for i in range(_slots.size() - SLOTS_PER_ROW, _slots.size()):
		if i >= 0:
			_slots[i] = ""
	GameEvents.inventory_changed.emit()
	if SaveManager:
		SaveManager.save_game(false)
	return true

func serialize_data() -> Dictionary:
	return {
		"unlocked_rows": unlocked_rows,
		"slots": get_slots()
	}

func load_data(data: Dictionary) -> void:
	unlocked_rows = clampi(int(data.get("unlocked_rows", INITIAL_ROWS)), INITIAL_ROWS, MAX_ROWS)
	var loaded_slots: Array = data.get("slots", [])
	load_slots(loaded_slots)

func load_slots(slots_data: Array) -> void:
	var max_s := get_max_slots()
	_slots.resize(max_s)
	_slots.fill("")
	for i in range(mini(slots_data.size(), max_s)):
		_slots[i] = str(slots_data[i])
	GameEvents.inventory_changed.emit()
