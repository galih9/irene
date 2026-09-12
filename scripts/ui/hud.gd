class_name HUD
extends Control

@onready var level_label: Label = %LevelLabel
@onready var exp_bar: ProgressBar = %ExpBar

@onready var coins_label: Label = %CoinsLabel
@onready var gems_label: Label = %GemsLabel
@onready var energy_label: Label = %EnergyLabel

@onready var level_box: Control = %LevelBox
@onready var energy_box: Control = %EnergyBox
@onready var coins_box: Control = %CoinsBox
@onready var gems_box: Control = %GemsBox

@onready var level_icon: TextureRect = %LevelIcon
@onready var energy_icon: TextureRect = %EnergyIcon
@onready var coin_icon: TextureRect = %CoinIcon
@onready var gem_icon: TextureRect = %GemIcon

@onready var shop_btn: Button = %ShopBtn
@onready var options_btn: Button = %OptionsBtn
@onready var debug_btn: Button = %DebugBtn

func _ready() -> void:
	GameEvents.currency_changed.connect(_on_currency_changed)
	GameEvents.player_exp_changed.connect(_on_exp_changed)
	GameEvents.player_leveled_up.connect(_on_leveled_up)

	shop_btn.pressed.connect(_on_shop_pressed)
	options_btn.pressed.connect(_on_options_pressed)
	debug_btn.pressed.connect(_on_debug_pressed)

	_update_all_labels()
	_update_level_ui()

func set_landscape(is_landscape: bool) -> void:
	if is_landscape:
		custom_minimum_size = Vector2(1600, 85)
		offset_bottom = 85.0
	else:
		custom_minimum_size = Vector2(720, 105)
		offset_bottom = 105.0

func _process(_delta: float) -> void:
	# Update tooltip info for energy
	if EconomyManager.energy < EconomyManager.max_energy:
		var secs := int(EconomyManager.get_seconds_to_next_energy())
		energy_box.tooltip_text = "Energy: %d/%d\n+1 in %02ds" % [EconomyManager.energy, EconomyManager.max_energy, secs + 1]
	else:
		energy_box.tooltip_text = "Energy: FULL (%d/%d)" % [EconomyManager.energy, EconomyManager.max_energy]

func _update_all_labels() -> void:
	coins_label.text = str(EconomyManager.coins)
	gems_label.text = str(EconomyManager.gems)
	energy_label.text = "%d/%d" % [EconomyManager.energy, EconomyManager.max_energy]

func _update_level_ui() -> void:
	level_label.text = "Lv. %d" % ProgressionManager.player_level
	var req := ProgressionManager.get_current_level_req()
	exp_bar.max_value = req
	exp_bar.value = ProgressionManager.player_exp

func _on_exp_changed(lvl: int, current_exp: int, req_exp: int) -> void:
	level_label.text = "Lv. %d" % lvl
	exp_bar.max_value = req_exp
	exp_bar.value = current_exp

func _on_leveled_up(_new_level: int) -> void:
	_update_level_ui()
	_update_all_labels()
	_pop_node(level_icon)

func _on_currency_changed(type: String, _new_amount: int, delta: int) -> void:
	_update_all_labels()
	if delta > 0:
		match type:
			"coins":
				_pop_node(coin_icon)
			"gems":
				_pop_node(gem_icon)
			"energy":
				_pop_node(energy_icon)

func _pop_node(node: Control) -> void:
	if not node:
		return
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", Vector2(1.22, 1.22), 0.12)
	tween.tween_property(node, "scale", Vector2.ONE, 0.18)

func _on_shop_pressed() -> void:
	SoundManager.play_click()
	GameEvents.request_shop_open.emit()

func _on_options_pressed() -> void:
	SoundManager.play_click()
	GameEvents.request_options_open.emit()

func _on_debug_pressed() -> void:
	SoundManager.play_click()
	GameEvents.request_debug_toggle.emit()
