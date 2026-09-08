class_name ItemView
extends Node2D

@export var data: ItemData:
	set(val):
		data = val
		if is_inside_tree():
			_update_visuals()

var grid_coord: Vector2i = Vector2i(-1, -1)
var is_in_inventory: bool = false
var inventory_slot_idx: int = -1

var is_dragging: bool = false
var target_slot_pos: Vector2 = Vector2.ZERO

@onready var visuals: Node2D = $Visuals
@onready var sprite: Sprite2D = $Visuals/Sprite
@onready var shadow: Sprite2D = $Shadow
@onready var glow: Sprite2D = $Visuals/Glow
@onready var tier_badge: PanelContainer = $Visuals/TierBadge
@onready var tier_label: Label = $Visuals/TierBadge/TierLabel
@onready var spawner_badge: PanelContainer = $Visuals/SpawnerBadge
@onready var touch_area: Control = $TouchArea

var _pulse_tween: Tween
var _scale_tween: Tween

func _ready() -> void:
	if data:
		_update_visuals()
	glow.visible = false

func setup(item_data: ItemData) -> void:
	data = item_data
	_update_visuals()

func _update_visuals() -> void:
	if not data:
		return

	# Color the icon
	sprite.modulate = data.color

	# Update tier badge
	if data.max_tier > 1:
		tier_badge.visible = true
		tier_label.text = "T%d" % data.tier
	else:
		tier_badge.visible = false

	# Spawner badge
	spawner_badge.visible = data.is_spawner

func animate_pickup() -> void:
	is_dragging = true
	z_index = 100
	if _scale_tween:
		_scale_tween.kill()
	_scale_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_scale_tween.tween_property(visuals, "scale", Vector2(1.2, 1.2), 0.15)
	_scale_tween.tween_property(shadow, "position", Vector2(0, 16), 0.15)
	_scale_tween.tween_property(shadow, "scale", Vector2(0.5, 0.5), 0.15)
	_scale_tween.tween_property(shadow, "modulate:a", 0.45, 0.15)
	SoundManager.play_pickup()

func animate_drop(on_complete: Callable = Callable()) -> void:
	is_dragging = false
	z_index = 10
	set_merge_highlight(false)
	if _scale_tween:
		_scale_tween.kill()
	_scale_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_scale_tween.tween_property(visuals, "scale", Vector2.ONE, 0.2)
	_scale_tween.tween_property(shadow, "position", Vector2(0, 6), 0.2)
	_scale_tween.tween_property(shadow, "scale", Vector2(0.42, 0.42), 0.2)
	_scale_tween.tween_property(shadow, "modulate:a", 0.25, 0.2)
	if on_complete.is_valid():
		_scale_tween.finished.connect(on_complete)
	SoundManager.play_drop()

func animate_snap_to(target_pos: Vector2, on_complete: Callable = Callable()) -> void:
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", target_pos, 0.12)
	if on_complete.is_valid():
		tween.finished.connect(on_complete)

func animate_bounce_back(origin_pos: Vector2) -> void:
	is_dragging = false
	z_index = 10
	set_merge_highlight(false)
	var tween := create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", origin_pos, 0.35)
	var sc_tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	sc_tween.tween_property(visuals, "scale", Vector2.ONE, 0.2)
	sc_tween.tween_property(shadow, "position", Vector2(0, 6), 0.2)
	sc_tween.tween_property(shadow, "scale", Vector2(0.42, 0.42), 0.2)
	sc_tween.tween_property(shadow, "modulate:a", 0.25, 0.2)

func animate_merge_pop() -> void:
	# Juicy squash and stretch
	visuals.scale = Vector2(1.4, 0.6)
	var tween := create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(visuals, "scale", Vector2.ONE, 0.4)

	# Flash effect
	var orig_color := sprite.modulate
	sprite.modulate = Color.WHITE * 1.8
	var flash_tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	flash_tween.tween_property(sprite, "modulate", orig_color, 0.25)
	SoundManager.play_merge()

func animate_spawner_tap() -> void:
	# Mechanical button press
	visuals.scale = Vector2(0.85, 0.85)
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(visuals, "scale", Vector2.ONE, 0.25)

func animate_wobble() -> void:
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(visuals, "rotation_degrees", 12.0, 0.05)
	tween.tween_property(visuals, "rotation_degrees", -12.0, 0.05)
	tween.tween_property(visuals, "rotation_degrees", 8.0, 0.05)
	tween.tween_property(visuals, "rotation_degrees", 0.0, 0.05)

func animate_spawn_flight(from_pos: Vector2, to_pos: Vector2, on_complete: Callable = Callable()) -> void:
	global_position = from_pos
	visuals.scale = Vector2(0.2, 0.2)
	z_index = 80

	var duration := 0.38
	var tween := create_tween().set_parallel(true)
	# Parabolic height arc
	var mid_y := minf(from_pos.y, to_pos.y) - 90.0

	var pos_tween := create_tween()
	pos_tween.tween_method(func(t: float):
		var p_start := from_pos
		var p_mid := Vector2(lerpf(from_pos.x, to_pos.x, 0.5), mid_y)
		var p_end := to_pos
		# Quadratic bezier
		var q0 := p_start.lerp(p_mid, t)
		var q1 := p_mid.lerp(p_end, t)
		global_position = q0.lerp(q1, t)
	, 0.0, 1.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tween.tween_property(visuals, "scale", Vector2(1.2, 1.2), duration * 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(visuals, "scale", Vector2.ONE, duration * 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	pos_tween.finished.connect(func():
		z_index = 10
		SoundManager.play_drop()
		if on_complete.is_valid():
			on_complete.call()
	)

func set_merge_highlight(active: bool) -> void:
	glow.visible = active
	if active:
		if _pulse_tween and _pulse_tween.is_valid():
			_pulse_tween.kill()
		_pulse_tween = create_tween().set_loops()
		_pulse_tween.tween_property(visuals, "scale", Vector2(1.12, 1.12), 0.25).set_trans(Tween.TRANS_SINE)
		_pulse_tween.tween_property(visuals, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_SINE)
	else:
		if _pulse_tween and _pulse_tween.is_valid():
			_pulse_tween.kill()
		if not is_dragging:
			visuals.scale = Vector2.ONE
