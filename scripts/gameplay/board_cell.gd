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

func _ready() -> void:
	set_highlight(0)

func setup_style(bg_col: Color, border_col: Color, hover_empty: Color, hover_merge: Color, rad: int) -> void:
	cell_bg_color = bg_col
	cell_border_color = border_col
	hover_empty_color = hover_empty
	hover_merge_color = hover_merge
	corner_radius = rad
	set_highlight(_current_highlight)

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
			style.bg_color = cell_bg_color
			style.border_color = cell_border_color
			style.border_width_left = 1
			style.border_width_top = 1
			style.border_width_right = 1
			style.border_width_bottom = 1
		1: # Hover empty slot
			style.bg_color = hover_empty_color
			style.border_color = Color(0.5, 0.75, 1.0, 0.9)
			style.border_width_left = 2
			style.border_width_top = 2
			style.border_width_right = 2
			style.border_width_bottom = 2
		2: # Hover merge partner
			style.bg_color = hover_merge_color
			style.border_color = Color(0.6, 1.0, 0.6, 1.0)
			style.border_width_left = 3
			style.border_width_top = 3
			style.border_width_right = 3
			style.border_width_bottom = 3
	background.add_theme_stylebox_override("panel", style)

