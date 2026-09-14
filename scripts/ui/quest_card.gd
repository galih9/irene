class_name QuestCard
extends Control

signal deliver_pressed(quest: QuestData)

var quest_data: QuestData = null
var is_ready_to_deliver: bool = false
var is_cooldown_mode: bool = false

@onready var background: Panel = $Background
@onready var header: HBoxContainer = $Background/VBox/Header
@onready var customer_avatar: Panel = $Background/VBox/Header/Avatar
@onready var customer_name_label: Label = $Background/VBox/Header/NameLabel
@onready var req_scroll: ScrollContainer = $Background/VBox/ReqScroll
@onready var requirements_container: HBoxContainer = $Background/VBox/ReqScroll/ReqContainer
@onready var reward_label: Label = $Background/VBox/RewardLabel
@onready var deliver_btn: Button = $Background/VBox/DeliverBtn

@onready var cooldown_box: VBoxContainer = $Background/VBox/CooldownBox
@onready var cooldown_label: Label = $Background/VBox/CooldownBox/CooldownLabel
@onready var cooldown_bar: ProgressBar = $Background/VBox/CooldownBox/CooldownBar

var _highlight_tween: Tween = null

func _ready() -> void:
	deliver_btn.pressed.connect(_on_deliver_pressed)

func setup(quest: QuestData, is_ready: bool, available_item_ids: Array[String]) -> void:
	quest_data = quest
	is_ready_to_deliver = is_ready
	is_cooldown_mode = false
	visible = true

	if is_instance_valid(cooldown_box):
		cooldown_box.visible = false
	if is_instance_valid(header):
		header.visible = true
	if is_instance_valid(req_scroll):
		req_scroll.visible = true
	if is_instance_valid(reward_label):
		reward_label.visible = true
	if is_instance_valid(deliver_btn):
		deliver_btn.visible = true

	customer_name_label.text = quest.customer_name

	# Special styling for Ultimate Quest
	if quest.id.begins_with("ultimate_quest"):
		var ult_style := StyleBoxFlat.new()
		ult_style.bg_color = Color(1.0, 0.98, 0.92, 0.98)
		ult_style.border_color = Color(1.0, 0.82, 0.2, 1.0)
		ult_style.border_width_left = 3
		ult_style.border_width_top = 3
		ult_style.border_width_right = 3
		ult_style.border_width_bottom = 3
		ult_style.corner_radius_top_left = 14
		ult_style.corner_radius_top_right = 14
		ult_style.corner_radius_bottom_right = 14
		ult_style.corner_radius_bottom_left = 14
		ult_style.shadow_color = Color(1.0, 0.78, 0.15, 0.35)
		ult_style.shadow_size = 10
		background.add_theme_stylebox_override("panel", ult_style)
	else:
		background.remove_theme_stylebox_override("panel")

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

func setup_cooldown(_remaining: float = 0.0, _total: float = 0.0) -> void:
	is_cooldown_mode = true
	quest_data = null
	is_ready_to_deliver = false
	set_delivery_highlight(false)
	visible = false

	if is_instance_valid(header):
		header.visible = false
	if is_instance_valid(req_scroll):
		req_scroll.visible = false
	if is_instance_valid(reward_label):
		reward_label.visible = false
	if is_instance_valid(deliver_btn):
		deliver_btn.visible = false
	if is_instance_valid(cooldown_box):
		cooldown_box.visible = false

func set_delivery_highlight(enable: bool) -> void:
	if _highlight_tween and _highlight_tween.is_valid():
		_highlight_tween.kill()
		_highlight_tween = null

	if not is_instance_valid(deliver_btn):
		return

	deliver_btn.pivot_offset = deliver_btn.size * 0.5
	if enable:
		_highlight_tween = create_tween().set_loops()
		_highlight_tween.tween_property(deliver_btn, "scale", Vector2(1.08, 1.08), 0.35).set_trans(Tween.TRANS_SINE)
		_highlight_tween.tween_property(deliver_btn, "modulate", Color(1.3, 1.3, 1.0), 0.35)
		_highlight_tween.tween_property(deliver_btn, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_SINE)
		_highlight_tween.tween_property(deliver_btn, "modulate", Color.WHITE, 0.35)
	else:
		deliver_btn.scale = Vector2.ONE
		deliver_btn.modulate = Color.WHITE

func slide_in_from_top() -> void:
	modulate.a = 0.0
	position.y -= 45.0
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", position.y + 45.0, 0.45)
	tween.tween_property(self, "modulate:a", 1.0, 0.4)

func _create_req_badge(item_data: ItemData, has_it: bool) -> Control:
	var box := Panel.new()
	box.custom_minimum_size = Vector2(46, 46)

	var box_style := StyleBoxFlat.new()
	box_style.corner_radius_top_left = 8
	box_style.corner_radius_top_right = 8
	box_style.corner_radius_bottom_right = 8
	box_style.corner_radius_bottom_left = 8

	if has_it:
		box_style.bg_color = Color(1.0, 1.0, 1.0, 0.95)
		box_style.border_color = Color(0.35, 0.78, 0.42, 1.0)
		box_style.border_width_left = 2
		box_style.border_width_top = 2
		box_style.border_width_right = 2
		box_style.border_width_bottom = 2
	else:
		box_style.bg_color = Color(0.92, 0.90, 0.88, 0.85)
		box_style.border_color = Color(0.80, 0.76, 0.72, 0.8)
		box_style.border_width_left = 1
		box_style.border_width_top = 1
		box_style.border_width_right = 1
		box_style.border_width_bottom = 1

	box.add_theme_stylebox_override("panel", box_style)

	# Icon
	var icon := TextureRect.new()
	if item_data.icon_texture:
		icon.texture = item_data.icon_texture
		icon.modulate = Color(1, 1, 1, 1.0 if has_it else 0.45)
	else:
		icon.texture = preload("res://icon.jpg")
		icon.modulate = Color(1, 1, 1, 0.9 if has_it else 0.45)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(32, 32)
	icon.position = Vector2(7, 7)
	box.add_child(icon)

	# Status checkmark / dots
	var check_lbl := Label.new()
	check_lbl.text = "✓" if has_it else "..."
	check_lbl.add_theme_font_size_override("font_size", 14)
	check_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	check_lbl.position = Vector2(16, 25)
	check_lbl.size = Vector2(26, 18)
	check_lbl.add_theme_color_override("font_color", Color(0.2, 0.65, 0.3) if has_it else Color(0.58, 0.54, 0.52))
	box.add_child(check_lbl)

	return box

func _on_deliver_pressed() -> void:
	if is_ready_to_deliver and quest_data:
		set_delivery_highlight(false)
		deliver_pressed.emit(quest_data)
