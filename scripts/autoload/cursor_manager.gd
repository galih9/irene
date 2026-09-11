extends Node

# Preloaded cursor textures
const CURSOR_ARROW_TEX: Texture2D = preload("res://assets/cursor/pointer_a.png")
const CURSOR_POINTING_HAND_TEX: Texture2D = preload("res://assets/cursor/hand_point.png")
const CURSOR_DRAG_TEX: Texture2D = preload("res://assets/cursor/hand_closed.png")
const CURSOR_CAN_DROP_TEX: Texture2D = preload("res://assets/cursor/hand_open.png")
const CURSOR_FORBIDDEN_TEX: Texture2D = preload("res://assets/cursor/disabled.png")
const CURSOR_HELP_TEX: Texture2D = preload("res://assets/cursor/mark_question_pointer_b.png")
const CURSOR_WAIT_TEX: Texture2D = preload("res://assets/cursor/progress_full.png")

# Exact pixel hotspots based on asset geometry (32x32)
const HOTSPOT_ARROW: Vector2 = Vector2(10, 6)
const HOTSPOT_POINTING_HAND: Vector2 = Vector2(10, 2)
const HOTSPOT_DRAG: Vector2 = Vector2(16, 16)
const HOTSPOT_CAN_DROP: Vector2 = Vector2(16, 14)
const HOTSPOT_FORBIDDEN: Vector2 = Vector2(16, 16)
const HOTSPOT_HELP: Vector2 = Vector2(10, 6)
const HOTSPOT_WAIT: Vector2 = Vector2(16, 16)

func _ready() -> void:
	register_all_cursors()
	# Automatically wire BaseButton hover cursor across the scene tree
	get_tree().node_added.connect(_on_node_added)
	_apply_to_existing_nodes(get_tree().root)

func register_all_cursors() -> void:
	Input.set_custom_mouse_cursor(CURSOR_ARROW_TEX, Input.CURSOR_ARROW, HOTSPOT_ARROW)
	Input.set_custom_mouse_cursor(CURSOR_POINTING_HAND_TEX, Input.CURSOR_POINTING_HAND, HOTSPOT_POINTING_HAND)
	Input.set_custom_mouse_cursor(CURSOR_DRAG_TEX, Input.CURSOR_DRAG, HOTSPOT_DRAG)
	Input.set_custom_mouse_cursor(CURSOR_CAN_DROP_TEX, Input.CURSOR_CAN_DROP, HOTSPOT_CAN_DROP)
	Input.set_custom_mouse_cursor(CURSOR_FORBIDDEN_TEX, Input.CURSOR_FORBIDDEN, HOTSPOT_FORBIDDEN)
	Input.set_custom_mouse_cursor(CURSOR_HELP_TEX, Input.CURSOR_HELP, HOTSPOT_HELP)
	Input.set_custom_mouse_cursor(CURSOR_WAIT_TEX, Input.CURSOR_WAIT, HOTSPOT_WAIT)
	Input.set_custom_mouse_cursor(CURSOR_WAIT_TEX, Input.CURSOR_BUSY, HOTSPOT_WAIT)

func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		if node.mouse_default_cursor_shape == Control.CURSOR_ARROW:
			node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _apply_to_existing_nodes(node: Node) -> void:
	if node is BaseButton:
		if node.mouse_default_cursor_shape == Control.CURSOR_ARROW:
			node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for child in node.get_children():
		_apply_to_existing_nodes(child)

# Helper API for gameplay interactions
var current_cursor_shape: Input.CursorShape = Input.CURSOR_ARROW

func set_cursor(shape: Input.CursorShape) -> void:
	current_cursor_shape = shape
	Input.set_default_cursor_shape(shape)

func reset_cursor() -> void:
	set_cursor(Input.CURSOR_ARROW)

func set_drag_cursor() -> void:
	set_cursor(Input.CURSOR_DRAG)

func set_can_drop_cursor() -> void:
	set_cursor(Input.CURSOR_CAN_DROP)

func set_forbidden_cursor() -> void:
	set_cursor(Input.CURSOR_FORBIDDEN)
