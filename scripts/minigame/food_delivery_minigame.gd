class_name FoodDeliveryMinigame
extends Control

signal exit_requested()

const ItemComponent = preload("res://scripts/minigame/food_delivery_item.gd")
const LevelDB = preload("res://scripts/minigame/delivery_level_database.gd")

const MAX_TEMP_SLOTS: int = 7
const TOTAL_LEVELS: int = 10

# Game State
var current_level: int = 1
var time_remaining: float = 90.0
var max_time: float = 90.0
var is_game_active: bool = false
var is_paused: bool = false

var orders_queue: Array[String] = []
var current_order_item: String = ""
var current_order_filled: int = 0
var total_orders_in_level: int = 0
var orders_completed_count: int = 0

var temporary_items: Array[FoodDeliveryItem] = []
var stack_columns: Array[Array] = [] # Array of Array[FoodDeliveryItem]
var is_animating_move: bool = false

# UI References
var bg_rect: TextureRect
var top_bar: Control
var level_title_label: Label
var timer_label: Label
var timer_bar: ProgressBar
var orders_count_label: Label
var back_btn: Button
var restart_btn: Button
var level_select_btn: Button

# Delivery Box Area
var delivery_box_panel: Panel
var order_speech_label: Label
var delivery_slots: Array[Panel] = []
var delivery_slot_items: Array[FoodDeliveryItem] = []

# Temporary Slots Area
var temp_counter_panel: Panel
var temp_slots: Array[Panel] = []
var temp_slots_label: Label

# Playfield / Stacks
var playfield_container: Control
var stacks_container: HBoxContainer
var flying_layer: Control

# Modals
var win_modal_layer: Control
var win_modal: PanelContainer
var win_title: Label
var win_reward_label: Label
var win_reward_icon: TextureRect
var win_next_btn: Button
var win_levels_btn: Button
var win_exit_btn: Button
var win_particles: CPUParticles2D

var game_over_modal_layer: Control
var game_over_modal: PanelContainer
var game_over_reason_label: Label
var game_over_retry_btn: Button
var game_over_levels_btn: Button
var game_over_exit_btn: Button

var level_select_modal: Control
var level_grid: GridContainer

func _init() -> void:
	name = "FoodDeliveryMinigame"
	set_anchors_preset(PRESET_FULL_RECT)

func _ready() -> void:
	_build_ui()
	var starting_level := 1
	if is_instance_valid(ProgressionManager):
		starting_level = ProgressionManager.delivery_max_unlocked_level
	start_level(starting_level)

func _process(delta: float) -> void:
	if not is_game_active or is_paused:
		return

	time_remaining -= delta
	_update_timer_display()

	if time_remaining <= 0.0:
		time_remaining = 0.0
		_trigger_game_over("Time ran out! The food delivery expired.")

