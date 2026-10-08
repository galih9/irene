class_name OverworldBuilding
extends Node2D

## Represents a mergeable building on the isometric overworld board.
## Supports arbitrary multi-tile footprints (1x1, 1x2, 2x2, etc.) with
## exact ground footprint alignment, dynamic shadow generation, and juice animations.

const OverworldGeometryClass = preload("res://scripts/experimental/overworld_geometry.gd")
const OverworldBuildingDataClass = preload("res://scripts/experimental/overworld_building_data.gd")

## Backward compatibility dictionary for legacy references
const TIER_CONFIGS: Dictionary = {
	1: {
		"name": "Bakery Foundation",
		"tier": 1,
		"footprint": [Vector2i(0, 0)],
		"footprint_desc": "1x1",
		"texture_path": "res://assets/world/1x1.png",
		"scale": 0.185,
		"sprite_pos": Vector2(13.7, -46.0),
		"badge_text": "T1 (1x1)",
		"badge_color": Color(0.92, 0.78, 0.42),
		"next_tier": 2
	},
	2: {
		"name": "Bakery Framework",
		"tier": 2,
		"footprint": [Vector2i(0, 0), Vector2i(1, 0)],
		"footprint_desc": "1x2",
		"texture_path": "res://assets/world/1x2.png",
		"scale": 0.26,
		"sprite_pos": Vector2(-12.0, -38.0),
		"badge_text": "T2 (1x2)",
		"badge_color": Color(0.45, 0.85, 0.95),
		"next_tier": 3
	},
	3: {
		"name": "Grand Bakery",
		"tier": 3,
		"footprint": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
		"footprint_desc": "2x2",
		"texture_path": "res://assets/world/2x2.png",
		"scale": 0.36,
		"sprite_pos": Vector2(-47.0, -98.0),
		"badge_text": "T3 (2x2) MAX",
		"badge_color": Color(1.0, 0.82, 0.25),
		"next_tier": 0
	}
}

signal construction_finished(building: OverworldBuilding)

const SMOKE_TEXTURES: Array[Texture2D] = [
	preload("res://assets/vfx/smoke_01.png"),
	preload("res://assets/vfx/smoke_02.png"),
	preload("res://assets/vfx/smoke_03.png"),
	preload("res://assets/vfx/smoke_04.png"),
	preload("res://assets/vfx/smoke_05.png"),
	preload("res://assets/vfx/smoke_06.png"),
	preload("res://assets/vfx/smoke_07.png"),
	preload("res://assets/vfx/smoke_08.png"),
	preload("res://assets/vfx/smoke_09.png"),
	preload("res://assets/vfx/smoke_10.png")
]

# State
var tier: int = 1
var chain_id: String = "bakery"
var root_coord: Vector2i = Vector2i.ZERO
var is_dragging: bool = false
var is_merge_highlighted: bool = false
var building_data: Resource = null

# Construction State
var is_under_construction: bool = false
var construction_timer: float = 0.0
var construction_duration: float = 10.0
var construction_audio: AudioStreamPlayer = null
var smoke_container: Node2D = null
var construction_timer_panel: PanelContainer = null
var construction_timer_label: Label = null
var _smoke_spawn_timer: float = 0.0

var _board_ref: Node = null
var _glow_tween: Tween = null
var _anim_tween: Tween = null

# Child nodes
var ground_shadow: Polygon2D
var visuals: Node2D
var sprite: Sprite2D
var glow_sprite: Sprite2D
var badge_label: Label
var badge_panel: PanelContainer

func _ready() -> void:
	z_as_relative = false
	_build_nodes_if_needed()
	_build_construction_nodes()
	_update_visuals()

func setup(p_tier: int, p_root: Vector2i, p_board: Node, p_chain: String = "bakery") -> void:
	tier = clampi(p_tier, 1, 3)
	root_coord = p_root
	_board_ref = p_board
	chain_id = p_chain
	building_data = OverworldBuildingDataClass.get_data(tier, chain_id)
	_build_nodes_if_needed()
	_update_visuals()

