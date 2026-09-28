class_name ThreadRollerMinigame
extends Control

## Main Controller for the Thread Rolling Minigame.
## Features modular cloth grid (multi-cell clothes), upgradeable roller station,
## capacity-based spools (default: 3 cells/seconds), in-game coin upgrades,
## FIFO roller queue, multiple progression levels, and orientation adaptability.

signal exit_requested()
signal level_completed(level_num: int, score: int)

@onready var cloth_grid: ClothGrid = $VBoxContainer/GridContainer/ClothGrid
@onready var roller_station: RollerStation = $VBoxContainer/StationContainer/RollerStation
@onready var roller_queue: RollerQueue = $VBoxContainer/QueueContainer/RollerQueue

# UI Elements
@onready var level_label: Label = $TopBar/Margin/HBox/LevelLabel
@onready var coin_label: Label = $TopBar/Margin/HBox/CoinLabel
@onready var cloth_count_label: Label = $TopBar/Margin/HBox/ClothCountLabel
@onready var score_label: Label = $TopBar/Margin/HBox/ScoreLabel
@onready var back_btn: Button = $TopBar/Margin/HBox/BackBtn

@onready var upgrade_slot_btn: Button = $ControlBar/Margin/HBox/UpgradeSlotBtn
@onready var next_level_btn: Button = $ControlBar/Margin/HBox/NextLevelBtn
@onready var restart_btn: Button = $ControlBar/Margin/HBox/RestartBtn
@onready var auto_dispatch_btn: Button = $ControlBar/Margin/HBox/AutoDispatchBtn

@onready var upgrade_modal: RollerUpgradeModal = $UpgradeModal

@onready var win_overlay: Control = $WinOverlay
@onready var win_title: Label = $WinOverlay/Panel/VBox/TitleLabel
@onready var win_next_btn: Button = $WinOverlay/Panel/VBox/HBox/NextBtn
@onready var win_replay_btn: Button = $WinOverlay/Panel/VBox/HBox/ReplayBtn

@onready var jam_toast: PanelContainer = $JamToast
@onready var jam_label: Label = $JamToast/Margin/VBox/JamLabel
@onready var jam_slot_btn: Button = $JamToast/Margin/VBox/HBox/JamSlotBtn
@onready var jam_restart_btn: Button = $JamToast/Margin/VBox/HBox/JamRestartBtn

var current_level: int = 1
var score: int = 0
var auto_dispatch: bool = false
var is_game_active: bool = false

# Progression upgrades (persist across levels during minigame play)
var purchased_slots: int = 1
var roller_capacity: int = 3 # Default: 3 seconds / 3 cells of the same color

func _ready() -> void:
	# Connect UI buttons
	if is_instance_valid(back_btn):
		back_btn.pressed.connect(_on_back_pressed)
	if is_instance_valid(upgrade_slot_btn):
		upgrade_slot_btn.pressed.connect(_on_open_upgrades_pressed)
	if is_instance_valid(next_level_btn):
		next_level_btn.pressed.connect(_on_next_level_pressed)
	if is_instance_valid(restart_btn):
		restart_btn.pressed.connect(_on_restart_pressed)
	if is_instance_valid(auto_dispatch_btn):
		auto_dispatch_btn.pressed.connect(_on_auto_dispatch_toggled)

	if is_instance_valid(win_next_btn):
		win_next_btn.pressed.connect(_on_next_level_pressed)
	if is_instance_valid(win_replay_btn):
		win_replay_btn.pressed.connect(_on_restart_pressed)

	if is_instance_valid(jam_slot_btn):
		jam_slot_btn.pressed.connect(func():
			jam_toast.visible = false
			_on_open_upgrades_pressed()
		)
	if is_instance_valid(jam_restart_btn):
		jam_restart_btn.pressed.connect(func():
			jam_toast.visible = false
			_on_restart_pressed()
		)

	# Connect Upgrade Modal
	if is_instance_valid(upgrade_modal):
		upgrade_modal.slot_upgrade_purchased.connect(_on_slot_upgraded)
		upgrade_modal.capacity_upgrade_purchased.connect(_on_capacity_upgraded)

	# Connect currency changes
	if is_instance_valid(GameEvents):
		GameEvents.currency_changed.connect(_on_currency_changed)

	# Connect minigame signals
	if is_instance_valid(roller_queue):
		roller_queue.spool_dispatched.connect(_on_spool_dispatched_from_queue)
	if is_instance_valid(roller_station):
		roller_station.slot_selected.connect(_on_slot_selected)
		roller_station.spool_docked.connect(_on_spool_docked)
		roller_station.roller_finished.connect(_on_roller_finished)
	if is_instance_valid(cloth_grid):
		cloth_grid.all_blocks_cleared.connect(_on_level_won)

	# Connect orientation if available
	if is_instance_valid(OrientationManager):
		OrientationManager.orientation_changed.connect(apply_orientation)
		apply_orientation(OrientationManager.is_landscape)

	# Start initial level
	start_level(current_level)

