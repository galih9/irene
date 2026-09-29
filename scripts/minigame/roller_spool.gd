class_name RollerSpool
extends Control

## Represents a colored thread spool/roller with a specific capacity (default: 3 cells / 3 seconds).
## As cells of the same color are rolled, current_fill increases.
## Once full (current_fill >= capacity), it plays an arcing throwing-out ejection animation.

signal spool_clicked(spool: RollerSpool)
signal ejection_completed(spool: RollerSpool)

@export var color_id: String = "green":
	set(val):
		color_id = val
		queue_redraw()

@export var capacity: int = 3
var current_fill: int = 0

var is_spinning: bool = false
var spin_speed: float = 8.0 # rad/s

var _eject_tween: Tween = null
var _wobble_tween: Tween = null

func _ready() -> void:
	custom_minimum_size = Vector2(56, 56)
	size = custom_minimum_size
	pivot_offset = size * 0.5
	mouse_filter = MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		spool_clicked.emit(self)

func setup(p_color_id: String, p_size: Vector2 = Vector2(56, 56), p_cap: int = 3) -> void:
	color_id = p_color_id
	capacity = maxi(1, p_cap)
	current_fill = 0
	custom_minimum_size = p_size
	size = p_size
	pivot_offset = p_size * 0.5
	queue_redraw()

func _process(delta: float) -> void:
	if is_spinning:
		rotation += spin_speed * delta

func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.48

	var c_data := ThreadColorPalette.get_color_data(color_id)
	var thread_c: Color = c_data.get("thread", Color.WHITE)
	var main_c: Color = c_data.get("main", Color.WHITE)
	var dark_c: Color = c_data.get("dark", Color.BLACK)
	var light_c: Color = c_data.get("light", Color.WHITE)

	# 1. Outer rim / spool flange (Wood / brass tone)
	var wood_base := Color(0.82, 0.68, 0.50, 1.0)
	var wood_dark := Color(0.55, 0.40, 0.28, 1.0)
	draw_circle(center + Vector2(0, 3), radius, Color(0, 0, 0, 0.25)) # Shadow
	draw_circle(center, radius, wood_base)
	draw_arc(center, radius, 0, TAU, 32, wood_dark, 2.5, true)

	# 2. Wound Thread Layer - radius scales with fill percentage
	var fill_ratio := clampf(float(current_fill) / float(maxi(1, capacity)), 0.15, 1.0)
	var max_thread_radius := radius * 0.82
	var min_thread_radius := radius * 0.40
	var thread_radius := lerpf(min_thread_radius, max_thread_radius, fill_ratio)

	draw_circle(center, thread_radius, main_c)

	# Thread windings / concentric texture rings
	var ring_count := maxi(1, int(fill_ratio * 4.0))
	for i in range(1, ring_count + 1):
		var r_ring := thread_radius * (float(i) / float(ring_count + 1))
		var ring_col := dark_c
		ring_col.a = 0.5
		draw_arc(center, r_ring, 0, TAU, 24, ring_col, 1.5, true)

	# Radial thread notches (shows rotation clearly during rolling)
	var notch_count := 4
	for i in range(notch_count):
		var angle := float(i) * (TAU / float(notch_count))
		var n_dir := Vector2(cos(angle), sin(angle))
		draw_line(center + n_dir * (thread_radius * 0.35), center + n_dir * (thread_radius * 0.95), light_c, 2.0)

	# 3. Center metallic spindle pin
	var pin_radius := radius * 0.28
	draw_circle(center, pin_radius, Color(0.25, 0.22, 0.20, 1.0))
	draw_circle(center, pin_radius * 0.7, Color(0.12, 0.10, 0.10, 1.0))
	# Highlight shine on pin
	draw_circle(center + Vector2(-1, -1), pin_radius * 0.3, Color(0.8, 0.8, 0.8, 0.6))

func start_spinning() -> void:
	is_spinning = true

func stop_spinning() -> void:
	is_spinning = false

func is_full() -> bool:
	return current_fill >= capacity

func get_available_capacity() -> int:
	return maxi(0, capacity - current_fill)

func add_fill(amount: int = 1) -> void:
	current_fill = mini(current_fill + amount, capacity)
	# Quick bounce feedback
	pivot_offset = size * 0.5
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.08)
	tween.tween_property(self, "scale", Vector2.ONE, 0.12)
	queue_redraw()

## Plays a satisfying arcing throw-out ejection animation when the spool is full.
func animate_eject(target_dir: Vector2 = Vector2(1.0, -0.6), on_complete: Callable = Callable()) -> void:
	stop_spinning()
	pivot_offset = size * 0.5

	if _eject_tween and _eject_tween.is_valid():
		_eject_tween.kill()

	var start_pos := position
	var x_distance := signf(target_dir.x) * 450.0
	if absf(x_distance) < 200.0:
		x_distance = 450.0

	var apex_y := -160.0 # Upward arc apex relative to start
	var final_y := 600.0  # Off-screen drop relative to start

	var duration := 0.6

	_eject_tween = create_tween().set_parallel(true)

	# Horizontal throw across screen
	_eject_tween.tween_property(self, "position:x", start_pos.x + x_distance, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Vertical parabolic arc: Upward burst (0.24s) then downward drop (0.36s)
	var v_tween := create_tween()
	v_tween.tween_property(self, "position:y", start_pos.y + apex_y, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	v_tween.tween_property(self, "position:y", start_pos.y + final_y, 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Rapid spinning while in flight
	var spin_rot := TAU * 3.0 * (1.0 if x_distance >= 0.0 else -1.0)
	_eject_tween.tween_property(self, "rotation", rotation + spin_rot, duration)

	# Dynamic scale pop at apex then shrink
	var s_tween := create_tween()
	s_tween.tween_property(self, "scale", Vector2(1.25, 1.25), 0.2)
	s_tween.tween_property(self, "scale", Vector2(0.5, 0.5), 0.4)

	# Fade out during descent
	var a_tween := create_tween()
	a_tween.tween_interval(0.35)
	a_tween.tween_property(self, "modulate:a", 0.0, 0.25)

	_eject_tween.chain().tween_callback(func():
		ejection_completed.emit(self)
		if on_complete.is_valid():
			on_complete.call()
		queue_free()
	)
