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

# Array of item_ids (String) or item dictionaries (Dictionary with "id" and metadata)
# "" represents an empty slot
var _slots: Array = []

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
		if get_item_id_at(i) == "":
			return true
	return false

func get_first_empty_slot() -> int:
	var max_s := get_max_slots()
	for i in range(mini(_slots.size(), max_s)):
		if get_item_id_at(i) == "":
			return i
	return -1

func add_item(item_id: String, extra_data: Dictionary = {}) -> bool:
	if item_id.is_empty():
		return false
	var idx := get_first_empty_slot()
	if idx == -1:
		return false
	if extra_data.is_empty():
		_slots[idx] = item_id
	else:
		var dict: Dictionary = extra_data.duplicate(true)
		dict["id"] = item_id
		_slots[idx] = dict
	GameEvents.inventory_changed.emit()
	return true

func set_item_at(slot_idx: int, item_id: String, extra_data: Dictionary = {}) -> bool:
	if slot_idx < 0 or slot_idx >= get_max_slots():
		return false
	if extra_data.is_empty():
		_slots[slot_idx] = item_id
	else:
		var dict: Dictionary = extra_data.duplicate(true)
		dict["id"] = item_id
		_slots[slot_idx] = dict
	GameEvents.inventory_changed.emit()
	return true

func remove_item_at(slot_idx: int) -> String:
	if slot_idx < 0 or slot_idx >= get_max_slots():
		return ""
	var item_id := get_item_id_at(slot_idx)
	_slots[slot_idx] = ""
	if not item_id.is_empty():
		GameEvents.inventory_changed.emit()
	return item_id

func remove_item_data_at(slot_idx: int) -> Dictionary:
	if slot_idx < 0 or slot_idx >= get_max_slots():
		return {}
	var data := get_item_data_at(slot_idx)
	_slots[slot_idx] = ""
	if not data.is_empty():
		GameEvents.inventory_changed.emit()
	return data

func remove_item_by_id(item_id: String) -> bool:
	var max_s := get_max_slots()
	for i in range(mini(_slots.size(), max_s)):
		if get_item_id_at(i) == item_id:
			_slots[i] = ""
			GameEvents.inventory_changed.emit()
			return true
	return false

func get_item_id_at(slot_idx: int) -> String:
	if slot_idx < 0 or slot_idx >= get_max_slots():
		return ""
	var s: Variant = _slots[slot_idx]
	if s is String:
		return s as String
	elif s is Dictionary:
		return str((s as Dictionary).get("id", ""))
	return ""

func get_item_data_at(slot_idx: int) -> Dictionary:
	if slot_idx < 0 or slot_idx >= get_max_slots():
		return {}
	var s: Variant = _slots[slot_idx]
	if s is Dictionary:
		return (s as Dictionary).duplicate(true)
	elif s is String and not (s as String).is_empty():
		return {"id": s as String}
	return {}

func get_used_count() -> int:
	var count := 0
	var max_s := get_max_slots()
	for i in range(mini(_slots.size(), max_s)):
		if not get_item_id_at(i).is_empty():
			count += 1
	return count

func get_all_item_ids() -> Array[String]:
	var result: Array[String] = []
	var max_s := get_max_slots()
	for i in range(mini(_slots.size(), max_s)):
		var id := get_item_id_at(i)
		if not id.is_empty():
			result.append(id)
	return result

func clear_all() -> void:
	_slots.resize(get_max_slots())
	_slots.fill("")
	GameEvents.inventory_changed.emit()

func get_slots() -> Array:
	var max_s := get_max_slots()
	var result: Array = []
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
		var s: Variant = slots_data[i]
		if s is Dictionary:
			_slots[i] = (s as Dictionary).duplicate(true)
		elif s is String:
			_slots[i] = s as String
		else:
			_slots[i] = ""
	GameEvents.inventory_changed.emit()
