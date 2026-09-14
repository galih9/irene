class_name ProgressionModal
extends Control

@onready var close_btn: Button = $Panel/VBox/Header/CloseBtn
@onready var progress_label: Label = $Panel/VBox/Header/VBox/ProgressLabel
@onready var progress_bar: ProgressBar = $Panel/VBox/Header/VBox/ProgressBar
@onready var tabs_container: HBoxContainer = $Panel/VBox/TabsScroll/TabsContainer
@onready var scroll: ScrollContainer = $Panel/VBox/Scroll
@onready var items_container: VBoxContainer = $Panel/VBox/Scroll/ItemsContainer

# Touch swipe scroll variables
var _is_touching: bool = false
var _is_swiping: bool = false
var _touch_start_pos: Vector2 = Vector2.ZERO
var _scroll_start_y: float = 0.0
var _scroll_velocity_y: float = 0.0
var _last_touch_pos_y: float = 0.0
var _last_touch_time: float = 0.0
var _is_claiming_in_place: bool = false
const DRAG_THRESHOLD: float = 10.0
const INERTIA_FRICTION: float = 7.0

const TABS: Array[Dictionary] = [
	{"id": "kitchen", "name": "🍳 Kitchen"},
	{"id": "farm", "name": "🌾 Farm"},
	{"id": "chests", "name": "🎁 Chests"},
	{"id": "achievements", "name": "🏆 Achievements"}
]

const KITCHEN_CHAINS: Array[Dictionary] = [
	{"id": "foodbox", "name": "Food Boxes"},
	{"id": "oven", "name": "Ovens"},
	{"id": "fridge", "name": "Fridges"},
	{"id": "rack", "name": "Racks"},
	{"id": "egg", "name": "Eggs"},
	{"id": "leaf", "name": "Produce & Herbs"},
	{"id": "beef", "name": "Meats"},
	{"id": "cake", "name": "Baked Goods"},
	{"id": "sandwich", "name": "Sandwiches"},
	{"id": "drink", "name": "Beverages"},
	{"id": "util", "name": "Kitchen Utilities"}
]

const FARM_CHAINS: Array[Dictionary] = [
	{"id": "barn", "name": "Barns"},
	{"id": "hay", "name": "Hay & Grass"},
	{"id": "tree", "name": "Fruit Trees"},
	{"id": "bird", "name": "Birds & Poultry"},
	{"id": "pine", "name": "Pine Trees"},
	{"id": "water", "name": "Water & Tanks"},
	{"id": "cow", "name": "Cows & Cattle"},
	{"id": "sheep", "name": "Sheep & Lambs"},
	{"id": "pig", "name": "Pigs"},
	{"id": "watering", "name": "Watering Tools"},
	{"id": "fruit", "name": "Orchard Fruits"},
	{"id": "tool", "name": "Farm Tools"},
	{"id": "milk", "name": "Milk & Dairy"},
	{"id": "wool", "name": "Wool & Textiles"}
]

const CHEST_CHAINS: Array[Dictionary] = [
	{"id": "chest_purple", "name": "EXP Chests"},
	{"id": "chest_green", "name": "Energy Chests"},
	{"id": "chest_yellow", "name": "Gold Chests"},
	{"id": "chest_blue", "name": "Diamond Chests"},
	{"id": "chest", "name": "Classic Chests"},
	{"id": "exp", "name": "EXP Stars"},
	{"id": "gold", "name": "Coins & Wealth"},
	{"id": "energy", "name": "Coffee & Energy"},
	{"id": "diamond", "name": "Diamonds"}
]

var _current_tab_id: String = "kitchen"
var _tab_buttons: Dictionary = {} # tab_id -> Button

func _ready() -> void:
	visible = false
	close_btn.pressed.connect(close_modal)
	GameEvents.request_progression_open.connect(open_modal)
	GameEvents.progression_changed.connect(_on_progression_changed)

	_setup_tabs()

func open_modal() -> void:
	visible = true
	scale = Vector2(0.9, 0.9)
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.2)
	_is_touching = false
	_is_swiping = false
	_scroll_velocity_y = 0.0
	_update_header()
	_load_tab(_current_tab_id)

func _process(delta: float) -> void:
	if not visible or not is_instance_valid(scroll):
		return
	if not _is_touching and absf(_scroll_velocity_y) > 8.0:
		scroll.scroll_vertical += int(round(_scroll_velocity_y * delta))
		_scroll_velocity_y = lerp(_scroll_velocity_y, 0.0, clampf(INERTIA_FRICTION * delta, 0.0, 1.0))
		if absf(_scroll_velocity_y) <= 8.0:
			_scroll_velocity_y = 0.0

