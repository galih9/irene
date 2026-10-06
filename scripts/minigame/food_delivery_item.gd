class_name FoodDeliveryItem
extends Control

signal clicked(item: FoodDeliveryItem)
signal drag_started(item: FoodDeliveryItem)
signal drag_moved(item: FoodDeliveryItem, global_pos: Vector2)
signal drag_ended(item: FoodDeliveryItem, global_pos: Vector2)

@export var item_id: String = ""

var is_topmost: bool = false
var is_animating: bool = false
var is_pressed: bool = false
var is_dragging: bool = false

var press_start_pos: Vector2 = Vector2.ZERO
var drag_offset: Vector2 = Vector2.ZERO
var original_global_pos: Vector2 = Vector2.ZERO
var original_z_index: int = 1

var panel: Panel
var icon_rect: TextureRect

var base_size: Vector2 = Vector2(72, 72)
var _current_tween: Tween = null

func _init(id: String = "") -> void:
	item_id = id
	custom_minimum_size = base_size
	size = base_size
	pivot_offset = base_size * 0.5

func _ready() -> void:
	_build_visuals()
	if not item_id.is_empty():
		setup(item_id)
	set_topmost(is_topmost)

func _build_visuals() -> void:
	panel = Panel.new()
	panel.name = "TilePanel"
	panel.set_anchors_preset(PRESET_FULL_RECT)
	panel.mouse_filter = MOUSE_FILTER_IGNORE
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.99, 0.98, 0.95, 1.0)
	style.set_corner_radius_all(14)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 3
	style.border_color = Color(0.85, 0.80, 0.72, 1.0)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.15)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	icon_rect = TextureRect.new()
	icon_rect.name = "Icon"
	icon_rect.set_anchors_preset(PRESET_FULL_RECT)
	icon_rect.offset_left = 6
	icon_rect.offset_top = 6
	icon_rect.offset_right = -6
	icon_rect.offset_bottom = -6
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(icon_rect)

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)

func setup(new_id: String) -> void:
	item_id = new_id
	if is_instance_valid(icon_rect) and not item_id.is_empty():
		var data: ItemData = ItemDatabase.get_item(item_id) if is_instance_valid(ItemDatabase) else null
		if data and data.icon_texture:
			icon_rect.texture = data.icon_texture
		else:
			var tex: Texture2D = _get_fallback_texture(item_id)
			if tex:
				icon_rect.texture = tex

func _get_fallback_texture(id: String) -> Texture2D:
	match id:
		"bakery_6": return load("res://assets/items/kitchen/sandwich/sandwich6.png")
		"bakery_3": return load("res://assets/items/kitchen/sandwich/sandwich3.png")
		"sweets_2": return load("res://assets/items/kitchen/cake/cake_2.png")
		"sweets_5": return load("res://assets/items/kitchen/cake/cake_5.png")
		"grill_2": return load("res://assets/items/kitchen/beef/beef_2.png")
		"grill_3": return load("res://assets/items/kitchen/beef/beef_3.png")
		"drinks_2": return load("res://assets/items/kitchen/drink/drink_2.png")
		"healthy_3": return load("res://assets/items/kitchen/eggs/egg_2.png")
	return null

func set_topmost(active: bool) -> void:
	is_topmost = active
	if is_animating or is_dragging:
		return

	if is_topmost:
		mouse_filter = MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		modulate = Color(1.0, 1.0, 1.0, 1.0)
		z_index = 10
	else:
		mouse_filter = MOUSE_FILTER_IGNORE
		mouse_default_cursor_shape = Control.CURSOR_ARROW
		modulate = Color(0.68, 0.68, 0.72, 0.90)
		z_index = 1
		scale = Vector2.ONE

func _on_mouse_entered() -> void:
	if is_topmost and not is_animating and not is_dragging:
		if _current_tween:
			_current_tween.kill()
		_current_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_current_tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.12)

func _on_mouse_exited() -> void:
	if not is_animating and not is_dragging:
		if _current_tween:
			_current_tween.kill()
		_current_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_current_tween.tween_property(self, "scale", Vector2.ONE, 0.12)

func _on_gui_input(event: InputEvent) -> void:
	if is_animating or not is_topmost:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_pressed = true
			is_dragging = false
			press_start_pos = event.global_position
			drag_offset = event.global_position - global_position
			original_global_pos = global_position
			original_z_index = z_index
			accept_event()
		else:
			if is_pressed:
				is_pressed = false
				if is_dragging:
					is_dragging = false
					drag_ended.emit(self, event.global_position)
				else:
					clicked.emit(self)
				accept_event()

	elif event is InputEventMouseMotion and is_pressed and not is_animating:
		if not is_dragging:
			if (event.global_position - press_start_pos).length() > 6.0:
				is_dragging = true
				z_index = 250
				drag_started.emit(self)
		if is_dragging:
			global_position = event.global_position - drag_offset
			drag_moved.emit(self, event.global_position)
			accept_event()

func return_to_origin(duration: float = 0.18) -> void:
	is_dragging = false
	is_pressed = false
	if _current_tween:
		_current_tween.kill()
	_current_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_current_tween.tween_property(self, "global_position", original_global_pos, duration)
	_current_tween.tween_property(self, "scale", Vector2.ONE, duration)
	_current_tween.tween_callback(func():
		z_index = original_z_index
	)

func play_wiggle() -> void:
	if is_animating:
		return
	if _current_tween:
		_current_tween.kill()
	var orig_pos := position
	_current_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_current_tween.tween_property(self, "position:x", orig_pos.x - 7.0, 0.05)
	_current_tween.tween_property(self, "position:x", orig_pos.x + 7.0, 0.05)
	_current_tween.tween_property(self, "position:x", orig_pos.x - 5.0, 0.05)
	_current_tween.tween_property(self, "position:x", orig_pos.x + 5.0, 0.05)
	_current_tween.tween_property(self, "position:x", orig_pos.x, 0.05)
	_current_tween.parallel().tween_property(self, "modulate", Color(1.2, 0.5, 0.5, 1.0), 0.1)
	_current_tween.tween_property(self, "modulate", Color.WHITE, 0.15)

func play_pop_in() -> void:
	scale = Vector2(0.5, 0.5)
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.22)
