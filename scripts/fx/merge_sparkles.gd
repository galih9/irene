class_name MergeSparkles
extends Node2D

const STAR_TEX: Texture2D = preload("res://assets/vfx/star_02.png")
const SPARK_TEX: Texture2D = preload("res://assets/vfx/spark_02.png")

static func get_sparkle_texture() -> Texture2D:
	return STAR_TEX


@onready var particles: CPUParticles2D = $Particles

func _ready() -> void:
	z_index = 80
	if not particles:
		particles = CPUParticles2D.new()
		particles.name = "Particles"
		add_child(particles)

	_setup_particles()
	_spawn_gleams()

	var timer := get_tree().create_timer(1.0)
	if timer:
		timer.timeout.connect(queue_free)

func _setup_particles() -> void:
	var tex := get_sparkle_texture()
	particles.texture = tex
	particles.amount = 16
	particles.lifetime = 0.6
	particles.one_shot = true
	particles.explosiveness = 0.92
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 8.0
	particles.spread = 180.0
	particles.gravity = Vector2(0, 100.0)
	particles.initial_velocity_min = 70.0
	particles.initial_velocity_max = 180.0
	particles.damping_min = 40.0
	particles.damping_max = 70.0
	particles.angular_velocity_min = -180.0
	particles.angular_velocity_max = 180.0
	particles.scale_amount_min = 0.05
	particles.scale_amount_max = 0.12

	# Color ramp: white -> golden yellow -> transparent orange
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	grad.add_point(0.4, Color(1.0, 0.92, 0.4, 0.95))
	grad.add_point(0.8, Color(1.0, 0.75, 0.2, 0.7))
	grad.set_color(grad.get_point_count() - 1, Color(1.0, 0.5, 0.1, 0.0))
	particles.color_ramp = grad

	# Scale curve: pop up then shrink
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.4))
	curve.add_point(Vector2(0.2, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	particles.scale_amount_curve = curve

	particles.emitting = true

func _spawn_gleams() -> void:
	var gleam_offsets := [
		Vector2(-22, -18),
		Vector2(24, -14),
		Vector2(-16, 20),
		Vector2(18, 16)
	]
	var delays := [0.0, 0.06, 0.12, 0.18]

	for i in range(gleam_offsets.size()):
		var gleam := Sprite2D.new()
		gleam.texture = STAR_TEX if (i % 2 == 0) else SPARK_TEX
		gleam.position = gleam_offsets[i]
		gleam.scale = Vector2.ZERO
		gleam.modulate = Color(1.0, 0.95, 0.6, 0.0)
		add_child(gleam)

		var tw := create_tween()
		tw.tween_interval(delays[i])
		tw.parallel().tween_property(gleam, "scale", Vector2(0.12, 0.12), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(gleam, "modulate:a", 1.0, 0.14)
		tw.parallel().tween_property(gleam, "rotation", deg_to_rad(60.0), 0.35)
		tw.chain().tween_property(gleam, "scale", Vector2.ZERO, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(gleam, "modulate:a", 0.0, 0.16)
