class_name MinigameSelectionModal
extends Control

const DialogMotion = preload("res://scripts/ui/modal_presenter.gd")

@onready var dimmer: ColorRect = $Dimmer
@onready var panel: Panel = $Panel
@onready var close_btn: Button = $Panel/VBox/Header/CloseBtn
@onready var thread_roller_btn: Button = $Panel/VBox/ScrollContainer/CardsContainer/ThreadRollerCard/Margin/HBox/ActionBtn
@onready var liquid_sort_btn: Button = $Panel/VBox/ScrollContainer/CardsContainer/LiquidSortCard/Margin/HBox/ActionBtn
@onready var food_delivery_btn: Button = $Panel/VBox/ScrollContainer/CardsContainer/FoodDeliveryCard/Margin/HBox/ActionBtn

func _ready() -> void:
	visible = false
	DialogMotion.install(self, close_btn, close_modal)
	if is_instance_valid(close_btn):
		close_btn.pressed.connect(close_modal)
	if is_instance_valid(thread_roller_btn):
		thread_roller_btn.pressed.connect(_on_thread_roller_selected)
	if is_instance_valid(liquid_sort_btn):
		liquid_sort_btn.pressed.connect(_on_liquid_sort_selected)
	if is_instance_valid(food_delivery_btn):
		food_delivery_btn.pressed.connect(_on_food_delivery_selected)

	if is_instance_valid(GameEvents):
		GameEvents.request_minigame_select_open.connect(open_modal)

func open_modal() -> void:
	DialogMotion.show_dialog(self)

func close_modal() -> void:
	if is_instance_valid(SoundManager):
		SoundManager.play_drop()
	DialogMotion.hide_dialog(self)

func _on_thread_roller_selected() -> void:
	if is_instance_valid(SoundManager):
		SoundManager.play_click()
	close_modal()
	GameEvents.request_minigame_toggle.emit()

func _on_liquid_sort_selected() -> void:
	if is_instance_valid(SoundManager):
		SoundManager.play_click()
	close_modal()
	GameEvents.request_liquid_sort_open.emit()

func _on_food_delivery_selected() -> void:
	if is_instance_valid(SoundManager):
		SoundManager.play_click()
	close_modal()
	GameEvents.request_food_delivery_open.emit()


