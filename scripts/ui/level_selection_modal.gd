class_name LevelSelectionModal
extends Control

@onready var dimmer: ColorRect = $Dimmer
@onready var panel: Panel = $Panel
@onready var close_btn: Button = $Panel/VBox/Header/CloseBtn
@onready var kitchen_btn: Button = $Panel/VBox/ScrollContainer/CardsContainer/KitchenCard/Margin/HBox/ActionBtn
@onready var farm_btn: Button = $Panel/VBox/ScrollContainer/CardsContainer/FarmCard/Margin/HBox/ActionBtn
@onready var witch_btn: Button = $Panel/VBox/ScrollContainer/CardsContainer/WitchCard/Margin/HBox/ActionBtn

func _ready() -> void:
	visible = false
	close_btn.pressed.connect(close_modal)
	kitchen_btn.pressed.connect(_on_kitchen_selected)
	farm_btn.pressed.connect(_on_farm_selected)
	witch_btn.pressed.connect(_on_witch_selected)
	GameEvents.request_map_open.connect(open_modal)

func open_modal() -> void:
	update_view()
	visible = true
	scale = Vector2(0.9, 0.9)
	pivot_offset = size * 0.5
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.2)

func close_modal() -> void:
	SoundManager.play_drop()
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.15)
	tween.finished.connect(func(): visible = false)

func update_view() -> void:
	var cur_level := SaveManager.current_board_id

	# Kitchen
	if cur_level == "kitchen":
		kitchen_btn.disabled = true
		kitchen_btn.text = "Current"
	else:
		kitchen_btn.disabled = false
		kitchen_btn.text = "Travel"

	# Farm
	if cur_level == "farm":
		farm_btn.disabled = true
		farm_btn.text = "Current"
	else:
		farm_btn.disabled = false
		farm_btn.text = "Travel"

	# Witch
	if not ProgressionManager.is_witch_unlocked:
		witch_btn.disabled = false
		witch_btn.text = "Unlock (5,000 G)"
	elif cur_level == "witch":
		witch_btn.disabled = true
		witch_btn.text = "Current"
	else:
		witch_btn.disabled = false
		witch_btn.text = "Travel"

func _on_kitchen_selected() -> void:
	if SaveManager.current_board_id == "kitchen":
		return
	SoundManager.play_click()
	close_modal()
	GameEvents.level_change_requested.emit("kitchen")

func _on_farm_selected() -> void:
	if SaveManager.current_board_id == "farm":
		return
	SoundManager.play_click()
	close_modal()
	GameEvents.level_change_requested.emit("farm")

func _on_witch_selected() -> void:
	if not ProgressionManager.is_witch_unlocked:
		if EconomyManager.spend_coins(5000):
			ProgressionManager.is_witch_unlocked = true
			SaveManager.save_game()
			SoundManager.play_buy()
			GameEvents.show_floating_text.emit("Witch's Haven Unlocked!", witch_btn.global_position + Vector2(0, -30), Color(0.9, 0.7, 1.0))
			update_view()
		else:
			SoundManager.play_drop()
			GameEvents.show_floating_text.emit("Need 5,000 Gold!", witch_btn.global_position + Vector2(0, -30), Color(1.0, 0.4, 0.4))
		return

	if SaveManager.current_board_id == "witch":
		return
	SoundManager.play_click()
	close_modal()
	GameEvents.level_change_requested.emit("witch")