func _build_ui() -> void:
	# 1. Background
	bg_rect = TextureRect.new()
	bg_rect.name = "Background"
	bg_rect.set_anchors_preset(PRESET_FULL_RECT)
	bg_rect.mouse_filter = MOUSE_FILTER_IGNORE
	bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var bg_tex: Texture2D = load("res://assets/background/kitchen.jpeg")
	if bg_tex:
		bg_rect.texture = bg_tex
	add_child(bg_rect)

	# Cozy dark backdrop overlay for high contrast
	var overlay := ColorRect.new()
	overlay.name = "Overlay"
	overlay.set_anchors_preset(PRESET_FULL_RECT)
	overlay.color = Color(0.12, 0.09, 0.07, 0.78)
	overlay.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(overlay)

	# 2. Main Layout Container
	var main_vbox := VBoxContainer.new()
	main_vbox.name = "MainVBox"
	main_vbox.set_anchors_preset(PRESET_FULL_RECT)
	main_vbox.offset_left = 16
	main_vbox.offset_right = -16
	main_vbox.offset_top = 16
	main_vbox.offset_bottom = -20
	main_vbox.add_theme_constant_override("separation", 14)
	add_child(main_vbox)

	# 3. Top Header Bar
	top_bar = Control.new()
	top_bar.name = "TopBar"
	top_bar.custom_minimum_size = Vector2(0, 95)
	main_vbox.add_child(top_bar)

	var top_hbox := HBoxContainer.new()
	top_hbox.set_anchors_preset(PRESET_FULL_RECT)
	top_hbox.add_theme_constant_override("separation", 10)
	top_bar.add_child(top_hbox)

	back_btn = Button.new()
	back_btn.text = "← Back"
	back_btn.custom_minimum_size = Vector2(76, 44)
	back_btn.size_flags_vertical = SIZE_SHRINK_CENTER
	back_btn.pressed.connect(_on_back_pressed)
	_style_button(back_btn, Color(0.85, 0.42, 0.35))
	top_hbox.add_child(back_btn)

	var title_vbox := VBoxContainer.new()
	title_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	title_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	top_hbox.add_child(title_vbox)

	level_title_label = Label.new()
	level_title_label.text = "Level 1: Morning Rush"
	level_title_label.add_theme_font_size_override("font_size", 18)
	level_title_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
	level_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_vbox.add_child(level_title_label)

	var timer_hbox := HBoxContainer.new()
	timer_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	timer_hbox.add_theme_constant_override("separation", 8)
	title_vbox.add_child(timer_hbox)

	timer_label = Label.new()
	timer_label.text = "⏱ 90s"
	timer_label.add_theme_font_size_override("font_size", 14)
	timer_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45))
	timer_hbox.add_child(timer_label)

	timer_bar = ProgressBar.new()
	timer_bar.custom_minimum_size = Vector2(160, 12)
	timer_bar.size_flags_vertical = SIZE_SHRINK_CENTER
	timer_bar.max_value = 100.0
	timer_bar.value = 100.0
	timer_bar.show_percentage = false
	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = Color(0.3, 0.78, 0.45)
	bar_style.set_corner_radius_all(6)
	timer_bar.add_theme_stylebox_override("fill", bar_style)
	timer_hbox.add_child(timer_bar)

	orders_count_label = Label.new()
	orders_count_label.text = "📦 Orders: 0/3"
	orders_count_label.add_theme_font_size_override("font_size", 13)
	orders_count_label.add_theme_color_override("font_color", Color(0.9, 0.88, 0.82))
	orders_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_vbox.add_child(orders_count_label)

	restart_btn = Button.new()
	restart_btn.text = "↺"
	restart_btn.custom_minimum_size = Vector2(44, 44)
	restart_btn.size_flags_vertical = SIZE_SHRINK_CENTER
	restart_btn.pressed.connect(_on_restart_pressed)
	_style_button(restart_btn, Color(0.45, 0.65, 0.8))
	top_hbox.add_child(restart_btn)

	level_select_btn = Button.new()
	level_select_btn.text = "☰"
	level_select_btn.custom_minimum_size = Vector2(44, 44)
	level_select_btn.size_flags_vertical = SIZE_SHRINK_CENTER
	level_select_btn.pressed.connect(open_level_select)
	_style_button(level_select_btn, Color(0.55, 0.55, 0.6))
	top_hbox.add_child(level_select_btn)

	# 4. Delivery Box Area (Top Matching Box)
	delivery_box_panel = Panel.new()
	delivery_box_panel.name = "DeliveryBoxPanel"
	delivery_box_panel.custom_minimum_size = Vector2(0, 160)
	var box_style := StyleBoxFlat.new()
	box_style.bg_color = Color(0.96, 0.93, 0.88, 0.98)
	box_style.border_width_left = 3
	box_style.border_width_top = 3
	box_style.border_width_right = 3
	box_style.border_width_bottom = 4
	box_style.border_color = Color(0.82, 0.65, 0.45, 1.0)
	box_style.set_corner_radius_all(18)
	box_style.shadow_color = Color(0, 0, 0, 0.22)
	box_style.shadow_size = 8
	box_style.shadow_offset = Vector2(0, 4)
	delivery_box_panel.add_theme_stylebox_override("panel", box_style)
	main_vbox.add_child(delivery_box_panel)

	var box_vbox := VBoxContainer.new()
	box_vbox.set_anchors_preset(PRESET_FULL_RECT)
	box_vbox.offset_left = 12
	box_vbox.offset_right = -12
	box_vbox.offset_top = 10
	box_vbox.offset_bottom = -10
	box_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	box_vbox.add_theme_constant_override("separation", 8)
	delivery_box_panel.add_child(box_vbox)

	order_speech_label = Label.new()
	order_speech_label.text = "🛵 Delivery Request: Deliver 3x Croissant!"
	order_speech_label.add_theme_font_size_override("font_size", 16)
	order_speech_label.add_theme_color_override("font_color", Color(0.25, 0.18, 0.12))
	order_speech_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box_vbox.add_child(order_speech_label)

	var slots_hbox := HBoxContainer.new()
	slots_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	slots_hbox.add_theme_constant_override("separation", 20)
	box_vbox.add_child(slots_hbox)

	delivery_slots.clear()
	for i in range(3):
		var slot := Panel.new()
		slot.name = "DeliverySlot_%d" % i
		slot.custom_minimum_size = Vector2(80, 80)
		var s_style := StyleBoxFlat.new()
		s_style.bg_color = Color(0.88, 0.84, 0.78, 0.6)
		s_style.border_width_left = 2
		s_style.border_width_top = 2
		s_style.border_width_right = 2
		s_style.border_width_bottom = 2
		s_style.border_color = Color(0.72, 0.65, 0.55, 0.8)
		s_style.set_corner_radius_all(14)
		slot.add_theme_stylebox_override("panel", s_style)
		slots_hbox.add_child(slot)
		delivery_slots.append(slot)

	# 5. Temporary Counter Panel (Holding Tray)
	temp_counter_panel = Panel.new()
	temp_counter_panel.name = "TempCounterPanel"
	temp_counter_panel.custom_minimum_size = Vector2(0, 115)
	var temp_style := StyleBoxFlat.new()
	temp_style.bg_color = Color(0.24, 0.20, 0.18, 0.92)
	temp_style.border_width_left = 2
	temp_style.border_width_top = 2
	temp_style.border_width_right = 2
	temp_style.border_width_bottom = 2
	temp_style.border_color = Color(0.55, 0.48, 0.40, 0.9)
	temp_style.set_corner_radius_all(16)
	temp_counter_panel.add_theme_stylebox_override("panel", temp_style)
	main_vbox.add_child(temp_counter_panel)

	var temp_vbox := VBoxContainer.new()
	temp_vbox.set_anchors_preset(PRESET_FULL_RECT)
	temp_vbox.offset_left = 10
	temp_vbox.offset_right = -10
	temp_vbox.offset_top = 8
	temp_vbox.offset_bottom = -8
	temp_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	temp_vbox.add_theme_constant_override("separation", 6)
	temp_counter_panel.add_child(temp_vbox)

	temp_slots_label = Label.new()
	temp_slots_label.text = "Temporary Counter: 0 / 7 (Unmatched Foods)"
	temp_slots_label.add_theme_font_size_override("font_size", 13)
	temp_slots_label.add_theme_color_override("font_color", Color(0.92, 0.88, 0.82))
	temp_slots_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	temp_vbox.add_child(temp_slots_label)

	var temp_slots_hbox := HBoxContainer.new()
	temp_slots_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	temp_slots_hbox.add_theme_constant_override("separation", 8)
	temp_vbox.add_child(temp_slots_hbox)

	temp_slots.clear()
	for i in range(MAX_TEMP_SLOTS):
		var t_slot := Panel.new()
		t_slot.name = "TempSlot_%d" % i
		t_slot.custom_minimum_size = Vector2(68, 68)
		var ts_style := StyleBoxFlat.new()
		ts_style.bg_color = Color(0.18, 0.15, 0.14, 0.7)
		ts_style.border_width_left = 1
		ts_style.border_width_top = 1
		ts_style.border_width_right = 1
		ts_style.border_width_bottom = 1
		ts_style.border_color = Color(0.42, 0.38, 0.34, 0.7)
		ts_style.set_corner_radius_all(12)
		t_slot.add_theme_stylebox_override("panel", ts_style)
		temp_slots_hbox.add_child(t_slot)
		temp_slots.append(t_slot)

	# 6. Playfield: Stacks Area
	playfield_container = Control.new()
	playfield_container.name = "PlayfieldContainer"
	playfield_container.size_flags_vertical = SIZE_EXPAND_FILL
	main_vbox.add_child(playfield_container)

	var playfield_center := CenterContainer.new()
	playfield_center.name = "PlayfieldCenter"
	playfield_center.set_anchors_preset(PRESET_FULL_RECT)
	playfield_center.mouse_filter = MOUSE_FILTER_IGNORE
	playfield_container.add_child(playfield_center)

	var playfield_board := PanelContainer.new()
	playfield_board.name = "PlayfieldBoard"
	var board_style := StyleBoxFlat.new()
	board_style.bg_color = Color(0.18, 0.15, 0.13, 0.72)
	board_style.border_width_left = 2
	board_style.border_width_top = 2
	board_style.border_width_right = 2
	board_style.border_width_bottom = 3
	board_style.border_color = Color(0.48, 0.40, 0.34, 0.8)
	board_style.set_corner_radius_all(20)
	board_style.shadow_color = Color(0, 0, 0, 0.3)
	board_style.shadow_size = 12
	board_style.shadow_offset = Vector2(0, 4)
	playfield_board.add_theme_stylebox_override("panel", board_style)
	playfield_center.add_child(playfield_board)

	var board_margin := MarginContainer.new()
	board_margin.add_theme_constant_override("margin_left", 14)
	board_margin.add_theme_constant_override("margin_right", 14)
	board_margin.add_theme_constant_override("margin_top", 14)
	board_margin.add_theme_constant_override("margin_bottom", 14)
	playfield_board.add_child(board_margin)

	stacks_container = HBoxContainer.new()
	stacks_container.name = "StacksContainer"
	stacks_container.alignment = BoxContainer.ALIGNMENT_CENTER
	stacks_container.add_theme_constant_override("separation", 14)
	board_margin.add_child(stacks_container)

	# Top Animation Layer for flying items
	flying_layer = Control.new()
	flying_layer.name = "FlyingLayer"
	flying_layer.set_anchors_preset(PRESET_FULL_RECT)
	flying_layer.mouse_filter = MOUSE_FILTER_IGNORE
	flying_layer.z_index = 200
	add_child(flying_layer)

	# 7. Modals
	_build_win_modal()
	_build_game_over_modal()
	_build_level_select_modal()

