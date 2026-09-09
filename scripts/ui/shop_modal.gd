class_name ShopModal
extends Control

var board_ref: Board = null

@onready var close_btn: Button = $Panel/VBox/Header/CloseBtn
@onready var items_container: VBoxContainer = $Panel/VBox/Scroll/ItemsContainer

func _ready() -> void:
	visible = false
	close_btn.pressed.connect(close_shop)
	GameEvents.request_shop_open.connect(open_shop)
	_setup_shop_items()

func open_shop() -> void:
	visible = true
	scale = Vector2(0.9, 0.9)
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.2)

func close_shop() -> void:
	SoundManager.play_drop()
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.15)
	tween.finished.connect(func(): visible = false)

func _setup_shop_items() -> void:
	for child in items_container.get_children():
		child.queue_free()

	# --- 1. RANDOM ITEM CRATES (GOLD / COINS) ---
	_add_category_header("🎲 RANDOM ITEM CRATES (GOLD)")

	_add_shop_entry("🎲 Random Tier 1 Item", "Spawns a random starter Tool, Plant, Egg, or Herb!", "coins", 25, func():
		var pool := ["tools_1", "plant_1", "gem_1", "egg_1", "leaf_1"]
		var picked: String = pool[randi() % pool.size()]
		_spawn_reward_on_board(picked)
	, true)

	_add_shop_entry("🎁 Mystery Surprise Crate", "Spawns a random Tier 1-2 item or currency pouch!", "coins", 50, func():
		var pool := ["tools_2", "plant_2", "gem_2", "coins_2", "energy_2", "tools_1", "plant_1", "egg_1", "egg_2", "leaf_1", "leaf_2"]
		var picked: String = pool[randi() % pool.size()]
		_spawn_reward_on_board(picked)
	, true)

	_add_shop_entry("⭐ Lucky High-Tier Chest", "Spawns a valuable Tier 2-3 item directly on board!", "coins", 90, func():
		var pool := ["tools_3", "plant_3", "gem_3", "coins_3", "energy_3", "egg_3", "leaf_3", "tools_2", "plant_2"]
		var picked: String = pool[randi() % pool.size()]
		_spawn_reward_on_board(picked)
	, true)

	# --- 2. ENERGY REFILLS (GOLD / COINS) ---
	_add_category_header("⚡ ENERGY PURCHASES (GOLD)")

	_add_shop_entry("⚡ Quick Spark (+25 Energy)", "Restores 25 Energy to keep merging!", "coins", 20, func():
		EconomyManager.add_energy(25)
		GameEvents.show_floating_text.emit("+25 Energy! ⚡", global_position + Vector2(310, 360), Color(0.3, 1.0, 0.5))
	, false)

	_add_shop_entry("⚡ Energy Surge (+60 Energy)", "Great value! Restores 60 Energy instantly.", "coins", 45, func():
		EconomyManager.add_energy(60)
		GameEvents.show_floating_text.emit("+60 Energy! ⚡", global_position + Vector2(310, 360), Color(0.3, 1.0, 0.5))
	, false)

	_add_shop_entry("⚡ Maximum Charge (+100 Energy)", "Completely refills your entire energy tank!", "coins", 70, func():
		EconomyManager.add_energy(100)
		GameEvents.show_floating_text.emit("+100 Max Energy! ⚡", global_position + Vector2(310, 360), Color(0.3, 1.0, 0.5))
	, false)

	# --- 3. SPECIFIC ITEMS & DAILY FREE ---
	_add_category_header("🌱 DIRECT SUPPLIES & GIFTS")

	_add_shop_entry("🥚 Fresh Egg (T1)", "Spawns a fresh farm egg.", "coins", 15, func():
		_spawn_reward_on_board("egg_1")
	, true)

	_add_shop_entry("🥬 Fresh Herb (T1)", "Spawns a garden culinary herb.", "coins", 15, func():
		_spawn_reward_on_board("leaf_1")
	, true)

	_add_shop_entry("🔧 Starter Wrench (T1)", "Spawns a Tier 1 Wrench.", "coins", 15, func():
		_spawn_reward_on_board("tools_1")
	, true)

	_add_shop_entry("🌱 Starter Seed (T1)", "Spawns a Tier 1 Seed.", "coins", 15, func():
		_spawn_reward_on_board("plant_1")
	, true)

	_add_shop_entry("💎 Rare Crystal Shard (T1)", "Spawns a shining crystal shard.", "gems", 4, func():
		_spawn_reward_on_board("gem_1")
	, true)

	_add_shop_entry("🌟 Free Daily Energy (+25)", "A daily gift to keep you going!", "free", 0, func():
		EconomyManager.add_energy(25)
		GameEvents.show_floating_text.emit("+25 Free Energy! ⚡", global_position + Vector2(310, 360), Color(0.3, 1.0, 0.5))
	, false)

