class_name QuestCard
extends Control

signal deliver_pressed(quest: QuestData)

var quest_data: QuestData = null
var is_ready_to_deliver: bool = false

@onready var customer_avatar: Panel = $Background/VBox/Header/Avatar
@onready var customer_name_label: Label = $Background/VBox/Header/NameLabel
@onready var requirements_container: HBoxContainer = $Background/VBox/ReqContainer
@onready var reward_label: Label = $Background/VBox/RewardLabel
@onready var deliver_btn: Button = $Background/VBox/DeliverBtn

func _ready() -> void:
	deliver_btn.pressed.connect(_on_deliver_pressed)

func setup(quest: QuestData, is_ready: bool, available_item_ids: Array[String]) -> void:
	quest_data = quest
	is_ready_to_deliver = is_ready

	customer_name_label.text = quest.customer_name

	# Avatar color
	var av_style := StyleBoxFlat.new()
	av_style.bg_color = quest.customer_color
	av_style.corner_radius_top_left = 14
	av_style.corner_radius_top_right = 14
	av_style.corner_radius_bottom_right = 14
	av_style.corner_radius_bottom_left = 14
	customer_avatar.add_theme_stylebox_override("panel", av_style)

	# Rewards
	var rewards_text: String = "+%d Gold" % quest.reward_coins
	if quest.reward_gems > 0:
		rewards_text += "  +%d Gems" % quest.reward_gems
	if quest.reward_exp > 0:
		rewards_text += "  +%d EXP" % quest.reward_exp
	reward_label.text = rewards_text

	# Requirements
	for child in requirements_container.get_children():
		child.queue_free()

	# Track available items to mark checkmarks correctly
	var temp_avail := available_item_ids.duplicate()
	for req_id in quest.required_item_ids:
		var item_data := ItemDatabase.get_item(req_id)
		if not item_data:
			continue

		var has_it := temp_avail.has(req_id)
		if has_it:
			temp_avail.erase(req_id)

		var req_node := _create_req_badge(item_data, has_it)
		requirements_container.add_child(req_node)

	# Deliver button state
	deliver_btn.disabled = not is_ready_to_deliver
	deliver_btn.text = "DELIVER!" if is_ready_to_deliver else "Incomplete"

func _create_req_badge(item_data: ItemData, has_it: bool) -> Control:
	var box := Panel.new()
	box.custom_minimum_size = Vector2(46, 46)

	var box_style := StyleBoxFlat.new()
	box_style.bg_color = item_data.color * (1.0 if has_it else 0.4)
	box_style.border_width_left = 2
	box_style.border_width_top = 2
	box_style.border_width_right = 2
	box_style.border_width_bottom = 2
	box_style.border_color = Color(0.4, 0.9, 0.4, 1.0) if has_it else Color(0.3, 0.35, 0.4, 0.8)
	box_style.corner_radius_top_left = 8
	box_style.corner_radius_top_right = 8
	box_style.corner_radius_bottom_right = 8
	box_style.corner_radius_bottom_left = 8
	box.add_theme_stylebox_override("panel", box_style)

	# Icon
	var icon := TextureRect.new()
	if item_data.icon_texture:
		icon.texture = item_data.icon_texture
		icon.modulate = Color(1, 1, 1, 1.0 if has_it else 0.4)
		box_style.bg_color = Color(0.18, 0.22, 0.3, 0.95) if has_it else Color(0.12, 0.14, 0.18, 0.8)
	else:
		icon.texture = preload("res://icon.svg")
		icon.modulate = Color(1, 1, 1, 0.9 if has_it else 0.4)
		box_style.bg_color = item_data.color * (1.0 if has_it else 0.4)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(30, 30)
	icon.position = Vector2(8, 8)
	box.add_child(icon)

	# Tier badge
	var tier_lbl := Label.new()
	tier_lbl.text = "T%d" % item_data.tier
	tier_lbl.add_theme_font_size_override("font_size", 10)
	tier_lbl.position = Vector2(2, 2)
	tier_lbl.add_theme_color_override("font_color", Color.WHITE)
	tier_lbl.add_theme_color_override("font_outline_color", Color(0.18, 0.12, 0.08, 0.8))
	tier_lbl.add_theme_constant_override("outline_size", 2)
	box.add_child(tier_lbl)

	# Status checkmark / X
	var check_lbl := Label.new()
	check_lbl.text = "✓" if has_it else "..."
	check_lbl.add_theme_font_size_override("font_size", 14)
	check_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	check_lbl.position = Vector2(16, 26)
	check_lbl.size = Vector2(26, 18)
	check_lbl.add_theme_color_override("font_color", Color(0.42, 0.95, 0.55) if has_it else Color(0.68, 0.64, 0.62, 0.7))
	box.add_child(check_lbl)

	return box

func _on_deliver_pressed() -> void:
	if is_ready_to_deliver and quest_data:
		deliver_pressed.emit(quest_data)
