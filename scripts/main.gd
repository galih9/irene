class_name MainGame
extends Node2D

@export var floating_text_scene: PackedScene = preload("res://scenes/floating_text.tscn")

@onready var hud: HUD = $CanvasLayer/UI/HUD
@onready var quest_manager: QuestManager = $CanvasLayer/UI/QuestContainer/QuestManager
@onready var board: Board = $CanvasLayer/UI/Board
@onready var bottom_nav_bar: BottomNavBar = $CanvasLayer/UI/BottomNavBar
@onready var info_area: Control = $CanvasLayer/UI/BottomBar/InfoArea
@onready var info_btn: Button = $CanvasLayer/UI/BottomBar/InfoArea/Margin/HBox/InfoBtn
@onready var info_title_label: Label = $CanvasLayer/UI/BottomBar/InfoArea/Margin/HBox/TextVBox/TitleLabel
@onready var info_desc_label: Label = $CanvasLayer/UI/BottomBar/InfoArea/Margin/HBox/TextVBox/DescLabel
@onready var info_sell_btn: Button = $CanvasLayer/UI/BottomBar/InfoArea/Margin/HBox/SellBtn
@onready var progression_modal: ProgressionModal = $CanvasLayer/Modals/ProgressionModal
@onready var inventory_modal: InventoryModal = $CanvasLayer/Modals/InventoryModal
@onready var shop_modal: ShopModal = $CanvasLayer/Modals/ShopModal
@onready var debug_menu: DebugMenu = $CanvasLayer/Modals/DebugMenu
@onready var option_modal: OptionModal = $CanvasLayer/Modals/OptionModal
@onready var irene_modal: IrenePopupModal = $CanvasLayer/Modals/IrenePopupModal
@onready var irene_toast: IreneToast = $CanvasLayer/UI/IreneToast
@onready var floating_layer: Node2D = $CanvasLayer/FloatingLayer
@onready var background_rect: TextureRect = $BackgroundLayer/Background
@onready var quest_container: Control = $CanvasLayer/UI/QuestContainer
@onready var bottom_bar: Control = $CanvasLayer/UI/BottomBar

const BG_PORTRAIT = preload("res://assets/background.jpeg")
const BG_LANDSCAPE = preload("res://assets/background_landscape.jpg")

var tutorial_manager: TutorialManager = null

func _ready() -> void:
	# Set references
	board.bottom_nav_bar = bottom_nav_bar
	inventory_modal.board_ref = board
	shop_modal.board_ref = board
	debug_menu.board_ref = board
	debug_menu.quest_manager_ref = quest_manager

	# Apply initial orientation
	if is_instance_valid(OrientationManager):
		OrientationManager.orientation_changed.connect(apply_orientation)
		apply_orientation(OrientationManager.is_landscape)
	else:
		board.position.x = (720.0 - board.get_board_width()) * 0.5

	# Listen to viewport resize for dynamic responsiveness
	get_viewport().size_changed.connect(func():
		if is_inside_tree() and is_instance_valid(OrientationManager):
			apply_orientation(OrientationManager.is_landscape)
	)

	# Info Area handlers
	if is_instance_valid(info_btn):
		info_btn.pressed.connect(_on_info_btn_pressed)
	if is_instance_valid(info_sell_btn):
		info_sell_btn.pressed.connect(_on_info_sell_btn_pressed)
	GameEvents.item_selected.connect(_on_item_selected)
	_update_info_area(null)

	# Setup Quests
	quest_manager.setup(board)

	# Setup BottomNavBar reward slot
	if is_instance_valid(bottom_nav_bar):
		bottom_nav_bar.reward_slot_pressed.connect(_on_reward_slot_pressed)

	# Listen to floating text signal
	GameEvents.show_floating_text.connect(_on_show_floating_text)

	# Setup Irene Tutorial
	tutorial_manager = TutorialManager.new()
	tutorial_manager.name = "TutorialManager"
	add_child(tutorial_manager)
	tutorial_manager.setup(board, irene_modal, irene_toast, bottom_nav_bar)

	# Register with SaveManager
	SaveManager.board_ref = board
	SaveManager.quest_manager_ref = quest_manager
	SaveManager.tutorial_manager_ref = tutorial_manager
	SaveManager.is_gameplay_active = true

	# Decide whether to load saved game or setup starter board
	if SaveManager.should_load_on_start and SaveManager.has_save():
		var load_success := SaveManager.load_game(board, quest_manager)
		if not load_success:
			_setup_initial_board()
	else:
		_setup_initial_board()

	tutorial_manager.start_tutorial_if_needed()

