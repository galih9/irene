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

	_add_shop_entry("⚡ Energy Refill (+50)", "Instantly restores 50 energy.", "coins", 35, func():
		EconomyManager.add_energy(50)
		GameEvents.show_floating_text.emit("+50 Energy! ⚡", global_position + Vector2(330, 400), Color(0.3, 1.0, 0.5))
	)

	_add_shop_entry("🎁 Mystery Chest", "Spawns a chest with surprise items!", "coins", 50, func():
		_spawn_reward_on_board("coins_2")
	)

	_add_shop_entry("🔧 Starter Wrench (T1)", "Spawns a Tier 1 Wrench on the board.", "coins", 15, func():
		_spawn_reward_on_board("tools_1")
	)

	_add_shop_entry("🌱 Starter Seed (T1)", "Spawns a Tier 1 Seed on the board.", "coins", 15, func():
		_spawn_reward_on_board("plant_1")
	)

	_add_shop_entry("💎 Crystal Shard (T1)", "Spawns a rare crystal shard.", "gems", 4, func():
		_spawn_reward_on_board("gem_1")
	)

	_add_shop_entry("🌟 Free Daily Energy (+25)", "A daily gift to keep you going!", "free", 0, func():
		EconomyManager.add_energy(25)
		GameEvents.show_floating_text.emit("+25 Free Energy! ⚡", global_position + Vector2(330, 400), Color(0.3, 1.0, 0.5))
	)

func _add_shop_entry(title: String, desc: String, cost_type: String, cost_amount: int, on_buy: Callable) -> void:
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
	lbl_title.add_theme_font_size_override("font_size", 15)

	var lbl_desc := Label.new()
	lbl_desc.text = desc
	lbl_desc.add_theme_color_override("font_color", Color(0.65, 0.7, 0.8))
	lbl_desc.add_theme_font_size_override("font_size", 12)

	vbox.add_child(lbl_title)
	vbox.add_child(lbl_desc)
	hbox.add_child(vbox)

	var buy_btn := Button.new()
	buy_btn.custom_minimum_size = Vector2(90, 42)
	buy_btn.add_theme_font_size_override("font_size", 13)

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

	buy_btn.pressed.connect(func():
		_handle_purchase(cost_type, cost_amount, on_buy)
	)

	hbox.add_child(buy_btn)
	items_container.add_child(row)

func _handle_purchase(cost_type: String, cost_amount: int, on_buy: Callable) -> void:
	if cost_type == "coins":
		if not EconomyManager.spend_coins(cost_amount):
			SoundManager.play_error()
			GameEvents.show_floating_text.emit("Not enough Coins!", global_position + Vector2(330, 400), Color(1.0, 0.4, 0.4))
			return
	elif cost_type == "gems":
		if not EconomyManager.spend_gems(cost_amount):
			SoundManager.play_error()
			GameEvents.show_floating_text.emit("Not enough Gems!", global_position + Vector2(330, 400), Color(1.0, 0.4, 0.4))
			return

	SoundManager.play_consume()
	on_buy.call()

func _spawn_reward_on_board(item_id: String) -> void:
	if not board_ref:
		return
	var empty_cells := board_ref.get_empty_cells()
	if empty_cells.is_empty():
		SoundManager.play_error()
		GameEvents.show_floating_text.emit("Board is Full!", global_position + Vector2(330, 400), Color(1.0, 0.4, 0.4))
		return

	var coord := empty_cells[randi() % empty_cells.size()]
	board_ref.spawn_item_flight(global_position + Vector2(330, 400), coord, item_id)