func get_building_name() -> String:
	if building_data:
		return building_data.name
	return TIER_CONFIGS.get(tier, {}).get("name", "Bakery")

func get_footprint_desc() -> String:
	if building_data:
		return building_data.footprint_desc
	return TIER_CONFIGS.get(tier, {}).get("footprint_desc", "1x1")

func get_footprint_offsets() -> Array[Vector2i]:
	if building_data:
		return building_data.footprint.duplicate()
	var cfg: Dictionary = TIER_CONFIGS.get(tier, {})
	var arr: Array[Vector2i] = []
	for v in cfg.get("footprint", [Vector2i(0, 0)]):
		arr.append(v)
	return arr

func get_occupied_cells() -> Array[Vector2i]:
	var offsets := get_footprint_offsets()
	var cells: Array[Vector2i] = []
	for off in offsets:
		cells.append(root_coord + off)
	return cells

func _build_nodes_if_needed() -> void:
	if not ground_shadow:
		ground_shadow = Polygon2D.new()
		ground_shadow.name = "GroundShadow"
		ground_shadow.color = Color(0.04, 0.14, 0.06, 0.35)
		add_child(ground_shadow)

	if not visuals:
		visuals = Node2D.new()
		visuals.name = "Visuals"
		add_child(visuals)

	if not sprite:
		sprite = Sprite2D.new()
		sprite.name = "Sprite"
		sprite.centered = true
		visuals.add_child(sprite)

	if not glow_sprite:
		glow_sprite = Sprite2D.new()
		glow_sprite.name = "GlowSprite"
		glow_sprite.centered = true
		glow_sprite.modulate = Color(1.0, 0.9, 0.3, 0.0)
		visuals.add_child(glow_sprite)

	if not badge_panel:
		badge_panel = PanelContainer.new()
		badge_panel.name = "Badge"
		badge_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.12, 0.18, 0.14, 0.88)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.85, 0.75, 0.45, 0.8)
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_right = 8
		style.corner_radius_bottom_left = 8
		style.content_margin_left = 6
		style.content_margin_right = 6
		style.content_margin_top = 2
		style.content_margin_bottom = 2
		badge_panel.add_theme_stylebox_override("panel", style)

		badge_label = Label.new()
		badge_label.name = "Label"
		badge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge_label.add_theme_font_size_override("font_size", 12)
		badge_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.85))
		badge_panel.add_child(badge_label)

		visuals.add_child(badge_panel)

func _update_visuals() -> void:
	if not building_data:
		building_data = OverworldBuildingDataClass.get_data(tier, chain_id)
	
	var tex_path: String = building_data.texture_path
	var tex: Texture2D = load(tex_path)
	if tex:
		sprite.texture = tex
		glow_sprite.texture = tex
	
	var sc: float = building_data.scale
	sprite.scale = Vector2(sc, sc)
	glow_sprite.scale = Vector2(sc, sc)

	# Exactly aligned ground offset
	var s_pos: Vector2 = building_data.sprite_offset
	sprite.position = s_pos
	glow_sprite.position = s_pos

	# Badge update and positioning
	if badge_label:
		badge_label.text = building_data.badge_text
		badge_label.add_theme_color_override("font_color", building_data.badge_color)
	if badge_panel and tex:
		# Place badge slightly above the building roof
		var badge_y: float = s_pos.y - (tex.get_height() * sc * 0.5) - 10.0
		badge_panel.position = Vector2(-badge_panel.size.x * 0.5, badge_y)

	_update_shadow_polygon()

func _update_shadow_polygon() -> void:
	if not ground_shadow:
		return
	# Dynamically calculate the exact merged footprint boundary for this building's multi-tile footprint
	var offsets := get_footprint_offsets()
	var poly := OverworldGeometryClass.get_footprint_polygon(offsets, OverworldGeometryClass.DEFAULT_TILE_SIZE, 3.0)
	ground_shadow.polygon = poly

