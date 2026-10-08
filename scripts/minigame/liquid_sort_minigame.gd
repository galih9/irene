class_name LiquidSortMinigame
extends Control

const LiquidBottle = preload("res://scripts/minigame/liquid_bottle.gd")
const LiquidColorPalette = preload("res://scripts/minigame/liquid_color_palette.gd")
const LiquidSortLevelGenerator = preload("res://scripts/minigame/liquid_sort_level_generator.gd")
const LiquidStream = preload("res://scripts/minigame/liquid_stream.gd")

signal exit_requested()

@export var current_level: int = 1

var bottles: Array[LiquidBottle] = []
var selected_bottle: LiquidBottle = null
var is_pouring: bool = false
var undo_stack: Array[Dictionary] = []
var extra_bottles_added: int = 0

# UI References
var top_bar: Control
var level_label: Label
var back_btn: Button
var undo_btn: Button
var restart_btn: Button
var add_bottle_btn: Button

# Containers
var bottles_container: Control
var stream_renderer: LiquidStream
var win_modal: PanelContainer
var win_title: Label
var win_next_btn: Button
var confetti_particles: CPUParticles2D
var loading_overlay: Control       # shown while BFS level generation runs on a thread
var loading_dots_label: Label      # animated "..." dots so the user knows it's working

var generation_thread: Thread = null   # background thread for level generation
var _pending_config = null             # result passed back from the thread

var is_landscape_mode: bool = false

func _init() -> void:
	name = "LiquidSortMinigame"
	set_anchors_preset(PRESET_FULL_RECT)

func _ready() -> void:
	_build_ui()
	start_level(current_level)