func apply_orientation(landscape: bool) -> void:
	var vp_size := get_viewport_rect().size if is_inside_tree() else Vector2(1600.0, 900.0)
	var vp_width := maxf(vp_size.x, 1600.0) if landscape else 720.0

	# 1. Background
	if is_instance_valid(background_rect):
		background_rect.texture = BG_LANDSCAPE if landscape else BG_PORTRAIT

	# 2. Board rotation and centering
	if is_instance_valid(board):
		board.rotate_board(landscape)
		if landscape:
			board.position.x = (vp_width - board.get_board_width()) * 0.5
			board.position.y = 86.0
		else:
			board.position.x = (720.0 - board.get_board_width()) * 0.5
			board.position.y = 298.0

	# 3. Quests on the left (Landscape) vs top (Portrait)
	if is_instance_valid(quest_container) and is_instance_valid(quest_manager):
		quest_manager.set_layout_vertical(landscape)
		if landscape:
			quest_container.offset_left = 32.0
			quest_container.offset_top = 86.0
			quest_container.offset_right = 302.0
			quest_container.offset_bottom = 610.0
		else:
			quest_container.offset_left = 28.0
			quest_container.offset_top = 114.0
			quest_container.offset_right = 692.0
			quest_container.offset_bottom = 286.0

	# 4. Bottom nav on the right (Landscape) vs bottom (Portrait)
	if is_instance_valid(bottom_nav_bar):
		bottom_nav_bar.set_layout_vertical(landscape)
		if landscape:
			bottom_nav_bar.offset_left = vp_width - 240.0
			bottom_nav_bar.offset_top = 140.0
			bottom_nav_bar.offset_right = vp_width - 40.0
			bottom_nav_bar.offset_bottom = 560.0
		else:
			bottom_nav_bar.offset_left = 28.0
			bottom_nav_bar.offset_top = 1166.0
			bottom_nav_bar.offset_right = 692.0
			bottom_nav_bar.offset_bottom = 1282.0

	# 5. Bottom information area
	if is_instance_valid(bottom_bar):
		if landscape:
			var info_width := 720.0
			bottom_bar.offset_left = (vp_width - info_width) * 0.5
			bottom_bar.offset_top = 672.0
			bottom_bar.offset_right = bottom_bar.offset_left + info_width
			bottom_bar.offset_bottom = 768.0
		else:
			bottom_bar.offset_left = 28.0
			bottom_bar.offset_top = 1296.0
			bottom_bar.offset_right = 692.0
			bottom_bar.offset_bottom = 1394.0

	# 6. Top HUD
	if is_instance_valid(hud):
		hud.set_landscape(landscape)

	# 7. Irene toast on top
	if is_instance_valid(irene_toast):
		irene_toast.set_landscape(landscape)

func _exit_tree() -> void:
	if SaveManager:
		SaveManager.is_gameplay_active = false
		if SaveManager.board_ref == board:
			SaveManager.board_ref = null
		if SaveManager.quest_manager_ref == quest_manager:
			SaveManager.quest_manager_ref = null
		if SaveManager.tutorial_manager_ref == tutorial_manager:
			SaveManager.tutorial_manager_ref = null

func _get_tiered_drop(dist: float) -> String:
	var prefix := "egg" if randf() < 0.5 else "leaf"
	var tier := 1
	if dist > 1.5:
		tier = 2 if randf() < 0.85 else 1
	else:
		tier = 1 if randf() < 0.85 else 2
	return "%s_%d" % [prefix, tier]

