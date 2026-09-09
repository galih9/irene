class_name BottomNavBar
extends Control

signal progression_pressed()
signal inventory_pressed()
signal shop_pressed()

@onready var progression_btn: Button = $HBoxContainer/ProgressionBtn
@onready var inventory_btn: Button = $HBoxContainer/InventoryBtn
@onready var shop_btn: Button = $HBoxContainer/ShopBtn

@onready var badge_panel: PanelContainer = $HBoxContainer/ProgressionBtn/Badge
@onready var badge_label: Label = $HBoxContainer/ProgressionBtn/Badge/BadgeLabel
@onready var inventory_capacity_label: Label = $HBoxContainer/InventoryBtn/Margin/VBox/CapacityLabel

var _inventory_highlighted: bool = false
var _inv_normal_style: StyleBoxFlat
var _inv_hover_style: StyleBoxFlat

func _ready() -> void:
	progression_btn.pressed.connect(_on_progression_pressed)
	inventory_btn.pressed.connect(_on_inventory_pressed)
	shop_btn.pressed.connect(_on_shop_pressed)

	GameEvents.inventory_changed.connect(update_inventory_display)
	GameEvents.progression_changed.connect(update_progression_display)

	_setup_inventory_styles()
	update_inventory_display()
	update_progression_display()

func _setup_inventory_styles() -> void:
	var base_style := inventory_btn.get_theme_stylebox("normal")
	if base_style is StyleBoxFlat:
		_inv_normal_style = base_style.duplicate()
		_inv_hover_style = base_style.duplicate()
		_inv_hover_style.bg_color = Color(0.18, 0.25, 0.38, 0.98)
		_inv_hover_style.border_color = Color(0.35, 0.8, 1.0, 1.0)
		_inv_hover_style.border_width_left = 3
		_inv_hover_style.border_width_top = 3
		_inv_hover_style.border_width_right = 3
		_inv_hover_style.border_width_bottom = 3

func update_inventory_display() -> void:
	if is_instance_valid(inventory_capacity_label):
		var used := InventoryManager.get_used_count()
		var max_slots := InventoryManager.get_max_slots()
		inventory_capacity_label.text = "[%d / %d]" % [used, max_slots]
		if used >= max_slots:
			inventory_capacity_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
		elif used > 0:
			inventory_capacity_label.add_theme_color_override("font_color", Color(0.45, 0.85, 1.0))
		else:
			inventory_capacity_label.add_theme_color_override("font_color", Color(0.65, 0.72, 0.82))

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
	if _inv_hover_style and _inv_normal_style:
		inventory_btn.add_theme_stylebox_override("normal", _inv_hover_style if highlighted else _inv_normal_style)
	
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
	SoundManager.play_pickup()
	progression_pressed.emit()
	GameEvents.request_progression_open.emit()

func _on_inventory_pressed() -> void:
	SoundManager.play_pickup()
	inventory_pressed.emit()
	GameEvents.request_inventory_open.emit()

func _on_shop_pressed() -> void:
	SoundManager.play_pickup()
	shop_pressed.emit()
	GameEvents.request_shop_open.emit()
