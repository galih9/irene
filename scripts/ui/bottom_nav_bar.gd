class_name BottomNavBar
extends Control

signal progression_pressed()
signal inventory_pressed()
signal shop_pressed()
signal reward_slot_pressed()

@export var reward_slot_on_left: bool = true:
	set(val):
		reward_slot_on_left = val
		_update_reward_slot_order()

@onready var hbox: BoxContainer = $HBoxContainer
@onready var progression_btn: Button = $HBoxContainer/ProgressionBtn
@onready var inventory_btn: Button = $HBoxContainer/InventoryBtn
@onready var shop_btn: Button = $HBoxContainer/ShopBtn
@onready var reward_btn: Button = $HBoxContainer/RewardBtn

@onready var inventory_icon: TextureRect = $HBoxContainer/InventoryBtn/Margin/HBox/Icon
@onready var inventory_title: Label = $HBoxContainer/InventoryBtn/Margin/HBox/VBox/Title
@onready var shop_icon: TextureRect = $HBoxContainer/ShopBtn/Margin/HBox/Icon
@onready var shop_title: Label = $HBoxContainer/ShopBtn/Margin/HBox/Title

@onready var badge_panel: PanelContainer = $HBoxContainer/ProgressionBtn/Badge
@onready var badge_label: Label = $HBoxContainer/ProgressionBtn/Badge/BadgeLabel
@onready var inventory_capacity_label: Label = $HBoxContainer/InventoryBtn/Margin/HBox/VBox/CapacityLabel

@onready var reward_icon: TextureRect = $HBoxContainer/RewardBtn/Margin/Icon
@onready var reward_badge: PanelContainer = $HBoxContainer/RewardBtn/Badge
@onready var reward_badge_label: Label = $HBoxContainer/RewardBtn/Badge/BadgeLabel
@onready var shine_overlay: ColorRect = $HBoxContainer/RewardBtn/ShineOverlay

const MILESTONE_BACKPACK: int = 5
const MILESTONE_SHOP: int = 5

var _inventory_highlighted: bool = false
var is_vertical: bool = false

func is_inventory_unlocked() -> bool:
	return QuestManager.get_completed_count() >= MILESTONE_BACKPACK

func is_shop_unlocked() -> bool:
	return QuestManager.get_completed_count() >= MILESTONE_SHOP

func _ready() -> void:
	progression_btn.pressed.connect(_on_progression_pressed)
	inventory_btn.pressed.connect(_on_inventory_pressed)
	shop_btn.pressed.connect(_on_shop_pressed)
	if is_instance_valid(reward_btn):
		reward_btn.pressed.connect(_on_reward_slot_pressed)

	GameEvents.inventory_changed.connect(update_inventory_display)
	GameEvents.progression_changed.connect(update_progression_display)
	GameEvents.reward_queue_changed.connect(update_reward_slot_display)
	GameEvents.quest_count_changed.connect(func(_cnt): update_milestone_locks())
	GameEvents.quest_milestone_unlocked.connect(func(milestone):
		update_milestone_locks()
		if milestone == "backpack":
			play_inventory_pulse()
		elif milestone == "shop" and is_instance_valid(shop_btn):
			var tween := create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			shop_btn.pivot_offset = shop_btn.size * 0.5
			tween.tween_property(shop_btn, "scale", Vector2(1.15, 0.85), 0.1)
			tween.tween_property(shop_btn, "scale", Vector2.ONE, 0.2)
	)

	_update_reward_slot_order()
	update_inventory_display()
	update_progression_display()
	update_reward_slot_display()
	update_milestone_locks()

func set_layout_vertical(vertical: bool) -> void:
	is_vertical = vertical
	if is_instance_valid(hbox):
		hbox.vertical = vertical
		if vertical:
			hbox.alignment = BoxContainer.ALIGNMENT_CENTER
			hbox.add_theme_constant_override("separation", 14)
		else:
			hbox.alignment = BoxContainer.ALIGNMENT_CENTER
			hbox.add_theme_constant_override("separation", 12)
	if vertical:
		custom_minimum_size = Vector2(200, 300)
		for btn in [progression_btn, inventory_btn, shop_btn]:
			if is_instance_valid(btn):
				btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				btn.custom_minimum_size = Vector2(0, 58)
		if is_instance_valid(reward_btn):
			reward_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			reward_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			reward_btn.custom_minimum_size = Vector2(70, 70)
	else:
		custom_minimum_size = Vector2(664, 116)
		for btn in [progression_btn, inventory_btn, shop_btn]:
			if is_instance_valid(btn):
				btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				btn.custom_minimum_size = Vector2(0, 60)
		if is_instance_valid(reward_btn):
			reward_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			reward_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			reward_btn.custom_minimum_size = Vector2(70, 70)

