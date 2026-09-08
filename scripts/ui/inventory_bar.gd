class_name InventoryBar
extends Control

const NUM_SLOTS: int = 5
const SLOT_SIZE: float = 88.0
const SLOT_SPACING: float = 12.0

@onready var slots_container: HBoxContainer = $MarginContainer/HBoxContainer
@onready var title_label: Label = $TitleLabel

var _slots: Array = [] # Array of Panel
var _items: Array = [] # Array of ItemView or null

var board_ref: Node2D = null

const COLOR_NORMAL := Color(0.14, 0.17, 0.22, 0.9)
const COLOR_HOVER := Color(0.3, 0.5, 0.8, 0.95)

func _ready() -> void:
	_items.resize(NUM_SLOTS)
	_items.fill(null)
	_create_slots()

func _create_slots() -> void:
	for child in slots_container.get_children():
		child.queue_free()
	_slots.clear()

	for i in range(NUM_SLOTS):
		var slot := Panel.new()
		slot.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_apply_slot_style(slot, COLOR_NORMAL)
		slots_container.add_child(slot)
		_slots.append(slot)

func _apply_slot_style(slot: Panel, bg_color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = Color(0.28, 0.35, 0.48, 0.7)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	slot.add_theme_stylebox_override("panel", style)

func is_pos_inside(world_pos: Vector2) -> bool:
	return get_global_rect().has_point(world_pos)

func get_slot_at_world_pos(world_pos: Vector2) -> int:
	for i in range(_slots.size()):
		var slot: Panel = _slots[i]
		if slot.get_global_rect().has_point(world_pos):
			return i
	return -1

func get_slot_global_center(slot_idx: int) -> Vector2:
	if slot_idx < 0 or slot_idx >= _slots.size():
		return global_position
	var slot: Panel = _slots[slot_idx]
	return slot.global_position + slot.size * 0.5

func get_slot_center(slot_idx: int) -> Vector2:
	var g_center := get_slot_global_center(slot_idx)
	if board_ref:
		return board_ref.to_local(g_center)
	return g_center

func get_item_at(slot_idx: int) -> ItemView:
	if slot_idx < 0 or slot_idx >= _items.size():
		return null
	return _items[slot_idx]

func set_item_at(slot_idx: int, item: ItemView) -> void:
	if slot_idx < 0 or slot_idx >= _items.size():
		return
	_items[slot_idx] = item
	if item:
		item.is_in_inventory = true
		item.inventory_slot_idx = slot_idx
		item.grid_coord = Vector2i(-1, -1)

func clear_slot(slot_idx: int) -> void:
	if slot_idx >= 0 and slot_idx < _items.size():
		_items[slot_idx] = null

func set_slot_highlight(slot_idx: int, state: int) -> void:
	if slot_idx < 0 or slot_idx >= _slots.size():
		return
	var slot: Panel = _slots[slot_idx]
	if state == 1:
		_apply_slot_style(slot, COLOR_HOVER)
	else:
		_apply_slot_style(slot, COLOR_NORMAL)

func clear_highlights() -> void:
	for slot in _slots:
		_apply_slot_style(slot, COLOR_NORMAL)

func get_all_items() -> Array[ItemView]:
	var result: Array[ItemView] = []
	for it in _items:
		if it != null:
			result.append(it)
	return result