func _input(event: InputEvent) -> void:
	if not visible or not is_instance_valid(scroll):
		return

	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.index == 0:
			if touch.pressed:
				if scroll.get_global_rect().has_point(touch.position):
					_start_touch(touch.position)
			else:
				if _is_touching:
					_end_touch()

	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event
		if drag.index == 0 and _is_touching:
			_update_drag(drag.position)

	elif event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if scroll.get_global_rect().has_point(mb.position):
					_start_touch(mb.position)
			else:
				if _is_touching:
					_end_touch()

	elif event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event
		if _is_touching and (mm.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			_update_drag(mm.position)

func _start_touch(pos: Vector2) -> void:
	_is_touching = true
	_is_swiping = false
	_touch_start_pos = pos
	_last_touch_pos_y = pos.y
	_last_touch_time = Time.get_ticks_msec() / 1000.0
	_scroll_start_y = float(scroll.scroll_vertical)
	_scroll_velocity_y = 0.0

func _update_drag(pos: Vector2) -> void:
	var cur_time := Time.get_ticks_msec() / 1000.0
	var dt := cur_time - _last_touch_time
	var dy := pos.y - _last_touch_pos_y
	if dt > 0.001:
		var inst_vel := -dy / dt
		_scroll_velocity_y = lerp(_scroll_velocity_y, inst_vel, 0.4)
	_last_touch_pos_y = pos.y
	_last_touch_time = cur_time

	var total_delta_y := pos.y - _touch_start_pos.y
	if not _is_swiping and absf(total_delta_y) > DRAG_THRESHOLD:
		_is_swiping = true

	if _is_swiping:
		scroll.scroll_vertical = int(round(_scroll_start_y - total_delta_y))
		get_viewport().set_input_as_handled()

func _end_touch() -> void:
	var cur_time := Time.get_ticks_msec() / 1000.0
	if cur_time - _last_touch_time > 0.08:
		_scroll_velocity_y = 0.0
	if _is_swiping:
		get_viewport().set_input_as_handled()
	_is_touching = false
	_is_swiping = false

func close_modal() -> void:
	SoundManager.play_drop()
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.15)
	tween.finished.connect(func(): visible = false)

func focus_chain(chain_id: String) -> void:
	var target_tab := "kitchen"
	for chain in FARM_CHAINS:
		if chain.id == chain_id:
			target_tab = "farm"
			break
	for chain in CHEST_CHAINS:
		if chain.id == chain_id:
			target_tab = "chests"
			break
	_current_tab_id = target_tab
	_update_tab_highlights()
	_load_tab(_current_tab_id)

func _setup_tabs() -> void:
	for child in tabs_container.get_children():
		child.queue_free()
	_tab_buttons.clear()

	for tab in TABS:
		var btn := Button.new()
		btn.text = tab.name
		btn.custom_minimum_size = Vector2(130, 40)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 14)
		_apply_tab_style(btn, tab.id == _current_tab_id)

		var tab_id: String = tab.id
		btn.pressed.connect(func():
			_current_tab_id = tab_id
			_update_tab_highlights()
			_load_tab(tab_id)
			SoundManager.play_pickup()
		)
		tabs_container.add_child(btn)
		_tab_buttons[tab_id] = btn

func _apply_tab_style(btn: Button, is_active: bool) -> void:
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	if is_active:
		style.bg_color = Color(0.92, 0.88, 0.98, 1.0)
		style.border_color = Color(0.62, 0.4, 0.88, 1.0)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		btn.add_theme_color_override("font_color", Color(0.28, 0.16, 0.44))
	else:
		style.bg_color = Color(0.92, 0.9, 0.88, 0.8)
		style.border_color = Color(0.82, 0.78, 0.75, 0.8)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		btn.add_theme_color_override("font_color", Color(0.48, 0.44, 0.42))
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)

func _update_tab_highlights() -> void:
	for tab_id in _tab_buttons.keys():
		_apply_tab_style(_tab_buttons[tab_id], tab_id == _current_tab_id)

func _update_header() -> void:
	var unlocked := ProgressionManager.get_total_unlocked_count()
	var total := ProgressionManager.get_total_items_count()
	var pct := int((float(unlocked) / float(maxi(total, 1))) * 100.0)
	progress_label.text = "Discovered: %d / %d (%d%%)" % [unlocked, total, pct]
	progress_bar.max_value = total
	progress_bar.value = unlocked

func _on_progression_changed() -> void:
	if visible:
		_update_header()
		if not _is_claiming_in_place:
			_load_tab(_current_tab_id)

