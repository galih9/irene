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
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(130, 140)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12

	if item_id.is_empty():
		style.bg_color = Color(0.14, 0.13, 0.16, 0.75)
		style.border_color = Color(0.26, 0.24, 0.3, 0.5)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		card.add_theme_stylebox_override("panel", style)

		var vbox_empty := VBoxContainer.new()
		vbox_empty.alignment = BoxContainer.ALIGNMENT_CENTER

		var plus_lbl := Label.new()
		plus_lbl.text = "+"
		plus_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		plus_lbl.add_theme_font_size_override("font_size", 28)
		plus_lbl.add_theme_color_override("font_color", Color(0.48, 0.45, 0.5))
		vbox_empty.add_child(plus_lbl)

		var empty_lbl := Label.new()
		empty_lbl.text = "Empty"
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_font_size_override("font_size", 12)
		empty_lbl.add_theme_color_override("font_color", Color(0.68, 0.64, 0.7))
		vbox_empty.add_child(empty_lbl)

		card.add_child(vbox_empty)
		return card

	# Occupied Slot
	var item := ItemDatabase.get_item(item_id)
	style.bg_color = Color(0.18, 0.16, 0.2, 0.95)
	style.border_color = Color(0.38, 0.55, 0.75, 0.8)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	card.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	# Icon container
	var icon_box := Panel.new()
	icon_box.custom_minimum_size = Vector2(48, 48)
	icon_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var icon_style := StyleBoxFlat.new()
	icon_style.corner_radius_top_left = 8
	icon_style.corner_radius_top_right = 8
	icon_style.corner_radius_bottom_right = 8
	icon_style.corner_radius_bottom_left = 8
	icon_style.bg_color = item.color * 0.35 if item else Color(0.2, 0.2, 0.2)
	icon_style.border_color = item.color * 0.9 if item else Color.WHITE
	icon_style.border_width_left = 2
	icon_style.border_width_top = 2
	icon_style.border_width_right = 2
	icon_style.border_width_bottom = 2
	icon_box.add_theme_stylebox_override("panel", icon_style)

	if item and item.icon_texture:
		var tr := TextureRect.new()
		tr.texture = item.icon_texture
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.anchors_preset = Control.PRESET_FULL_RECT
		tr.offset_left = 4
		tr.offset_top = 4
		tr.offset_right = -4
		tr.offset_bottom = -4
		icon_box.add_child(tr)

		var tier_badge := Label.new()
		tier_badge.text = "T%d" % item.tier
		tier_badge.add_theme_font_size_override("font_size", 10)
		tier_badge.position = Vector2(3, 1)
		tier_badge.add_theme_color_override("font_color", Color.WHITE)
		icon_box.add_child(tier_badge)
	else:
		var tier_lbl := Label.new()
		tier_lbl.anchors_preset = Control.PRESET_FULL_RECT
		tier_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tier_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tier_lbl.text = "T%d" % (item.tier if item else 1)
		tier_lbl.add_theme_color_override("font_color", item.color if item else Color.WHITE)
		tier_lbl.add_theme_font_size_override("font_size", 14)
		icon_box.add_child(tier_lbl)
	vbox.add_child(icon_box)

	# Name label
	var name_lbl := Label.new()
	name_lbl.text = item.display_name if item else item_id
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.98, 0.94))
	vbox.add_child(name_lbl)

	# Retrieve Button
	var retrieve_btn := Button.new()
	retrieve_btn.text = "Take ⬆️"
	retrieve_btn.custom_minimum_size = Vector2(80, 28)
	retrieve_btn.add_theme_font_size_override("font_size", 12)
	retrieve_btn.add_theme_color_override("font_color", Color.WHITE)
	retrieve_btn.add_theme_color_override("font_outline_color", Color(0.1, 0.18, 0.28, 0.7))
	retrieve_btn.add_theme_constant_override("outline_size", 1)

	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.28, 0.6, 0.9, 1.0)
	btn_style.corner_radius_top_left = 6
	btn_style.corner_radius_top_right = 6
	btn_style.corner_radius_bottom_right = 6
	btn_style.corner_radius_bottom_left = 6
	retrieve_btn.add_theme_stylebox_override("normal", btn_style)
	retrieve_btn.add_theme_stylebox_override("hover", btn_style)

	retrieve_btn.pressed.connect(func():
		_retrieve_item_to_board(slot_idx, item_id, card.global_position + card.size * 0.5)
	)
	vbox.add_child(retrieve_btn)

	return card

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
