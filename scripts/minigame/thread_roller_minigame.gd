class_name ThreadRollerMinigame
extends Control

## Main Controller for the Thread Rolling Minigame.
## Features modular cloth grid (multi-cell clothes), upgradeable roller station,
## capacity-based spools (default: 3 cells), in-game coin upgrades,
## JSON cloth levels, gold unlocks, and orientation adaptability.

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

const LevelLibrary = preload("res://scripts/minigame/cloth_level_library.gd")

@onready var level_select: Control = $LevelSelect
@onready var level_buttons: GridContainer = $LevelSelect/Margin/VBox/Scroll/Levels
@onready var selection_status: Label = $LevelSelect/Margin/VBox/Status
var levels: Array[Dictionary] = []
var _round_id: int = 0
var current_level: int = 1
var score: int = 0
var auto_dispatch: bool = false
var is_game_active: bool = false

# Progression upgrades (persist across levels during minigame play)
var purchased_slots: int = 3
var roller_capacity: int = 3 # Default: 3 cells of the same color

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

	levels = LevelLibrary.load_levels()
	show_level_select()

func is_level_unlocked(index: int) -> bool:
	return index == 0 or ProgressionManager.cloth_unlocked_levels.has(levels[index]["id"])

func show_level_select() -> void:
	_round_id += 1
	is_game_active = false
	cloth_grid.clear_grid()
	roller_station.clear_station()
	roller_queue.clear_queue()
	win_overlay.hide()
	jam_toast.hide()
	upgrade_modal.hide()
	$VBoxContainer.hide()
	$ControlBar.hide()
	level_select.show()
	selection_status.text = "Choose a cloth pattern. Unlock once, replay anytime."
	_refresh_level_buttons()
	_update_header_ui()

func _refresh_level_buttons() -> void:
	for child in level_buttons.get_children():
		level_buttons.remove_child(child)
		child.queue_free()
	for i in range(levels.size()):
		var unlocked := is_level_unlocked(i)
		var cost: int = levels[i]["cost"]
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 96)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_stylebox_override("normal", next_level_btn.get_theme_stylebox("normal"))
		button.add_theme_font_size_override("font_size", 20)
		button.text = "Level %d\n%s" % [i + 1, "Play" if unlocked else "Unlock · %d gold" % cost]
		button.disabled = not unlocked and EconomyManager.coins < cost
		button.pressed.connect(_on_level_selected.bind(i))
		level_buttons.add_child(button)
	if levels.is_empty():
		selection_status.text = "No valid cloth levels found."

func _on_level_selected(index: int) -> void:
	if index < 0 or index >= levels.size():
		return
	if not is_level_unlocked(index):
		var cost: int = levels[index]["cost"]
		if not EconomyManager.spend_coins(cost):
			selection_status.text = "You need %d gold to unlock this level." % cost
			return
		ProgressionManager.cloth_unlocked_levels.append(levels[index]["id"])
		if not SaveManager.save_game(false):
			ProgressionManager.cloth_unlocked_levels.erase(levels[index]["id"])
			EconomyManager.add_coins(cost)
			selection_status.text = "Could not save the unlock. Your gold was returned."
			return
	start_level(index + 1)

## Only unlocked, authored JSON levels can be started, including via replay.
func start_level(level_num: int) -> void:
	if level_num < 1 or level_num > levels.size() or not is_level_unlocked(level_num - 1):
		return
	_round_id += 1
	current_level = level_num
	score = 0
	is_game_active = true
	win_overlay.hide()
	jam_toast.hide()
	upgrade_modal.hide()
	level_select.hide()
	$VBoxContainer.show()
	$ControlBar.show()
	cloth_grid.setup_level(levels[level_num - 1]["rows"])
	roller_station.setup_station(purchased_slots)

	# Fixed queue order based on first encounters from bottom to top.
	var counts := cloth_grid.get_remaining_cells_by_color()
	var queue_colors: Array[String] = []
	var seen: Array[String] = []
	var level_rows: Array = levels[level_num - 1]["rows"]
	for r in range(level_rows.size() - 1, -1, -1):
		for cell in level_rows[r]:
			var color: String = cell["color"]
			if seen.has(color):
				continue
			seen.append(color)
	# Interleave colors so large patterns do not hide an entire color off-screen.
	while not counts.is_empty():
		for color in seen:
			if not counts.has(color):
				continue
			queue_colors.append(color)
			counts[color] -= roller_capacity
			if counts[color] <= 0:
				counts.erase(color)
	roller_queue.setup_queue(queue_colors, roller_capacity)
	_update_header_ui()
	if auto_dispatch:
		_check_and_roll()

