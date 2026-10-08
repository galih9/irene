class_name ForcedTutorialOverlay
extends Control

const HAND_POINT_TEX: Texture2D = preload("res://assets/cursor/hd_hand_point.png")
const HAND_TAP_TEX: Texture2D = preload("res://assets/cursor/hd_hand_tap.png")

@onready var backdrop: ColorRect = $Backdrop
@onready var hand: Sprite2D = $Hand

var board_ref: Board = null
var source_coord: Vector2i = Vector2i(-1, -1)
var target_coord: Vector2i = Vector2i(-1, -1)

var _source_screen_pos: Vector2 = Vector2.ZERO
var _target_screen_pos: Vector2 = Vector2.ZERO
var _source_rect: Rect2 = Rect2()
var _target_rect: Rect2 = Rect2()

var _hand_tween: Tween = null
var _base_hand_scale: Vector2 = Vector2(0.42, 0.42)
# Fingertip is at (-65.5, -91) relative to center of 193x188 sprite
var _hand_offset_to_center: Vector2 = Vector2(27.5, 38.2)

var is_dragging: bool = false
var is_active: bool = false

func _ready() -> void:
	z_index = 45
	anchors_preset = Control.PRESET_FULL_RECT
	mouse_filter = Control.MOUSE_FILTER_STOP

	if backdrop and not backdrop.material:
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://shaders/tutorial_cutout.gdshader")
		backdrop.material = mat

	get_viewport().size_changed.connect(_update_geometry)
	var om = get_node_or_null("/root/OrientationManager")
	if is_instance_valid(om) and om.has_signal("orientation_changed"):
		om.orientation_changed.connect(func(_is_land): _update_geometry())

	GameEvents.item_drag_started.connect(_on_item_drag_started)
	GameEvents.item_drag_ended.connect(_on_item_drag_ended)

func setup(board: Board, src_coord: Vector2i, tgt_coord: Vector2i) -> void:
	board_ref = board
	source_coord = src_coord
	target_coord = tgt_coord
	is_active = true
	visible = true
	modulate.a = 0.0

	_update_geometry()

	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.25)
	tw.finished.connect(_start_hand_loop)

func _update_geometry() -> void:
	if not is_instance_valid(board_ref):
		return

	var vp_size := get_viewport_rect().size

	_source_screen_pos = board_ref.to_global(board_ref.get_cell_center(source_coord.x, source_coord.y))
	_target_screen_pos = board_ref.to_global(board_ref.get_cell_center(target_coord.x, target_coord.y))

	var cell_size: float = board_ref.cell_size
	var half_size: float = cell_size * 0.55

	_source_rect = Rect2(_source_screen_pos - Vector2(half_size, half_size), Vector2(half_size * 2.0, half_size * 2.0))
	_target_rect = Rect2(_target_screen_pos - Vector2(half_size, half_size), Vector2(half_size * 2.0, half_size * 2.0))

	if backdrop and backdrop.material is ShaderMaterial:
		var sm := backdrop.material as ShaderMaterial
		sm.set_shader_parameter("screen_size", vp_size)
		sm.set_shader_parameter("cutout_a_center", _source_screen_pos)
		sm.set_shader_parameter("cutout_a_size", Vector2(cell_size + 6.0, cell_size + 6.0))
		sm.set_shader_parameter("cutout_b_center", _target_screen_pos)
		sm.set_shader_parameter("cutout_b_size", Vector2(cell_size + 6.0, cell_size + 6.0))
		sm.set_shader_parameter("corner_radius", 14.0)

func _has_point(point: Vector2) -> bool:
	if not visible or not is_active:
		return false

	# When dragging, pass events through freely
	if is_dragging:
		return false

	# Allow direct touch on source cell
	if _source_rect.has_point(point):
		return false

	# Block all other points on screen
	return true

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_pulse_hand_reminder()

func _pulse_hand_reminder() -> void:
	if hand and hand.visible and not is_dragging:
		var tw := create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(hand, "scale", _base_hand_scale * 1.25, 0.1)
		tw.tween_property(hand, "scale", _base_hand_scale, 0.2)

func _start_hand_loop() -> void:
	if _hand_tween and _hand_tween.is_valid():
		_hand_tween.kill()

	if not is_instance_valid(hand):
		return

	hand.visible = true
	hand.modulate.a = 0.0
	hand.texture = HAND_POINT_TEX
	hand.scale = _base_hand_scale

	_hand_tween = create_tween().set_loops()

	# 1. Reset to source position and fade in
	_hand_tween.tween_callback(func():
		hand.position = _source_screen_pos + _hand_offset_to_center
		hand.texture = HAND_POINT_TEX
		hand.scale = _base_hand_scale
	)
	_hand_tween.tween_property(hand, "modulate:a", 1.0, 0.2)

	# 2. Tap down
	_hand_tween.tween_callback(func():
		hand.texture = HAND_TAP_TEX
	)
	_hand_tween.tween_property(hand, "scale", _base_hand_scale * 0.9, 0.12)

	# 3. Tween smoothly from source to target
	_hand_tween.tween_property(hand, "position", _target_screen_pos + _hand_offset_to_center, 0.95).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

	# 4. Release at target
	_hand_tween.tween_callback(func():
		hand.texture = HAND_POINT_TEX
	)
	_hand_tween.tween_property(hand, "scale", _base_hand_scale, 0.12)

	# 5. Fade out and pause briefly
	_hand_tween.tween_property(hand, "modulate:a", 0.0, 0.22)
	_hand_tween.tween_interval(0.25)

func _on_item_drag_started(item_view: Node) -> void:
	var it := item_view as ItemView
	if it and it.grid_coord == source_coord:
		is_dragging = true
		if _hand_tween and _hand_tween.is_valid():
			_hand_tween.kill()
		if hand:
			create_tween().tween_property(hand, "modulate:a", 0.0, 0.12)

func _on_item_drag_ended(_item_view: Node) -> void:
	if not is_active:
		return
	is_dragging = false
	get_tree().create_timer(0.2).timeout.connect(func():
		if is_active and not is_dragging:
			_start_hand_loop()
	)

func dismiss() -> void:
	if not is_active:
		return
	is_active = false
	if _hand_tween and _hand_tween.is_valid():
		_hand_tween.kill()

	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.finished.connect(queue_free)
