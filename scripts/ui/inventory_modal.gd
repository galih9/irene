class_name InventoryModal
extends Control

var board_ref: Board = null

@onready var close_btn: Button = $Panel/VBox/Header/CloseBtn
@onready var capacity_label: Label = $Panel/VBox/Header/VBox/CapacityLabel
@onready var slots_grid: GridContainer = $Panel/VBox/Scroll/Content/SlotsGrid
@onready var expansion_container: VBoxContainer = $Panel/VBox/Scroll/Content/ExpansionContainer

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
	capacity_label.text = "Capacity: %d / %d slots used (Row %d of %d)" % [used, max_slots, InventoryManager.unlocked_rows, InventoryManager.MAX_ROWS]

	for child in slots_grid.get_children():
		child.queue_free()

	for slot_idx in range(max_slots):
		var item_id := InventoryManager.get_item_id_at(slot_idx)
		var slot_panel := _create_slot_card(slot_idx, item_id)
		slots_grid.add_child(slot_panel)

	# Build expansion controls
	if is_instance_valid(expansion_container):
		for child in expansion_container.get_children():
			child.queue_free()

		if InventoryManager.unlocked_rows < InventoryManager.MAX_ROWS:
			var next_row := InventoryManager.unlocked_rows + 1
			var cost := InventoryManager.get_next_row_cost()
			var can_afford := InventoryManager.can_unlock_next_row()

			var expand_panel := PanelContainer.new()
			var p_style := StyleBoxFlat.new()
			p_style.bg_color = Color(1.0, 1.0, 1.0, 0.95) if can_afford else Color(0.93, 0.92, 0.90, 0.85)
			p_style.border_color = Color(0.35, 0.72, 0.45, 1.0) if can_afford else Color(0.8, 0.78, 0.75, 0.8)
			p_style.border_width_left = 2
			p_style.border_width_top = 2
			p_style.border_width_right = 2
			p_style.border_width_bottom = 2
			p_style.corner_radius_top_left = 12
			p_style.corner_radius_top_right = 12
			p_style.corner_radius_bottom_right = 12
			p_style.corner_radius_bottom_left = 12
			expand_panel.add_theme_stylebox_override("panel", p_style)

			var margin := MarginContainer.new()
			margin.add_theme_constant_override("margin_left", 12)
			margin.add_theme_constant_override("margin_top", 10)
			margin.add_theme_constant_override("margin_right", 12)
			margin.add_theme_constant_override("margin_bottom", 10)
			expand_panel.add_child(margin)

			var hbox := HBoxContainer.new()
			hbox.add_theme_constant_override("separation", 12)
			margin.add_child(hbox)

			var vbox := VBoxContainer.new()
			vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var title_lbl := Label.new()
			title_lbl.text = "Expand Storage (Row %d)" % next_row
			title_lbl.add_theme_font_size_override("font_size", 14)
			title_lbl.add_theme_color_override("font_color", Color(0.18, 0.16, 0.22))
			vbox.add_child(title_lbl)

			var sub_lbl := Label.new()
			sub_lbl.text = "Unlocks 4 additional storage slots (+4)"
			sub_lbl.add_theme_font_size_override("font_size", 11)
			sub_lbl.add_theme_color_override("font_color", Color(0.48, 0.45, 0.52))
			vbox.add_child(sub_lbl)
			hbox.add_child(vbox)

			var buy_btn := Button.new()
			buy_btn.custom_minimum_size = Vector2(120, 38)
			var currency_icon_str := "🪙 Gold" if cost.get("currency", "") == "coins" else "💎 Gems"
			buy_btn.text = "%d %s\nUnlock" % [cost.get("amount", 0), currency_icon_str]
			buy_btn.add_theme_font_size_override("font_size", 11)
			buy_btn.disabled = not can_afford

			var btn_style := StyleBoxFlat.new()
			btn_style.corner_radius_top_left = 8
			btn_style.corner_radius_top_right = 8
			btn_style.corner_radius_bottom_right = 8
			btn_style.corner_radius_bottom_left = 8
			if can_afford:
				btn_style.bg_color = Color(0.22, 0.72, 0.38, 1.0) if cost.get("currency", "") == "coins" else Color(0.2, 0.65, 0.95, 1.0)
				buy_btn.add_theme_color_override("font_color", Color.WHITE)
			else:
				btn_style.bg_color = Color(0.8, 0.78, 0.76, 0.9)
				buy_btn.add_theme_color_override("font_color", Color(0.5, 0.48, 0.46))
			buy_btn.add_theme_stylebox_override("normal", btn_style)
			buy_btn.add_theme_stylebox_override("hover", btn_style)
			buy_btn.add_theme_stylebox_override("disabled", btn_style)

			buy_btn.pressed.connect(func():
				if InventoryManager.unlock_next_row():
					SoundManager.play_quest()
					GameEvents.show_floating_text.emit("+4 Backpack Slots! 🎉", buy_btn.global_position + Vector2(0, -30), Color(0.3, 1.0, 0.4))
					_update_slots()
			)
			hbox.add_child(buy_btn)
			expansion_container.add_child(expand_panel)
		else:
			var max_lbl := Label.new()
			max_lbl.text = "✨ Maximum Storage Capacity Reached (9 / 9 Rows) ✨"
			max_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			max_lbl.add_theme_font_size_override("font_size", 12)
			max_lbl.add_theme_color_override("font_color", Color(0.35, 0.65, 0.4))
			expansion_container.add_child(max_lbl)

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

	# Show spawner charges or water badge if item has charges
	var slot_data := InventoryManager.get_item_data_at(slot_idx)
	if slot_data.has("spawner_charges"):
		var charges: int = int(slot_data.get("spawner_charges", 0))
		var badge := Label.new()
		badge.text = str(charges)
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.custom_minimum_size = Vector2(22, 18)
		badge.position = Vector2(slot_btn.custom_minimum_size.x - 26, 4)
		var badge_style := StyleBoxFlat.new()
		badge_style.bg_color = Color(0.95, 0.52, 0.15, 0.95)
		badge_style.corner_radius_top_left = 5
		badge_style.corner_radius_top_right = 5
		badge_style.corner_radius_bottom_right = 5
		badge_style.corner_radius_bottom_left = 5
		badge.add_theme_stylebox_override("panel", badge_style)
		badge.add_theme_font_size_override("font_size", 11)
		badge.add_theme_color_override("font_color", Color.WHITE)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot_btn.add_child(badge)
	elif slot_data.has("water_fed") and int(slot_data.get("water_fed", 0)) > 0:
		var w_count: int = int(slot_data.get("water_fed", 0))
		var badge := Label.new()
		badge.text = "🍎%d" % w_count
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.custom_minimum_size = Vector2(28, 18)
		badge.position = Vector2(slot_btn.custom_minimum_size.x - 32, 4)
		var badge_style := StyleBoxFlat.new()
		badge_style.bg_color = Color(0.2, 0.65, 0.35, 0.95)
		badge_style.corner_radius_top_left = 5
		badge_style.corner_radius_top_right = 5
		badge_style.corner_radius_bottom_right = 5
		badge_style.corner_radius_bottom_left = 5
		badge.add_theme_stylebox_override("panel", badge_style)
		badge.add_theme_font_size_override("font_size", 10)
		badge.add_theme_color_override("font_color", Color.WHITE)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot_btn.add_child(badge)

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

	# Retrieve stored metadata before removing
	var slot_data := InventoryManager.get_item_data_at(slot_idx)

	# Remove from inventory
	InventoryManager.remove_item_at(slot_idx)

	# Spawn onto board with preserved charges / metadata
	var target_coord := empty_cells[0]
	board_ref.spawn_item_flight(from_pos, target_coord, item_id, slot_data)
	SoundManager.play_drop()

	var item_data := ItemDatabase.get_item(item_id)
	var item_name := item_data.display_name if item_data else item_id
	GameEvents.show_floating_text.emit("%s to Board! ⬆️" % item_name, from_pos + Vector2(0, -30), Color(0.4, 0.85, 1.0))

	_update_slots()