func is_point_inside(world_pos: Vector2) -> bool:
	# 1. Check sprite bounding box
	if sprite and sprite.texture:
		var local_p := sprite.to_local(world_pos)
		var sz := sprite.texture.get_size()
		var rect := Rect2(-sz * 0.5, sz)
		if rect.has_point(local_p):
			return true
	# 2. Check ground shadow footprint
	if ground_shadow and ground_shadow.polygon.size() >= 3:
		var local_p := ground_shadow.to_local(world_pos)
		if Geometry2D.is_point_in_polygon(local_p, ground_shadow.polygon):
			return true
	return false

# =========================================================================
# JUICE & ANIMATION METHODS
# =========================================================================

func animate_pickup() -> void:
	is_dragging = true
	z_index = 120 # Elevate above other isometric tiles & buildings while dragging
	if _anim_tween and _anim_tween.is_valid():
		_anim_tween.kill()
	_anim_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_anim_tween.tween_property(visuals, "position:y", -32.0, 0.16)
	_anim_tween.tween_property(visuals, "scale", Vector2(1.08, 1.08), 0.16)
	_anim_tween.tween_property(ground_shadow, "scale", Vector2(0.85, 0.85), 0.16)
	_anim_tween.tween_property(ground_shadow, "modulate:a", 0.25, 0.16)

func animate_drop() -> void:
	is_dragging = false
	z_index = 0
	if _anim_tween and _anim_tween.is_valid():
		_anim_tween.kill()
	_anim_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_anim_tween.tween_property(visuals, "position:y", 0.0, 0.18)
	_anim_tween.tween_property(visuals, "scale", Vector2.ONE, 0.18)
	_anim_tween.tween_property(ground_shadow, "scale", Vector2.ONE, 0.18)
	_anim_tween.tween_property(ground_shadow, "modulate:a", 1.0, 0.18)

func animate_snap_to(target_pos: Vector2) -> void:
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "global_position", target_pos, 0.18)

func animate_merge_pop() -> void:
	visuals.scale = Vector2(1.35, 1.35)
	var tw := create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(visuals, "scale", Vector2.ONE, 0.45)
	
	if glow_sprite:
		glow_sprite.modulate = Color(1.0, 1.0, 0.5, 0.9)
		var flash_tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		flash_tw.tween_property(glow_sprite, "modulate:a", 0.0, 0.4)

func animate_tap() -> void:
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(visuals, "scale", Vector2(1.15, 0.88), 0.08)
	tw.tween_property(visuals, "scale", Vector2(0.92, 1.08), 0.1)
	tw.tween_property(visuals, "scale", Vector2.ONE, 0.12)

func animate_wobble() -> void:
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(visuals, "rotation_degrees", -6.0, 0.05)
	tw.tween_property(visuals, "rotation_degrees", 6.0, 0.08)
	tw.tween_property(visuals, "rotation_degrees", -4.0, 0.06)
	tw.tween_property(visuals, "rotation_degrees", 0.0, 0.05)

func set_merge_highlight(enabled: bool) -> void:
	if is_merge_highlighted == enabled:
		return
	is_merge_highlighted = enabled
	if _glow_tween and _glow_tween.is_valid():
		_glow_tween.kill()
	
	if enabled:
		_glow_tween = create_tween().set_loops()
		_glow_tween.tween_property(glow_sprite, "modulate:a", 0.85, 0.35).set_trans(Tween.TRANS_SINE)
		_glow_tween.tween_property(glow_sprite, "modulate:a", 0.25, 0.35).set_trans(Tween.TRANS_SINE)
		
		var pop := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pop.tween_property(visuals, "scale", Vector2(1.1, 1.1), 0.12)
	else:
		if glow_sprite:
			var off_tw := create_tween()
			off_tw.tween_property(glow_sprite, "modulate:a", 0.0, 0.15)
		var reset_tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		reset_tw.tween_property(visuals, "scale", Vector2.ONE, 0.12)