func _setup_initial_board() -> void:
	board.clear_board(false)

	var boxed_pool := [
		"beef_1", "beef_2", "cake_1", "cake_2",
		"sandwich_1", "sandwich_2", "drink_1", "drink_2",
		"util_1", "util_2", "oven_1", "fridge_1", "rack_1",
		"egg_2", "leaf_2", "egg_3", "leaf_3"
	]

	var is_ls := (board.cols == 9 and board.rows == 7)
	var center_coord := Vector2i(4, 3) if is_ls else Vector2i(3, 4)

	var portrait_previews := {
		Vector2i(1, 2): "oven_1",
		Vector2i(5, 2): "fridge_1",
		Vector2i(3, 6): "rack_1"
	}
	var previews: Dictionary = {}
	for p_coord in portrait_previews:
		var target_coord: Vector2i = board.map_coord_for_orientation(p_coord, true) if is_ls else p_coord
		previews[target_coord] = portrait_previews[p_coord]

	# Starter 3x3 Active Zone
	var portrait_starter_cells := {
		Vector2i(3, 4): {"id": "foodbox_1", "state": ItemView.ItemState.NORMAL},
		Vector2i(2, 4): {"id": "foodbox_1", "state": ItemView.ItemState.LOCKED},
		Vector2i(4, 4): {"id": "foodbox_2", "state": ItemView.ItemState.LOCKED},
		Vector2i(3, 3): {"id": "egg_1", "state": ItemView.ItemState.LOCKED},
		Vector2i(3, 5): {"id": "leaf_1", "state": ItemView.ItemState.LOCKED},
		Vector2i(2, 3): {"id": "leaf_1", "state": ItemView.ItemState.LOCKED},
		Vector2i(4, 3): {"id": "egg_1", "state": ItemView.ItemState.LOCKED},
		Vector2i(2, 5): {"id": "egg_2", "state": ItemView.ItemState.LOCKED},
		Vector2i(4, 5): {"id": "leaf_2", "state": ItemView.ItemState.LOCKED},
	}
	var mapped_starter_cells: Dictionary = {}
	for p_coord in portrait_starter_cells:
		var target_coord: Vector2i = board.map_coord_for_orientation(p_coord, true) if is_ls else p_coord
		mapped_starter_cells[target_coord] = portrait_starter_cells[p_coord]

	# Populate Board
	for c in range(board.cols):
		for r in range(board.rows):
			var cur_coord := Vector2i(c, r)
			var is_perimeter: bool = false
			var req_level := 2

			if is_ls:
				is_perimeter = (r == 0 or r == 6 or c == 0 or c == 1 or c == 7 or c == 8)
				if r == 0 or r == 6:
					req_level = 4 if (c >= 3 and c <= 5) else 5
				elif c == 0 or c == 8:
					req_level = 3
				elif c == 1 or c == 7:
					req_level = 2 if (r >= 2 and r <= 4) else 3
			else:
				is_perimeter = (r == 0 or r == 1 or r == 7 or r == 8 or c == 0 or c == 6)
				if r == 0 or r == 8:
					req_level = 4 if (c == 2 or c == 3 or c == 4) else 5
				elif r == 1 or r == 7:
					req_level = 3
				elif c == 0 or c == 6:
					req_level = 2 if (r >= 3 and r <= 5) else 3

			if mapped_starter_cells.has(cur_coord):
				var cell_info: Dictionary = mapped_starter_cells[cur_coord]
				board.spawn_item_at(cur_coord, cell_info["id"], cell_info["state"])
			elif is_perimeter:
				var rand_item: String = boxed_pool[randi() % boxed_pool.size()]
				board.spawn_item_at(cur_coord, rand_item, ItemView.ItemState.HIDDEN, req_level)
			else:
				if previews.has(cur_coord):
					board.spawn_item_at(cur_coord, previews[cur_coord], ItemView.ItemState.HIDDEN, 1)
				else:
					var dist: float = Vector2(c, r).distance_to(Vector2(center_coord))
					var drop_item: String = _get_tiered_drop(dist)
					board.spawn_item_at(cur_coord, drop_item, ItemView.ItemState.HIDDEN, 1)

	board.update_all_cells_lock_visuals()

	# Clean initial backpack inventory
	InventoryManager.clear_all()

	# Register starter discovery
	ProgressionManager.unlock_item("foodbox_1", true)

	GameEvents.board_changed.emit()
	GameEvents.inventory_changed.emit()

