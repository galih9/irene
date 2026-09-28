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

# Cubic Bezier control points for the pouring arc
var p0: Vector2 = Vector2.ZERO
var p1: Vector2 = Vector2.ZERO
var p2: Vector2 = Vector2.ZERO
var p3: Vector2 = Vector2.ZERO

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
	# accelerates under gravity and drops into the neck. This matches the reference image.
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.20))   # broad at the spout exit
	curve.add_point(Vector2(0.30, 1.00))  # slight widening at pour start
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

func _evaluate_bezier(t: float) -> Vector2:
	var u := 1.0 - t
	return u * u * u * p0 + 3.0 * u * u * t * p1 + 3.0 * u * t * t * p2 + t * t * t * p3

func _update_stream_geometry(t_start: float, t_end: float) -> void:
	if t_end <= t_start:
		line.clear_points()
		return
	var pts := PackedVector2Array()
	var steps := 32
	for i in range(steps + 1):
		var frac := float(i) / float(steps)
		var t := lerpf(t_start, t_end, frac)
		pts.append(_evaluate_bezier(t))
	line.points = pts

func set_flow_path(from_pt: Vector2, to_pt: Vector2, color_val: Color) -> void:
	if flow_tween:
		flow_tween.kill()

	var local_from := to_local(from_pt)
	var local_to := to_local(to_pt)
	stream_color = color_val

	# Cubic Bezier for inside-bottle pour:
	# - p0 = source lip (slightly to side above neck)
	# - p3 = liquid surface inside target bottle (below neck, inside body)
	# The stream curves quickly from the lip to align with the neck, then falls straight down.
	p0 = local_from
	p3 = local_to

	var dx := p3.x - p0.x
	var dy := p3.y - p0.y

	# ctrl1: exits lip tangentially, quickly sweeps toward the neck center x
	p1 = Vector2(p0.x + dx * 0.60, p0.y + dy * 0.15)

	# ctrl2: aligned with p3 x (neck/bottle center), just above the surface
	# This keeps the lower portion of the stream perfectly vertical inside the bottle
	p2 = Vector2(p3.x, p0.y + dy * 0.70)

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