func _style_button(btn: Button, bg_col: Color) -> void:
	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = bg_col
	style_normal.set_corner_radius_all(10)
	var style_hover := StyleBoxFlat.new()
	style_hover.bg_color = bg_col.lightened(0.15)
	style_hover.set_corner_radius_all(10)
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_color_override("font_color", Color.WHITE)

func _build_win_modal() -> void:
	win_modal_layer = Control.new()
	win_modal_layer.name = "WinModalLayer"
	win_modal_layer.set_anchors_preset(PRESET_FULL_RECT)
	win_modal_layer.grow_horizontal = Control.GROW_DIRECTION_BOTH
	win_modal_layer.grow_vertical = Control.GROW_DIRECTION_BOTH
	win_modal_layer.z_index = 400
	win_modal_layer.visible = false
	add_child(win_modal_layer)

	var dimmer := ColorRect.new()
	dimmer.name = "Dimmer"
	dimmer.set_anchors_preset(PRESET_FULL_RECT)
	dimmer.grow_horizontal = Control.GROW_DIRECTION_BOTH
	dimmer.grow_vertical = Control.GROW_DIRECTION_BOTH
	dimmer.color = Color(0.06, 0.08, 0.10, 0.75)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	win_modal_layer.add_child(dimmer)

	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(PRESET_FULL_RECT)
	center.grow_horizontal = Control.GROW_DIRECTION_BOTH
	center.grow_vertical = Control.GROW_DIRECTION_BOTH
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	win_modal_layer.add_child(center)

	win_modal = PanelContainer.new()
	win_modal.name = "WinModal"
	win_modal.custom_minimum_size = Vector2(480, 480)
	win_modal.pivot_offset = Vector2(240, 240)
	win_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	win_modal.visible = false

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.99, 0.98, 0.94, 0.98)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 4
	style.border_color = Color(0.35, 0.75, 0.45, 1.0)
	style.set_corner_radius_all(22)
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 20
	style.shadow_offset = Vector2(0, 10)
	win_modal.add_theme_stylebox_override("panel", style)
	center.add_child(win_modal)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	win_modal.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	win_title = Label.new()
	win_title.text = "🎉 Delivery Complete!"
	win_title.add_theme_font_size_override("font_size", 24)
	win_title.add_theme_color_override("font_color", Color(0.2, 0.5, 0.25))
	win_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(win_title)

	var desc_label := Label.new()
	desc_label.text = "All customer orders delivered in time!\nYou earned a special reward:"
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.4, 0.35, 0.3))
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc_label)

	var reward_panel := PanelContainer.new()
	reward_panel.custom_minimum_size = Vector2(100, 100)
	var r_style := StyleBoxFlat.new()
	r_style.bg_color = Color(1.0, 0.95, 0.85, 0.9)
	r_style.border_width_left = 2
	r_style.border_width_top = 2
	r_style.border_width_right = 2
	r_style.border_width_bottom = 2
	r_style.border_color = Color(0.9, 0.75, 0.4)
	r_style.set_corner_radius_all(14)
	reward_panel.add_theme_stylebox_override("panel", r_style)
	vbox.add_child(reward_panel)

	var r_vbox := VBoxContainer.new()
	r_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	reward_panel.add_child(r_vbox)

	win_reward_icon = TextureRect.new()
	win_reward_icon.custom_minimum_size = Vector2(64, 64)
	win_reward_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	win_reward_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r_vbox.add_child(win_reward_icon)

	win_reward_label = Label.new()
	win_reward_label.text = "Gold Sovereign"
	win_reward_label.add_theme_font_size_override("font_size", 15)
	win_reward_label.add_theme_color_override("font_color", Color(0.3, 0.25, 0.2))
	win_reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	r_vbox.add_child(win_reward_label)

	var note_label := Label.new()
	note_label.text = "✨ Placed in your temporary reward slot! ✨"
	note_label.add_theme_font_size_override("font_size", 12)
	note_label.add_theme_color_override("font_color", Color(0.2, 0.6, 0.3))
	note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(note_label)

	var btn_hbox := HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_hbox)

	win_levels_btn = Button.new()
	win_levels_btn.text = "Levels"
	win_levels_btn.custom_minimum_size = Vector2(100, 44)
	_style_button(win_levels_btn, Color(0.45, 0.55, 0.65))
	win_levels_btn.pressed.connect(func():
		if is_instance_valid(win_modal_layer):
			win_modal_layer.visible = false
		win_modal.visible = false
		open_level_select()
	)
	btn_hbox.add_child(win_levels_btn)

	win_next_btn = Button.new()
	win_next_btn.text = "Next Level →"
	win_next_btn.custom_minimum_size = Vector2(130, 44)
	_style_button(win_next_btn, Color(0.28, 0.68, 0.38))
	win_next_btn.pressed.connect(_on_win_next_pressed)
	btn_hbox.add_child(win_next_btn)

	win_exit_btn = Button.new()
	win_exit_btn.text = "Exit"
	win_exit_btn.custom_minimum_size = Vector2(80, 44)
	_style_button(win_exit_btn, Color(0.7, 0.4, 0.35))
	win_exit_btn.pressed.connect(func():
		if is_instance_valid(win_modal_layer):
			win_modal_layer.visible = false
		win_modal.visible = false
		_on_back_pressed()
	)
	btn_hbox.add_child(win_exit_btn)

	# Confetti particles
	win_particles = CPUParticles2D.new()
	win_particles.name = "WinParticles"
	win_particles.position = Vector2(240, 0)
	win_particles.emitting = false
	win_particles.one_shot = true
	win_particles.amount = 40
	win_particles.lifetime = 1.6
	win_particles.explosiveness = 0.85
	win_particles.direction = Vector2(0, 1)
	win_particles.spread = 70.0
	win_particles.initial_velocity_min = 120.0
	win_particles.initial_velocity_max = 280.0
	win_particles.scale_amount_min = 4.0
	win_particles.scale_amount_max = 8.0
	win_modal.add_child(win_particles)