func _build_ui() -> void:
	# 1. Dark Atmospheric Background
	var bg_rect := ColorRect.new()
	bg_rect.name = "Background"
	bg_rect.set_anchors_preset(PRESET_FULL_RECT)
	bg_rect.color = Color(0.08, 0.08, 0.11, 1.0)
	add_child(bg_rect)

	# Subtle ambient stars / floating bubbles in background
	var bg_bubbles := CPUParticles2D.new()
	bg_bubbles.name = "BGBubbles"
	bg_bubbles.position = Vector2(360, 800)
	bg_bubbles.amount = 24
	bg_bubbles.lifetime = 6.0
	bg_bubbles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	bg_bubbles.emission_rect_extents = Vector2(360, 800)
	bg_bubbles.direction = Vector2(0, -1)
	bg_bubbles.spread = 20.0
	bg_bubbles.initial_velocity_min = 10.0
	bg_bubbles.initial_velocity_max = 25.0
	bg_bubbles.scale_amount_min = 2.0
	bg_bubbles.scale_amount_max = 5.0
	bg_bubbles.color = Color(1.0, 1.0, 1.0, 0.12)
	add_child(bg_bubbles)

	# 2. Main Bottles Playfield Container
	bottles_container = Control.new()
	bottles_container.name = "BottlesContainer"
	bottles_container.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bottles_container)

	# 3. Stream Renderer (layered over bottles container)
	stream_renderer = LiquidStream.new()
	stream_renderer.name = "LiquidStream"
	stream_renderer.z_index = 50
	add_child(stream_renderer)

	# 4. Top Header Bar
	top_bar = Control.new()
	top_bar.name = "TopBar"
	top_bar.custom_minimum_size = Vector2(0, 90)
	top_bar.set_anchors_preset(PRESET_TOP_WIDE)
	top_bar.offset_bottom = 90.0
	add_child(top_bar)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 12)
	top_bar.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(hbox)


	# Back Button
	back_btn = Button.new()
	back_btn.name = "BackBtn"
	back_btn.text = "← Back"
	back_btn.custom_minimum_size = Vector2(86, 44)
	back_btn.pressed.connect(_on_back_pressed)
	hbox.add_child(back_btn)

	# Level Indicator
	level_label = Label.new()
	level_label.name = "LevelLabel"
	level_label.size_flags_horizontal = SIZE_EXPAND_FILL
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_label.text = "Level 1"
	level_label.add_theme_font_size_override("font_size", 24)
	level_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85, 1.0))
	level_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	level_label.add_theme_constant_override("shadow_offset_x", 1)
	level_label.add_theme_constant_override("shadow_offset_y", 2)
	hbox.add_child(level_label)

	# Action Buttons
	undo_btn = Button.new()
	undo_btn.name = "UndoBtn"
	undo_btn.text = "⟲ Undo"
	undo_btn.custom_minimum_size = Vector2(80, 44)
	undo_btn.pressed.connect(_on_undo_pressed)
	hbox.add_child(undo_btn)

	restart_btn = Button.new()
	restart_btn.name = "RestartBtn"
	restart_btn.text = "↻ Reset"
	restart_btn.custom_minimum_size = Vector2(76, 44)
	restart_btn.pressed.connect(_on_restart_pressed)
	hbox.add_child(restart_btn)

	add_bottle_btn = Button.new()
	add_bottle_btn.name = "AddBottleBtn"
	add_bottle_btn.text = "+ Bottle"
	add_bottle_btn.custom_minimum_size = Vector2(84, 44)
	add_bottle_btn.pressed.connect(_on_add_bottle_pressed)
	hbox.add_child(add_bottle_btn)

	# 5. Victory Confetti Particles
	confetti_particles = CPUParticles2D.new()
	confetti_particles.name = "VictoryConfetti"
	confetti_particles.position = Vector2(360, 400)
	confetti_particles.emitting = false
	confetti_particles.one_shot = true
	confetti_particles.explosiveness = 0.8
	confetti_particles.amount = 40
	confetti_particles.lifetime = 1.6
	confetti_particles.direction = Vector2(0, -1)
	confetti_particles.spread = 180.0
	confetti_particles.initial_velocity_min = 120.0
	confetti_particles.initial_velocity_max = 280.0
	confetti_particles.scale_amount_min = 4.0
	confetti_particles.scale_amount_max = 9.0
	confetti_particles.color = Color(1.0, 0.85, 0.3, 1.0)
	confetti_particles.z_index = 100
	add_child(confetti_particles)

	# 6. Victory Modal
	_build_victory_modal()

	# 7. Loading Overlay (shown during BFS generation on next level)
	_build_loading_overlay()

func _build_victory_modal() -> void:
	win_modal = PanelContainer.new()
	win_modal.name = "WinModal"
	win_modal.custom_minimum_size = Vector2(400, 260)
	win_modal.set_anchors_preset(PRESET_CENTER)
	win_modal.offset_left = -200.0
	win_modal.offset_top = -130.0
	win_modal.offset_right = 200.0
	win_modal.offset_bottom = 130.0
	win_modal.z_index = 120
	win_modal.visible = false

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.14, 0.20, 0.98)
	style.border_color = Color(1.0, 0.82, 0.35, 1.0)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_right = 18
	style.corner_radius_bottom_left = 18
	style.shadow_size = 24
	style.shadow_color = Color(0, 0, 0, 0.5)
	win_modal.add_theme_stylebox_override("panel", style)
	add_child(win_modal)

	var vm_margin := MarginContainer.new()
	vm_margin.add_theme_constant_override("margin_left", 24)
	vm_margin.add_theme_constant_override("margin_right", 24)
	vm_margin.add_theme_constant_override("margin_top", 24)
	vm_margin.add_theme_constant_override("margin_bottom", 24)
	win_modal.add_child(vm_margin)

	var vm_vbox := VBoxContainer.new()
	vm_vbox.add_theme_constant_override("separation", 16)
	vm_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vm_margin.add_child(vm_vbox)


	win_title = Label.new()
	win_title.text = "★ Level Complete! ★"
	win_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_title.add_theme_font_size_override("font_size", 26)
	win_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35, 1.0))
	vm_vbox.add_child(win_title)

	var reward_lbl := Label.new()
	reward_lbl.text = "All liquids perfectly sorted!\n+50 Coins Earned"
	reward_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_lbl.add_theme_font_size_override("font_size", 16)
	reward_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95, 1.0))
	vm_vbox.add_child(reward_lbl)

	win_next_btn = Button.new()
	win_next_btn.text = "Next Level ▶"
	win_next_btn.custom_minimum_size = Vector2(180, 48)
	win_next_btn.size_flags_horizontal = SIZE_SHRINK_CENTER
	win_next_btn.pressed.connect(_on_next_level_pressed)
	vm_vbox.add_child(win_next_btn)

