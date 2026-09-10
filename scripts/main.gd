class_name MainGame
extends Node2D

@export var floating_text_scene: PackedScene = preload("res://scenes/floating_text.tscn")

@onready var hud: HUD = $CanvasLayer/UI/HUD
@onready var quest_manager: QuestManager = $CanvasLayer/UI/QuestContainer/QuestManager
@onready var board: Board = $CanvasLayer/UI/Board
@onready var bottom_nav_bar: BottomNavBar = $CanvasLayer/UI/BottomNavBar
@onready var sell_bin: Control = $CanvasLayer/UI/BottomBar/SellBin
@onready var progression_modal: ProgressionModal = $CanvasLayer/Modals/ProgressionModal
@onready var inventory_modal: InventoryModal = $CanvasLayer/Modals/InventoryModal
@onready var shop_modal: ShopModal = $CanvasLayer/Modals/ShopModal
@onready var debug_menu: DebugMenu = $CanvasLayer/Modals/DebugMenu
@onready var option_modal: OptionModal = $CanvasLayer/Modals/OptionModal
@onready var floating_layer: Node2D = $CanvasLayer/FloatingLayer

@export_group("UI Theme Styling")
@export var match_board_color: bool = true
@export var custom_button_color: Color = Color.TRANSPARENT
@export var custom_button_border_color: Color = Color.TRANSPARENT
@export var custom_container_color: Color = Color.TRANSPARENT
@export var custom_container_border_color: Color = Color.TRANSPARENT
@export var custom_shop_btn_color: Color = Color.TRANSPARENT
@export var custom_inventory_btn_color: Color = Color.TRANSPARENT
@export var custom_progression_btn_color: Color = Color.TRANSPARENT
@export var custom_guide_container_color: Color = Color.TRANSPARENT
@export var custom_sell_bin_color: Color = Color.TRANSPARENT

func _ready() -> void:
	# Center the board horizontally based on current columns and cell size
	board.position.x = (720.0 - board.get_board_width()) * 0.5

	# Set references
	board.bottom_nav_bar = bottom_nav_bar
	board.sell_bin = sell_bin
	inventory_modal.board_ref = board
	shop_modal.board_ref = board
	debug_menu.board_ref = board
	debug_menu.quest_manager_ref = quest_manager

	# Setup Quests
	quest_manager.setup(board)

	# Listen to floating text signal
	GameEvents.show_floating_text.connect(_on_show_floating_text)

	# Register with SaveManager
	SaveManager.board_ref = board
	SaveManager.quest_manager_ref = quest_manager
	SaveManager.is_gameplay_active = true

	# Apply UI Theme Colors
	apply_ui_styling()

	# Decide whether to load saved game or setup starter board
	if SaveManager.should_load_on_start and SaveManager.has_save():
		var load_success := SaveManager.load_game(board, quest_manager)
		if not load_success:
			_setup_initial_board()
	else:
		_setup_initial_board()