func _build_game_over_modal() -> void:
	game_over_modal_layer = Control.new()
	game_over_modal_layer.name = "GameOverModalLayer"
	game_over_modal_layer.set_anchors_preset(PRESET_FULL_RECT)
	game_over_modal_layer.grow_horizontal = Control.GROW_DIRECTION_BOTH
	game_over_modal_layer.grow_vertical = Control.GROW_DIRECTION_BOTH
	game_over_modal_layer.z_index = 400
	game_over_modal_layer.visible = false
	add_child(game_over_modal_layer)

	var dimmer := ColorRect.new()
	dimmer.name = "Dimmer"
	dimmer.set_anchors_preset(PRESET_FULL_RECT)
	dimmer.grow_horizontal = Control.GROW_DIRECTION_BOTH
	dimmer.grow_vertical = Control.GROW_DIRECTION_BOTH
	dimmer.color = Color(0.12, 0.05, 0.05, 0.75)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	game_over_modal_layer.add_child(dimmer)

	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(PRESET_FULL_RECT)
	center.grow_horizontal = Control.GROW_DIRECTION_BOTH
	center.grow_vertical = Control.GROW_DIRECTION_BOTH
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_over_modal_layer.add_child(center)

	game_over_modal = PanelContainer.new()
	game_over_modal.name = "GameOverModal"
	game_over_modal.custom_minimum_size = Vector2(440, 360)
	game_over_modal.pivot_offset = Vector2(220, 180)
	game_over_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	game_over_modal.visible = false

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.98, 0.95, 0.93, 0.98)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 4
	style.border_color = Color(0.85, 0.35, 0.35, 1.0)
	style.set_corner_radius_all(22)
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 20
	style.shadow_offset = Vector2(0, 8)
	game_over_modal.add_theme_stylebox_override("panel", style)
	center.add_child(game_over_modal)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	game_over_modal.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "⚠️ Delivery Failed!"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.8, 0.25, 0.25))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	game_over_reason_label = Label.new()
	game_over_reason_label.text = "Temporary slots are full and no matching items can solve the delivery!"
	game_over_reason_label.add_theme_font_size_override("font_size", 14)
	game_over_reason_label.add_theme_color_override("font_color", Color(0.45, 0.38, 0.35))
	game_over_reason_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(game_over_reason_label)

	var btn_hbox := HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 14)
	vbox.add_child(btn_hbox)

	game_over_retry_btn = Button.new()
	game_over_retry_btn.text = "Try Again ↺"
	game_over_retry_btn.custom_minimum_size = Vector2(130, 46)
	_style_button(game_over_retry_btn, Color(0.3, 0.65, 0.45))
	game_over_retry_btn.pressed.connect(func():
		if is_instance_valid(game_over_modal_layer):
			game_over_modal_layer.visible = false
		game_over_modal.visible = false
		start_level(current_level)
	)
	btn_hbox.add_child(game_over_retry_btn)

	game_over_levels_btn = Button.new()
	game_over_levels_btn.text = "Levels"
	game_over_levels_btn.custom_minimum_size = Vector2(90, 46)
	_style_button(game_over_levels_btn, Color(0.45, 0.55, 0.65))
	game_over_levels_btn.pressed.connect(func():
		if is_instance_valid(game_over_modal_layer):
			game_over_modal_layer.visible = false
		game_over_modal.visible = false
		open_level_select()
	)
	btn_hbox.add_child(game_over_levels_btn)

	game_over_exit_btn = Button.new()
	game_over_exit_btn.text = "Exit"
	game_over_exit_btn.custom_minimum_size = Vector2(80, 46)
	_style_button(game_over_exit_btn, Color(0.65, 0.45, 0.4))
	game_over_exit_btn.pressed.connect(func():
		if is_instance_valid(game_over_modal_layer):
			game_over_modal_layer.visible = false
		game_over_modal.visible = false
		_on_back_pressed()
	)
	btn_hbox.add_child(game_over_exit_btn)

