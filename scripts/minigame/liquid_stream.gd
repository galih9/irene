class_name LiquidStream
extends Node2D

@export var stream_color: Color = Color(0.28, 0.62, 0.98, 1.0):
	set(val):
		stream_color = val
		_update_material_color()

var line: Line2D
var shader_material: ShaderMaterial
var is_active: bool = false
var flow_tween: Tween = null

var flow_start: Vector2 = Vector2.ZERO
var flow_end: Vector2 = Vector2.ZERO
var receiving_bottle: LiquidBottle = null
var visible_start: float = 0.0
var visible_end: float = 0.0

const STREAM_SHADER: Shader = preload("res://shaders/fluid_stream.gdshader")

func _init() -> void:
	line = Line2D.new()
	line.name = "StreamLine"
	line.width = 14.0
	line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
	line.round_precision = 16
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.joint_mode = Line2D.LINE_JOINT_ROUND

	# Dummy 4x4 white image texture to guarantee UV mapping in Line2D
	var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	line.texture = ImageTexture.create_from_image(img)

	# Liquid stream taper: wider at the bottle lip where it flows out, narrowing as it
	# accelerates under gravity and drops into the neck.
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.20))   # broad at the spout exit
	curve.add_point(Vector2(0.30, 1.00))  # steady flow below the lip
	curve.add_point(Vector2(0.65, 0.70))  # narrows as it accelerates downward
	curve.add_point(Vector2(1.0, 0.55))   # thin at entry into bottle neck
	line.width_curve = curve

	shader_material = ShaderMaterial.new()
	shader_material.shader = STREAM_SHADER
	line.material = shader_material
	add_child(line)

	visible = false

func _ready() -> void:
	_update_material_color()

func _update_material_color() -> void:
	if shader_material:
		shader_material.set_shader_parameter("stream_color", stream_color)
	if line:
		line.default_color = stream_color

func _process(_delta: float) -> void:
	if is_active and is_instance_valid(receiving_bottle):
		flow_end = to_local(receiving_bottle.get_liquid_surface_global())
		_update_stream_geometry(visible_start, visible_end)

func _update_stream_geometry(t_start: float, t_end: float) -> void:
	visible_start = t_start
	visible_end = t_end
	if t_end <= t_start:
		line.clear_points()
		return
	# Source positioning aligns the lip with the receiving mouth. Keep every
	# point on that vertical axis, including emergence and the draining tail.
	var start := Vector2(flow_end.x, flow_start.y)
	line.points = PackedVector2Array([
		start.lerp(flow_end, t_start),
		start.lerp(flow_end, t_end)
	])

func set_flow_path(from_pt: Vector2, to_pt: Vector2, color_val: Color, target: LiquidBottle = null) -> void:
	if flow_tween:
		flow_tween.kill()

	flow_start = to_local(from_pt)
	flow_end = to_local(to_pt)
	receiving_bottle = target
	stream_color = color_val
	# Keep the widest part narrower than the opening on small layouts too.
	line.width = target.size.x * 0.10 if is_instance_valid(target) else 14.0

	visible = true
	is_active = true
	line.modulate.a = 1.0

	# Fast, seamless emergence: the continuous stream flows cleanly from spout into the neck
	_update_stream_geometry(0.0, 0.05)
	flow_tween = create_tween()
	flow_tween.tween_method(func(val: float):
		_update_stream_geometry(0.0, val)
	, 0.05, 1.0, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func stop() -> void:
	is_active = false
	receiving_bottle = null
	if flow_tween:
		flow_tween.kill()

	# Cleanly drain stream tail down into destination bottle and fade
	flow_tween = create_tween()
	flow_tween.set_parallel(true)
	flow_tween.tween_method(func(val: float):
		_update_stream_geometry(val, 1.0)
	, 0.0, 1.0, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	flow_tween.tween_property(line, "modulate:a", 0.0, 0.09)

	flow_tween.chain().tween_callback(func():
		visible = false
		line.clear_points()
		line.modulate.a = 1.0
	)