## Starts a given level index (1 = Sketch Reference, 2+ = Bigger & More Colorful).
func start_level(level_num: int) -> void:
	current_level = level_num
	is_game_active = true
	if is_instance_valid(win_overlay):
		win_overlay.visible = false
	if is_instance_valid(jam_toast):
		jam_toast.visible = false
	if is_instance_valid(upgrade_modal):
		upgrade_modal.visible = false

	# Setup based on level definition
	match level_num:
		1:
			# Design Sketch Reference: starts with 1 slot (or purchased_slots), multi-cell clothes, capacity 3
			_setup_sketch_reference_level()
		2:
			# 4 cols x 3 rows, 4 colors (Red, Blue, Green, Yellow)
			_setup_level(4, 3, ["red", "blue", "green", "yellow"], maxi(purchased_slots, 2))
		3:
			# 5 cols x 3 rows, 5 colors
			_setup_level(5, 3, ["red", "blue", "green", "yellow", "purple"], maxi(purchased_slots, 2))
		4:
			# 5 cols x 4 rows, 6 colors
			_setup_level(5, 4, ["red", "blue", "green", "yellow", "purple", "orange"], maxi(purchased_slots, 3))
		_:
			# Procedural scaling for higher levels
			var c := mini(4 + (level_num / 2), 6)
			var r := mini(2 + (level_num / 2), 5)
			var cols_count := mini(3 + level_num, 8)
			var colors := ThreadColorPalette.get_palette_subset(cols_count)
			_setup_level(c, r, colors, maxi(purchased_slots, mini(2 + (level_num / 3), 4)))

	_update_header_ui()

func _setup_sketch_reference_level() -> void:
	# Stacks matching sketch with varying cells (each cell represents 1 second of rolling):
	# Col 0 = Red (1x2 = 2s) & Red (1x3 = 3s)  -> 5 Red cells
	# Col 1 = Blue (1x3 = 3s) & Blue (1x3 = 3s) -> 6 Blue cells
	# Col 2 = Green (1x3 = 3s) & Green (1x3 = 3s) -> 6 Green cells
	# Col 3 = Green (1x2 = 2s) & Green (1x2 = 2s) -> 4 Green cells
	# Total Green = 10 cells -> Needs 4 Green spools (at cap 3: 3+3+3+1 = 10 cells)
	# Total Blue = 6 cells -> Needs 2 Blue spools (3+3 = 6 cells)
	# Total Red = 5 cells -> Needs 2 Red spools (3+2 = 5 cells)
	# Total Spools = 8 spools!
	var custom_stacks: Array = [
		[ {"color": "red", "rows": 1, "cols": 2}, {"color": "red", "rows": 1, "cols": 3} ],
		[ {"color": "blue", "rows": 1, "cols": 3}, {"color": "blue", "rows": 1, "cols": 3} ],
		[ {"color": "green", "rows": 1, "cols": 3}, {"color": "green", "rows": 1, "cols": 3} ],
		[ {"color": "green", "rows": 1, "cols": 2}, {"color": "green", "rows": 1, "cols": 2} ]
	]
	cloth_grid.setup_grid(4, 2, ["red", "blue", "green"], custom_stacks)

	# First section starts with 1 slot (or user's purchased slots)
	roller_station.setup_station(purchased_slots)

	# FIFO Queue matching the sketch sequence where green rolls first
	var queue_colors: Array[String] = [
		"green", "blue", "red", "blue", "green", "green", "green", "red"
	]
	roller_queue.setup_queue(queue_colors, roller_capacity)