func _build_level_select_modal() -> void:
	level_select_modal = Control.new()
	level_select_modal.name = "LevelSelectModal"
	level_select_modal.set_anchors_preset(PRESET_FULL_RECT)
	level_select_modal.grow_horizontal = Control.GROW_DIRECTION_BOTH
	level_select_modal.grow_vertical = Control.GROW_DIRECTION_BOTH
	level_select_modal.visible = false
	level_select_modal.z_index = 420
	add_child(level_select_modal)

	var dimmer := ColorRect.new()
	dimmer.set_anchors_preset(PRESET_FULL_RECT)
	dimmer.grow_horizontal = Control.GROW_DIRECTION_BOTH
	dimmer.grow_vertical = Control.GROW_DIRECTION_BOTH
	dimmer.color = Color(0.08, 0.08, 0.1, 0.88)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	level_select_modal.add_child(dimmer)

	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(PRESET_FULL_RECT)
	center.grow_horizontal = Control.GROW_DIRECTION_BOTH
	center.grow_vertical = Control.GROW_DIRECTION_BOTH
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_select_modal.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 680)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var p_style := StyleBoxFlat.new()
	p_style.bg_color = Color(0.98, 0.96, 0.92, 1.0)
	p_style.border_width_left = 2
	p_style.border_width_top = 2
	p_style.border_width_right = 2
	p_style.border_width_bottom = 3
	p_style.border_color = Color(0.78, 0.72, 0.65)
	p_style.set_corner_radius_all(20)
	p_style.shadow_color = Color(0, 0, 0, 0.35)
	p_style.shadow_size = 20
	panel.add_theme_stylebox_override("panel", p_style)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	var header_hbox := HBoxContainer.new()
	vbox.add_child(header_hbox)

	var title_lbl := Label.new()
	title_lbl.text = "Select Delivery Level"
	title_lbl.size_flags_horizontal = SIZE_EXPAND_FILL
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", Color(0.24, 0.18, 0.14))
	header_hbox.add_child(title_lbl)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(40, 40)
	_style_button(close_btn, Color(0.75, 0.45, 0.45))
	close_btn.pressed.connect(func(): level_select_modal.visible = false)
	header_hbox.add_child(close_btn)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	level_grid = GridContainer.new()
	level_grid.columns = 2
	level_grid.size_flags_horizontal = SIZE_EXPAND_FILL
	level_grid.add_theme_constant_override("h_separation", 14)
	level_grid.add_theme_constant_override("v_separation", 14)
	scroll.add_child(level_grid)

# =============================================================================
# GAME LOOP & LEVEL INITIALIZATION
# =============================================================================

func start_level(level_num: int) -> void:
	current_level = clampi(level_num, 1, TOTAL_LEVELS)
	var level_data := LevelDB.get_level(current_level)

	if is_instance_valid(win_modal_layer):
		win_modal_layer.visible = false
	win_modal.visible = false
	if is_instance_valid(game_over_modal_layer):
		game_over_modal_layer.visible = false
	game_over_modal.visible = false
	level_select_modal.visible = false
	is_paused = false
	is_animating_move = false

	# Setup orders
	var raw_orders: Array = level_data.get("orders", [])
	orders_queue.clear()
	for o in raw_orders:
		orders_queue.append(str(o))

	total_orders_in_level = orders_queue.size()
	orders_completed_count = 0
	current_order_filled = 0

	# Timer
	max_time = float(level_data.get("time_limit", 90))
	time_remaining = max_time
	_update_timer_display()

	# Clear previous delivery slots
	_clear_delivery_slots()

	# Clear previous temporary items
	for it in temporary_items:
		if is_instance_valid(it):
			it.queue_free()
	temporary_items.clear()
	_update_temporary_counter_display()

	# Setup Title
	var title_text: String = level_data.get("title", "Delivery Rush")
	level_title_label.text = "Level %d: %s" % [current_level, title_text]
	orders_count_label.text = "📦 Orders: 0 / %d" % total_orders_in_level

	# Build Stacks
	_build_stacks(level_data.get("stacks", []))

	# Activate first order
	_advance_to_next_order()

	is_game_active = true

func _build_stacks(stacks_data: Array) -> void:
	for child in stacks_container.get_children():
		child.queue_free()
	stack_columns.clear()

	var max_items_in_level: int = 1
	for col_data in stacks_data:
		max_items_in_level = maxi(max_items_in_level, col_data.size())

	var col_width: float = 80.0
	var item_width: float = 72.0
	var item_x: float = (col_width - item_width) * 0.5
	var step_y: float = 46.0
	var top_pad: float = 8.0
	var bottom_pad: float = 8.0
	var col_height: float = top_pad + bottom_pad + item_width + float(max_items_in_level - 1) * step_y

	var col_count: int = stacks_data.size()
	var separation: int = 14
	if col_count >= 6:
		separation = 10
	elif col_count >= 5:
		separation = 12
	stacks_container.add_theme_constant_override("separation", separation)

	for col_idx in range(stacks_data.size()):
		var col_data: Array = stacks_data[col_idx]
		var col_control := Control.new()
		col_control.name = "StackCol_%d" % col_idx
		col_control.custom_minimum_size = Vector2(col_width, col_height)

		# Subtle column track tray backing to ground the items visually
		var col_track := Panel.new()
		col_track.name = "TrackBg"
		col_track.set_anchors_preset(PRESET_FULL_RECT)
		col_track.mouse_filter = MOUSE_FILTER_IGNORE
		var track_style := StyleBoxFlat.new()
		track_style.bg_color = Color(0.18, 0.14, 0.12, 0.45)
		track_style.border_width_left = 1
		track_style.border_width_top = 1
		track_style.border_width_right = 1
		track_style.border_width_bottom = 1
		track_style.border_color = Color(0.42, 0.36, 0.30, 0.5)
		track_style.set_corner_radius_all(14)
		col_track.add_theme_stylebox_override("panel", track_style)
		col_control.add_child(col_track)

		stacks_container.add_child(col_control)

		var items_in_col: Array = []
		var total_rows: int = col_data.size()

		# Stacking from TOP to BOTTOM:
		# Index 0 in col_data is the bottom of the stack (deepest, locked under other items).
		# Index total_rows - 1 in col_data is the topmost item of the stack (first accessible).
		# Accessible item (total_rows - 1) is placed at y = top_pad (top of the column).
		# Deeper items are placed below it (depth 1, 2, ... down the column).
		for row_idx in range(total_rows):
			var item_id: String = str(col_data[row_idx])
			var item := ItemComponent.new(item_id)
			item.name = "Item_%d_%d" % [col_idx, row_idx]

			# Connect click & drag signals directly without .bind() to avoid argument mismatches
			item.clicked.connect(_on_stack_item_clicked)
			item.drag_ended.connect(_on_stack_item_drag_ended)

			var depth_from_top: int = (total_rows - 1) - row_idx
			var y_pos: float = top_pad + float(depth_from_top) * step_y
			item.position = Vector2(item_x, y_pos)

			col_control.add_child(item)
			items_in_col.append(item)

		stack_columns.append(items_in_col)

	_refresh_stack_visuals()