# =========================================================================
# CONSTRUCTION SYSTEM (SFX Loop with Camera Attenuation + Multi-Smoke VFX + Timer)
# =========================================================================

func _exit_tree() -> void:
	if construction_audio and construction_audio.playing:
		construction_audio.stop()

func _process(delta: float) -> void:
	if not is_under_construction:
		return

	construction_timer = maxf(0.0, construction_timer - delta)
	_update_construction_timer_display()
	_update_audio_volume()

	_smoke_spawn_timer += delta
	if _smoke_spawn_timer >= 0.22:
		_smoke_spawn_timer = 0.0
		_spawn_smoke_puff()

	if construction_timer <= 0.0:
		finish_construction()

func _build_construction_nodes() -> void:
	if not smoke_container and visuals:
		smoke_container = Node2D.new()
		smoke_container.name = "SmokeContainer"
		smoke_container.z_index = 25
		visuals.add_child(smoke_container)

	if not construction_audio:
		construction_audio = AudioStreamPlayer.new()
		construction_audio.name = "ConstructionAudio"
		construction_audio.stream = preload("res://assets/sfx/construction.mp3")
		construction_audio.volume_db = -80.0
		construction_audio.finished.connect(func():
			if is_under_construction and is_instance_valid(construction_audio):
				construction_audio.play()
		)
		add_child(construction_audio)

	if not construction_timer_panel and visuals:
		construction_timer_panel = PanelContainer.new()
		construction_timer_panel.name = "ConstructionTimerPanel"
		construction_timer_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.18, 0.13, 0.08, 0.95)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(1.0, 0.78, 0.22, 0.95)
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_right = 8
		style.corner_radius_bottom_left = 8
		style.content_margin_left = 8
		style.content_margin_right = 8
		style.content_margin_top = 3
		style.content_margin_bottom = 3
		construction_timer_panel.add_theme_stylebox_override("panel", style)

		construction_timer_label = Label.new()
		construction_timer_label.name = "ConstructionTimerLabel"
		construction_timer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		construction_timer_label.add_theme_font_size_override("font_size", 13)
		construction_timer_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.35))
		construction_timer_label.text = "🔨 10s"
		construction_timer_panel.add_child(construction_timer_label)
		construction_timer_panel.visible = false
		visuals.add_child(construction_timer_panel)

func start_construction(duration: float = 10.0) -> void:
	_build_construction_nodes()
	is_under_construction = true
	construction_duration = duration
	construction_timer = duration

	if badge_panel:
		badge_panel.visible = false
	if construction_timer_panel:
		construction_timer_panel.visible = true
	_update_construction_timer_display()

	if construction_audio:
		construction_audio.play()
		_update_audio_volume()

	# Initial multiple smoke construction burst
	_smoke_spawn_timer = 0.0
	for i in range(4):
		_spawn_smoke_puff()

	# Animated subtle construction wobble / pulsing
	if _anim_tween and _anim_tween.is_valid():
		_anim_tween.kill()
	_anim_tween = create_tween().set_loops()
	_anim_tween.tween_property(visuals, "scale", Vector2(1.03, 0.97), 0.35).set_trans(Tween.TRANS_SINE)
	_anim_tween.tween_property(visuals, "scale", Vector2(0.97, 1.03), 0.35).set_trans(Tween.TRANS_SINE)

func finish_construction() -> void:
	is_under_construction = false
	construction_timer = 0.0

	if construction_audio and construction_audio.playing:
		construction_audio.stop()

	if _anim_tween and _anim_tween.is_valid():
		_anim_tween.kill()
		_anim_tween = null
	visuals.scale = Vector2.ONE
	visuals.position = Vector2.ZERO

	if construction_timer_panel:
		construction_timer_panel.visible = false
	if badge_panel:
		badge_panel.visible = true

	animate_merge_pop()

	if _board_ref:
		if _board_ref.has_method("spawn_sparkles"):
			_board_ref.spawn_sparkles(global_position)
		if _board_ref.has_method("show_floating_text"):
			_board_ref.show_floating_text("Built %s!" % get_building_name(), global_position + Vector2(0, -70), Color(0.4, 1.0, 0.5))

	construction_finished.emit(self)

