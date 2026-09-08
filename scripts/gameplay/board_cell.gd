class_name BoardCell
extends Control

@export var grid_coord: Vector2i = Vector2i.ZERO

@onready var background: Panel = $Background

const COLOR_NORMAL := Color(0.18, 0.21, 0.27, 0.9)
const COLOR_HOVER_EMPTY := Color(0.28, 0.38, 0.52, 0.95)
const COLOR_HOVER_MERGE := Color(0.25, 0.65, 0.38, 0.95)

func _ready() -> void:
	set_highlight(0)

func set_highlight(state: int) -> void:
	if not background:
		return
	var style: StyleBoxFlat = background.get_theme_stylebox("panel").duplicate()
	match state:
		0: # Normal
			style.bg_color = COLOR_NORMAL
			style.border_color = Color(0.28, 0.32, 0.4, 0.5)
			style.border_width_left = 1
			style.border_width_top = 1
			style.border_width_right = 1
			style.border_width_bottom = 1
		1: # Hover empty slot
			style.bg_color = COLOR_HOVER_EMPTY
			style.border_color = Color(0.5, 0.75, 1.0, 0.9)
			style.border_width_left = 2
			style.border_width_top = 2
			style.border_width_right = 2
			style.border_width_bottom = 2
		2: # Hover merge partner
			style.bg_color = COLOR_HOVER_MERGE
			style.border_color = Color(0.6, 1.0, 0.6, 1.0)
			style.border_width_left = 3
			style.border_width_top = 3
			style.border_width_right = 3
			style.border_width_bottom = 3
	background.add_theme_stylebox_override("panel", style)