func _setup_level(cols_cnt: int, rows_cnt: int, colors_pool: Array[String], initial_slots: int = 1) -> void:
	cloth_grid.setup_grid(cols_cnt, rows_cnt, colors_pool)
	roller_station.setup_station(maxi(purchased_slots, initial_slots))

	# Build a solvable FIFO queue calculated from cell requirements per color
	var cell_counts := cloth_grid.get_remaining_cells_by_color()
	var needed_spools: Array[String] = []

	for col_id in cell_counts.keys():
		var cells: int = cell_counts[col_id]
		var spools_count := ceili(float(cells) / float(roller_capacity))
		for i in range(spools_count):
			needed_spools.append(col_id)

	# Shuffle queue while keeping early exposed colors near the front to ensure smooth start
	var exposed := cloth_grid.get_exposed_blocks()
	var front_colors: Array[String] = []
	for eb in exposed:
		if needed_spools.has(eb.color_id):
			front_colors.append(eb.color_id)
			needed_spools.erase(eb.color_id)

	needed_spools.shuffle()
	var final_queue: Array[String] = []
	final_queue.append_array(front_colors)
	final_queue.append_array(needed_spools)

	roller_queue.setup_queue(final_queue, roller_capacity)

func _update_header_ui() -> void:
	if is_instance_valid(level_label):
		var name_suffix := " (Sketch Ref)" if current_level == 1 else ""
		level_label.text = "Level %d%s" % [current_level, name_suffix]
	if is_instance_valid(coin_label):
		var coins: int = EconomyManager.coins if is_instance_valid(EconomyManager) else 0
		coin_label.text = "🪙 %d" % coins
	if is_instance_valid(cloth_count_label):
		var left := cloth_grid.get_total_remaining_cells()
		cloth_count_label.text = "Cells: %d" % left
	if is_instance_valid(score_label):
		score_label.text = "Score: %d" % score
	if is_instance_valid(upgrade_slot_btn):
		upgrade_slot_btn.text = "⚙ Upgrades (%d)" % roller_station.max_slots
	if is_instance_valid(auto_dispatch_btn):
		auto_dispatch_btn.text = "Auto: ON" if auto_dispatch else "Auto: OFF"

## Handles a spool moving from queue into an empty roller slot.
## If no slot is free, the spool is returned to the front of the queue.
func _on_spool_dispatched_from_queue(spool: RollerSpool) -> void:
	if not is_instance_valid(spool):
		return
	var empty_slot := roller_station.get_first_empty_slot()
	if empty_slot == null:
		# No slot available — return spool back to front of queue so it isn't lost
		if is_instance_valid(roller_queue):
			roller_queue.spool_queue.push_front(spool)
			roller_queue.update_layout(true)
		return

	var from_pos := spool.global_position
	empty_slot.receive_spool(spool, from_pos)
	if is_instance_valid(SoundManager):
		SoundManager.play_click()

## Tapping an empty slot draws the next spool from the queue.
func _on_slot_selected(slot: RollerSlot) -> void:
	if not slot.is_occupied and roller_queue.has_spools():
		var spool := roller_queue.pop_front_spool()
		if spool:
			empty_slot_receive_spool(slot, spool)

func empty_slot_receive_spool(slot: RollerSlot, spool: RollerSpool) -> void:
	var from_pos := spool.global_position
	slot.receive_spool(spool, from_pos)
	if is_instance_valid(SoundManager):
		SoundManager.play_click()

## Called when a spool finishes docking firmly into a slot.
func _on_spool_docked(_slot: RollerSlot, _spool: RollerSpool) -> void:
	_check_and_roll()