func _build_loading_overlay() -> void:
	loading_overlay = Control.new()
	loading_overlay.name = "LoadingOverlay"
	loading_overlay.set_anchors_preset(PRESET_FULL_RECT)
	loading_overlay.z_index = 200
	loading_overlay.visible = false
	add_child(loading_overlay)

	# Semi-transparent dark backdrop
	var bg := ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.72)
	loading_overlay.add_child(bg)

	# Centered card
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(280, 130)
	card.set_anchors_preset(PRESET_CENTER)
	card.offset_left = -140.0
	card.offset_top = -65.0
	card.offset_right = 140.0
	card.offset_bottom = 65.0
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.12, 0.12, 0.18, 0.97)
	card_style.border_color = Color(0.55, 0.75, 1.0, 0.7)
	card_style.set_border_width_all(2)
	card_style.set_corner_radius_all(16)
	card_style.shadow_size = 18
	card_style.shadow_color = Color(0, 0, 0, 0.45)
	card.add_theme_stylebox_override("panel", card_style)
	loading_overlay.add_child(card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.text = "Generating Level..."
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0, 1.0))
	vbox.add_child(title_lbl)

	loading_dots_label = Label.new()
	loading_dots_label.text = "Solving puzzle layout  ●○○"
	loading_dots_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_dots_label.add_theme_font_size_override("font_size", 13)
	loading_dots_label.add_theme_color_override("font_color", Color(0.6, 0.75, 1.0, 0.85))
	vbox.add_child(loading_dots_label)

func _process(_delta: float) -> void:
	# Animate loading dots while generation thread is running
	if not (loading_overlay and loading_overlay.visible and loading_dots_label):
		return
	var frame := int(Time.get_ticks_msec() / 380) % 3
	var frames := ["Solving puzzle layout  ●○○", "Solving puzzle layout  ●●○", "Solving puzzle layout  ●●●"]
	loading_dots_label.text = frames[frame]

func start_level(level: int) -> void:
	current_level = level
	undo_stack.clear()
	extra_bottles_added = 0
	selected_bottle = null
	is_pouring = false
	win_modal.visible = false

	if is_instance_valid(level_label):
		level_label.text = "Level %d" % current_level

	_update_undo_button()

	# Clear previous bottles immediately so the screen isn't frozen on the old state
	for b in bottles:
		if is_instance_valid(b):
			b.queue_free()
	bottles.clear()

	# Show loading overlay right away — user sees feedback instead of a frozen screen
	if loading_overlay:
		loading_overlay.visible = true

	# Run BFS level generation on a background thread so the main thread stays responsive
	if generation_thread and generation_thread.is_started():
		generation_thread.wait_to_finish()
	generation_thread = Thread.new()
	generation_thread.start(_generate_level_threaded.bind(level))

func _generate_level_threaded(level: int) -> void:
	# Runs on a background thread — do NOT touch any Node or UI from here
	var config := LiquidSortLevelGenerator.generate_level(level)
	# Hand the result back to the main thread safely via call_deferred
	call_deferred("_on_generation_done", config)

func _on_generation_done(config: LiquidSortLevelGenerator.LevelConfig) -> void:
	# Back on the main thread — safe to modify the scene tree
	if generation_thread and generation_thread.is_started():
		generation_thread.wait_to_finish()
	generation_thread = null

	if loading_overlay:
		loading_overlay.visible = false

	_instantiate_bottles(config)