func _load_tab(tab_id: String) -> void:
	for child in items_container.get_children():
		child.queue_free()

	if tab_id == "kitchen":
		for chain in KITCHEN_CHAINS:
			_render_chain_segment(chain)
	elif tab_id == "farm":
		for chain in FARM_CHAINS:
			_render_chain_segment(chain)
	elif tab_id == "chests":
		for chain in CHEST_CHAINS:
			_render_chain_segment(chain)
	elif tab_id == "achievements":
		_render_achievements_placeholder()

func _render_chain_segment(chain: Dictionary) -> void:
	var header_box := VBoxContainer.new()
	header_box.add_theme_constant_override("separation", 6)

	var title_lbl := Label.new()
	title_lbl.text = chain.name
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", Color(0.2, 0.16, 0.25))
	header_box.add_child(title_lbl)

	var sep := HSeparator.new()
	var sep_style := StyleBoxLine.new()
	sep_style.color = Color(0.78, 0.74, 0.82, 0.7)
	sep_style.thickness = 2
	sep.add_theme_stylebox_override("separator", sep_style)
	header_box.add_child(sep)

	items_container.add_child(header_box)

	var chain_items: Array = ItemDatabase.get_chain(chain.id)
	for item in chain_items:
		var item_data: ItemData = item
		var row := _create_item_row(item_data)
		items_container.add_child(row)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	items_container.add_child(spacer)

func _render_achievements_placeholder() -> void:
	var center_box := VBoxContainer.new()
	center_box.alignment = BoxContainer.ALIGNMENT_CENTER
	center_box.custom_minimum_size = Vector2(0, 320)
	center_box.add_theme_constant_override("separation", 12)

	var trophy_lbl := Label.new()
	trophy_lbl.text = "🏆"
	trophy_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	trophy_lbl.add_theme_font_size_override("font_size", 48)
	center_box.add_child(trophy_lbl)

	var title_lbl := Label.new()
	title_lbl.text = "Achievements Coming Soon!"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", Color(0.22, 0.18, 0.28))
	center_box.add_child(title_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = "Culinary milestones, chef badges, and special rewards will be unlocked here in upcoming updates."
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 13)
	desc_lbl.add_theme_color_override("font_color", Color(0.48, 0.44, 0.52))
	center_box.add_child(desc_lbl)

	items_container.add_child(center_box)

