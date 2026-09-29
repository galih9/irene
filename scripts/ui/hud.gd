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

# Rolling counter displayed values
var _displayed_coins: float = 0.0
var _displayed_gems: float = 0.0
var _displayed_energy: float = 0.0
var _displayed_exp: float = 0.0

# Active flying flight trackers per currency
var _active_flying_consumers: Dictionary = {
	"coins": 0,
	"gems": 0,
	"energy": 0,
	"exp": 0
}

var fx_layer: Control = null

func _ready() -> void:
	# Initialize overlay layer for flying particle effects
	fx_layer = Control.new()
	fx_layer.name = "FlyFXLayer"
	fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.top_level = true
	fx_layer.z_index = 250
	add_child(fx_layer)

	_setup_centered_pivots()

	_displayed_coins = float(EconomyManager.coins)
	_displayed_gems = float(EconomyManager.gems)
	_displayed_energy = float(EconomyManager.energy)
	_displayed_exp = float(ProgressionManager.player_exp)

	GameEvents.currency_changed.connect(_on_currency_changed)
	GameEvents.player_exp_changed.connect(_on_exp_changed)
	GameEvents.player_leveled_up.connect(_on_leveled_up)
	GameEvents.item_consumed.connect(_on_item_consumed)

	shop_btn.pressed.connect(_on_shop_pressed)
	options_btn.pressed.connect(_on_options_pressed)
	debug_btn.pressed.connect(_on_debug_pressed)
	debug_btn.visible = OS.has_feature("editor")

	_update_all_labels()
	_update_level_ui()

func _setup_centered_pivots() -> void:
	if is_instance_valid(coins_box): coins_box.pivot_offset = coins_box.size * 0.5
	if is_instance_valid(energy_box): energy_box.pivot_offset = energy_box.size * 0.5
	if is_instance_valid(gems_box): gems_box.pivot_offset = gems_box.size * 0.5
	if is_instance_valid(level_box): level_box.pivot_offset = level_box.size * 0.5

	if is_instance_valid(coins_label): coins_label.pivot_offset = coins_label.size * 0.5
	if is_instance_valid(gems_label): gems_label.pivot_offset = gems_label.size * 0.5
	if is_instance_valid(energy_label): energy_label.pivot_offset = energy_label.size * 0.5
	if is_instance_valid(level_label): level_label.pivot_offset = level_label.size * 0.5

	if is_instance_valid(coin_icon): coin_icon.pivot_offset = coin_icon.size * 0.5
	if is_instance_valid(energy_icon): energy_icon.pivot_offset = energy_icon.size * 0.5
	if is_instance_valid(gem_icon): gem_icon.pivot_offset = gem_icon.size * 0.5
	if is_instance_valid(level_icon): level_icon.pivot_offset = level_icon.size * 0.5

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
	_displayed_coins = float(EconomyManager.coins)
	_displayed_gems = float(EconomyManager.gems)
	_displayed_energy = float(EconomyManager.energy)
	coins_label.text = str(EconomyManager.coins)
	gems_label.text = str(EconomyManager.gems)
	energy_label.text = "%d/%d" % [EconomyManager.energy, EconomyManager.max_energy]

func _update_level_ui() -> void:
	level_label.text = "Lv. %d" % ProgressionManager.player_level
	var req := ProgressionManager.get_current_level_req()
	exp_bar.max_value = req
	_displayed_exp = float(ProgressionManager.player_exp)
	exp_bar.value = ProgressionManager.player_exp

func _on_exp_changed(lvl: int, current_exp: int, req_exp: int) -> void:
	level_label.text = "Lv. %d" % lvl
	exp_bar.max_value = req_exp
	if _active_flying_consumers.get("exp", 0) == 0:
		_displayed_exp = float(current_exp)
		exp_bar.value = current_exp

func _on_leveled_up(_new_level: int) -> void:
	_update_level_ui()
	_update_all_labels()
	_pop_node(level_icon)
	_gleam_label(level_label, Color(1.0, 0.85, 1.0), Color(0.92, 0.78, 1, 1), true)

