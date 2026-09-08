class_name MainGame
extends Node2D

@export var floating_text_scene: PackedScene = preload("res://scenes/floating_text.tscn")

@onready var hud: HUD = $CanvasLayer/UI/HUD
@onready var quest_manager: QuestManager = $CanvasLayer/UI/QuestContainer/QuestManager
@onready var board: Board = $CanvasLayer/UI/Board
@onready var inventory_bar: InventoryBar = $CanvasLayer/UI/InventoryBar
@onready var sell_bin: Control = $CanvasLayer/UI/BottomBar/SellBin
@onready var shop_modal: ShopModal = $CanvasLayer/Modals/ShopModal
@onready var debug_menu: DebugMenu = $CanvasLayer/Modals/DebugMenu
@onready var floating_layer: Node2D = $CanvasLayer/FloatingLayer

func _ready() -> void:
	# Set references
	board.inventory_bar = inventory_bar
	board.sell_bin = sell_bin
	inventory_bar.board_ref = board
	shop_modal.board_ref = board
	debug_menu.board_ref = board
	debug_menu.quest_manager_ref = quest_manager

	# Setup Quests
	quest_manager.setup(board, inventory_bar)

	# Listen to floating text signal
	GameEvents.show_floating_text.connect(_on_show_floating_text)

	# Setup starter board
	_setup_initial_board()

func _setup_initial_board() -> void:
	board.clear_board()

	# Place primary spawners in the center
	board.spawn_item_at(Vector2i(2, 4), "plant_5") # Ancient Tree (Plant spawner)
	board.spawn_item_at(Vector2i(4, 4), "tools_5") # Toolbox (Tool spawner)

	# Place starter items ready to merge
	board.spawn_item_at(Vector2i(2, 3), "tools_1") # Wrench
	board.spawn_item_at(Vector2i(4, 3), "tools_1") # Wrench (merge -> Hammer)

	board.spawn_item_at(Vector2i(2, 5), "plant_1") # Seed
	board.spawn_item_at(Vector2i(4, 5), "plant_1") # Seed (merge -> Sprout)

	# Place consumables & rare
	board.spawn_item_at(Vector2i(3, 2), "coins_1") # Bronze coin
	board.spawn_item_at(Vector2i(3, 6), "energy_1") # Energy spark
	board.spawn_item_at(Vector2i(3, 4), "gem_1") # Gem shard

	# Put a bonus item in backpack inventory slot 0
	var inv_item: ItemView = board.item_view_scene.instantiate()
	board.items_container.add_child(inv_item)
	inv_item.setup(ItemDatabase.get_item("tools_2"))
	inventory_bar.set_item_at(0, inv_item)
	inv_item.position = inventory_bar.get_slot_center(0)

	GameEvents.board_changed.emit()
	GameEvents.inventory_changed.emit()

func _on_show_floating_text(text: String, world_pos: Vector2, color: Color) -> void:
	var ft: FloatingText = floating_text_scene.instantiate()
	floating_layer.add_child(ft)
	ft.global_position = world_pos
	ft.setup(text, color)