func _refresh_stack_visuals() -> void:
	for col in stack_columns:
		for i in range(col.size()):
			var item: FoodDeliveryItem = col[i]
			var is_top := (i == col.size() - 1)
			item.set_topmost(is_top)
			item.original_z_index = i + 1
			item.z_index = i + 1

func _clear_delivery_slots() -> void:
	for it in delivery_slot_items:
		if is_instance_valid(it):
			it.queue_free()
	delivery_slot_items.clear()
	current_order_filled = 0

func _advance_to_next_order() -> void:
	_clear_delivery_slots()

	if orders_queue.is_empty():
		_trigger_win()
		return

	current_order_item = orders_queue.pop_front()
	var item_data := ItemDatabase.get_item(current_order_item) if is_instance_valid(ItemDatabase) else null
	var item_name := item_data.display_name if item_data else current_order_item
	order_speech_label.text = "🛵 Deliver 3x %s!" % item_name
	orders_count_label.text = "📦 Orders: %d / %d" % [orders_completed_count, total_orders_in_level]

	for slot in delivery_slots:
		var ghost := slot.get_node_or_null("GhostIcon") as TextureRect
		if not ghost:
			ghost = TextureRect.new()
			ghost.name = "GhostIcon"
			ghost.set_anchors_preset(PRESET_FULL_RECT)
			ghost.offset_left = 10
			ghost.offset_top = 10
			ghost.offset_right = -10
			ghost.offset_bottom = -10
			ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ghost.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ghost.modulate = Color(1.0, 1.0, 1.0, 0.25)
			ghost.mouse_filter = MOUSE_FILTER_IGNORE
			slot.add_child(ghost)
		if item_data and item_data.icon_texture:
			ghost.texture = item_data.icon_texture

	_check_and_transfer_from_temp_slots()

func _check_and_transfer_from_temp_slots() -> void:
	if current_order_item.is_empty() or temporary_items.is_empty():
		return

	var matches_in_temp: Array[FoodDeliveryItem] = []
	for it in temporary_items:
		if is_instance_valid(it) and it.item_id == current_order_item:
			matches_in_temp.append(it)

	for it in matches_in_temp:
		if current_order_filled < 3:
			temporary_items.erase(it)
			_disconnect_temp_item_signals(it)
			_fly_item_to_delivery_box(it)

	_repack_temporary_slots()

# =============================================================================
# ITEM INTERACTIONS: CLICK & DRAG HANDLING
# =============================================================================

func _find_item_column(item: FoodDeliveryItem) -> int:
	for i in range(stack_columns.size()):
		if stack_columns[i].has(item):
			return i
	return -1

func _on_stack_item_clicked(item: FoodDeliveryItem) -> void:
	if not is_game_active or is_paused or is_animating_move:
		return

	var col_idx := _find_item_column(item)
	if col_idx == -1:
		return

	var col: Array = stack_columns[col_idx]
	if col.is_empty() or col.back() != item:
		return

	if not item.is_topmost:
		return

	# If matches current order -> flies to delivery box
	if item.item_id == current_order_item and current_order_filled < 3:
		col.pop_back()
		_disconnect_stack_item_signals(item)
		_refresh_stack_visuals()
		_fly_item_to_delivery_box(item)
	else:
		# Unmatched item -> moves to temporary counter
		if temporary_items.size() < MAX_TEMP_SLOTS:
			col.pop_back()
			_disconnect_stack_item_signals(item)
			_refresh_stack_visuals()
			_fly_item_to_temp_counter(item)
		else:
			# Temporary counter is FULL!
			if is_instance_valid(SoundManager):
				SoundManager.play_error()
			item.play_wiggle()
			_flash_temp_counter_warning()
			_check_unsolvable_game_over()

func _on_stack_item_drag_ended(item: FoodDeliveryItem, drop_pos: Vector2) -> void:
	if not is_game_active or is_paused or is_animating_move:
		item.return_to_origin()
		return

	var col_idx := _find_item_column(item)
	if col_idx == -1:
		item.return_to_origin()
		return

	var col: Array = stack_columns[col_idx]
	if col.is_empty() or col.back() != item:
		item.return_to_origin()
		return

	var box_rect := delivery_box_panel.get_global_rect()
	var temp_rect := temp_counter_panel.get_global_rect()

	# Dropped on Delivery Box
	if box_rect.has_point(drop_pos):
		if item.item_id == current_order_item and current_order_filled < 3:
			col.pop_back()
			_disconnect_stack_item_signals(item)
			_refresh_stack_visuals()
			_fly_item_to_delivery_box(item)
			return
		else:
			if is_instance_valid(SoundManager):
				SoundManager.play_error()
			item.play_wiggle()
			item.return_to_origin()
			return

	# Dropped on Temporary Counter
	elif temp_rect.has_point(drop_pos):
		if temporary_items.size() < MAX_TEMP_SLOTS:
			col.pop_back()
			_disconnect_stack_item_signals(item)
			_refresh_stack_visuals()
			_fly_item_to_temp_counter(item)
			return
		else:
			if is_instance_valid(SoundManager):
				SoundManager.play_error()
			item.play_wiggle()
			_flash_temp_counter_warning()
			item.return_to_origin()
			_check_unsolvable_game_over()
			return

	# Dropped outside target areas -> snap back to origin
	item.return_to_origin()

func _disconnect_stack_item_signals(item: FoodDeliveryItem) -> void:
	if item.clicked.is_connected(_on_stack_item_clicked):
		item.clicked.disconnect(_on_stack_item_clicked)
	if item.drag_ended.is_connected(_on_stack_item_drag_ended):
		item.drag_ended.disconnect(_on_stack_item_drag_ended)