func _on_currency_changed(type: String, new_amount: int, delta: int) -> void:
	# If flying consumable tokens are active for this currency, let the token arrivals drive incrementing
	if _active_flying_consumers.get(type, 0) > 0:
		return

	if delta > 0:
		match type:
			"coins":
				_animate_rolling_counter(coins_label, _displayed_coins, float(new_amount), func(v: float):
					_displayed_coins = v
					coins_label.text = str(int(round(v)))
				, coin_icon, coins_box, Color(1.0, 1.0, 0.65), Color(1, 0.84, 0.28, 1))
			"gems":
				_animate_rolling_counter(gems_label, _displayed_gems, float(new_amount), func(v: float):
					_displayed_gems = v
					gems_label.text = str(int(round(v)))
				, gem_icon, gems_box, Color(0.7, 1.0, 1.0), Color(0.42, 0.88, 1, 1))
			"energy":
				_animate_rolling_counter(energy_label, _displayed_energy, float(new_amount), func(v: float):
					_displayed_energy = v
					energy_label.text = "%d/%d" % [int(round(v)), EconomyManager.max_energy]
				, energy_icon, energy_box, Color(0.7, 1.0, 0.8), Color(0.4, 0.96, 0.65, 1))
	else:
		_update_all_labels()

func _animate_rolling_counter(
	label: Label, from_val: float, to_val: float, update_cb: Callable,
	icon: Control, box: Control, flash_col: Color, base_col: Color
) -> void:
	_punch_hud_element(icon, box, true)
	_gleam_label(label, flash_col, base_col, true)
	var tw := create_tween()
	tw.tween_method(update_cb, from_val, to_val, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.chain().tween_callback(func():
		update_cb.call(to_val)
	)

func _pop_node(node: Control) -> void:
	if not node:
		return
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", Vector2(1.22, 1.22), 0.12)
	tween.tween_property(node, "scale", Vector2.ONE, 0.18)

# ==============================================================================
# Consumable Flying Tokens & Eyecatching HUD Animations
# ==============================================================================

func _on_item_consumed(item_data: ItemData, world_pos: Vector2) -> void:
	if not item_data or not item_data.is_consumable:
		return
	play_consumable_fly_animation(item_data, world_pos)

func play_consumable_fly_animation(item_data: ItemData, world_pos: Vector2) -> void:
	var curr := item_data.consume_currency
	if curr == "diamond":
		curr = "gems"
	var tier := item_data.tier

	# Mark that flying tokens are active for this currency
	_active_flying_consumers[curr] = _active_flying_consumers.get(curr, 0) + 1

	# Determine particle count scaling based on consumed tier
	var token_count: int = clampi(5 + tier * 2 + (2 if tier >= 4 else 0), 6, 24)

	# Target HUD elements
	var target_icon: TextureRect = null
	var target_box: Control = null
	var token_texture: Texture2D = null
	var token_color := Color.WHITE

	match curr:
		"coins":
			target_icon = coin_icon
			target_box = coins_box
			token_texture = coin_icon.texture if (coin_icon and coin_icon.texture) else preload("res://assets/items/rewards/gold/gold1.png")
			token_color = Color(1.0, 0.88, 0.25)
		"energy":
			target_icon = energy_icon
			target_box = energy_box
			token_texture = energy_icon.texture if (energy_icon and energy_icon.texture) else preload("res://assets/items/rewards/energy/energy_1.png")
			token_color = Color(0.35, 1.0, 0.6)
		"exp":
			target_icon = level_icon
			target_box = level_box
			token_texture = level_icon.texture if (level_icon and level_icon.texture) else preload("res://assets/items/rewards/exp/exp1.png")
			token_color = Color(0.85, 0.55, 1.0)
		"gems":
			target_icon = gem_icon
			target_box = gems_box
			token_texture = gem_icon.texture if (gem_icon and gem_icon.texture) else preload("res://assets/items/rewards/diamond/diamond_1.png")
			token_color = Color(0.45, 0.9, 1.0)

	if not target_icon:
		return

	# Calculate chunk increase per token arrival
	var start_val := _get_displayed_val(curr)
	var final_val := _get_actual_val(curr)
	var total_diff := maxf(0.0, final_val - start_val)
	var diff_per_token := total_diff / float(token_count) if token_count > 0 else 0.0

	for i in range(token_count):
		_spawn_single_flying_token(
			i, token_count, curr, world_pos, target_icon, target_box,
			token_texture, token_color, diff_per_token, final_val
		)

func _spawn_single_flying_token(
	index: int, total_count: int, curr: String, start_pos: Vector2,
	target_icon: TextureRect, target_box: Control,
	token_tex: Texture2D, token_col: Color,
	diff_per_token: float, final_target_val: float
) -> void:
	if not is_instance_valid(fx_layer):
		return

	var token := TextureRect.new()
	token.mouse_filter = Control.MOUSE_FILTER_IGNORE
	token.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	token.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var token_size := Vector2(38, 38)
	token.custom_minimum_size = token_size
	token.size = token_size
	token.pivot_offset = token_size * 0.5
	token.texture = token_tex
	token.z_index = 250
	token.global_position = start_pos - token_size * 0.5
	token.scale = Vector2(0.2, 0.2)
	token.modulate = Color(1.15, 1.15, 1.15, 1.0)
	fx_layer.add_child(token)

	# Staggered launch delay
	var delay := float(index) * 0.038

	# Phase 1: Realistic mobile-game burst scatter (downward & sideways fountain)
	var burst_spread_x := randf_range(-65.0, 65.0)
	var burst_down_y := randf_range(35.0, 95.0) # Downward scatter
	var burst_pos := start_pos + Vector2(burst_spread_x, burst_down_y)
	var burst_dur := randf_range(0.20, 0.28)
	var burst_spin := randf_range(-PI, PI) * 1.5

	# Phase 2: Upward curved flight to HUD target
	var fly_dur := randf_range(0.42, 0.54)
	var spin_speed := randf_range(16.0, 24.0) * (1.0 if randf() > 0.5 else -1.0)
	var phase_offset := randf() * TAU

	var is_last := (index == total_count - 1)

	var seq := create_tween()
	if delay > 0.0:
		seq.tween_interval(delay)

	# Burst phase: pop down and out
	seq.parallel().tween_property(token, "global_position", burst_pos - token_size * 0.5, burst_dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	seq.parallel().tween_property(token, "scale", Vector2(1.18, 1.18), burst_dur).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	seq.parallel().tween_property(token, "rotation", burst_spin, burst_dur)

	# Swoop phase: accelerated quadratic Bezier curve to HUD target with continuous 3D spinning
	var P0 := burst_pos
	seq.chain().tween_method(func(t: float):
		if not is_instance_valid(token) or not is_instance_valid(target_icon):
			return
		var P2 := target_icon.global_position + target_icon.size * 0.5
		# Bowing curve outwards
		var bow_x := (P2.x - P0.x) * 0.2 + (sin(t * PI) * (80.0 if index % 2 == 0 else -80.0))
		var mid_y := minf(P0.y, P2.y) - 60.0
		var P1 := Vector2((P0.x + P2.x) * 0.5 + bow_x, mid_y)

		var inv_t := 1.0 - t
		var cur_pos := inv_t * inv_t * P0 + 2.0 * inv_t * t * P1 + t * t * P2
		token.global_position = cur_pos - token_size * 0.5

		# 3D tumbling flip simulation (oscillating scale.x) & rotation
		var flip := absf(cos(t * spin_speed + phase_offset))
		var cur_scale := lerpf(0.9, 0.75, t)
		token.scale = Vector2(lerpf(0.2, cur_scale, flip), cur_scale)
		token.rotation += 0.25
	, 0.0, 1.0, fly_dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	# Impact phase at HUD target
	seq.chain().tween_callback(func():
		if not is_inside_tree():
			return
		var impact_pos := target_icon.global_position + target_icon.size * 0.5 if is_instance_valid(target_icon) else Vector2.ZERO
		_on_token_impact(curr, index, total_count, impact_pos, target_icon, target_box, token_col, diff_per_token, final_target_val, is_last)
		if is_instance_valid(token):
			var hit_tw := token.create_tween().set_parallel(true)
			hit_tw.tween_property(token, "scale", Vector2(1.35, 1.35), 0.08)
			hit_tw.tween_property(token, "modulate:a", 0.0, 0.08)
			hit_tw.chain().tween_callback(token.queue_free)
	)

func _on_token_impact(
	curr: String, index: int, total_count: int, impact_pos: Vector2,
	target_icon: TextureRect, target_box: Control, token_col: Color,
	diff_per_token: float, final_target_val: float, is_last: bool
) -> void:
	# 1. Sound with cascading pitch chime
	var pitch := 1.0 + (float(index) / float(maxi(total_count, 1))) * 0.45
	SoundManager.play_token_arrival(pitch)

	# 2. Visual sparkle particles at impact point
	_spawn_impact_sparkles(impact_pos, token_col)

	# 3. Punch icon and box
	_punch_hud_element(target_icon, target_box, is_last)

	# 4. Increment displayed counter smoothly
	_apply_token_value_step(curr, diff_per_token, final_target_val, is_last)

	if is_last:
		_active_flying_consumers[curr] = maxi(0, _active_flying_consumers.get(curr, 1) - 1)

func _spawn_impact_sparkles(pos: Vector2, col: Color) -> void:
	if not is_instance_valid(fx_layer):
		return
	# 4 radiating mini sparks
	for s in range(4):
		var spark := ColorRect.new()
		spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spark.size = Vector2(5, 5)
		spark.color = col.lightened(0.4)
		spark.pivot_offset = Vector2(2.5, 2.5)
		spark.global_position = pos - Vector2(2.5, 2.5)
		spark.z_index = 260
		fx_layer.add_child(spark)

		var angle := randf() * TAU
		var dist := randf_range(16.0, 32.0)
		var target_offset := Vector2(cos(angle), sin(angle)) * dist

		var sp_tw := spark.create_tween().set_parallel(true)
		sp_tw.tween_property(spark, "global_position", spark.global_position + target_offset, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		sp_tw.tween_property(spark, "scale", Vector2(0.1, 0.1), 0.16)
		sp_tw.tween_property(spark, "rotation", randf_range(-PI, PI), 0.16)
		sp_tw.chain().tween_callback(spark.queue_free)

func _punch_hud_element(icon: Control, box: Control, is_last: bool) -> void:
	if is_instance_valid(icon):
		var punch_scale := Vector2(1.35, 1.35) if is_last else Vector2(1.22, 1.22)
		var icon_tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		icon_tw.tween_property(icon, "scale", punch_scale, 0.07)
		icon_tw.tween_property(icon, "scale", Vector2.ONE, 0.12)
		icon.rotation = randf_range(-0.1, 0.1)
		var rot_tw := create_tween()
		rot_tw.tween_property(icon, "rotation", 0.0, 0.12)

	if is_instance_valid(box):
		var box_scale := Vector2(1.10, 1.10) if is_last else Vector2(1.05, 1.05)
		var box_tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		box_tw.tween_property(box, "scale", box_scale, 0.06)
		box_tw.tween_property(box, "scale", Vector2.ONE, 0.10)

func _apply_token_value_step(curr: String, diff: float, _final_val: float, is_last: bool) -> void:
	match curr:
		"coins":
			if is_last:
				_displayed_coins = float(EconomyManager.coins)
			else:
				_displayed_coins = minf(float(EconomyManager.coins), _displayed_coins + diff)
			coins_label.text = str(int(round(_displayed_coins)))
			_gleam_label(coins_label, Color(1.0, 1.0, 0.65), Color(1, 0.84, 0.28, 1), is_last)
		"gems":
			if is_last:
				_displayed_gems = float(EconomyManager.gems)
			else:
				_displayed_gems = minf(float(EconomyManager.gems), _displayed_gems + diff)
			gems_label.text = str(int(round(_displayed_gems)))
			_gleam_label(gems_label, Color(0.7, 1.0, 1.0), Color(0.42, 0.88, 1, 1), is_last)
		"energy":
			if is_last:
				_displayed_energy = float(EconomyManager.energy)
			else:
				_displayed_energy = minf(float(EconomyManager.energy), _displayed_energy + diff)
			energy_label.text = "%d/%d" % [int(round(_displayed_energy)), EconomyManager.max_energy]
			_gleam_label(energy_label, Color(0.7, 1.0, 0.8), Color(0.4, 0.96, 0.65, 1), is_last)
		"exp":
			var req := ProgressionManager.get_current_level_req()
			exp_bar.max_value = req
			if is_last:
				_displayed_exp = float(ProgressionManager.player_exp)
			else:
				_displayed_exp = minf(float(ProgressionManager.player_exp), _displayed_exp + diff)
			exp_bar.value = _displayed_exp
			level_label.text = "Lv. %d" % ProgressionManager.player_level
			_gleam_label(level_label, Color(1.0, 0.85, 1.0), Color(0.92, 0.78, 1, 1), is_last)

func _gleam_label(label: Label, flash_col: Color, base_col: Color, is_last: bool) -> void:
	if not is_instance_valid(label):
		return
	label.pivot_offset = label.size * 0.5
	var target_scale := Vector2(1.25, 1.25) if is_last else Vector2(1.12, 1.12)
	var dur := 0.22 if is_last else 0.10
	label.set("theme_override_colors/font_color", flash_col)
	var tw := label.create_tween().set_parallel(true)
	tw.tween_property(label, "scale", target_scale, dur * 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(label, "scale", Vector2.ONE, dur * 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(label, "theme_override_colors/font_color", base_col, dur * 0.6)

func _get_displayed_val(curr: String) -> float:
	match curr:
		"coins": return _displayed_coins
		"gems": return _displayed_gems
		"energy": return _displayed_energy
		"exp": return _displayed_exp
	return 0.0

func _get_actual_val(curr: String) -> float:
	match curr:
		"coins": return float(EconomyManager.coins)
		"gems": return float(EconomyManager.gems)
		"energy": return float(EconomyManager.energy)
		"exp": return float(ProgressionManager.player_exp)
	return 0.0

func _on_shop_pressed() -> void:
	SoundManager.play_click()
	GameEvents.request_shop_open.emit()

func _on_options_pressed() -> void:
	SoundManager.play_click()
	GameEvents.request_options_open.emit()

func _on_debug_pressed() -> void:
	SoundManager.play_click()
	GameEvents.request_debug_toggle.emit()