func apply_ui_styling() -> void:
	var base_bg: Color = board.board_bg_color if is_instance_valid(board) else Color(0.827, 0.341, 0, 0.74)
	var base_border: Color = board.board_border_color if is_instance_valid(board) else Color(0.827, 0.341, 0, 1.0)

	var btn_bg: Color = custom_button_color if custom_button_color.a > 0.0 else base_bg
	var btn_border: Color = custom_button_border_color if custom_button_border_color.a > 0.0 else base_border
	var cont_bg: Color = custom_container_color if custom_container_color.a > 0.0 else base_bg
	var cont_border: Color = custom_container_border_color if custom_container_border_color.a > 0.0 else base_border

	var shop_col: Color = custom_shop_btn_color if custom_shop_btn_color.a > 0.0 else btn_bg
	var inv_col: Color = custom_inventory_btn_color if custom_inventory_btn_color.a > 0.0 else btn_bg
	var prog_col: Color = custom_progression_btn_color if custom_progression_btn_color.a > 0.0 else btn_bg
	var guide_col: Color = custom_guide_container_color if custom_guide_container_color.a > 0.0 else cont_bg
	var sell_col: Color = custom_sell_bin_color if custom_sell_bin_color.a > 0.0 else cont_bg

	# Style BottomNavBar buttons
	if is_instance_valid(bottom_nav_bar):
		bottom_nav_bar.apply_custom_colors(shop_col, inv_col, prog_col, btn_border)

	# Style HUD buttons and containers
	if is_instance_valid(hud):
		hud.apply_custom_colors(shop_col, cont_bg, cont_border)

	# Style Guide Container (HelpBar)
	var help_bar: Panel = get_node_or_null("CanvasLayer/UI/HelpBar")
	if is_instance_valid(help_bar):
		var hsb := StyleBoxFlat.new()
		hsb.bg_color = guide_col
		hsb.border_color = cont_border
		hsb.border_width_left = 2
		hsb.border_width_top = 2
		hsb.border_width_right = 2
		hsb.border_width_bottom = 2
		hsb.corner_radius_top_left = 12
		hsb.corner_radius_top_right = 12
		hsb.corner_radius_bottom_right = 12
		hsb.corner_radius_bottom_left = 12
		help_bar.add_theme_stylebox_override("panel", hsb)

	# Style SellBin
	if is_instance_valid(sell_bin) and sell_bin is Panel:
		var ssb := StyleBoxFlat.new()
		ssb.bg_color = sell_col
		ssb.border_color = cont_border
		ssb.border_width_left = 2
		ssb.border_width_top = 2
		ssb.border_width_right = 2
		ssb.border_width_bottom = 2
		ssb.corner_radius_top_left = 12
		ssb.corner_radius_top_right = 12
		ssb.corner_radius_bottom_right = 12
		ssb.corner_radius_bottom_left = 12
		sell_bin.add_theme_stylebox_override("panel", ssb)

func _exit_tree() -> void:
	if SaveManager:
		SaveManager.is_gameplay_active = false
		if SaveManager.board_ref == board:
			SaveManager.board_ref = null
		if SaveManager.quest_manager_ref == quest_manager:
			SaveManager.quest_manager_ref = null

func _setup_initial_board() -> void:
	board.clear_board()

	var boxed_pool := [
		"beef_1", "beef_2", "cake_1", "cake_2",
		"sandwich_1", "sandwich_2", "drink_1", "drink_2",
		"util_1", "util_2", "gold_1", "energy_1", "exp_1", "diamond_1"
	]

	var food_drops := [
		"egg_1", "egg_2", "leaf_1", "leaf_2"
	]

	# 1. Populate Board (7 columns x 9 rows: cols 0..6, rows 0..8)
	for c in range(board.cols):
		for r in range(board.rows):
			# Determine if this coordinate is Perimeter (RED / BOXED)
			var is_perimeter: bool = (r == 0 or r == 1 or r == 7 or r == 8 or c == 0 or c == 6)

			if is_perimeter:
				# Outer ring level requirements: Lv. 2 for inner edge, Lv. 3-5 for outer
				var req_level := 2
				if r == 0 or r == 8:
					req_level = 4 if (c == 2 or c == 3 or c == 4) else 5
				elif r == 1 or r == 7:
					req_level = 3
				elif c == 0 or c == 6:
					req_level = 2 if (r >= 3 and r <= 5) else 3

				var rand_item: String = boxed_pool[randi() % boxed_pool.size()]
				board.spawn_item_at(Vector2i(c, r), rand_item, ItemView.ItemState.BOXED, req_level)
			else:
				# Inner 5x5 Area (cols 1..5, rows 2..6)
				if r == 4 and c == 3:
					# Center: Scripted Normal Tier 1 Foodbox (GREEN)
					board.spawn_item_at(Vector2i(3, 4), "foodbox_1", ItemView.ItemState.NORMAL)
				elif r == 4 and c == 2:
					# Center Left: Scripted Locked Tier 1 Foodbox (ORANGE)
					board.spawn_item_at(Vector2i(2, 4), "foodbox_1", ItemView.ItemState.LOCKED)
				elif r == 4 and c == 4:
					# Center Right: Scripted Locked Tier 2 Foodbox (ORANGE)
					board.spawn_item_at(Vector2i(4, 4), "foodbox_2", ItemView.ItemState.LOCKED)
				else:
					# Nearby locked items: food producer drops (eggs, leafs) with random tiers
					# so the player can merge what the crafted food spawner drops and unlock empty slots!
					var drop_item: String = food_drops[randi() % food_drops.size()]
					board.spawn_item_at(Vector2i(c, r), drop_item, ItemView.ItemState.LOCKED)

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
