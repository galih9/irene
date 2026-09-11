class_name ProgressionModal
extends Control

@onready var close_btn: Button = $Panel/VBox/Header/CloseBtn
@onready var progress_label: Label = $Panel/VBox/Header/VBox/ProgressLabel
@onready var progress_bar: ProgressBar = $Panel/VBox/Header/VBox/ProgressBar
@onready var tabs_container: HBoxContainer = $Panel/VBox/TabsScroll/TabsContainer
@onready var items_container: VBoxContainer = $Panel/VBox/Scroll/ItemsContainer

var _chains: Array[Dictionary] = [
	{"id": "foodbox", "name": "Foodbox"},
	{"id": "oven", "name": "Oven"},
	{"id": "fridge", "name": "Fridge"},
	{"id": "rack", "name": "Rack"},
	{"id": "egg", "name": "Eggs"},
	{"id": "leaf", "name": "Leafs"},
	{"id": "beef", "name": "Beef"},
	{"id": "cake", "name": "Cake"},
	{"id": "sandwich", "name": "Sandwich"},
	{"id": "drink", "name": "Drink"},
	{"id": "util", "name": "Utils"},
	{"id": "exp", "name": "EXP"},
	{"id": "gold", "name": "Gold"},
	{"id": "energy", "name": "Energy"},
	{"id": "diamond", "name": "Diamonds"},
	{"id": "chest", "name": "Chests"}
]

var _current_chain_id: String = "foodbox"
var _tab_buttons: Dictionary = {} # chain_id -> Button

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
	_update_header()
	_load_chain(_current_chain_id)

func close_modal() -> void:
	SoundManager.play_drop()
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.15)
	tween.finished.connect(func(): visible = false)

func _setup_tabs() -> void:
	for child in tabs_container.get_children():
		child.queue_free()
	_tab_buttons.clear()

	for chain in _chains:
		var btn := Button.new()
		btn.text = chain.name
		btn.custom_minimum_size = Vector2(90, 38)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 12)
		_apply_tab_style(btn, chain.id == _current_chain_id)

		var chain_id: String = chain.id
		btn.pressed.connect(func():
			_current_chain_id = chain_id
			_update_tab_highlights()
			_load_chain(chain_id)
			SoundManager.play_pickup()
		)
		tabs_container.add_child(btn)
		_tab_buttons[chain_id] = btn

func _apply_tab_style(btn: Button, is_active: bool) -> void:
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	if is_active:
		style.bg_color = Color(0.38, 0.28, 0.52, 0.95)
		style.border_color = Color(0.75, 0.55, 0.95, 1.0)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
	else:
		style.bg_color = Color(0.16, 0.14, 0.18, 0.8)
		style.border_color = Color(0.28, 0.24, 0.32, 0.5)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)

func _update_tab_highlights() -> void:
	for chain_id in _tab_buttons.keys():
		_apply_tab_style(_tab_buttons[chain_id], chain_id == _current_chain_id)

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
		_load_chain(_current_chain_id)

func _load_chain(chain_id: String) -> void:
	for child in items_container.get_children():
		child.queue_free()

	var chain_items: Array = ItemDatabase.get_chain(chain_id)
	for item in chain_items:
		var item_data: ItemData = item
		var row := _create_item_row(item_data)
		items_container.add_child(row)

