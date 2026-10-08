class_name BoardCell
extends Control

@export var grid_coord: Vector2i = Vector2i.ZERO

@export_group("Visual Styling")
@export var cell_bg_color: Color = Color(0.18, 0.21, 0.27, 0.9):
	set(val):
		cell_bg_color = val
		set_highlight(_current_highlight)

@export var cell_border_color: Color = Color(0.28, 0.32, 0.4, 0.5):
	set(val):
		cell_border_color = val
		set_highlight(_current_highlight)

@export var cell_locked_bg_color: Color = Color(0.10, 0.11, 0.14, 0.95):
	set(val):
		cell_locked_bg_color = val
		set_highlight(_current_highlight)

@export var cell_locked_border_color: Color = Color(0.20, 0.22, 0.26, 0.6):
	set(val):
		cell_locked_border_color = val
		set_highlight(_current_highlight)

@export var hover_empty_color: Color = Color(0.28, 0.38, 0.52, 0.95):
	set(val):
		hover_empty_color = val
		set_highlight(_current_highlight)

@export var hover_merge_color: Color = Color(0.25, 0.65, 0.38, 0.95):
	set(val):
		hover_merge_color = val
		set_highlight(_current_highlight)

@export var corner_radius: int = 12:
	set(val):
		corner_radius = val
		set_highlight(_current_highlight)

@onready var background: Panel = $Background

var _current_highlight: int = 0
var is_locked: bool = false:
	set(val):
		is_locked = val
		set_highlight(_current_highlight)

var is_hidden_cell: bool = false:
	set(val):
		is_hidden_cell = val
		visible = not is_hidden_cell

func _ready() -> void:
	set_highlight(0)

func set_locked(val: bool) -> void:
	is_locked = val

func set_cell_hidden(val: bool) -> void:
	is_hidden_cell = val

func set_cell_size(sz: float) -> void:
	custom_minimum_size = Vector2(sz, sz)
	size = Vector2(sz, sz)
	offset_right = offset_left + sz
	offset_bottom = offset_top + sz
	reset_size()

func setup_style(bg_col: Color, border_col: Color, hover_empty: Color, hover_merge: Color, rad: int, locked_bg: Color = Color(0.10, 0.11, 0.14, 0.95), locked_border: Color = Color(0.20, 0.22, 0.26, 0.6)) -> void:
	cell_bg_color = bg_col
	cell_border_color = border_col
	cell_locked_bg_color = locked_bg
	cell_locked_border_color = locked_border
	hover_empty_color = hover_empty
	hover_merge_color = hover_merge
	corner_radius = rad
	set_highlight(_current_highlight)

var shining_circle: Sprite2D = null
var _shine_tween: Tween = null

func _ensure_shining_circle() -> void:
	if not shining_circle:
		shining_circle = get_node_or_null("ShiningCircle")
	if not shining_circle:
		shining_circle = Sprite2D.new()
		shining_circle.name = "ShiningCircle"
		shining_circle.texture = preload("res://assets/vfx/circle_03.png")
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		shining_circle.material = mat
		shining_circle.modulate = Color(1.0, 0.95, 0.55, 0.9)
		shining_circle.scale = Vector2(0.22, 0.22)
		shining_circle.visible = false
		shining_circle.z_index = 5
		add_child(shining_circle)
		if background:
			shining_circle.position = background.size * 0.5
		else:
			shining_circle.position = Vector2(40, 40)

func _set_shining_circle_visible(vis: bool) -> void:
	_ensure_shining_circle()
	if not shining_circle:
		return
	if vis:
		if background:
			shining_circle.position = background.size * 0.5
		shining_circle.visible = true
		if _shine_tween and _shine_tween.is_valid():
			_shine_tween.kill()
		_shine_tween = create_tween().set_loops()
		_shine_tween.tween_property(shining_circle, "rotation", deg_to_rad(360.0), 3.0).from(0.0)
		_shine_tween.parallel().tween_property(shining_circle, "scale", Vector2(0.25, 0.25), 0.4).set_trans(Tween.TRANS_SINE)
		_shine_tween.parallel().tween_property(shining_circle, "modulate:a", 1.0, 0.4)
		_shine_tween.chain().tween_property(shining_circle, "scale", Vector2(0.20, 0.20), 0.4).set_trans(Tween.TRANS_SINE)
		_shine_tween.parallel().tween_property(shining_circle, "modulate:a", 0.7, 0.4)
	else:
		shining_circle.visible = false
		if _shine_tween and _shine_tween.is_valid():
			_shine_tween.kill()
			_shine_tween = null

func set_highlight(state: int) -> void:
	_current_highlight = state
	if not background or not is_inside_tree():
		return
	var style: StyleBoxFlat = background.get_theme_stylebox("panel")
	if style:
		style = style.duplicate()
	else:
		style = StyleBoxFlat.new()

	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.corner_radius_bottom_left = corner_radius

	match state:
		0: # Normal
			_set_shining_circle_visible(false)
			if is_locked:
				style.bg_color = cell_locked_bg_color
				style.border_color = cell_locked_border_color
			else:
				style.bg_color = cell_bg_color
				style.border_color = cell_border_color
			style.border_width_left = 1
			style.border_width_top = 1
			style.border_width_right = 1
			style.border_width_bottom = 1
		1: # Hover empty slot
			_set_shining_circle_visible(false)
			style.bg_color = hover_empty_color
			style.border_color = Color(0.5, 0.75, 1.0, 0.9)
			style.border_width_left = 2
			style.border_width_top = 2
			style.border_width_right = 2
			style.border_width_bottom = 2
		2: # Hover merge partner (show shining circle instead of green border)
			_set_shining_circle_visible(true)
			if is_locked:
				style.bg_color = cell_locked_bg_color
				style.border_color = cell_locked_border_color
			else:
				style.bg_color = cell_bg_color
				style.border_color = cell_border_color
			style.border_width_left = 1
			style.border_width_top = 1
			style.border_width_right = 1
			style.border_width_bottom = 1
		3: # Tutorial highlight
			_set_shining_circle_visible(false)
			style.bg_color = Color(1.0, 0.82, 0.35, 0.35)
			style.border_color = Color(1.0, 0.88, 0.3, 1.0)
			style.border_width_left = 3
			style.border_width_top = 3
			style.border_width_right = 3
			style.border_width_bottom = 3
	background.add_theme_stylebox_override("panel", style)


