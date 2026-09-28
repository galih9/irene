class_name LiquidBottle
extends Control

signal bottle_clicked(bottle: LiquidBottle)
signal pour_finished()
signal bottle_completed(bottle: LiquidBottle)

@export var capacity: int = 3
var layers: Array[String] = []

var bottle_index: int = 0
var is_selected: bool = false
var is_animating: bool = false
var is_complete: bool = false

var original_position: Vector2 = Vector2.ZERO
var hover_tween: Tween = null
var tilt_tween: Tween = null

# Child nodes
var fluid_rect: ColorRect
var glass_texture: TextureRect
var fluid_material: ShaderMaterial
var click_btn: Button
var cork_rect: TextureRect
var complete_icon: Control # Compatibility reference to cork_rect

const LiquidColorPalette = preload("res://scripts/minigame/liquid_color_palette.gd")
const FLUID_SHADER: Shader = preload("res://shaders/fluid_bottle.gdshader")
const BOTTLE_TEXTURE: Texture2D = preload("res://assets/items/extras/bottle/normal.png")
const MASK_TEXTURE: Texture2D = preload("res://assets/items/extras/bottle/inner_mask.png")
const CORK_TEXTURE: Texture2D = preload("res://assets/items/extras/bottle/cork.png")

func _init() -> void:
	custom_minimum_size = Vector2(100, 150)
	size = Vector2(100, 150)
	pivot_offset = Vector2(50, 75)

func _ready() -> void:
	_setup_children()
	original_position = position
	update_visuals()

func _process(_delta: float) -> void:
	if fluid_material:
		var cur_tilt: float = fluid_material.get_shader_parameter("tilt_angle")
		if not is_equal_approx(cur_tilt, rotation):
			fluid_material.set_shader_parameter("tilt_angle", rotation)

func _setup_children() -> void:
	# 1. Fluid Shader Rect (rendered behind glass)
	fluid_rect = ColorRect.new()
	fluid_rect.name = "FluidRect"
	fluid_rect.set_anchors_preset(PRESET_FULL_RECT)
	fluid_rect.mouse_filter = MOUSE_FILTER_IGNORE
	
	fluid_material = ShaderMaterial.new()
	fluid_material.shader = FLUID_SHADER
	fluid_material.set_shader_parameter("inner_mask", MASK_TEXTURE)
	fluid_rect.material = fluid_material
	add_child(fluid_rect)

	# 2. Glass Bottle Overlay (on top of fluid)
	glass_texture = TextureRect.new()
	glass_texture.name = "GlassTexture"
	glass_texture.set_anchors_preset(PRESET_FULL_RECT)
	glass_texture.texture = BOTTLE_TEXTURE
	glass_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glass_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glass_texture.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(glass_texture)

	# 3. Completed Cork Stopper (plugs into the bottle neck opening)
	cork_rect = TextureRect.new()
	cork_rect.name = "CorkRect"
	cork_rect.texture = CORK_TEXTURE
	cork_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cork_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cork_rect.mouse_filter = MOUSE_FILTER_IGNORE
	cork_rect.visible = false
	cork_rect.z_index = 2
	add_child(cork_rect)
	complete_icon = cork_rect

	# 4. Interactive Click Button
	click_btn = Button.new()
	click_btn.name = "ClickBtn"
	click_btn.set_anchors_preset(PRESET_FULL_RECT)
	click_btn.flat = true
	click_btn.focus_mode = FOCUS_NONE
	click_btn.mouse_default_cursor_shape = CursorShape.CURSOR_POINTING_HAND
	click_btn.pressed.connect(_on_click_pressed)
	add_child(click_btn)

	_update_cork_layout()

func _get_cork_size() -> Vector2:
	var cw := size.x * 0.38
	return Vector2(cw, cw)

func _get_cork_target_pos() -> Vector2:
	var c_size := _get_cork_size()
	var cx := (size.x - c_size.x) * 0.5
	# Factor 0.06 places the cork stopper firmly inside the glass neck opening
	var cy := (size.y * 0.06) - (c_size.y * 0.5)
	return Vector2(cx, cy)