func update_milestone_locks() -> void:
	var inv_unlocked := is_inventory_unlocked()
	var shop_unlocked := is_shop_unlocked()

	# Backpack button gating
	if is_instance_valid(inventory_btn):
		inventory_btn.disabled = not inv_unlocked
	if is_instance_valid(inventory_icon):
		inventory_icon.modulate = Color.WHITE if inv_unlocked else Color(0.45, 0.45, 0.45, 0.65)
	if is_instance_valid(inventory_title):
		inventory_title.text = "Backpack" if inv_unlocked else "Locked"
	if is_instance_valid(inventory_capacity_label):
		if inv_unlocked:
			update_inventory_display()
		else:
			inventory_capacity_label.text = "[3 Quests]"
			inventory_capacity_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

	# Shop button gating
	if is_instance_valid(shop_btn):
		shop_btn.disabled = not shop_unlocked
	if is_instance_valid(shop_icon):
		shop_icon.modulate = Color.WHITE if shop_unlocked else Color(0.45, 0.45, 0.45, 0.65)
	if is_instance_valid(shop_title):
		shop_title.text = "Shop" if shop_unlocked else "Locked (5)"

func update_inventory_display() -> void:
	if not is_inventory_unlocked():
		if is_instance_valid(inventory_capacity_label):
			inventory_capacity_label.text = "[3 Quests]"
			inventory_capacity_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		return
	if is_instance_valid(inventory_capacity_label):
		var used := InventoryManager.get_used_count()
		var max_slots := InventoryManager.get_max_slots()
		inventory_capacity_label.text = "[%d / %d]" % [used, max_slots]
		if used >= max_slots:
			inventory_capacity_label.add_theme_color_override("font_color", Color(1.0, 0.48, 0.48))
		elif used > 0:
			inventory_capacity_label.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0))
		else:
			inventory_capacity_label.add_theme_color_override("font_color", Color(0.82, 0.78, 0.72))

func update_progression_display() -> void:
	if not is_instance_valid(badge_panel) or not is_instance_valid(badge_label):
		return
	var unclaimed := ProgressionManager.get_unclaimed_count()
	if unclaimed > 0:
		badge_panel.visible = true
		badge_label.text = str(unclaimed)
	else:
		badge_panel.visible = false

func get_inventory_button() -> Control:
	return inventory_btn

func is_pos_inside_inventory_button(world_pos: Vector2) -> bool:
	if not is_inventory_unlocked():
		return false
	return inventory_btn.get_global_rect().has_point(world_pos)

func set_inventory_hover(highlighted: bool) -> void:
	if _inventory_highlighted == highlighted:
		return
	_inventory_highlighted = highlighted
	if highlighted:
		var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(inventory_btn, "scale", Vector2(1.04, 1.04), 0.1)
	else:
		var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(inventory_btn, "scale", Vector2.ONE, 0.1)

var _progression_highlighted: bool = false
var _reward_pulse_tween: Tween = null

func play_inventory_pulse() -> void:
	inventory_btn.pivot_offset = inventory_btn.size * 0.5
	var tween := create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(inventory_btn, "scale", Vector2(1.15, 0.85), 0.1)
	tween.tween_property(inventory_btn, "scale", Vector2(0.9, 1.1), 0.15)
	tween.tween_property(inventory_btn, "scale", Vector2.ONE, 0.2)

func play_progression_pulse() -> void:
	if not is_instance_valid(progression_btn):
		return
	progression_btn.pivot_offset = progression_btn.size * 0.5
	var tween := create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(progression_btn, "scale", Vector2(1.15, 0.85), 0.1)
	tween.tween_property(progression_btn, "scale", Vector2(0.9, 1.1), 0.15)
	tween.tween_property(progression_btn, "scale", Vector2.ONE, 0.2)

func set_progression_highlight(enable: bool) -> void:
	if not is_instance_valid(progression_btn):
		return
	_progression_highlighted = enable
	progression_btn.pivot_offset = progression_btn.size * 0.5
	if enable:
		if progression_btn.has_meta("highlight_tween"):
			var old_tw = progression_btn.get_meta("highlight_tween")
			if is_instance_valid(old_tw):
				old_tw.kill()
		var tween := create_tween().set_loops()
		tween.tween_property(progression_btn, "scale", Vector2(1.08, 1.08), 0.35).set_trans(Tween.TRANS_SINE)
		tween.tween_property(progression_btn, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_SINE)
		progression_btn.set_meta("highlight_tween", tween)
	else:
		if progression_btn.has_meta("highlight_tween"):
			var tw = progression_btn.get_meta("highlight_tween")
			if is_instance_valid(tw):
				tw.kill()
			progression_btn.remove_meta("highlight_tween")
		progression_btn.scale = Vector2.ONE