func _create_item_row(item: ItemData) -> Control:
	var is_unlocked := ProgressionManager.is_unlocked(item.id)
	var is_claimed := ProgressionManager.is_claimed(item.id)

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12

	if is_unlocked:
		style.bg_color = Color(1.0, 1.0, 1.0, 0.95)
		style.border_color = Color(0.82, 0.78, 0.88, 0.85)
	else:
		style.bg_color = Color(0.93, 0.92, 0.90, 0.85)
		style.border_color = Color(0.85, 0.83, 0.80, 0.6)

	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_PASS
	hbox.add_theme_constant_override("separation", 14)
	margin.add_child(hbox)

	# 1. Icon Box
	var icon_box := Panel.new()
	icon_box.mouse_filter = Control.MOUSE_FILTER_PASS
	icon_box.custom_minimum_size = Vector2(56, 56)
	var icon_style := StyleBoxFlat.new()
	icon_style.corner_radius_top_left = 10
	icon_style.corner_radius_top_right = 10
	icon_style.corner_radius_bottom_right = 10
	icon_style.corner_radius_bottom_left = 10
	if is_unlocked:
		icon_style.bg_color = Color(0.96, 0.95, 0.98, 1.0)
		icon_style.border_color = item.color * 0.9 if item else Color(0.8, 0.8, 0.8)
	else:
		icon_style.bg_color = Color(0.88, 0.86, 0.85, 1.0)
		icon_style.border_color = Color(0.78, 0.76, 0.75, 1.0)
	icon_style.border_width_left = 2
	icon_style.border_width_top = 2
	icon_style.border_width_right = 2
	icon_style.border_width_bottom = 2
	icon_box.add_theme_stylebox_override("panel", icon_style)

	if is_unlocked:
		if item.icon_texture:
			var tr := TextureRect.new()
			tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tr.texture = item.icon_texture
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.custom_minimum_size = Vector2(44, 44)
			tr.anchors_preset = Control.PRESET_FULL_RECT
			tr.offset_left = 6
			tr.offset_top = 6
			tr.offset_right = -6
			tr.offset_bottom = -6
			icon_box.add_child(tr)
		else:
			var icon_lbl := Label.new()
			icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			icon_lbl.anchors_preset = Control.PRESET_FULL_RECT
			icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			icon_lbl.text = item.display_name
			icon_lbl.add_theme_color_override("font_color", item.color)
			icon_lbl.add_theme_font_size_override("font_size", 12)
			icon_box.add_child(icon_lbl)
	else:
		var icon_lbl := Label.new()
		icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_lbl.anchors_preset = Control.PRESET_FULL_RECT
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_lbl.text = "Locked"
		icon_lbl.add_theme_font_size_override("font_size", 13)
		icon_lbl.add_theme_color_override("font_color", Color(0.6, 0.56, 0.54))
		icon_box.add_child(icon_lbl)
	hbox.add_child(icon_box)

	# 2. Text Info
	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var title_lbl := Label.new()
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_unlocked:
		title_lbl.text = "%s (Tier %d)" % [item.display_name, item.tier]
		title_lbl.add_theme_color_override("font_color", Color(0.18, 0.14, 0.22))
	else:
		title_lbl.text = "??? (Tier %d)" % item.tier
		title_lbl.add_theme_color_override("font_color", Color(0.55, 0.52, 0.58))
	title_lbl.add_theme_font_size_override("font_size", 15)
	vbox.add_child(title_lbl)

	var desc_lbl := Label.new()
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_unlocked:
		desc_lbl.text = item.description
		desc_lbl.add_theme_color_override("font_color", Color(0.38, 0.35, 0.42))
	else:
		desc_lbl.text = "Merge Tier %d items to discover!" % maxi(item.tier - 1, 1)
		desc_lbl.add_theme_color_override("font_color", Color(0.6, 0.58, 0.64))
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_lbl)
	hbox.add_child(vbox)

	# 3. Reward / Action Button
	var action_box := VBoxContainer.new()
	action_box.mouse_filter = Control.MOUSE_FILTER_PASS
	action_box.alignment = BoxContainer.ALIGNMENT_CENTER

	if not is_unlocked:
		var locked_lbl := Label.new()
		locked_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		locked_lbl.text = "Locked"
		locked_lbl.add_theme_color_override("font_color", Color(0.6, 0.56, 0.62))
		locked_lbl.add_theme_font_size_override("font_size", 12)
		action_box.add_child(locked_lbl)
	elif not is_claimed:
		var reward := ProgressionManager.get_reward_for_item(item.id)
		var claim_btn := Button.new()
		claim_btn.custom_minimum_size = Vector2(96, 38)
		
		var reward_str := "+%d 💎\n+🎁 Chest" % reward.gems
		claim_btn.text = reward_str
		claim_btn.add_theme_font_size_override("font_size", 11)
		claim_btn.add_theme_color_override("font_color", Color.WHITE)
		claim_btn.add_theme_color_override("font_outline_color", Color(0.2, 0.12, 0.04, 0.7))
		claim_btn.add_theme_constant_override("outline_size", 2)

		var btn_style := StyleBoxFlat.new()
		btn_style.bg_color = Color(0.92, 0.68, 0.16, 1.0)
		btn_style.corner_radius_top_left = 8
		btn_style.corner_radius_top_right = 8
		btn_style.corner_radius_bottom_right = 8
		btn_style.corner_radius_bottom_left = 8
		claim_btn.add_theme_stylebox_override("normal", btn_style)
		claim_btn.add_theme_stylebox_override("hover", btn_style)

		# Pulsing animation on claim button
		var pulse := create_tween().set_loops()
		pulse.tween_property(claim_btn, "modulate", Color(1.15, 1.15, 1.15), 0.4)
		pulse.tween_property(claim_btn, "modulate", Color.WHITE, 0.4)

		claim_btn.pressed.connect(func():
			pulse.kill()
			claim_btn.disabled = true
			_is_claiming_in_place = true
			var res := ProgressionManager.claim_reward(item.id)
			_is_claiming_in_place = false
			SoundManager.play_quest()
			var msg := "+%d Diamonds!\n+🎁 Chest sent to Reward Slot!" % res.gems
			GameEvents.show_floating_text.emit("Codex Reward!\n" + msg, panel.global_position + Vector2(250, 20), Color(0.4, 1.0, 0.4))
			
			# In-place update to eliminate lag
			for child in action_box.get_children():
				child.queue_free()
			var claimed_lbl := Label.new()
			claimed_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			claimed_lbl.text = "Claimed"
			claimed_lbl.add_theme_color_override("font_color", Color(0.25, 0.68, 0.35))
			claimed_lbl.add_theme_font_size_override("font_size", 12)
			action_box.add_child(claimed_lbl)

			_update_header()
		)
		action_box.add_child(claim_btn)
	else:
		var claimed_lbl := Label.new()
		claimed_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		claimed_lbl.text = "Claimed"
		claimed_lbl.add_theme_color_override("font_color", Color(0.25, 0.68, 0.35))
		claimed_lbl.add_theme_font_size_override("font_size", 12)
		action_box.add_child(claimed_lbl)

	hbox.add_child(action_box)
	return panel