func _update_cork_layout() -> void:
	if not is_instance_valid(cork_rect):
		return
	var c_size := _get_cork_size()
	cork_rect.size = c_size
	cork_rect.custom_minimum_size = c_size
	cork_rect.pivot_offset = Vector2(c_size.x * 0.5, c_size.y * 0.75)
	if not is_animating:
		cork_rect.position = _get_cork_target_pos()

func set_bottle_size(new_size: Vector2) -> void:
	custom_minimum_size = new_size
	size = new_size
	pivot_offset = new_size * 0.5
	_update_cork_layout()

func setup(cap: int, initial_layers: Array[String]) -> void:
	capacity = max(1, cap)
	layers = initial_layers.duplicate()
	is_selected = false
	is_animating = false
	rotation = 0.0
	is_complete = check_is_complete()
	if cork_rect:
		cork_rect.visible = is_complete
		cork_rect.scale = Vector2.ONE
		cork_rect.modulate.a = 1.0
		_update_cork_layout()
	update_visuals()

func _on_click_pressed() -> void:
	if is_animating:
		return
	bottle_clicked.emit(self)

func get_top_color() -> String:
	if layers.is_empty():
		return ""
	return layers[layers.size() - 1]

func get_top_consecutive_count() -> int:
	if layers.is_empty():
		return 0
	var top_col := get_top_color()
	var count := 0
	for i in range(layers.size() - 1, -1, -1):
		if layers[i] == top_col:
			count += 1
		else:
			break
	return count

func get_available_space() -> int:
	return max(0, capacity - layers.size())

func is_empty_bottle() -> bool:
	return layers.is_empty()

func is_full() -> bool:
	return layers.size() >= capacity

func check_is_complete() -> bool:
	if not is_full():
		return false
	var first_col := layers[0]
	for col in layers:
		if col != first_col:
			return false
	return true

func can_receive_from(source: LiquidBottle) -> bool:
	if source == self or is_animating or source.is_animating:
		return false
	if source.is_empty_bottle():
		return false
	if is_full():
		return false
	if is_empty_bottle():
		return true
	return get_top_color() == source.get_top_color()

func set_selected(selected: bool) -> void:
	if is_selected == selected or is_animating:
		return
	is_selected = selected

	if hover_tween:
		hover_tween.kill()

	if is_selected:
		# Lift bottle with bouncy pop
		hover_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		hover_tween.tween_property(self, "position:y", original_position.y - 32.0, 0.22)
		hover_tween.tween_callback(_start_hover_loop)
		if fluid_material:
			fluid_material.set_shader_parameter("wave_amplitude", 0.018)
	else:
		# Lower back smoothly
		hover_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		hover_tween.tween_property(self, "position:y", original_position.y, 0.18)
		if fluid_material:
			fluid_material.set_shader_parameter("wave_amplitude", 0.010)