func _on_progression_pressed() -> void:
	SoundManager.play_click()
	set_progression_highlight(false)
	progression_pressed.emit()
	GameEvents.request_progression_open.emit()

func _on_inventory_pressed() -> void:
	if not is_inventory_unlocked():
		SoundManager.play_error()
		GameEvents.show_floating_text.emit("Complete 3 Quests to Unlock Backpack!", global_position + Vector2(size.x * 0.5, -40), Color(1.0, 0.5, 0.5))
		return
	SoundManager.play_click()
	inventory_pressed.emit()
	GameEvents.request_inventory_open.emit()

func _on_shop_pressed() -> void:
	if not is_shop_unlocked():
		SoundManager.play_error()
		GameEvents.show_floating_text.emit("Complete 5 Quests to Unlock Shop!", global_position + Vector2(size.x * 0.5, -40), Color(1.0, 0.5, 0.5))
		return
	SoundManager.play_click()
	shop_pressed.emit()
	GameEvents.request_shop_open.emit()

# =============================================================================
# Temporary Reward Slot Management
# =============================================================================

func _update_reward_slot_order() -> void:
	if not is_instance_valid(reward_btn) or not is_instance_valid(hbox):
		return
	if reward_slot_on_left:
		hbox.move_child(reward_btn, 0)
	else:
		hbox.move_child(reward_btn, hbox.get_child_count() - 1)

func update_reward_slot_display() -> void:
	if not is_instance_valid(reward_btn):
		return
	var count := ProgressionManager.get_reward_count()
	if count <= 0:
		if _reward_pulse_tween and _reward_pulse_tween.is_valid():
			_reward_pulse_tween.kill()
			_reward_pulse_tween = null
		reward_btn.visible = false
		if is_instance_valid(shine_overlay):
			shine_overlay.visible = false
		return

	if is_instance_valid(shine_overlay):
		shine_overlay.visible = true

	# If there are items in the reward queue, make sure slot is visible
	var top_id := ProgressionManager.peek_reward()
	var item_data := ItemDatabase.get_item(top_id)
	if is_instance_valid(reward_icon):
		if item_data and item_data.icon_texture:
			reward_icon.texture = item_data.icon_texture
		else:
			reward_icon.texture = preload("res://assets/items/rewards/chest/yellow/4.png")

	if is_instance_valid(reward_badge) and is_instance_valid(reward_badge_label):
		if count > 1:
			reward_badge.visible = true
			reward_badge_label.text = str(count)
		else:
			reward_badge.visible = false

	if not reward_btn.visible:
		reward_btn.visible = true
		reward_btn.scale = Vector2(0.5, 0.5)
		reward_btn.pivot_offset = Vector2(35, 35)
		var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(reward_btn, "scale", Vector2.ONE, 0.25)

	# Gentle idle breathing pulse for the shining tile
	if _reward_pulse_tween == null or not _reward_pulse_tween.is_valid():
		reward_btn.pivot_offset = Vector2(35, 35)
		_reward_pulse_tween = create_tween().set_loops()
		_reward_pulse_tween.tween_property(reward_btn, "scale", Vector2(1.05, 1.05), 0.6).set_trans(Tween.TRANS_SINE)
		_reward_pulse_tween.tween_property(reward_btn, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE)

func get_reward_button() -> Control:
	return reward_btn

func get_reward_button_pos() -> Vector2:
	if not is_instance_valid(reward_btn):
		return global_position
	return reward_btn.global_position + Vector2(35, 35)

func animate_reward_wobble() -> void:
	if not is_instance_valid(reward_btn):
		return
	reward_btn.pivot_offset = Vector2(35, 35)
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(reward_btn, "rotation_degrees", 8.0, 0.05)
	tween.tween_property(reward_btn, "rotation_degrees", -8.0, 0.05)
	tween.tween_property(reward_btn, "rotation_degrees", 5.0, 0.05)
	tween.tween_property(reward_btn, "rotation_degrees", 0.0, 0.05)

func _on_reward_slot_pressed() -> void:
	reward_slot_pressed.emit()
