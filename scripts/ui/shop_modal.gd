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

	# --- 1. RANDOM ITEM CRATES (GOLD) ---
	_add_category_header("RANDOM ITEM CRATES (GOLD)")

	_add_shop_entry("Starter Produce Crate", "Spawns a random starter Egg, Herb, Meat, Cake, or Utensil!", "coins", 25, func():
		var pool := ["egg_1", "leaf_1", "beef_1", "cake_1", "sandwich_1", "drink_1", "util_1"]
		var picked: String = pool[randi() % pool.size()]
		_spawn_reward_on_board(picked)
	, true)

	_add_shop_entry("Mystery Kitchen Crate", "Spawns a Tier 1-2 kitchen item, producer, or currency pouch!", "coins", 50, func():
		var pool := [
			"foodbox_1", "oven_1", "fridge_1", "rack_1",
			"egg_2", "leaf_2", "beef_2", "cake_2", "sandwich_2", "drink_2", "util_2",
			"gold_2", "energy_2"
		]
		var picked: String = pool[randi() % pool.size()]
		_spawn_reward_on_board(picked)
	, true)

	_add_shop_entry("Lucky Chef's Vault", "Spawns a valuable Tier 2-3 item or producer directly on board!", "coins", 90, func():
		var pool := [
			"foodbox_2", "oven_2", "fridge_2", "rack_2",
			"egg_3", "leaf_3", "beef_3", "cake_3", "sandwich_3", "drink_3", "util_3",
			"exp_2", "diamond_1"
		]
		var picked: String = pool[randi() % pool.size()]
		_spawn_reward_on_board(picked)
	, true)

	# --- 2. ENERGY REFILLS (GOLD) ---
	_add_category_header("ENERGY REFILLS (GOLD)")

	_add_shop_entry("Quick Spark (+25 Energy)", "Restores 25 Energy to keep merging!", "coins", 20, func():
		EconomyManager.add_energy(25)
		GameEvents.show_floating_text.emit("+25 Energy!", global_position + Vector2(310, 360), Color(0.3, 1.0, 0.5))
	, false)

	_add_shop_entry("Energy Surge (+60 Energy)", "Great value! Restores 60 Energy instantly.", "coins", 45, func():
		EconomyManager.add_energy(60)
		GameEvents.show_floating_text.emit("+60 Energy!", global_position + Vector2(310, 360), Color(0.3, 1.0, 0.5))
	, false)

	_add_shop_entry("Maximum Charge (+100 Energy)", "Completely refills your entire energy tank!", "coins", 70, func():
		EconomyManager.add_energy(100)
		GameEvents.show_floating_text.emit("+100 Max Energy!", global_position + Vector2(310, 360), Color(0.3, 1.0, 0.5))
	, false)

	# --- 3. SPECIFIC ITEMS & DAILY FREE ---
	_add_category_header("DIRECT SUPPLIES & GIFTS")

	_add_shop_entry("Wooden Foodbox (T1)", "Spawns a starter foodbox that produces eggs & greens.", "coins", 40, func():
		_spawn_reward_on_board("foodbox_1")
	, true)

	_add_shop_entry("Clay Toaster (T1)", "Spawns a starter oven that produces beef, cakes & sandwiches.", "coins", 40, func():
		_spawn_reward_on_board("oven_1")
	, true)

	_add_shop_entry("Mini Icebox (T1)", "Spawns a starter fridge that produces chilled drinks.", "coins", 40, func():
		_spawn_reward_on_board("fridge_1")
	, true)

	_add_shop_entry("Small Pegboard (T1)", "Spawns a starter rack that produces kitchen utensils.", "coins", 40, func():
		_spawn_reward_on_board("rack_1")
	, true)

	_add_shop_entry("Fresh Egg (T1)", "Spawns a fresh farm egg.", "coins", 15, func():
		_spawn_reward_on_board("egg_1")
	, true)

	_add_shop_entry("Fresh Herb (T1)", "Spawns a garden culinary herb.", "coins", 15, func():
		_spawn_reward_on_board("leaf_1")
	, true)

	_add_shop_entry("Raw Diamond Shard (T1)", "Spawns a shining diamond shard.", "gems", 4, func():
		_spawn_reward_on_board("diamond_1")
	, true)

	_add_shop_entry("Free Daily Energy (+25)", "A daily gift to keep you going!", "free", 0, func():
		EconomyManager.add_energy(25)
		GameEvents.show_floating_text.emit("+25 Free Energy!", global_position + Vector2(310, 360), Color(0.3, 1.0, 0.5))
	, false)

