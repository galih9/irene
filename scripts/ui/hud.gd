class_name HUD
extends Control

@onready var level_label: Label = $Margin/HBox/LevelBox/Margin/HBox/VBox/LevelLabel
@onready var exp_bar: ProgressBar = $Margin/HBox/LevelBox/Margin/HBox/VBox/ExpBar

@onready var coins_label: Label = $Margin/HBox/CoinsBox/Margin/HBox/Value
@onready var gems_label: Label = $Margin/HBox/GemsBox/Margin/HBox/Value

@onready var energy_label: Label = $Margin/HBox/EnergyBox/Margin/HBox/VBox/Label
@onready var energy_timer_label: Label = $Margin/HBox/EnergyBox/Margin/HBox/VBox/TimerLabel
@onready var energy_bar: ProgressBar = $Margin/HBox/EnergyBox/Margin/HBox/VBox/ProgressBar

@onready var shop_btn: Button = $Margin/HBox/ButtonsBox/ShopBtn
@onready var options_btn: Button = $Margin/HBox/ButtonsBox/OptionsBtn
@onready var debug_btn: Button = $Margin/HBox/ButtonsBox/DebugBtn

func _ready() -> void:
	GameEvents.currency_changed.connect(_on_currency_changed)
	GameEvents.player_exp_changed.connect(_on_exp_changed)
	GameEvents.player_leveled_up.connect(_on_leveled_up)

	shop_btn.pressed.connect(_on_shop_pressed)
	if has_node("Margin/HBox/ButtonsBox/OptionsBtn"):
		options_btn.pressed.connect(_on_options_pressed)
	if has_node("Margin/HBox/ButtonsBox/DebugBtn"):
		debug_btn.pressed.connect(_on_debug_pressed)

	_update_all_labels()
	_update_level_ui()

func _process(_delta: float) -> void:
	# Update energy timer
	if EconomyManager.energy < EconomyManager.max_energy:
		var secs := int(EconomyManager.get_seconds_to_next_energy())
		energy_timer_label.text = "+1 in %02ds" % (secs + 1)
	else:
		energy_timer_label.text = "FULL"

func _update_all_labels() -> void:
	coins_label.text = str(EconomyManager.coins)
	gems_label.text = str(EconomyManager.gems)
	energy_label.text = "%d/%d" % [EconomyManager.energy, EconomyManager.max_energy]
	energy_bar.max_value = EconomyManager.max_energy
	energy_bar.value = EconomyManager.energy

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
	# Visual pop on level box
	var box: Control = $Margin/HBox/LevelBox
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(box, "scale", Vector2(1.15, 1.15), 0.15)
	tween.tween_property(box, "scale", Vector2.ONE, 0.2)

func _on_currency_changed(_type: String, _new_amount: int, _delta: int) -> void:
	_update_all_labels()

func _on_shop_pressed() -> void:
	SoundManager.play_pickup()
	GameEvents.request_shop_open.emit()

func _on_options_pressed() -> void:
	SoundManager.play_pickup()
	GameEvents.request_options_open.emit()

func _on_debug_pressed() -> void:
	SoundManager.play_pickup()
	GameEvents.request_debug_toggle.emit()

func apply_custom_colors(btn_col: Color, cont_col: Color, border_col: Color = Color.TRANSPARENT) -> void:
	var buttons := [shop_btn, options_btn, debug_btn]
	for btn in buttons:
		if is_instance_valid(btn):
			var sb: StyleBoxFlat = StyleBoxFlat.new()
			sb.bg_color = btn_col
			if border_col.a > 0.0:
				sb.border_color = border_col
				sb.border_width_left = 1
				sb.border_width_top = 1
				sb.border_width_right = 1
				sb.border_width_bottom = 1
			sb.corner_radius_top_left = 8
			sb.corner_radius_top_right = 8
			sb.corner_radius_bottom_right = 8
			sb.corner_radius_bottom_left = 8
			var hover_sb := sb.duplicate()
			hover_sb.bg_color = btn_col.lightened(0.12)
			var press_sb := sb.duplicate()
			press_sb.bg_color = btn_col.darkened(0.12)
			btn.add_theme_stylebox_override("normal", sb)
			btn.add_theme_stylebox_override("hover", hover_sb)
			btn.add_theme_stylebox_override("pressed", press_sb)

	var pill_boxes := [
		get_node_or_null("Margin/HBox/LevelBox"),
		get_node_or_null("Margin/HBox/EnergyBox"),
		get_node_or_null("Margin/HBox/CoinsBox"),
		get_node_or_null("Margin/HBox/GemsBox")
	]
	for pbox in pill_boxes:
		if is_instance_valid(pbox) and pbox is PanelContainer:
			var psb := StyleBoxFlat.new()
			psb.bg_color = cont_col
			if border_col.a > 0.0:
				psb.border_color = border_col
				psb.border_width_left = 1
				psb.border_width_top = 1
				psb.border_width_right = 1
				psb.border_width_bottom = 1
			psb.corner_radius_top_left = 10
			psb.corner_radius_top_right = 10
			psb.corner_radius_bottom_right = 10
			psb.corner_radius_bottom_left = 10
			pbox.add_theme_stylebox_override("panel", psb)
