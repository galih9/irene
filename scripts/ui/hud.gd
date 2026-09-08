class_name HUD
extends Control

@onready var coins_label: Label = $Margin/HBox/CoinsBox/HBox/Value
@onready var gems_label: Label = $Margin/HBox/GemsBox/HBox/Value
@onready var energy_label: Label = $Margin/HBox/EnergyBox/VBox/Label
@onready var energy_timer_label: Label = $Margin/HBox/EnergyBox/VBox/TimerLabel
@onready var energy_bar: ProgressBar = $Margin/HBox/EnergyBox/VBox/ProgressBar

@onready var shop_btn: Button = $Margin/HBox/ButtonsBox/ShopBtn
@onready var debug_btn: Button = $Margin/HBox/ButtonsBox/DebugBtn

func _ready() -> void:
	GameEvents.currency_changed.connect(_on_currency_changed)
	shop_btn.pressed.connect(_on_shop_pressed)
	debug_btn.pressed.connect(_on_debug_pressed)
	_update_all_labels()

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
	energy_label.text = "⚡ %d/%d" % [EconomyManager.energy, EconomyManager.max_energy]
	energy_bar.max_value = EconomyManager.max_energy
	energy_bar.value = EconomyManager.energy

func _on_currency_changed(_type: String, _new_amount: int, _delta: int) -> void:
	_update_all_labels()

func _on_shop_pressed() -> void:
	SoundManager.play_pickup()
	GameEvents.request_shop_open.emit()

func _on_debug_pressed() -> void:
	SoundManager.play_pickup()
	GameEvents.request_debug_toggle.emit()