func _on_show_floating_text(text: String, world_pos: Vector2, color: Color) -> void:
	var ft: FloatingText = floating_text_scene.instantiate()
	floating_layer.add_child(ft)
	ft.global_position = world_pos
	ft.setup(text, color)

func _on_reward_slot_pressed() -> void:
	if not is_instance_valid(board) or not is_instance_valid(bottom_nav_bar):
		return
	if not ProgressionManager.has_pending_rewards():
		return

	var empty_cells := board.get_empty_cells()
	if empty_cells.is_empty():
		SoundManager.play_error()
		bottom_nav_bar.animate_reward_wobble()
		var btn_pos := bottom_nav_bar.get_reward_button_pos()
		GameEvents.show_floating_text.emit("Board is Full!", btn_pos + Vector2(0, -35), Color(1.0, 0.45, 0.45))
		GameEvents.board_full_attempted.emit()
		return

	var reward_id := ProgressionManager.pop_reward()
	if reward_id.is_empty():
		return

	var target_cell := empty_cells[0]
	var btn_pos := bottom_nav_bar.get_reward_button_pos()
	board.spawn_item_flight(btn_pos, target_cell, reward_id)
	SoundManager.play_spawn()

	var item_data := ItemDatabase.get_item(reward_id)
	var item_name := item_data.display_name if item_data else reward_id
	GameEvents.show_floating_text.emit("Placed %s!" % item_name, btn_pos + Vector2(0, -35), Color(0.4, 1.0, 0.5))

func _on_item_selected(item_view: Node) -> void:
	_update_info_area(item_view)

func _update_info_area(item_view: Node) -> void:
	if not is_instance_valid(info_area):
		return

	if item_view == null or not is_instance_valid(item_view):
		info_title_label.text = "Select Item"
		info_desc_label.text = "Tap any item on the board to view info"
		info_btn.disabled = true
		info_btn.visible = false
		info_sell_btn.disabled = true
		info_sell_btn.visible = false
		return

	var item: ItemView = item_view as ItemView
	if not item or not item.data:
		return

	info_btn.visible = true
	info_btn.disabled = false

	if item.is_boxed():
		info_title_label.text = "Mystery Box"
		info_desc_label.text = "Unlocks at Player Level %d. Level up to open!" % item.unlock_level
		info_sell_btn.visible = false
		info_sell_btn.disabled = true
	elif item.is_locked():
		info_title_label.text = "Locked %s" % item.data.display_name
		info_desc_label.text = "Merge with another %s to unlock it!" % item.data.display_name
		info_sell_btn.visible = false
		info_sell_btn.disabled = true
	else:
		info_title_label.text = item.data.display_name
		info_desc_label.text = item.data.description
		info_sell_btn.visible = true
		info_sell_btn.disabled = false
		info_sell_btn.text = "$ %d" % item.data.sell_value

func _on_info_btn_pressed() -> void:
	SoundManager.play_click()
	if board and is_instance_valid(board.selected_item) and board.selected_item.data:
		var chain_id: String = board.selected_item.data.chain_id
		progression_modal.open_modal()
		if progression_modal.has_method("focus_chain"):
			progression_modal.focus_chain(chain_id)
	else:
		progression_modal.open_modal()

func _on_info_sell_btn_pressed() -> void:
	if board and is_instance_valid(board):
		board.sell_selected_item()
