class_name DebugMenu
extends Control

var board_ref: Board = null
var quest_manager_ref: QuestManager = null

@onready var close_btn: Button = $Panel/Margin/VBox/Header/CloseBtn
@onready var add_coins_btn: Button = $Panel/Margin/VBox/Scroll/Content/EcoGrid/AddCoinsBtn
@onready var add_gems_btn: Button = $Panel/Margin/VBox/Scroll/Content/EcoGrid/AddGemsBtn
@onready var add_energy_btn: Button = $Panel/Margin/VBox/Scroll/Content/EcoGrid/AddEnergyBtn
@onready var add_exp_btn: Button = $Panel/Margin/VBox/Scroll/Content/EcoGrid/AddExpBtn
@onready var inf_energy_check: CheckBox = $Panel/Margin/VBox/Scroll/Content/InfEnergyCheck

@onready var clear_board_btn: Button = $Panel/Margin/VBox/Scroll/Content/BoardGrid/ClearBtn
@onready var fill_board_btn: Button = $Panel/Margin/VBox/Scroll/Content/BoardGrid/FillBtn
@onready var complete_quest_btn: Button = $Panel/Margin/VBox/Scroll/Content/QuestBtn

@onready var spawn_items_container: HFlowContainer = $Panel/Margin/VBox/Scroll/Content/SpawnItemsContainer

func _ready() -> void:
	visible = false
	GameEvents.request_debug_toggle.connect(toggle_menu)
	close_btn.pressed.connect(toggle_menu)

	add_coins_btn.pressed.connect(func(): EconomyManager.add_coins(250))
	add_gems_btn.pressed.connect(func(): EconomyManager.add_gems(50))
	add_energy_btn.pressed.connect(func(): EconomyManager.add_energy(50))
	if has_node("Panel/Margin/VBox/Scroll/Content/EcoGrid/AddExpBtn"):
		add_exp_btn.pressed.connect(func(): ProgressionManager.add_exp(50))

	inf_energy_check.toggled.connect(func(toggled: bool):
		EconomyManager.infinite_energy = toggled
	)

	clear_board_btn.pressed.connect(func():
		if board_ref:
			board_ref.clear_board()
	)

	fill_board_btn.pressed.connect(func():
		if board_ref:
			board_ref.fill_board_random()
	)

	complete_quest_btn.pressed.connect(func():
		if quest_manager_ref:
			quest_manager_ref.complete_active_quest_debug()
	)

	_populate_spawn_buttons()

func toggle_menu() -> void:
	visible = not visible
	if visible:
		scale = Vector2(0.95, 0.95)
		var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", Vector2.ONE, 0.15)

func _populate_spawn_buttons() -> void:
	for child in spawn_items_container.get_children():
		child.queue_free()

	var all_items := ItemDatabase.get_all_items()
	for it in all_items:
		var item_data: ItemData = it
		var btn := Button.new()
		btn.text = "%s (T%d)" % [item_data.display_name, item_data.tier]
		btn.add_theme_font_size_override("font_size", 12)
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.add_theme_color_override("font_outline_color", Color(0.15, 0.1, 0.08, 0.75))
		btn.add_theme_constant_override("outline_size", 1)
		btn.custom_minimum_size = Vector2(130, 36)

		var style := StyleBoxFlat.new()
		style.bg_color = item_data.color * 0.7
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_right = 6
		style.corner_radius_bottom_left = 6
		btn.add_theme_stylebox_override("normal", style)

		btn.pressed.connect(func():
			_spawn_item_debug(item_data.id)
		)

		spawn_items_container.add_child(btn)

func _spawn_item_debug(item_id: String) -> void:
	if not board_ref:
		return
	var empty := board_ref.get_empty_cells()
	if empty.is_empty():
		SoundManager.play_error()
		GameEvents.show_floating_text.emit("Board is Full!", global_position + Vector2(330, 400), Color.RED)
		return
	var coord := empty[0]
	board_ref.spawn_item_at(coord, item_id)
	SoundManager.play_spawn()
