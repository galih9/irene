class_name OptionModal
extends Control

signal closed()

var _is_closing: bool = false

@onready var close_btn: Button = $Panel/Margin/VBox/Header/CloseBtn
@onready var save_btn: Button = $Panel/Margin/VBox/Content/SaveBtn
@onready var bgm_btn: Button = $Panel/Margin/VBox/Content/BgmBtn
@onready var sfx_btn: Button = $Panel/Margin/VBox/Content/SfxBtn
@onready var menu_btn: Button = $Panel/Margin/VBox/Content/MenuBtn
@onready var orientation_btn: Button = $Panel/Margin/VBox/Content/OrientationBtn
@onready var debug_btn: Button = $Panel/Margin/VBox/Content/DebugBtn
@onready var resume_btn: Button = $Panel/Margin/VBox/Content/ResumeBtn
@onready var status_label: Label = $Panel/Margin/VBox/Content/StatusLabel

func _ready() -> void:
	visible = false
	close_btn.pressed.connect(close_modal)
	resume_btn.pressed.connect(close_modal)
	save_btn.pressed.connect(_on_save_pressed)
	bgm_btn.pressed.connect(_on_bgm_pressed)
	sfx_btn.pressed.connect(_on_sfx_pressed)
	if is_instance_valid(orientation_btn):
		orientation_btn.pressed.connect(_on_orientation_pressed)
	menu_btn.pressed.connect(_on_menu_pressed)
	debug_btn.pressed.connect(_on_debug_pressed)

	GameEvents.request_options_open.connect(open_modal)
	_update_bgm_button()
	_update_sfx_button()
	_update_orientation_button()

func open_modal() -> void:
	_is_closing = false
	visible = true
	status_label.text = ""
	_update_bgm_button()
	_update_sfx_button()
	_update_orientation_button()
	if is_instance_valid(menu_btn):
		menu_btn.visible = true
	if is_instance_valid(save_btn):
		save_btn.visible = true
	if is_instance_valid(resume_btn):
		resume_btn.text = "  RESUME GAME"
	pivot_offset = size * 0.5
	scale = Vector2(0.9, 0.9)
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.2)

func close_modal() -> void:
	if _is_closing or not visible:
		return
	_is_closing = true
	SoundManager.play_drop()
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.15)
	tween.finished.connect(func():
		visible = false
		_is_closing = false
		closed.emit()
	)

func _on_save_pressed() -> void:
	SoundManager.play_click()
	var success := SaveManager.save_game(true, false)
	if success:
		status_label.text = "Game saved successfully! ✔"
		status_label.add_theme_color_override("font_color", Color(0.18, 0.65, 0.32))
	else:
		status_label.text = "Failed to save game! ✖"
		status_label.add_theme_color_override("font_color", Color(0.85, 0.2, 0.2))

func _on_bgm_pressed() -> void:
	SoundManager.play_click()
	SoundManager.toggle_bgm()
	_update_bgm_button()

func _update_bgm_button() -> void:
	if is_instance_valid(bgm_btn):
		if SoundManager.bgm_enabled:
			bgm_btn.text = "  MUSIC: ON"
		else:
			bgm_btn.text = "  MUSIC: OFF"

func _on_sfx_pressed() -> void:
	var enabled := SoundManager.toggle_sfx()
	if enabled:
		SoundManager.play_click()
	_update_sfx_button()

func _update_sfx_button() -> void:
	if is_instance_valid(sfx_btn):
		if SoundManager.sfx_enabled:
			sfx_btn.text = "  SOUND EFFECTS: ON"
		else:
			sfx_btn.text = "  SOUND EFFECTS: OFF"

func _on_orientation_pressed() -> void:
	SoundManager.play_click()
	if is_instance_valid(OrientationManager):
		OrientationManager.toggle_orientation()
		_update_orientation_button()
		if SaveManager:
			SaveManager.save_game(false, false)

func _update_orientation_button() -> void:
	if is_instance_valid(orientation_btn) and is_instance_valid(OrientationManager):
		if OrientationManager.is_landscape:
			orientation_btn.text = "  ORIENTATION: LANDSCAPE"
		else:
			orientation_btn.text = "  ORIENTATION: PORTRAIT"

func _on_menu_pressed() -> void:
	SoundManager.play_click()
	# Auto-save before returning to main menu
	SaveManager.save_game(false, false)
	SaveManager.is_gameplay_active = false
	if is_instance_valid(SoundManager):
		SoundManager.play_bgm(SoundManager.BGM_MENU)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_debug_pressed() -> void:
	close_modal()
	GameEvents.request_debug_toggle.emit()