func _disconnect_temp_item_signals(item: FoodDeliveryItem) -> void:
	if item.clicked.is_connected(_on_temp_item_clicked):
		item.clicked.disconnect(_on_temp_item_clicked)
	if item.drag_ended.is_connected(_on_temp_item_drag_ended):
		item.drag_ended.disconnect(_on_temp_item_drag_ended)

func _fly_item_to_delivery_box(item: FoodDeliveryItem) -> void:
	is_animating_move = true
	item.is_animating = true
	var start_pos := item.global_position

	item.get_parent().remove_child(item)
	flying_layer.add_child(item)
	item.global_position = start_pos
	item.z_index = 150

	var target_slot_idx := current_order_filled
	current_order_filled += 1
	var target_slot := delivery_slots[target_slot_idx]
	var target_pos := target_slot.global_position + Vector2(4, 4)

	if is_instance_valid(SoundManager):
		SoundManager.play_pickup()

	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(item, "global_position", target_pos, 0.22)
	tween.tween_property(item, "size", Vector2(72, 72), 0.22)
	tween.tween_property(item, "scale", Vector2.ONE, 0.22)

	tween.chain().tween_callback(func():
		is_animating_move = false
		item.is_animating = false
		if is_instance_valid(SoundManager):
			SoundManager.play_drop()

		item.get_parent().remove_child(item)
		target_slot.add_child(item)
		item.position = Vector2(4, 4)
		item.set_topmost(false)
		item.original_global_pos = item.global_position
		item.play_pop_in()
		delivery_slot_items.append(item)

		if current_order_filled >= 3:
			_on_delivery_box_completed()
	)

func _fly_item_to_temp_counter(item: FoodDeliveryItem) -> void:
	is_animating_move = true
	item.is_animating = true
	var start_pos := item.global_position

	item.get_parent().remove_child(item)
	flying_layer.add_child(item)
	item.global_position = start_pos
	item.z_index = 150

	var target_slot_idx := temporary_items.size()
	temporary_items.append(item)
	var target_slot := temp_slots[target_slot_idx]
	var target_pos := target_slot.global_position + Vector2(2, 2)

	if is_instance_valid(SoundManager):
		SoundManager.play_pickup()

	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(item, "global_position", target_pos, 0.20)
	tween.tween_property(item, "size", Vector2(64, 64), 0.20)
	tween.tween_property(item, "scale", Vector2.ONE, 0.20)

	tween.chain().tween_callback(func():
		is_animating_move = false
		item.is_animating = false
		if is_instance_valid(SoundManager):
			SoundManager.play_drop()

		item.get_parent().remove_child(item)
		target_slot.add_child(item)
		item.position = Vector2(2, 2)
		item.original_global_pos = item.global_position
		item.set_topmost(true)

		# Connect temporary item click and drag signals
		item.clicked.connect(_on_temp_item_clicked)
		item.drag_ended.connect(_on_temp_item_drag_ended)

		_update_temporary_counter_display()

		if temporary_items.size() >= MAX_TEMP_SLOTS:
			_check_unsolvable_game_over()
	)

func _on_temp_item_clicked(item: FoodDeliveryItem) -> void:
	if not is_game_active or is_paused or is_animating_move:
		return
	if not is_instance_valid(item) or not temporary_items.has(item):
		return

	if item.item_id == current_order_item and current_order_filled < 3:
		temporary_items.erase(item)
		_disconnect_temp_item_signals(item)
		_fly_item_to_delivery_box(item)
		_repack_temporary_slots()
	else:
		item.play_wiggle()

func _on_temp_item_drag_ended(item: FoodDeliveryItem, drop_pos: Vector2) -> void:
	if not is_game_active or is_paused or is_animating_move:
		item.return_to_origin()
		return
	if not is_instance_valid(item) or not temporary_items.has(item):
		item.return_to_origin()
		return

	var box_rect := delivery_box_panel.get_global_rect()
	if box_rect.has_point(drop_pos):
		if item.item_id == current_order_item and current_order_filled < 3:
			temporary_items.erase(item)
			_disconnect_temp_item_signals(item)
			_fly_item_to_delivery_box(item)
			_repack_temporary_slots()
			return
		else:
			if is_instance_valid(SoundManager):
				SoundManager.play_error()
			item.play_wiggle()
			item.return_to_origin()
			return

	item.return_to_origin()

func _repack_temporary_slots() -> void:
	for i in range(temporary_items.size()):
		var it := temporary_items[i]
		var target_slot := temp_slots[i]
		if it.get_parent() != target_slot:
			it.get_parent().remove_child(it)
			target_slot.add_child(it)
			it.position = Vector2(2, 2)
		it.original_global_pos = it.global_position
	_update_temporary_counter_display()

func _update_temporary_counter_display() -> void:
	var count := temporary_items.size()
	temp_slots_label.text = "Temporary Counter: %d / %d (Unmatched Foods)" % [count, MAX_TEMP_SLOTS]
	if count >= MAX_TEMP_SLOTS:
		temp_slots_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	elif count >= MAX_TEMP_SLOTS - 1:
		temp_slots_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.3))
	else:
		temp_slots_label.add_theme_color_override("font_color", Color(0.92, 0.88, 0.82))

func _flash_temp_counter_warning() -> void:
	var tween := create_tween()
	tween.tween_property(temp_counter_panel, "modulate", Color(1.3, 0.5, 0.5), 0.1)
	tween.tween_property(temp_counter_panel, "modulate", Color.WHITE, 0.15)

# =============================================================================
# ORDER COMPLETION & SOLVABILITY CHECK
# =============================================================================

func _on_delivery_box_completed() -> void:
	orders_completed_count += 1
	if is_instance_valid(SoundManager):
		SoundManager.play_merge()


	order_speech_label.text = "✅ DELIVERED! Order #%d Packed!" % orders_completed_count
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(delivery_box_panel, "scale", Vector2(1.04, 1.04), 0.15)
	tween.tween_property(delivery_box_panel, "scale", Vector2.ONE, 0.15)
	tween.tween_interval(0.3)
	tween.tween_callback(func():
		_advance_to_next_order()
	)