## Evaluates all ready-to-roll occupied slots against exposed cloth blocks.
func _check_and_roll() -> void:
	if not is_game_active:
		return

	var ready_slots := roller_station.get_ready_to_roll_slots()
	for slot in ready_slots:
		if not is_instance_valid(slot.current_spool):
			continue

		var spool_color := slot.current_spool.color_id
		var match_cloth: BigCloth = cloth_grid.find_matching_exposed_block(spool_color)
		if match_cloth != null and not match_cloth.is_rolling:
			var available_cap := slot.current_spool.get_available_capacity()
			var target_col := cloth_grid.find_matching_col(spool_color)
			var matching_cells := match_cloth.get_consecutive_color_count(target_col, spool_color) if target_col >= 0 else 0
			var cells_to_take := mini(available_cap, matching_cells)

			if cells_to_take > 0:
				_start_slot_rolling(slot, match_cloth, target_col, cells_to_take)

	# Auto-dispatch logic: if auto is on, dispatch to any empty slot
	if auto_dispatch and roller_station.has_empty_slot() and roller_queue.has_spools():
		var spool := roller_queue.pop_front_spool()
		if spool:
			var slot := roller_station.get_first_empty_slot()
			if slot:
				empty_slot_receive_spool(slot, spool)

	# Check for jam condition
	if roller_station.is_jammed(cloth_grid):
		_on_game_jammed()
	elif is_instance_valid(jam_toast) and jam_toast.visible:
		jam_toast.visible = false

## Starts rolling cells from a BigCloth column into a slot's spool.
func _start_slot_rolling(slot: RollerSlot, cloth: BigCloth, target_col: int, cells_to_take: int) -> void:
	var spool_color := slot.current_spool.color_id

	# Mark slot as rolling visually for thread drawing
	slot.is_rolling = true
	slot.current_cloth = cloth
	slot._thread_color = ThreadColorPalette.get_thread_color(spool_color)
	slot._thread_timer = 0.0
	if is_instance_valid(slot.current_spool):
		slot.current_spool.start_spinning()
	if is_instance_valid(SoundManager):
		SoundManager.play_spawn()

	# Per-cell callback — called every 1 second as each cell is consumed
	var on_cell := func():
		if is_instance_valid(slot) and is_instance_valid(slot.current_spool):
			slot.current_spool.add_fill(1)
		if is_instance_valid(slot):
			slot.queue_redraw()

	# Called when all cells in this rolling session are consumed
	var on_done := func():
		if is_instance_valid(slot):
			slot.is_rolling = false
			slot._thread_points.clear()
			slot.current_cloth = null
			slot.queue_redraw()
		if is_instance_valid(slot) and is_instance_valid(slot.current_spool):
			slot.current_spool.stop_spinning()
			if slot.current_spool.is_full():
				_eject_full_spool(slot)

		cloth_grid.consume_block_and_apply_gravity(cloth)
		if is_instance_valid(EconomyManager):
			EconomyManager.add_coins(5)
		score += 50
		_update_header_ui()
		get_tree().create_timer(0.1).timeout.connect(_check_and_roll)

	cloth.start_column_roll(target_col, cells_to_take, slot.global_position + slot.size * 0.5, on_cell, on_done)

## Handles the arc-throw animation when a full spool is ejected from a slot.
func _eject_full_spool(slot: RollerSlot) -> void:
	var departing := slot.current_spool
	slot.current_spool = null
	slot.is_occupied = false
	slot.queue_redraw()

	var exit_dir := Vector2(1.0, -0.6) if slot.slot_id % 2 == 1 else Vector2(-1.0, -0.6)

	var top_layer: Node = get_tree().root
	var p: Node = slot.get_parent()
	while p != null:
		if p.has_method("start_level") or p is CanvasLayer or p is Window:
			top_layer = p
			break
		p = p.get_parent()

	var start_gpos := departing.global_position
	departing.get_parent().remove_child(departing)
	top_layer.add_child(departing)
	departing.global_position = start_gpos

	if is_instance_valid(SoundManager):
		SoundManager.play_drop()
	departing.animate_eject(exit_dir, func(): pass)