func skip_construction() -> void:
	if is_under_construction:
		finish_construction()

func _update_construction_timer_display() -> void:
	if not construction_timer_panel or not construction_timer_label:
		return
	construction_timer_label.text = "🔨 %ds" % int(ceilf(construction_timer))
	if building_data and sprite and sprite.texture:
		var s_pos: Vector2 = building_data.sprite_offset
		var tex := sprite.texture
		var sc: float = building_data.scale
		var badge_y: float = s_pos.y - (tex.get_height() * sc * 0.5) - 34.0
		construction_timer_panel.position = Vector2(-construction_timer_panel.size.x * 0.5, badge_y)

func _get_camera() -> Camera2D:
	if _board_ref and "camera" in _board_ref and is_instance_valid(_board_ref.camera):
		return _board_ref.camera
	if get_viewport() and get_viewport().get_camera_2d():
		return get_viewport().get_camera_2d()
	return null

func _update_audio_volume() -> void:
	if not is_instance_valid(construction_audio) or not is_inside_tree():
		return
	var sm = get_tree().root.get_node_or_null("SoundManager") if get_tree() and get_tree().root else null
	if sm and not sm.sfx_enabled:
		construction_audio.volume_db = -80.0
		return

	var cam := _get_camera()
	if not cam:
		construction_audio.volume_db = -6.0
		return

	# Attenuate volume based on camera distance: closer = louder, farther = lower
	var cam_pos: Vector2 = cam.global_position
	var dist: float = global_position.distance_to(cam_pos)
	# Within 180px: max volume (-2.0 dB); at 1600px+: low volume (-38.0 dB)
	var t: float = clampf((dist - 180.0) / 1420.0, 0.0, 1.0)
	var vol: float = lerpf(-2.0, -38.0, t)

	# Camera zoom: zooming in brings the view closer -> louder
	var zoom_scale: float = clampf(cam.zoom.x, 0.45, 1.8)
	vol += (zoom_scale - 1.0) * 4.0

	construction_audio.volume_db = clampf(vol, -45.0, 2.0)

func _spawn_smoke_puff() -> void:
	if not smoke_container or SMOKE_TEXTURES.is_empty():
		return
	var puff := Sprite2D.new()
	var tex_idx := randi() % SMOKE_TEXTURES.size()
	puff.texture = SMOKE_TEXTURES[tex_idx]
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
	puff.material = mat

	# Multi-point smoke position around the building footprint
	var spread_x := float(tier) * 36.0
	var spread_y := float(tier) * 18.0
	var s_pos: Vector2 = building_data.sprite_offset if building_data else Vector2.ZERO
	var spawn_pos := Vector2(
		randf_range(-spread_x, spread_x),
		s_pos.y + randf_range(10.0 - spread_y, spread_y + 15.0)
	)
	puff.position = spawn_pos
	puff.scale = Vector2(0.06, 0.06)
	puff.modulate = Color(0.94, 0.92, 0.86, 0.82)
	smoke_container.add_child(puff)

	var target_scale := randf_range(0.24, 0.35)
	var rise_height := randf_range(45.0, 75.0)
	var target_y := spawn_pos.y - rise_height
	var duration := randf_range(0.65, 0.85)
	var rot_target := randf_range(-PI * 0.45, PI * 0.45)

	var tw := create_tween().set_parallel(true)
	tw.tween_property(puff, "position:y", target_y, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(puff, "position:x", spawn_pos.x + randf_range(-15.0, 15.0), duration)
	tw.tween_property(puff, "scale", Vector2(target_scale, target_scale), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(puff, "rotation", rot_target, duration)
	tw.tween_property(puff, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.finished.connect(func():
		if is_instance_valid(puff):
			puff.queue_free()
	)