func _start_hover_loop() -> void:
	if not is_selected or is_animating:
		return
	hover_tween = create_tween().set_loops()
	var base_y := original_position.y - 32.0
	hover_tween.tween_property(self, "position:y", base_y - 6.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	hover_tween.tween_property(self, "position:y", base_y + 4.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func wobble_error() -> void:
	if is_animating:
		return
	var orig_x := position.x
	var tween := create_tween()
	tween.tween_property(self, "position:x", orig_x - 7.0, 0.05)
	tween.tween_property(self, "position:x", orig_x + 7.0, 0.05)
	tween.tween_property(self, "position:x", orig_x - 5.0, 0.05)
	tween.tween_property(self, "position:x", orig_x + 5.0, 0.05)
	tween.tween_property(self, "position:x", orig_x, 0.05)

func get_lip_position_global() -> Vector2:
	# Returns the world coordinate of the bottle mouth lip where liquid pours out
	var lip_x := size.x * 0.5
	if rotation > 0.05:
		lip_x = size.x * 0.58
	elif rotation < -0.05:
		lip_x = size.x * 0.42
	var local_lip := Vector2(lip_x, size.y * 0.08)
	return get_global_transform() * local_lip

func get_neck_position_global() -> Vector2:
	# Returns the target bottle neck entry coordinate
	var local_neck := Vector2(size.x * 0.5, size.y * 0.18)
	return get_global_transform() * local_neck

func update_visuals() -> void:
	if not fluid_material:
		return

	is_complete = check_is_complete()
	if cork_rect and not is_animating:
		cork_rect.visible = is_complete

	fluid_material.set_shader_parameter("capacity", capacity)
	fluid_material.set_shader_parameter("layer_count", layers.size())
	fluid_material.set_shader_parameter("tilt_angle", rotation)

	var colors_arr: Array = []
	var heights_arr: Array = []

	for i in range(8):
		if i < layers.size():
			colors_arr.append(LiquidColorPalette.get_color(layers[i]))
			heights_arr.append(1.0)
		else:
			colors_arr.append(Color(0, 0, 0, 0))
			heights_arr.append(0.0)

	fluid_material.set_shader_parameter("layer_colors", colors_arr)
	fluid_material.set_shader_parameter("layer_heights", heights_arr)
	fluid_material.set_shader_parameter("fill_amount", 1.0)

func animate_fill_in(color_key: String, count: int, duration: float) -> void:
	# Add temporary placeholder layer that grows
	var start_idx := layers.size()
	for _c in range(count):
		layers.append(color_key)
	
	update_visuals()

	# Initially set newly added layers to height 0 so they don't flash at full height
	for k in range(count):
		_set_single_layer_height(start_idx + k, 0.0)
	
	# Animate the newly added layers growing from 0.0 to 1.0
	var tween := create_tween()
	var step_time := duration / float(count)
	for k in range(count):
		var target_layer := start_idx + k
		tween.tween_method(func(val: float):
			_set_single_layer_height(target_layer, val)
		, 0.0, 1.0, step_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	tween.finished.connect(func():
		update_visuals()
	)

func animate_pour_out(count: int, duration: float) -> void:
	var tween := create_tween()
	var step_time := duration / float(count)
	for k in range(count):
		var target_layer := layers.size() - 1 - k
		tween.tween_method(func(val: float):
			_set_single_layer_height(target_layer, val)
		, 1.0, 0.0, step_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	tween.finished.connect(func():
		for _c in range(count):
			if not layers.is_empty():
				layers.pop_back()
		update_visuals()
	)

func _set_single_layer_height(layer_idx: int, height_val: float) -> void:
	if not fluid_material:
		return
	var heights: Array = fluid_material.get_shader_parameter("layer_heights")
	if heights and layer_idx < heights.size():
		heights[layer_idx] = height_val
		fluid_material.set_shader_parameter("layer_heights", heights)

func celebrate_complete() -> void:
	is_complete = true
	if is_instance_valid(cork_rect):
		_update_cork_layout()
		var target_pos := _get_cork_target_pos()
		cork_rect.visible = true
		cork_rect.position = Vector2(target_pos.x, target_pos.y - 28.0)
		cork_rect.scale = Vector2(0.85, 1.25)
		cork_rect.modulate.a = 0.0

		var cork_tween := create_tween()
		cork_tween.set_parallel(true)
		cork_tween.tween_property(cork_rect, "position:y", target_pos.y, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		cork_tween.tween_property(cork_rect, "modulate:a", 1.0, 0.10)
		cork_tween.tween_property(cork_rect, "scale", Vector2(1.18, 0.82), 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

		# Elastic rebound into firm seal
		cork_tween.chain().tween_property(cork_rect, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Gentle celebratory bounce of the bottle
	var b_tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	b_tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.14)
	b_tween.tween_property(self, "scale", Vector2.ONE, 0.18)

	bottle_completed.emit(self)