func _on_roller_finished(_slot: RollerSlot, _cloth: Node) -> void:
	if is_instance_valid(SoundManager):
		SoundManager.play_merge()

	_update_header_ui()

	if auto_dispatch and roller_station.has_empty_slot() and roller_queue.has_spools():
		var spool := roller_queue.pop_front_spool()
		if spool:
			var empty_slot := roller_station.get_first_empty_slot()
			if empty_slot:
				empty_slot_receive_spool(empty_slot, spool)

func _on_level_won() -> void:
	is_game_active = false
	if is_instance_valid(SoundManager):
		SoundManager.play_quest()

	# Award level-clear coins!
	if is_instance_valid(EconomyManager):
		EconomyManager.add_coins(50)

	if is_instance_valid(win_overlay):
		win_overlay.visible = true
		win_title.text = "Level %d Cleared! 🎉" % current_level

	level_completed.emit(current_level, score)
	_update_header_ui()

func _on_game_jammed() -> void:
	if is_instance_valid(jam_toast):
		jam_toast.visible = true
		jam_label.text = "No matching cloth exposed!\nUpgrade roller or restart level."

func _on_open_upgrades_pressed() -> void:
	if is_instance_valid(upgrade_modal):
		upgrade_modal.open_modal(purchased_slots, roller_capacity)

func _on_slot_upgraded(new_slots: int) -> void:
	purchased_slots = new_slots
	roller_station.upgrade_slots(purchased_slots)
	_update_header_ui()
	_check_and_roll()

func _on_capacity_upgraded(new_capacity: int) -> void:
	roller_capacity = new_capacity
	if is_instance_valid(roller_queue):
		roller_queue.update_spools_capacity(roller_capacity)
	_update_header_ui()

## Quick debug/test helper for upgrading slots directly
func _on_upgrade_slot_pressed() -> void:
	purchased_slots += 1
	roller_station.add_slot()
	if is_instance_valid(SoundManager):
		SoundManager.play_open()
	_update_header_ui()
	_check_and_roll()

func _on_next_level_pressed() -> void:
	if is_instance_valid(SoundManager):
		SoundManager.play_click()
	start_level(current_level + 1)

func _on_restart_pressed() -> void:
	if is_instance_valid(SoundManager):
		SoundManager.play_click()
	start_level(current_level)

func _on_auto_dispatch_toggled() -> void:
	auto_dispatch = not auto_dispatch
	if is_instance_valid(SoundManager):
		SoundManager.play_click()
	_update_header_ui()
	if auto_dispatch:
		_check_and_roll()

func _on_currency_changed(type: String, _new_val: int, _delta: int) -> void:
	if type == "coins":
		_update_header_ui()

func _on_back_pressed() -> void:
	if is_instance_valid(SoundManager):
		SoundManager.play_click()
	exit_requested.emit()

func apply_orientation(landscape: bool) -> void:
	var vp_size := get_viewport_rect().size if is_inside_tree() else Vector2(720, 1600)
	var content_vbox: VBoxContainer = $VBoxContainer
	if not is_instance_valid(content_vbox):
		return

	content_vbox.set_anchors_preset(Control.PRESET_TOP_LEFT)
	if landscape:
		var w: float = maxf(vp_size.x, 1280.0)
		content_vbox.offset_left = 60.0
		content_vbox.offset_top = 136.0
		content_vbox.offset_right = w - 260.0
		content_vbox.offset_bottom = vp_size.y - 30.0
		content_vbox.add_theme_constant_override("separation", 16)
	else:
		content_vbox.offset_left = 24.0
		content_vbox.offset_top = 150.0
		content_vbox.offset_right = 696.0
		content_vbox.offset_bottom = 1140.0
		content_vbox.add_theme_constant_override("separation", 20)

	if is_instance_valid(cloth_grid):
		cloth_grid.update_layout()
	if is_instance_valid(roller_station):
		roller_station.update_layout()
	if is_instance_valid(roller_queue):
		roller_queue.update_layout(false)
