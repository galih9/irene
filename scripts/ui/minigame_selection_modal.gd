class_name MinigameSelectionModal
extends Control

@onready var dimmer: ColorRect = $Dimmer
@onready var panel: Panel = $Panel
@onready var close_btn: Button = $Panel/VBox/Header/CloseBtn
@onready var thread_roller_btn: Button = $Panel/VBox/ScrollContainer/CardsContainer/ThreadRollerCard/Margin/HBox/ActionBtn
@onready var liquid_sort_btn: Button = $Panel/VBox/ScrollContainer/CardsContainer/LiquidSortCard/Margin/HBox/ActionBtn

func _ready() -> void:
	visible = false
	if is_instance_valid(close_btn):
		close_btn.pressed.connect(close_modal)
	if is_instance_valid(thread_roller_btn):
		thread_roller_btn.pressed.connect(_on_thread_roller_selected)
	if is_instance_valid(liquid_sort_btn):
		liquid_sort_btn.pressed.connect(_on_liquid_sort_selected)
	if is_instance_valid(GameEvents):
		GameEvents.request_minigame_select_open.connect(open_modal)

func open_modal() -> void:
	visible = true
	scale = Vector2(0.9, 0.9)
	pivot_offset = size * 0.5
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.2)

func close_modal() -> void:
	if is_instance_valid(SoundManager):
		SoundManager.play_drop()
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.15)
	tween.finished.connect(func(): visible = false)

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