func _create_item_row(item: ItemData) -> Control:
	var is_unlocked := ProgressionManager.is_unlocked(item.id)
	var is_claimed := ProgressionManager.is_claimed(item.id)

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12

	if is_unlocked:
		style.bg_color = Color(0.14, 0.17, 0.24, 0.95)
		style.border_color = Color(0.3, 0.42, 0.58, 0.8)
	else:
		style.bg_color = Color(0.10, 0.11, 0.15, 0.9)
		style.border_color = Color(0.18, 0.20, 0.26, 0.6)

	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	margin.add_child(hbox)

	# 1. Icon Box
	var icon_box := Panel.new()
	icon_box.custom_minimum_size = Vector2(56, 56)
	var icon_style := StyleBoxFlat.new()
	icon_style.corner_radius_top_left = 10
	icon_style.corner_radius_top_right = 10
	icon_style.corner_radius_bottom_right = 10
	icon_style.corner_radius_bottom_left = 10
	if is_unlocked:
		icon_style.bg_color = Color(0.18, 0.22, 0.28, 0.95) if item.icon_texture else item.color * 0.35
		icon_style.border_color = item.color * 0.8
	else:
		icon_style.bg_color = Color(0.12, 0.13, 0.17, 1)
		icon_style.border_color = Color(0.2, 0.22, 0.28, 1)
	icon_style.border_width_left = 2
	icon_style.border_width_top = 2
	icon_style.border_width_right = 2
	icon_style.border_width_bottom = 2
	icon_box.add_theme_stylebox_override("panel", icon_style)

	if is_unlocked:
		if item.icon_texture:
			var tr := TextureRect.new()
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

			var tier_badge := Label.new()
			tier_badge.text = "T%d" % item.tier
			tier_badge.add_theme_font_size_override("font_size", 10)
			tier_badge.position = Vector2(4, 2)
			tier_badge.add_theme_color_override("font_color", Color.WHITE)
			icon_box.add_child(tier_badge)
		else:
			var icon_lbl := Label.new()
			icon_lbl.anchors_preset = Control.PRESET_FULL_RECT
			icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			icon_lbl.text = "T%d" % item.tier
			icon_lbl.add_theme_color_override("font_color", item.color)
			icon_lbl.add_theme_font_size_override("font_size", 18)
			icon_box.add_child(icon_lbl)
	else:
		var icon_lbl := Label.new()
		icon_lbl.anchors_preset = Control.PRESET_FULL_RECT
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_lbl.text = "Locked"
		icon_lbl.add_theme_font_size_override("font_size", 14)
		icon_lbl.add_theme_color_override("font_color", Color(0.65, 0.6, 0.68))
		icon_box.add_child(icon_lbl)
	hbox.add_child(icon_box)

	# 2. Text Info
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var title_lbl := Label.new()
	if is_unlocked:
		title_lbl.text = "%s (Tier %d)" % [item.display_name, item.tier]
		title_lbl.add_theme_color_override("font_color", Color(1.0, 0.98, 0.94))
	else:
		title_lbl.text = "??? (Tier %d)" % item.tier
		title_lbl.add_theme_color_override("font_color", Color(0.65, 0.6, 0.68))
	title_lbl.add_theme_font_size_override("font_size", 15)
	vbox.add_child(title_lbl)

	var desc_lbl := Label.new()
	if is_unlocked:
		desc_lbl.text = item.description
		desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.82, 0.78))
	else:
		desc_lbl.text = "Merge Tier %d items to discover!" % maxi(item.tier - 1, 1)
		desc_lbl.add_theme_color_override("font_color", Color(0.58, 0.54, 0.6))
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_lbl)
	hbox.add_child(vbox)

	# 3. Reward / Action Button
	var action_box := VBoxContainer.new()
	action_box.alignment = BoxContainer.ALIGNMENT_CENTER

	if not is_unlocked:
		var locked_lbl := Label.new()
		locked_lbl.text = "Locked"
		locked_lbl.add_theme_color_override("font_color", Color(0.6, 0.55, 0.62))
		locked_lbl.add_theme_font_size_override("font_size", 12)
		action_box.add_child(locked_lbl)
	elif not is_claimed:
		var reward := ProgressionManager.get_reward_for_item(item.id)
		var claim_btn := Button.new()
		claim_btn.custom_minimum_size = Vector2(96, 38)
		
		var reward_str := "CLAIM\n+%d Gold" % reward.coins
		if reward.gems > 0:
			reward_str += " +%d Gems" % reward.gems
		if reward.has("exp") and reward.exp > 0:
			reward_str += " +%d EXP" % reward.exp
		if reward.has("chest") and not str(reward.chest).is_empty():
			reward_str += "\n+🎁 Chest!"
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
			var res := ProgressionManager.claim_reward(item.id)
			SoundManager.play_quest()
			var msg := "+%d Gold!" % res.coins
			if res.gems > 0:
				msg += " +%d Gems!" % res.gems
			if res.has("exp") and res.exp > 0:
				msg += " +%d EXP!" % res.exp
			if res.has("chest") and not str(res.chest).is_empty():
				msg += "\n+🎁 Chest sent to Reward Slot!"
			GameEvents.show_floating_text.emit("Codex Reward!\n" + msg, panel.global_position + Vector2(250, 20), Color(0.4, 1.0, 0.4))
			_update_header()
			_load_chain(item.chain_id)
		)
		action_box.add_child(claim_btn)
	else:
		var claimed_lbl := Label.new()
		claimed_lbl.text = "Claimed"
		claimed_lbl.add_theme_color_override("font_color", Color(0.42, 0.88, 0.55))
		claimed_lbl.add_theme_font_size_override("font_size", 12)
		action_box.add_child(claimed_lbl)

	hbox.add_child(action_box)
	return panel