func _instantiate_bottles(config: LiquidSortLevelGenerator.LevelConfig) -> void:
	for i in range(config.bottle_data.size()):
		var bottle := LiquidBottle.new()
		bottle.bottle_index = i
		var bottle_layers: Array[String] = []
		for item in config.bottle_data[i]:
			bottle_layers.append(String(item))
		
		bottles_container.add_child(bottle)
		bottle.setup(config.capacity, bottle_layers)
		bottle.bottle_clicked.connect(_on_bottle_clicked)
		bottles.append(bottle)

	call_deferred("_layout_bottles")

func _layout_bottles() -> void:
	if bottles.is_empty():
		return

	var vp_size := get_viewport_rect().size if is_inside_tree() else Vector2(720, 1600)
	var is_ls := is_landscape_mode or vp_size.x > vp_size.y

	var total_count := bottles.size()
	# Split into 2 rows:
	var top_count := int(ceil(float(total_count) / 2.0))
	var bottom_count := total_count - top_count

	var avail_width := (vp_size.x - 60.0) if not is_ls else (vp_size.x * 0.72)
	var max_cols := maxi(top_count, bottom_count)

	# Calculate responsive bottle dimensions
	var spacing_x := 18.0 if max_cols <= 4 else (14.0 if max_cols <= 5 else 10.0)
	var bottle_w := clampf((avail_width - float(max_cols - 1) * spacing_x) / float(max_cols), 65.0, 110.0)
	var bottle_h := bottle_w * 1.55
	var row_spacing := 48.0 if not is_ls else 32.0

	var center_y := (vp_size.y * 0.5) if not is_ls else (vp_size.y * 0.52)
	var row0_y := center_y - bottle_h - row_spacing * 0.5
	var row1_y := center_y + row_spacing * 0.5

	# Position Top Row
	var row0_total_w := float(top_count) * bottle_w + float(top_count - 1) * spacing_x
	var row0_start_x := (vp_size.x - row0_total_w) * 0.5

	for i in range(top_count):
		var b := bottles[i]
		b.set_bottle_size(Vector2(bottle_w, bottle_h))
		var pos := Vector2(row0_start_x + float(i) * (bottle_w + spacing_x), row0_y)
		b.position = pos
		b.original_position = pos

	# Position Bottom Row
	var row1_total_w := float(bottom_count) * bottle_w + float(bottom_count - 1) * spacing_x
	var row1_start_x := (vp_size.x - row1_total_w) * 0.5

	for j in range(bottom_count):
		var idx := top_count + j
		var b := bottles[idx]
		b.set_bottle_size(Vector2(bottle_w, bottle_h))
		var pos := Vector2(row1_start_x + float(j) * (bottle_w + spacing_x), row1_y)
		b.position = pos
		b.original_position = pos

func _on_bottle_clicked(bottle: LiquidBottle) -> void:
	if is_pouring:
		return

	if selected_bottle == null:
		# Selection Attempt
		if bottle.is_empty_bottle() or bottle.check_is_complete():
			if SoundManager: SoundManager.play_error()
			bottle.wobble_error()
			return
		
		# Select bottle
		selected_bottle = bottle
		selected_bottle.set_selected(true)
		if SoundManager: SoundManager.play_pickup()

	elif selected_bottle == bottle:
		# Deselect same bottle
		selected_bottle.set_selected(false)
		selected_bottle = null
		if SoundManager: SoundManager.play_drop()

	else:
		# Try pouring from selected_bottle into target bottle
		if bottle.can_receive_from(selected_bottle):
			var src := selected_bottle
			var dst := bottle
			selected_bottle.set_selected(false)
			selected_bottle = null
			_execute_pour(src, dst)
		else:
			# If tapping another bottle that can be selected instead
			if not bottle.is_empty_bottle() and not bottle.check_is_complete():
				selected_bottle.set_selected(false)
				selected_bottle = bottle
				selected_bottle.set_selected(true)
				if SoundManager: SoundManager.play_pickup()
			else:
				if SoundManager: SoundManager.play_error()
				bottle.wobble_error()

