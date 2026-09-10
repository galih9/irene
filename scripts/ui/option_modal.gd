class_name OptionModal
extends Control

@onready var close_btn: Button = $Panel/Margin/VBox/Header/CloseBtn
@onready var save_btn: Button = $Panel/Margin/VBox/Content/SaveBtn
@onready var sfx_btn: Button = $Panel/Margin/VBox/Content/SfxBtn
@onready var menu_btn: Button = $Panel/Margin/VBox/Content/MenuBtn
@onready var debug_btn: Button = $Panel/Margin/VBox/Content/DebugBtn
@onready var resume_btn: Button = $Panel/Margin/VBox/Content/ResumeBtn
@onready var status_label: Label = $Panel/Margin/VBox/Content/StatusLabel

func _ready() -> void:
	visible = false
	close_btn.pressed.connect(close_modal)
	resume_btn.pressed.connect(close_modal)
	save_btn.pressed.connect(_on_save_pressed)
	sfx_btn.pressed.connect(_on_sfx_pressed)
	menu_btn.pressed.connect(_on_menu_pressed)
	debug_btn.pressed.connect(_on_debug_pressed)

	GameEvents.request_options_open.connect(open_modal)
	_update_sfx_button()

func open_modal() -> void:
	visible = true
	status_label.text = ""
	_update_sfx_button()
	scale = Vector2(0.9, 0.9)
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.2)

func close_modal() -> void:
	SoundManager.play_drop()
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.15)
	tween.finished.connect(func(): visible = false)

func _on_save_pressed() -> void:
	SoundManager.play_pickup()
	var success := SaveManager.save_game(true, false)
	if success:
		status_label.text = "Game saved successfully! ✔"
		status_label.add_theme_color_override("font_color", Color(0.4, 0.95, 0.5))
	else:
		status_label.text = "Failed to save game! ✖"
		status_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))

func _on_sfx_pressed() -> void:
	var enabled := SoundManager.toggle_sfx()
	if enabled:
		SoundManager.play_pickup()
	_update_sfx_button()

func _update_sfx_button() -> void:
	if is_instance_valid(sfx_btn):
		if SoundManager.sfx_enabled:
			sfx_btn.text = "SOUND EFFECTS: ON"
		else:
			sfx_btn.text = "SOUND EFFECTS: OFF"

func _on_menu_pressed() -> void:
	SoundManager.play_pickup()
	# Auto-save before returning to main menu
	SaveManager.save_game(false, false)
	SaveManager.is_gameplay_active = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_debug_pressed() -> void:
	close_modal()
	GameEvents.request_debug_toggle.emit()
