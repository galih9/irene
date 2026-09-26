class_name CageModal
extends Control

var board_ref: Board = null
var current_cage: ItemView = null

@onready var close_btn: Button = $Panel/VBox/Header/CloseBtn
@onready var title_label: Label = $Panel/VBox/Header/VBox/Title
@onready var capacity_label: Label = $Panel/VBox/Header/VBox/CapacityLabel
@onready var slots_grid: GridContainer = $Panel/VBox/Scroll/Content/SlotsGrid
@onready var info_label: Label = $Panel/VBox/TipLabel

func _ready() -> void:
	visible = false
	close_btn.pressed.connect(close_modal)
	GameEvents.request_cage_open.connect(open_modal)
	GameEvents.board_changed.connect(_on_board_changed)

func open_modal(cage: ItemView = null) -> void:
	if cage != null:
		current_cage = cage
	if not is_instance_valid(current_cage) or not current_cage.is_cage():
		return

	visible = true
	scale = Vector2(0.9, 0.9)
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.2)
	_update_slots()

func close_modal() -> void:
	SoundManager.play_drop()
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.15)
	tween.finished.connect(func():
		visible = false
		current_cage = null
	)

func _on_board_changed() -> void:
	if visible:
		if not is_instance_valid(current_cage) or not current_cage.is_inside_tree():
			close_modal()
		else:
			_update_slots()

func _update_slots() -> void:
	if not is_instance_valid(current_cage) or not current_cage.is_cage():
		return

	var cap := current_cage.get_cage_capacity()
	var count := current_cage.get_cage_stored_count()
	var animal_name := current_cage.get_cage_stored_animal_name()

	title_label.text = "ANIMAL CAGE (LV. %d)" % current_cage.data.tier
	if count == 0:
		capacity_label.text = "Capacity: 0 / %d slots used (Empty)" % cap
		info_label.text = "Drag matching animals of the same level into this cage!"
	else:
		capacity_label.text = "Capacity: %d / %d %s stored" % [count, cap, animal_name]
		info_label.text = "Tap an animal to return it to the board! Feed Hay (Lv.3-6) on board to harvest."

	# Adjust columns based on capacity
	if cap <= 2:
		slots_grid.columns = 2
	elif cap <= 4:
		slots_grid.columns = 2
	else:
		slots_grid.columns = 5

	for child in slots_grid.get_children():
		child.queue_free()

	for slot_idx in range(cap):
		var slot_card: Control
		if slot_idx < count:
			var entry: Dictionary = current_cage.cage_stored_items[slot_idx]
			slot_card = _create_occupied_card(slot_idx, entry)
		else:
			slot_card = _create_empty_card()
		slots_grid.add_child(slot_card)

func _create_empty_card() -> Control:
	var slot_btn := Button.new()
	slot_btn.custom_minimum_size = Vector2(80, 80)
	slot_btn.focus_mode = Control.FOCUS_NONE

	var normal_style := StyleBoxFlat.new()
	normal_style.corner_radius_top_left = 12
	normal_style.corner_radius_top_right = 12
	normal_style.corner_radius_bottom_right = 12
	normal_style.corner_radius_bottom_left = 12
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

func _create_occupied_card(slot_idx: int, entry: Dictionary) -> Control:
	var item_id: String = str(entry.get("id", ""))
	var item := ItemDatabase.get_item(item_id)

	var slot_btn := Button.new()
	slot_btn.custom_minimum_size = Vector2(80, 80)
	slot_btn.focus_mode = Control.FOCUS_NONE

	var normal_style := StyleBoxFlat.new()
	normal_style.corner_radius_top_left = 12
	normal_style.corner_radius_top_right = 12
	normal_style.corner_radius_bottom_right = 12
	normal_style.corner_radius_bottom_left = 12
	normal_style.bg_color = Color(1.0, 1.0, 1.0, 0.95)
	normal_style.border_color = Color(0.72, 0.78, 0.86, 0.9)
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 2
	normal_style.content_margin_left = 8
	normal_style.content_margin_top = 8
	normal_style.content_margin_right = 8
	normal_style.content_margin_bottom = 8

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
		slot_btn.add_theme_font_size_override("font_size", 11)
		slot_btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# Check shear cooldown on sheep
	var s_cd: float = float(entry.get("shear_cooldown", 0.0))
	if s_cd > 0.0:
		var badge := Label.new()
		badge.text = "%ds" % int(ceil(s_cd))
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.custom_minimum_size = Vector2(38, 18)
		badge.position = Vector2(slot_btn.custom_minimum_size.x - 42, 4)
		var badge_style := StyleBoxFlat.new()
		badge_style.bg_color = Color(0.85, 0.45, 0.2, 0.95)
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
		_retrieve_animal_to_board(slot_idx, slot_btn.global_position + slot_btn.size * 0.5)
	)

	return slot_btn

func _retrieve_animal_to_board(slot_idx: int, from_pos: Vector2) -> void:
	if not board_ref:
		return
	if not is_instance_valid(current_cage) or not current_cage.is_cage():
		return

	var empty_cells := board_ref.get_empty_cells()
	if empty_cells.is_empty():
		SoundManager.play_error()
		GameEvents.show_floating_text.emit("Board is Full!", global_position + Vector2(240, 300), Color(1.0, 0.4, 0.4))
		return

	var animal_dict := current_cage.remove_animal_from_cage(slot_idx)
	if animal_dict.is_empty():
		return

	var item_id: String = str(animal_dict.get("id", ""))
	var target_coord := empty_cells[0]
	board_ref.spawn_item_flight(from_pos, target_coord, item_id, animal_dict)
	SoundManager.play_drop()

	var item_data := ItemDatabase.get_item(item_id)
	var item_name := item_data.display_name if item_data else item_id
	GameEvents.show_floating_text.emit("%s to Board!" % item_name, from_pos + Vector2(0, -30), Color(0.4, 0.85, 1.0))

	_update_slots()
	GameEvents.board_changed.emit()
