class_name InventoryModal
extends Control

var board_ref: Board = null

@onready var close_btn: Button = $Panel/VBox/Header/CloseBtn
@onready var capacity_label: Label = $Panel/VBox/Header/VBox/CapacityLabel
@onready var slots_grid: GridContainer = $Panel/VBox/Margin/SlotsGrid

func _ready() -> void:
	visible = false
	close_btn.pressed.connect(close_modal)
	GameEvents.request_inventory_open.connect(open_modal)
	GameEvents.inventory_changed.connect(_on_inventory_changed)

func open_modal() -> void:
	visible = true
	scale = Vector2(0.9, 0.9)
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.2)
	_update_slots()

func close_modal() -> void:
	SoundManager.play_drop()
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.15)
	tween.finished.connect(func(): visible = false)

func _on_inventory_changed() -> void:
	if visible:
		_update_slots()

func _update_slots() -> void:
	var used := InventoryManager.get_used_count()
	var max_slots := InventoryManager.get_max_slots()
	capacity_label.text = "Capacity: %d / %d slots used" % [used, max_slots]

	for child in slots_grid.get_children():
		child.queue_free()

	for slot_idx in range(max_slots):
		var item_id := InventoryManager.get_item_id_at(slot_idx)
		var slot_panel := _create_slot_card(slot_idx, item_id)
		slots_grid.add_child(slot_panel)

func _create_slot_card(slot_idx: int, item_id: String) -> Control:
	var slot_btn := Button.new()
	slot_btn.custom_minimum_size = Vector2(80, 80)
	slot_btn.focus_mode = Control.FOCUS_NONE
	
	var normal_style := StyleBoxFlat.new()
	normal_style.corner_radius_top_left = 12
	normal_style.corner_radius_top_right = 12
	normal_style.corner_radius_bottom_right = 12
	normal_style.corner_radius_bottom_left = 12

	if item_id.is_empty():
		normal_style.bg_color = Color(0.91, 0.89, 0.86, 0.6)
		normal_style.border_color = Color(0.8, 0.77, 0.73, 0.6)
		normal_style.border_width_left = 2
		normal_style.border_width_top = 2
		normal_style.border_width_right = 2
		normal_style.border_width_bottom = 2
		slot_btn.add_theme_stylebox_override("normal", normal_style)
		slot_btn.add_theme_stylebox_override("disabled", normal_style)
		slot_btn.disabled = true

		var plus_lbl := Label.new()
		plus_lbl.text = "+"
		plus_lbl.anchors_preset = Control.PRESET_FULL_RECT
		plus_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		plus_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		plus_lbl.add_theme_font_size_override("font_size", 24)
		plus_lbl.add_theme_color_override("font_color", Color(0.68, 0.65, 0.62))
		plus_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot_btn.add_child(plus_lbl)
		return slot_btn

	# Occupied Slot
	var item := ItemDatabase.get_item(item_id)
	normal_style.bg_color = Color(1.0, 1.0, 1.0, 0.95)
	normal_style.border_color = Color(0.72, 0.78, 0.86, 0.9)
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 2
	normal_style.content_margin_left = 10
	normal_style.content_margin_top = 10
	normal_style.content_margin_right = 10
	normal_style.content_margin_bottom = 10

	var hover_style := normal_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.96, 0.98, 1.0, 1.0)
	hover_style.border_color = Color(0.35, 0.6, 0.9, 1.0)

	var pressed_style := normal_style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = Color(0.9, 0.94, 0.98, 1.0)
	pressed_style.border_color = Color(0.25, 0.5, 0.85, 1.0)

	slot_btn.add_theme_stylebox_override("normal", normal_style)
	slot_btn.add_theme_stylebox_override("hover", hover_style)
	slot_btn.add_theme_stylebox_override("pressed", pressed_style)

	if item and item.icon_texture:
		slot_btn.icon = item.icon_texture
		slot_btn.expand_icon = true
		slot_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	elif item:
		slot_btn.text = item.display_name
		slot_btn.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
		slot_btn.add_theme_font_size_override("font_size", 12)
		slot_btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	slot_btn.pressed.connect(func():
		_retrieve_item_to_board(slot_idx, item_id, slot_btn.global_position + slot_btn.size * 0.5)
	)

	return slot_btn

func _retrieve_item_to_board(slot_idx: int, item_id: String, from_pos: Vector2) -> void:
	if not board_ref:
		return

	var empty_cells := board_ref.get_empty_cells()
	if empty_cells.is_empty():
		SoundManager.play_error()
		GameEvents.show_floating_text.emit("Board is Full! ⚠️", global_position + Vector2(330, 400), Color(1.0, 0.4, 0.4))
		return

	# Remove from inventory
	InventoryManager.remove_item_at(slot_idx)

	# Spawn onto board
	var target_coord := empty_cells[0]
	board_ref.spawn_item_flight(from_pos, target_coord, item_id)
	SoundManager.play_drop()

	var item_data := ItemDatabase.get_item(item_id)
	var item_name := item_data.display_name if item_data else item_id
	GameEvents.show_floating_text.emit("%s to Board! ⬆️" % item_name, from_pos + Vector2(0, -30), Color(0.4, 0.85, 1.0))

	_update_slots()
