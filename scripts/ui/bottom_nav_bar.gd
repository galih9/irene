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

@onready var hbox: HBoxContainer = $HBoxContainer
@onready var progression_btn: Button = $HBoxContainer/ProgressionBtn
@onready var inventory_btn: Button = $HBoxContainer/InventoryBtn
@onready var shop_btn: Button = $HBoxContainer/ShopBtn
@onready var reward_btn: Button = $HBoxContainer/RewardBtn

@onready var badge_panel: PanelContainer = $HBoxContainer/ProgressionBtn/Badge
@onready var badge_label: Label = $HBoxContainer/ProgressionBtn/Badge/BadgeLabel
@onready var inventory_capacity_label: Label = $HBoxContainer/InventoryBtn/Margin/VBox/CapacityLabel

@onready var reward_icon: TextureRect = $HBoxContainer/RewardBtn/Margin/VBox/Icon
@onready var reward_badge: PanelContainer = $HBoxContainer/RewardBtn/Badge
@onready var reward_badge_label: Label = $HBoxContainer/RewardBtn/Badge/BadgeLabel

var _inventory_highlighted: bool = false

func _ready() -> void:
	progression_btn.pressed.connect(_on_progression_pressed)
	inventory_btn.pressed.connect(_on_inventory_pressed)
	shop_btn.pressed.connect(_on_shop_pressed)
	if is_instance_valid(reward_btn):
		reward_btn.pressed.connect(_on_reward_slot_pressed)

	GameEvents.inventory_changed.connect(update_inventory_display)
	GameEvents.progression_changed.connect(update_progression_display)
	GameEvents.reward_queue_changed.connect(update_reward_slot_display)

	_update_reward_slot_order()
	update_inventory_display()
	update_progression_display()
	update_reward_slot_display()

func update_inventory_display() -> void:
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

func play_inventory_pulse() -> void:
	inventory_btn.pivot_offset = inventory_btn.size * 0.5
	var tween := create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(inventory_btn, "scale", Vector2(1.15, 0.85), 0.1)
	tween.tween_property(inventory_btn, "scale", Vector2(0.9, 1.1), 0.15)
	tween.tween_property(inventory_btn, "scale", Vector2.ONE, 0.2)

func _on_progression_pressed() -> void:
	SoundManager.play_click()
	progression_pressed.emit()
	GameEvents.request_progression_open.emit()

func _on_inventory_pressed() -> void:
	SoundManager.play_click()
	inventory_pressed.emit()
	GameEvents.request_inventory_open.emit()

func _on_shop_pressed() -> void:
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
		reward_btn.visible = false
		return

	# If there are items in the reward queue, make sure slot is visible
	var top_id := ProgressionManager.peek_reward()
	var item_data := ItemDatabase.get_item(top_id)
	if is_instance_valid(reward_icon):
		if item_data and item_data.icon_texture:
			reward_icon.texture = item_data.icon_texture
		else:
			reward_icon.texture = preload("res://icon.svg")

	if is_instance_valid(reward_badge) and is_instance_valid(reward_badge_label):
		if count > 1:
			reward_badge.visible = true
			reward_badge_label.text = str(count)
		else:
			reward_badge.visible = false

	if not reward_btn.visible:
		reward_btn.visible = true
		reward_btn.scale = Vector2(0.5, 0.5)
		reward_btn.pivot_offset = reward_btn.size * 0.5
		var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(reward_btn, "scale", Vector2.ONE, 0.25)

func get_reward_button() -> Control:
	return reward_btn

func get_reward_button_pos() -> Vector2:
	if not is_instance_valid(reward_btn):
		return global_position
	return reward_btn.global_position + reward_btn.size * 0.5

func animate_reward_wobble() -> void:
	if not is_instance_valid(reward_btn):
		return
	reward_btn.pivot_offset = reward_btn.size * 0.5
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(reward_btn, "rotation_degrees", 8.0, 0.05)
	tween.tween_property(reward_btn, "rotation_degrees", -8.0, 0.05)
	tween.tween_property(reward_btn, "rotation_degrees", 5.0, 0.05)
	tween.tween_property(reward_btn, "rotation_degrees", 0.0, 0.05)

func _on_reward_slot_pressed() -> void:
	reward_slot_pressed.emit()