func _execute_pour(source: LiquidBottle, target: LiquidBottle) -> void:
	is_pouring = true
	source.is_animating = true
	target.is_animating = true
	if source.hover_tween:
		source.hover_tween.kill()

	# Record state for Undo
	var move_record: Dictionary = {
		"source_idx": source.bottle_index,
		"target_idx": target.bottle_index,
		"source_layers": source.layers.duplicate(),
		"target_layers": target.layers.duplicate()
	}
	undo_stack.append(move_record)
	_update_undo_button()

	var pour_color: String = source.get_top_color()
	var units_available := source.get_top_consecutive_count()
	var space_available := target.get_available_space()
	var units_to_pour := mini(units_available, space_available)
	var color_val := LiquidColorPalette.get_color(pour_color)

	# Decide pour direction based on which side of the target the source is on
	var vp_width := get_viewport_rect().size.x if is_inside_tree() else 720.0
	var target_center_x := target.global_position.x + target.size.x * 0.5
	var source_center_x := source.global_position.x + source.size.x * 0.5

	var pour_from_left: bool
	if target_center_x > vp_width * 0.65:
		pour_from_left = true
	elif target_center_x < vp_width * 0.35:
		pour_from_left = false
	elif abs(source_center_x - target_center_x) > 10.0:
		pour_from_left = source_center_x < target_center_x
	else:
		pour_from_left = target_center_x <= vp_width * 0.5

	# Dynamic tilt based on how many layers remain in the source bottle after pouring.
	# Nearly-empty bottle needs a steep tilt to drain the last bit.
	# Fuller bottles pour naturally at a gentler angle.
	var layers_remaining_after := source.layers.size() - units_to_pour
	var capacity := source.capacity
	# fill_ratio: 0.0 = will be empty after pour, 1.0 = still mostly full
	var fill_ratio_after := float(layers_remaining_after) / float(capacity)
	# Tilt range: 135° (steep, nearly empty) → 75° (gentle, more liquid left)
	var tilt_deg_abs := lerpf(135.0, 75.0, clampf(fill_ratio_after, 0.0, 1.0))
	var tilt_deg := tilt_deg_abs if pour_from_left else -tilt_deg_abs
	var target_tilt_rad := deg_to_rad(tilt_deg)

	# Align the actual pouring lip directly over the mouth. Clearance comes
	# from lifting the source, so the liquid can fall straight through the hole.
	var neck_global := target.get_neck_position_global()
	var desired_lip_global := neck_global + Vector2(0.0, -source.size.y * 0.20)
	var desired_lip_in_parent := bottles_container.get_global_transform().affine_inverse() * desired_lip_global

	# Calculate hover position so the rotated lip lands at desired_lip_in_parent
	var source_lip_local := source.get_lip_position_local(target_tilt_rad)
	var hover_pos := desired_lip_in_parent - source.pivot_offset - (source_lip_local - source.pivot_offset).rotated(target_tilt_rad)

	# 1. Fly source bottle to hover position above target, tilting mouth downward
	source.z_index = 40
	var target_glass_z := target.glass_texture.z_index
	target.glass_texture.z_index = stream_renderer.z_index + 1
	var tween := create_tween().set_parallel(true)
	tween.tween_property(source, "position", hover_pos, 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(source, "rotation", target_tilt_rad, 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tween.chain().tween_callback(func():
		# 2. Pour: stream goes from source lip → through target neck → down to liquid surface inside
		var lip_pt := source.get_lip_position_global()
		var surface_pt := target.get_liquid_surface_global()
		if SoundManager:
			SoundManager.play_pouring()
			SoundManager.play_merge_tier(2)

		var pour_duration := 0.45 + float(units_to_pour - 1) * 0.25
		source.animate_pour_out(units_to_pour, pour_duration)
		target.animate_fill_in(pour_color, units_to_pour, pour_duration)

		# Wait for pour duration
		var stream_timer := get_tree().create_timer(pour_duration)
		stream_timer.timeout.connect(func():
			# 3. Stop stream
			stream_renderer.stop()

			# 4. Return source bottle upright to original slot
			var return_tween := create_tween().set_parallel(true)
			return_tween.tween_property(source, "position", source.original_position, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
			return_tween.tween_property(source, "rotation", 0.0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

			return_tween.chain().tween_callback(func():
				source.z_index = 0
				target.glass_texture.z_index = target_glass_z
				source.rotation = 0.0
				source.update_visuals()
				target.update_visuals()
				source.is_animating = false
				target.is_animating = false
				is_pouring = false

				# Check if target bottle is completed
				if target.check_is_complete():
					target.celebrate_complete()
					if SoundManager: SoundManager.play_quest()

				# Check Win Condition
				_check_level_completed()
			)
		)
	)

func _check_level_completed() -> void:
	for b in bottles:
		if b.is_empty_bottle():
			continue
		if not b.check_is_complete():
			return

	# All non-empty bottles are completed!
	_on_level_won()

func _on_level_won() -> void:
	if SoundManager:
		SoundManager.play_quest()
	
	if EconomyManager:
		EconomyManager.add_coins(50)

	confetti_particles.restart()
	confetti_particles.emitting = true

	win_title.text = "★ Level %d Complete! ★" % current_level
	win_modal.visible = true
	win_modal.scale = Vector2(0.5, 0.5)
	win_modal.pivot_offset = win_modal.size * 0.5
	var win_tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	win_tween.tween_property(win_modal, "scale", Vector2.ONE, 0.3)

func _on_next_level_pressed() -> void:
	if SoundManager: SoundManager.play_click()
	win_modal.visible = false
	start_level(current_level + 1)

func _on_undo_pressed() -> void:
	if is_pouring or undo_stack.is_empty():
		return
	
	var last_move: Dictionary = undo_stack.pop_back()
	_update_undo_button()

	var src: LiquidBottle = bottles[last_move["source_idx"]]
	var dst: LiquidBottle = bottles[last_move["target_idx"]]

	src.layers.clear()
	for col in last_move["source_layers"]:
		src.layers.append(String(col))

	dst.layers.clear()
	for col in last_move["target_layers"]:
		dst.layers.append(String(col))

	src.rotation = 0.0
	dst.rotation = 0.0
	src.position = src.original_position
	dst.position = dst.original_position
	src.update_visuals()
	dst.update_visuals()

	if SoundManager: SoundManager.play_pickup()

func _on_restart_pressed() -> void:
	if is_pouring:
		return
	if SoundManager: SoundManager.play_click()
	start_level(current_level)

func _on_add_bottle_pressed() -> void:
	if is_pouring:
		return
	if extra_bottles_added >= 2:
		if SoundManager: SoundManager.play_error()
		return

	extra_bottles_added += 1
	var cap := bottles[0].capacity if not bottles.is_empty() else 3
	var new_b := LiquidBottle.new()
	new_b.bottle_index = bottles.size()
	bottles_container.add_child(new_b)
	new_b.setup(cap, [])
	new_b.bottle_clicked.connect(_on_bottle_clicked)
	bottles.append(new_b)

	if SoundManager: SoundManager.play_spawn()
	_layout_bottles()

func _update_undo_button() -> void:
	if undo_btn:
		undo_btn.disabled = undo_stack.is_empty()

func _on_back_pressed() -> void:
	if SoundManager: SoundManager.play_close()
	exit_requested.emit()

func apply_orientation(landscape: bool) -> void:
	is_landscape_mode = landscape
	_layout_bottles()