func _add_category_header(title: String) -> void:
	var lbl := Label.new()
	lbl.text = title
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.38, 0.28, 0.12))
	items_container.add_child(lbl)

func _add_shop_entry(title: String, desc: String, cost_type: String, cost_amount: int, on_buy: Callable, requires_board_space: bool) -> void:
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 68)

	var row_style := StyleBoxFlat.new()
	row_style.bg_color = Color(1.0, 1.0, 1.0, 0.95)
	row_style.border_width_left = 1
	row_style.border_width_top = 1
	row_style.border_width_right = 1
	row_style.border_width_bottom = 1
	row_style.border_color = Color(0.85, 0.82, 0.78, 0.9)
	row_style.corner_radius_top_left = 10
	row_style.corner_radius_top_right = 10
	row_style.corner_radius_bottom_right = 10
	row_style.corner_radius_bottom_left = 10
	row.add_theme_stylebox_override("panel", row_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	row.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	margin.add_child(hbox)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var t_lbl := Label.new()
	t_lbl.text = title
	t_lbl.add_theme_font_size_override("font_size", 14)
	t_lbl.add_theme_color_override("font_color", Color(0.18, 0.15, 0.12))
	vbox.add_child(t_lbl)

	var d_lbl := Label.new()
	d_lbl.text = desc
	d_lbl.add_theme_font_size_override("font_size", 11)
	d_lbl.add_theme_color_override("font_color", Color(0.48, 0.45, 0.42))
	d_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(d_lbl)

	hbox.add_child(vbox)

	var buy_btn := Button.new()
	buy_btn.custom_minimum_size = Vector2(86, 42)
	buy_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	buy_btn.add_theme_font_size_override("font_size", 13)
	buy_btn.add_theme_color_override("font_color", Color.WHITE)
	buy_btn.add_theme_color_override("font_outline_color", Color(0.18, 0.12, 0.08, 0.7))
	buy_btn.add_theme_constant_override("outline_size", 2)

	var btn_style := StyleBoxFlat.new()
	btn_style.corner_radius_top_left = 8
	btn_style.corner_radius_top_right = 8
	btn_style.corner_radius_bottom_right = 8
	btn_style.corner_radius_bottom_left = 8

	if cost_type == "coins":
		buy_btn.text = "%d Gold" % cost_amount
		btn_style.bg_color = Color(0.92, 0.68, 0.16)
	elif cost_type == "gems":
		buy_btn.text = "%d Gems" % cost_amount
		btn_style.bg_color = Color(0.25, 0.68, 0.9)
	else:
		buy_btn.text = "FREE!"
		btn_style.bg_color = Color(0.28, 0.78, 0.42)

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
			GameEvents.show_floating_text.emit("Board is Full!", global_position + Vector2(310, 360), Color(1.0, 0.4, 0.4))
			return

	if cost_type == "coins":
		if not EconomyManager.spend_coins(cost_amount):
			SoundManager.play_error()
			GameEvents.show_floating_text.emit("Not enough Gold!", global_position + Vector2(310, 360), Color(1.0, 0.4, 0.4))
			return
	elif cost_type == "gems":
		if not EconomyManager.spend_gems(cost_amount):
			SoundManager.play_error()
			GameEvents.show_floating_text.emit("Not enough Gems!", global_position + Vector2(310, 360), Color(1.0, 0.4, 0.4))
			return

	SoundManager.play_buy()
	on_buy.call()

func _spawn_reward_on_board(item_id: String) -> void:
	if not board_ref:
		return
	var empty := board_ref.get_empty_cells()
	if empty.is_empty():
		return
	var coord := empty[0]
	board_ref.spawn_item_flight(global_position + Vector2(310, 360), coord, item_id)
