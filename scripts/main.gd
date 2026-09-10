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

	# Decide whether to load saved game or setup starter board
	if SaveManager.should_load_on_start and SaveManager.has_save():
		var load_success := SaveManager.load_game(board, quest_manager)
		if not load_success:
			_setup_initial_board()
	else:
		_setup_initial_board()

func _exit_tree() -> void:
	if SaveManager:
		SaveManager.is_gameplay_active = false
		if SaveManager.board_ref == board:
			SaveManager.board_ref = null
		if SaveManager.quest_manager_ref == quest_manager:
			SaveManager.quest_manager_ref = null

func _setup_initial_board() -> void:
	board.clear_board()

	# Place primary spawners in the center
	board.spawn_item_at(Vector2i(2, 4), "foodbox_1") # Foodbox (Eggs & Leafs)
	board.spawn_item_at(Vector2i(3, 4), "oven_1")    # Oven (Beef, Cake, Sandwich)
	board.spawn_item_at(Vector2i(2, 5), "fridge_1")  # Fridge (Drink)
	board.spawn_item_at(Vector2i(3, 5), "rack_1")    # Rack (Utils)

	# Place starter items ready to merge
	board.spawn_item_at(Vector2i(1, 3), "egg_1")      # Fresh Egg
	board.spawn_item_at(Vector2i(4, 3), "egg_1")      # Fresh Egg (merge -> Double Eggs)

	board.spawn_item_at(Vector2i(1, 4), "leaf_1")     # Fresh Herb
	board.spawn_item_at(Vector2i(4, 4), "leaf_1")     # Fresh Herb (merge -> Crisp Celery)

	board.spawn_item_at(Vector2i(1, 5), "cake_1")     # Cupcake
	board.spawn_item_at(Vector2i(4, 5), "cake_1")     # Cupcake (merge -> Berry Tart)

	board.spawn_item_at(Vector2i(1, 6), "sandwich_1") # Toast Slice
	board.spawn_item_at(Vector2i(4, 6), "sandwich_1") # Toast Slice (merge -> Buttered Bread)

	# Place consumables
	board.spawn_item_at(Vector2i(2, 2), "gold_1")     # Gold
	board.spawn_item_at(Vector2i(3, 2), "energy_1")   # Energy
	board.spawn_item_at(Vector2i(2, 6), "exp_1")      # EXP Spark
	board.spawn_item_at(Vector2i(3, 6), "diamond_1")  # Diamond Shard

	# Put a starter bonus item in backpack inventory slot
	InventoryManager.clear_all()
	InventoryManager.add_item("beef_1")
	ProgressionManager.unlock_item("beef_1", true)

	GameEvents.board_changed.emit()
	GameEvents.inventory_changed.emit()

func _on_show_floating_text(text: String, world_pos: Vector2, color: Color) -> void:
	var ft: FloatingText = floating_text_scene.instantiate()
	floating_layer.add_child(ft)
	ft.global_position = world_pos
	ft.setup(text, color)