func _add_category_header(title: String) -> void:
	var lbl := Label.new()
	lbl.text = title
	lbl.add_theme_color_override("font_color", Color(0.5, 0.75, 1.0))
	lbl.add_theme_font_size_override("font_size", 12)
	items_container.add_child(lbl)

func _add_shop_entry(title: String, desc: String, cost_type: String, cost_amount: int, on_buy: Callable, requires_board_space: bool) -> void:
	var row := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.17, 0.23, 0.95)
	style.border_color = Color(0.25, 0.32, 0.42, 0.7)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	row.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.add_child(hbox)
	row.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var lbl_title := Label.new()
	lbl_title.text = title
	lbl_title.add_theme_color_override("font_color", Color(0.95, 0.95, 0.98))
	lbl_title.add_theme_font_size_override("font_size", 14)

	var lbl_desc := Label.new()
	lbl_desc.text = desc
	lbl_desc.add_theme_color_override("font_color", Color(0.65, 0.7, 0.8))
	lbl_desc.add_theme_font_size_override("font_size", 11)

	vbox.add_child(lbl_title)
	vbox.add_child(lbl_desc)
	hbox.add_child(vbox)

	var buy_btn := Button.new()
	buy_btn.custom_minimum_size = Vector2(92, 40)
	buy_btn.add_theme_font_size_override("font_size", 12)

	var btn_style := StyleBoxFlat.new()
	btn_style.corner_radius_top_left = 8
	btn_style.corner_radius_top_right = 8
	btn_style.corner_radius_bottom_right = 8
	btn_style.corner_radius_bottom_left = 8

	if cost_type == "coins":
		buy_btn.text = "🪙 %d" % cost_amount
		btn_style.bg_color = Color(0.85, 0.65, 0.15)
	elif cost_type == "gems":
		buy_btn.text = "💎 %d" % cost_amount
		btn_style.bg_color = Color(0.2, 0.65, 0.85)
	else:
		buy_btn.text = "FREE!"
		btn_style.bg_color = Color(0.25, 0.75, 0.35)

	buy_btn.add_theme_stylebox_override("normal", btn_style)
	buy_btn.add_theme_stylebox_override("hover", btn_style)

	buy_btn.pressed.connect(func():
		_handle_purchase(cost_type, cost_amount, on_buy, requires_board_space)
	)

	hbox.add_child(buy_btn)
	items_container.add_child(row)

func _handle_purchase(cost_type: String, cost_amount: int, on_buy: Callable, requires_board_space: bool) -> void:
	if requires_board_space:
		if not board_ref or board_ref.get_empty_cells().is_empty():
			SoundManager.play_error()
			GameEvents.show_floating_text.emit("Board is Full! ⚠️", global_position + Vector2(310, 360), Color(1.0, 0.4, 0.4))
			return

	if cost_type == "coins":
		if not EconomyManager.spend_coins(cost_amount):
			SoundManager.play_error()
			GameEvents.show_floating_text.emit("Not enough Coins!", global_position + Vector2(310, 360), Color(1.0, 0.4, 0.4))
			return
	elif cost_type == "gems":
		if not EconomyManager.spend_gems(cost_amount):
			SoundManager.play_error()
			GameEvents.show_floating_text.emit("Not enough Gems!", global_position + Vector2(310, 360), Color(1.0, 0.4, 0.4))
			return

	SoundManager.play_consume()
	on_buy.call()

func _spawn_reward_on_board(item_id: String) -> void:
	if not board_ref:
		return
	var empty_cells := board_ref.get_empty_cells()
	if empty_cells.is_empty():
		return

	var coord := empty_cells[randi() % empty_cells.size()]
	board_ref.spawn_item_flight(global_position + Vector2(310, 360), coord, item_id)
