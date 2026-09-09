extends Node

const MAX_SLOTS: int = 8

# Array of item_ids ("" represents an empty slot)
var _slots: Array[String] = []

func _ready() -> void:
	_slots.resize(MAX_SLOTS)
	_slots.fill("")

func has_free_slot() -> bool:
	return _slots.has("")

func get_first_empty_slot() -> int:
	return _slots.find("")

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
	if slot_idx < 0 or slot_idx >= MAX_SLOTS:
		return false
	_slots[slot_idx] = item_id
	GameEvents.inventory_changed.emit()
	return true

func remove_item_at(slot_idx: int) -> String:
	if slot_idx < 0 or slot_idx >= MAX_SLOTS:
		return ""
	var item_id := _slots[slot_idx]
	_slots[slot_idx] = ""
	if not item_id.is_empty():
		GameEvents.inventory_changed.emit()
	return item_id

func remove_item_by_id(item_id: String) -> bool:
	var idx := _slots.find(item_id)
	if idx != -1:
		_slots[idx] = ""
		GameEvents.inventory_changed.emit()
		return true
	return false

func get_item_id_at(slot_idx: int) -> String:
	if slot_idx < 0 or slot_idx >= MAX_SLOTS:
		return ""
	return _slots[slot_idx]

func get_used_count() -> int:
	var count := 0
	for item_id in _slots:
		if not item_id.is_empty():
			count += 1
	return count

func get_max_slots() -> int:
	return MAX_SLOTS

func get_all_item_ids() -> Array[String]:
	var result: Array[String] = []
	for item_id in _slots:
		if not item_id.is_empty():
			result.append(item_id)
	return result

func clear_all() -> void:
	_slots.fill("")
	GameEvents.inventory_changed.emit()

func get_slots() -> Array[String]:
	return _slots.duplicate()

func load_slots(slots_data: Array) -> void:
	_slots.resize(MAX_SLOTS)
	_slots.fill("")
	for i in range(mini(slots_data.size(), MAX_SLOTS)):
		_slots[i] = str(slots_data[i])
	GameEvents.inventory_changed.emit()

