class_name RollerUpgradeModal
extends Control

## Upgrade menu for the thread roller minigame.
## Allows players to spend in-game coins to:
## 1. Increase roller slots (1 -> 2 -> 3 -> 4 -> 5)
## 2. Increase roller capacity (3s -> 4s -> 5s -> 6s -> 7s -> 8s)

signal slot_upgrade_purchased(new_slots: int)
signal capacity_upgrade_purchased(new_capacity: int)
signal closed()

# Slot upgrade costs: slot 1 -> 2 is 50, 2 -> 3 is 100, etc.
const SLOT_COSTS: Dictionary = {
	1: 50,
	2: 100,
	3: 200,
	4: 350
}
const MAX_SLOTS: int = 5

# Capacity upgrade costs: 3s -> 4s is 40, 4s -> 5s is 80, etc.
const CAPACITY_COSTS: Dictionary = {
	3: 40,
	4: 80,
	5: 150,
	6: 250,
	7: 400
}
const MAX_CAPACITY: int = 8

var current_slots: int = 3
var current_capacity: int = 3

@onready var panel: Panel = $Panel
@onready var coin_label: Label = $Panel/VBox/HeaderBox/CoinLabel
@onready var close_btn: Button = $Panel/VBox/HeaderBox/CloseBtn

@onready var slot_curr_label: Label = $Panel/VBox/CardsBox/SlotCard/Margin/VBox/InfoHBox/CurrentLabel
@onready var slot_desc_label: Label = $Panel/VBox/CardsBox/SlotCard/Margin/VBox/DescLabel
@onready var slot_buy_btn: Button = $Panel/VBox/CardsBox/SlotCard/Margin/VBox/BuyBtn

@onready var cap_curr_label: Label = $Panel/VBox/CardsBox/CapCard/Margin/VBox/InfoHBox/CurrentLabel
@onready var cap_desc_label: Label = $Panel/VBox/CardsBox/CapCard/Margin/VBox/DescLabel
@onready var cap_buy_btn: Button = $Panel/VBox/CardsBox/CapCard/Margin/VBox/BuyBtn

func _ready() -> void:
	visible = false
	if is_instance_valid(close_btn):
		close_btn.pressed.connect(close_modal)
	if is_instance_valid(slot_buy_btn):
		slot_buy_btn.pressed.connect(_on_buy_slot_pressed)
	if is_instance_valid(cap_buy_btn):
		cap_buy_btn.pressed.connect(_on_buy_capacity_pressed)

	if is_instance_valid(GameEvents):
		GameEvents.currency_changed.connect(_on_currency_changed)

func open_modal(p_slots: int, p_capacity: int) -> void:
	current_slots = p_slots
	current_capacity = p_capacity
	visible = true
	_refresh_ui()

	if is_instance_valid(panel):
		panel.scale = Vector2(0.85, 0.85)
		panel.pivot_offset = panel.size * 0.5
		var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(panel, "scale", Vector2.ONE, 0.22)

	if is_instance_valid(SoundManager):
		SoundManager.play_open()

func close_modal() -> void:
	if is_instance_valid(panel):
		var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(panel, "scale", Vector2(0.85, 0.85), 0.15)
		tween.chain().tween_callback(func():
			visible = false
			closed.emit()
		)
	else:
		visible = false
		closed.emit()

	if is_instance_valid(SoundManager):
		SoundManager.play_close()

func _refresh_ui() -> void:
	var coins: int = EconomyManager.coins if is_instance_valid(EconomyManager) else 0

	# 1. Header Coins
	if is_instance_valid(coin_label):
		coin_label.text = "🪙 %d Coins" % coins

	# 2. Slot Card
	if is_instance_valid(slot_curr_label):
		if current_slots < MAX_SLOTS:
			slot_curr_label.text = "Slots: %d  ➔  %d" % [current_slots, current_slots + 1]
		else:
			slot_curr_label.text = "Slots: %d (MAX)" % current_slots

	if is_instance_valid(slot_buy_btn):
		if current_slots >= MAX_SLOTS:
			slot_buy_btn.text = "MAX LEVEL"
			slot_buy_btn.disabled = true
		else:
			var cost: int = SLOT_COSTS.get(current_slots, 100)
			slot_buy_btn.text = "Upgrade (%d 🪙)" % cost
			slot_buy_btn.disabled = (coins < cost)

	# 3. Capacity Card
	if is_instance_valid(cap_curr_label):
		if current_capacity < MAX_CAPACITY:
			cap_curr_label.text = "Capacity: %ds  ➔  %ds" % [current_capacity, current_capacity + 1]
		else:
			cap_curr_label.text = "Capacity: %ds (MAX)" % current_capacity

	if is_instance_valid(cap_buy_btn):
		if current_capacity >= MAX_CAPACITY:
			cap_buy_btn.text = "MAX LEVEL"
			cap_buy_btn.disabled = true
		else:
			var cost: int = CAPACITY_COSTS.get(current_capacity, 80)
			cap_buy_btn.text = "Upgrade (%d 🪙)" % cost
			cap_buy_btn.disabled = (coins < cost)

func _on_buy_slot_pressed() -> void:
	if current_slots >= MAX_SLOTS:
		return
	var cost: int = SLOT_COSTS.get(current_slots, 100)
	if not is_instance_valid(EconomyManager) or not EconomyManager.spend_coins(cost):
		if is_instance_valid(SoundManager):
			SoundManager.play_error()
		return

	current_slots += 1
	if is_instance_valid(SoundManager):
		SoundManager.play_quest()
	slot_upgrade_purchased.emit(current_slots)
	_refresh_ui()

func _on_buy_capacity_pressed() -> void:
	if current_capacity >= MAX_CAPACITY:
		return
	var cost: int = CAPACITY_COSTS.get(current_capacity, 80)
	if not is_instance_valid(EconomyManager) or not EconomyManager.spend_coins(cost):
		if is_instance_valid(SoundManager):
			SoundManager.play_error()
		return

	current_capacity += 1
	if is_instance_valid(SoundManager):
		SoundManager.play_quest()
	capacity_upgrade_purchased.emit(current_capacity)
	_refresh_ui()

func _on_currency_changed(type: String, _new_val: int, _delta: int) -> void:
	if type == "coins" and visible:
		_refresh_ui()