func _check_unsolvable_game_over() -> bool:
	if temporary_items.size() < MAX_TEMP_SLOTS:
		return false

	var needed := 3 - current_order_filled
	var available_topmost := 0
	for col in stack_columns:
		if not col.is_empty():
			var top_item: FoodDeliveryItem = col.back()
			if top_item.item_id == current_order_item:
				available_topmost += 1

	if available_topmost < needed:
		_trigger_game_over("Temporary counter is full and no accessible foods match the current delivery order!")
		return true

	return false

# =============================================================================
# WIN / GAME OVER / REWARDS
# =============================================================================

func _trigger_win() -> void:
	is_game_active = false
	if is_instance_valid(SoundManager):
		SoundManager.play_quest()


	var reward_id := _roll_random_reward()
	var reward_data := ItemDatabase.get_item(reward_id) if is_instance_valid(ItemDatabase) else null
	var reward_name := reward_data.display_name if reward_data else reward_id

	if is_instance_valid(ProgressionManager):
		ProgressionManager.push_reward(reward_id)
		ProgressionManager.unlock_delivery_level(current_level + 1)

	win_title.text = "🎉 Level %d Cleared!" % current_level
	win_reward_label.text = reward_name
	if reward_data and reward_data.icon_texture:
		win_reward_icon.texture = reward_data.icon_texture

	win_next_btn.visible = (current_level < TOTAL_LEVELS)
	if is_instance_valid(win_modal_layer):
		win_modal_layer.visible = true
	win_modal.visible = true
	win_modal.scale = Vector2(0.7, 0.7)
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(win_modal, "scale", Vector2.ONE, 0.3)
	win_particles.restart()
	win_particles.emitting = true

func _roll_random_reward() -> String:
	var roll := randf()
	if roll < 0.65:
		var consumables := [
			"exp_2", "exp_3", "exp_4",
			"gold_2", "gold_3", "gold_4",
			"energy_2", "energy_3", "energy_4",
			"diamond_1", "diamond_2"
		]
		return consumables[randi() % consumables.size()]
	else:
		var chests := [
			"chest_1", "chest_2",
			"chest_purple_1", "chest_green_1",
			"chest_yellow_1", "chest_blue_1"
		]
		return chests[randi() % chests.size()]

func _trigger_game_over(reason: String) -> void:
	if not is_game_active:
		return
	is_game_active = false
	if is_instance_valid(SoundManager):
		SoundManager.play_error()

	game_over_reason_label.text = reason
	if is_instance_valid(game_over_modal_layer):
		game_over_modal_layer.visible = true
	game_over_modal.visible = true
	game_over_modal.scale = Vector2(0.7, 0.7)
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(game_over_modal, "scale", Vector2.ONE, 0.28)

func _update_timer_display() -> void:
	var secs := int(ceil(time_remaining))
	timer_label.text = "⏱ %ds" % secs
	var pct := (time_remaining / max_time) * 100.0
	timer_bar.value = pct

	var bar_style := timer_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if bar_style:
		if pct > 45.0:
			bar_style.bg_color = Color(0.3, 0.78, 0.45)
		elif pct > 20.0:
			bar_style.bg_color = Color(0.95, 0.68, 0.22)
		else:
			bar_style.bg_color = Color(0.9, 0.32, 0.28)

# =============================================================================
# LEVEL SELECTION & NAVIGATION
# =============================================================================

func open_level_select() -> void:
	_refresh_level_grid()
	level_select_modal.visible = true

func _refresh_level_grid() -> void:
	for child in level_grid.get_children():
		child.queue_free()

	var max_unlocked := 1
	if is_instance_valid(ProgressionManager):
		max_unlocked = ProgressionManager.delivery_max_unlocked_level

	for lvl in range(1, TOTAL_LEVELS + 1):
		var is_unlocked := (lvl <= max_unlocked)
		var lvl_btn := Button.new()
		lvl_btn.custom_minimum_size = Vector2(230, 85)

		var btn_panel := PanelContainer.new()
		btn_panel.set_anchors_preset(PRESET_FULL_RECT)
		btn_panel.mouse_filter = MOUSE_FILTER_IGNORE
		lvl_btn.add_child(btn_panel)

		var lvl_vbox := VBoxContainer.new()
		lvl_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		btn_panel.add_child(lvl_vbox)

		var title_txt := "Level %d" % lvl
		if not is_unlocked:
			title_txt += " 🔒"
		else:
			title_txt += " ⭐" if lvl < max_unlocked else " ▷"

		var l_title := Label.new()
		l_title.text = title_txt
		l_title.add_theme_font_size_override("font_size", 16)
		l_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lvl_vbox.add_child(l_title)

		var lvl_info := DeliveryLevelDatabase.get_level(lvl)
		var sub_txt := "%s • %ds" % [lvl_info.get("title", ""), lvl_info.get("time_limit", 60)]
		var l_sub := Label.new()
		l_sub.text = sub_txt
		l_sub.add_theme_font_size_override("font_size", 11)
		l_sub.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		l_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lvl_vbox.add_child(l_sub)

		if is_unlocked:
			_style_button(lvl_btn, Color(0.28, 0.58, 0.42))
			lvl_btn.pressed.connect(func():
				level_select_modal.visible = false
				start_level(lvl)
			)
		else:
			_style_button(lvl_btn, Color(0.38, 0.38, 0.40))
			lvl_btn.disabled = true

		level_grid.add_child(lvl_btn)

func _on_back_pressed() -> void:
	if is_instance_valid(SoundManager):
		SoundManager.play_drop()
	exit_requested.emit()

func _on_restart_pressed() -> void:
	if is_instance_valid(SoundManager):
		SoundManager.play_click()
	start_level(current_level)

func _on_win_next_pressed() -> void:
	if is_instance_valid(win_modal_layer):
		win_modal_layer.visible = false
	win_modal.visible = false
	if current_level < TOTAL_LEVELS:
		start_level(current_level + 1)
	else:
		open_level_select()

func apply_orientation(landscape: bool) -> void:
	if landscape:
		custom_minimum_size = Vector2(1600, 900)
	else:
		custom_minimum_size = Vector2(720, 1600)