func _update_header_ui() -> void:
	if is_instance_valid(level_label):
		level_label.text = "Cloth Levels" if level_select.visible else "Level %d" % current_level
	if is_instance_valid(coin_label):
		var coins: int = EconomyManager.coins if is_instance_valid(EconomyManager) else 0
		coin_label.text = "%d gold" % coins
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
	if not is_game_active:
		roller_queue.spool_queue.push_front(spool)
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
	if is_game_active and not slot.is_occupied and roller_queue.has_spools():
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
		if not cloth_grid.get_remaining_cells_by_color().has(spool_color):
			_eject_full_spool(slot)
			continue
		var match_cloth: BigCloth = cloth_grid.find_matching_exposed_block(spool_color)
		if match_cloth != null:
			var available_cap := slot.current_spool.get_available_capacity()
			if available_cap > 0:
				_start_slot_rolling(slot, match_cloth, available_cap)

	# Dispatch an exposed color that is not already docked, avoiding duplicate
	# idle rollers and colors that were exhausted by a capacity upgrade.
	if auto_dispatch and roller_station.has_empty_slot():
		for spool in roller_queue.spool_queue:
			if cloth_grid.find_matching_col(spool.color_id) < 0:
				continue
			var already_docked := false
			for occupied in roller_station.get_occupied_slots():
				if is_instance_valid(occupied.current_spool) and occupied.current_spool.color_id == spool.color_id:
					already_docked = true
			if not already_docked:
				roller_queue.dispatch_spool(spool)
				break

	# Check for jam condition
	if roller_station.is_jammed(cloth_grid):
		_on_game_jammed()
	elif is_instance_valid(jam_toast) and jam_toast.visible:
		jam_toast.visible = false

## Rolls one matching exposed cell; completion schedules the next row-scan step.
func _start_slot_rolling(slot: RollerSlot, cloth: BigCloth, cells_to_take: int) -> void:
	var spool_color := slot.current_spool.color_id
	var round_id := _round_id

	# Mark slot as rolling visually for thread drawing
	slot.is_rolling = true
	slot.current_cloth = cloth
	slot._thread_color = ThreadColorPalette.get_thread_color(spool_color)
	slot._thread_timer = 0.0
	if is_instance_valid(slot.current_spool):
		slot.current_spool.start_spinning()
	if is_instance_valid(SoundManager):
		SoundManager.play_spawn()

	# One completed second of rolling contributes one unit of spool fill.
	var on_cell := func():
		if round_id != _round_id:
			return
		_update_header_ui()
		if is_instance_valid(slot) and is_instance_valid(slot.current_spool):
			slot.current_spool.add_fill(1)
		if is_instance_valid(slot):
			slot.queue_redraw()

	# Called when all cells in this rolling session are consumed
	var on_done := func():
		if round_id != _round_id:
			return
		if is_instance_valid(slot):
			slot.is_rolling = false
			slot.rolling_columns.clear()
			slot._thread_paths.clear()
			slot.current_cloth = null
			slot.queue_redraw()
		if is_instance_valid(slot) and is_instance_valid(slot.current_spool):
			slot.current_spool.stop_spinning()
			if slot.current_spool.is_full() or not cloth_grid.get_remaining_cells_by_color().has(spool_color):
				_eject_full_spool(slot)

		if is_instance_valid(EconomyManager):
			EconomyManager.add_coins(5)
		score += 50
		cloth_grid.consume_block_and_apply_gravity(cloth)
		_update_header_ui()
		get_tree().create_timer(0.1).timeout.connect(func():
			if round_id == _round_id:
				_check_and_roll()
		)

	slot.rolling_columns = cloth.start_exposed_roll(spool_color, cells_to_take, slot.global_position + slot.size * 0.5, on_cell, on_done)

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
	if not is_game_active:
		return
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
	show_level_select()

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
		if level_select.visible:
			_refresh_level_buttons()

func _on_back_pressed() -> void:
	if is_instance_valid(SoundManager):
		SoundManager.play_click()
	if not level_select.visible:
		show_level_select()
	else:
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
