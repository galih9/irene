class_name LevelSelectionModal
extends Control

@onready var dimmer: ColorRect = $Dimmer
@onready var panel: Panel = $Panel
@onready var close_btn: Button = $Panel/VBox/Header/CloseBtn
@onready var kitchen_btn: Button = $Panel/VBox/CardsContainer/KitchenCard/Margin/HBox/ActionBtn
@onready var farm_btn: Button = $Panel/VBox/CardsContainer/FarmCard/Margin/HBox/ActionBtn

func _ready() -> void:
	visible = false
	close_btn.pressed.connect(close_modal)
	kitchen_btn.pressed.connect(_on_kitchen_selected)
	farm_btn.pressed.connect(_on_farm_selected)
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
	if cur_level == "farm":
		farm_btn.disabled = true
		farm_btn.text = "Current"
		kitchen_btn.disabled = false
		kitchen_btn.text = "Travel"
	else:
		kitchen_btn.disabled = true
		kitchen_btn.text = "Current"
		farm_btn.disabled = false
		farm_btn.text = "Travel"

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
