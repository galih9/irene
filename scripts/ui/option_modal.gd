class_name OptionModal
extends Control

const DialogMotion = preload("res://scripts/ui/modal_presenter.gd")

const AppVersion = preload("res://scripts/core/app_version.gd")

signal closed()

var _is_closing: bool = false
var _is_delete_confirming: bool = false
var _delete_confirm_tween: Tween = null
var _danger_confirm_style: StyleBoxFlat = null

@onready var title_label: Label = $Panel/Margin/VBox/Header/Title
@onready var close_btn: Button = $Panel/Margin/VBox/Header/CloseBtn
@onready var save_btn: Button = $Panel/Margin/VBox/Content/SaveBtn
@onready var bgm_btn: Button = $Panel/Margin/VBox/Content/BgmBtn
@onready var sfx_btn: Button = $Panel/Margin/VBox/Content/SfxBtn
@onready var menu_btn: Button = $Panel/Margin/VBox/Content/MenuBtn
@onready var orientation_btn: Button = $Panel/Margin/VBox/Content/OrientationBtn
@onready var delete_btn: Button = $Panel/Margin/VBox/Content/DeleteBtn
@onready var debug_btn: Button = $Panel/Margin/VBox/Content/DebugBtn
@onready var resume_btn: Button = $Panel/Margin/VBox/Content/ResumeBtn
@onready var status_label: Label = $Panel/Margin/VBox/Content/StatusLabel
@onready var version_label: Label = $Panel/Margin/VBox/VersionLabel if has_node("Panel/Margin/VBox/VersionLabel") else null

func _ready() -> void:
	visible = false
	_init_styles()
	DialogMotion.install(self, close_btn, close_modal)
	close_btn.pressed.connect(close_modal)
	resume_btn.pressed.connect(close_modal)
	save_btn.pressed.connect(_on_save_pressed)
	bgm_btn.pressed.connect(_on_bgm_pressed)
	sfx_btn.pressed.connect(_on_sfx_pressed)
	if is_instance_valid(orientation_btn):
		orientation_btn.pressed.connect(_on_orientation_pressed)
	menu_btn.pressed.connect(_on_menu_pressed)
	if is_instance_valid(delete_btn):
		delete_btn.pressed.connect(_on_delete_pressed)
		_setup_button_hover(delete_btn)
	debug_btn.pressed.connect(_on_debug_pressed)
	debug_btn.visible = OS.has_feature("editor")

	GameEvents.request_options_open.connect(open_modal)
	_update_bgm_button()
	_update_sfx_button()
	_update_orientation_button()
	_update_delete_button_visuals()
	if is_instance_valid(version_label):
		version_label.text = AppVersion.get_full_display()

	_setup_button_hover(save_btn)
	_setup_button_hover(bgm_btn)
	_setup_button_hover(sfx_btn)
	_setup_button_hover(orientation_btn)
	_setup_button_hover(menu_btn)
	_setup_button_hover(debug_btn)
	_setup_button_hover(resume_btn)
	_setup_button_hover(close_btn)

func _init_styles() -> void:
	_danger_confirm_style = StyleBoxFlat.new()
	_danger_confirm_style.content_margin_left = 16.0
	_danger_confirm_style.content_margin_top = 12.0
	_danger_confirm_style.content_margin_right = 16.0
	_danger_confirm_style.content_margin_bottom = 12.0
	_danger_confirm_style.bg_color = Color(0.85, 0.22, 0.22, 1.0)
	_danger_confirm_style.border_width_left = 1
	_danger_confirm_style.border_width_top = 1
	_danger_confirm_style.border_width_right = 1
	_danger_confirm_style.border_width_bottom = 1
	_danger_confirm_style.border_color = Color(0.70, 0.15, 0.15, 1.0)
	_danger_confirm_style.corner_radius_top_left = 12
	_danger_confirm_style.corner_radius_top_right = 12
	_danger_confirm_style.corner_radius_bottom_right = 12
	_danger_confirm_style.corner_radius_bottom_left = 12
	_danger_confirm_style.shadow_color = Color(0.85, 0.22, 0.22, 0.35)
	_danger_confirm_style.shadow_size = 6
	_danger_confirm_style.shadow_offset = Vector2(0, 2)

func _setup_button_hover(btn: Button) -> void:
	if not is_instance_valid(btn):
		return
	btn.pivot_offset = btn.size * 0.5
	btn.mouse_entered.connect(func():
		if not btn.disabled:
			var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(btn, "scale", Vector2(1.02, 1.02), 0.1)
	)
	btn.mouse_exited.connect(func():
		var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(btn, "scale", Vector2.ONE, 0.08)
	)

func open_modal() -> void:
	_is_closing = false
	_disarm_delete_confirmation()
	DialogMotion.show_dialog(self)
	status_label.text = ""
	_update_bgm_button()
	_update_sfx_button()
	_update_orientation_button()
	_update_delete_button_visuals()
	if is_instance_valid(version_label):
		version_label.text = AppVersion.get_full_display()
	var in_gameplay := SaveManager.is_gameplay_active if SaveManager else false
	if is_instance_valid(menu_btn):
		menu_btn.visible = in_gameplay
	if is_instance_valid(save_btn):
		save_btn.visible = in_gameplay
	if is_instance_valid(delete_btn):
		delete_btn.visible = true
	if is_instance_valid(title_label):
		title_label.text = "Take a little break" if in_gameplay else "Make yourself at home"
	if is_instance_valid(resume_btn):
		resume_btn.text = "  RESUME GAME" if in_gameplay else "  BACK"

func close_modal() -> void:
	if _is_closing or not visible:
		return
	_is_closing = true
	_disarm_delete_confirmation()
	SoundManager.play_drop()
	DialogMotion.hide_dialog(self, func():
		_is_closing = false
		closed.emit()
	)

func _on_save_pressed() -> void:
	_disarm_delete_confirmation()
	SoundManager.play_click()
	var success := SaveManager.save_game(true, false)
	if success:
		status_label.text = "Game saved successfully!"
		status_label.add_theme_color_override("font_color", Color(0.18, 0.65, 0.32))
	else:
		status_label.text = "Failed to save game!"
		status_label.add_theme_color_override("font_color", Color(0.85, 0.2, 0.2))

func _on_bgm_pressed() -> void:
	_disarm_delete_confirmation()
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
	_disarm_delete_confirmation()
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
	_disarm_delete_confirmation()
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
	_disarm_delete_confirmation()
	SoundManager.play_click()
	# Auto-save before returning to main menu
	SaveManager.save_game(false, false)
	SaveManager.is_gameplay_active = false
	if is_instance_valid(SoundManager):
		SoundManager.play_bgm(SoundManager.BGM_MENU)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_debug_pressed() -> void:
	_disarm_delete_confirmation()
	close_modal()
	GameEvents.request_debug_toggle.emit()

func _on_delete_pressed() -> void:
	if not _is_delete_confirming:
		if is_instance_valid(SoundManager):
			SoundManager.play_click()
		_arm_delete_confirmation()
	else:
		_execute_delete()

func _arm_delete_confirmation() -> void:
	_is_delete_confirming = true
	if _delete_confirm_tween and _delete_confirm_tween.is_valid():
		_delete_confirm_tween.kill()

	if is_instance_valid(delete_btn):
		delete_btn.text = "  CONFIRM: DELETE SAVE DATA?"
		delete_btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		delete_btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
		delete_btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 1))
		delete_btn.add_theme_stylebox_override("normal", _danger_confirm_style)
		delete_btn.add_theme_stylebox_override("hover", _danger_confirm_style)

	if is_instance_valid(status_label):
		status_label.text = "Warning: This will permanently erase all progress!"
		status_label.add_theme_color_override("font_color", Color(0.85, 0.25, 0.25))

	_delete_confirm_tween = create_tween()
	_delete_confirm_tween.tween_interval(4.0)
	_delete_confirm_tween.tween_callback(_disarm_delete_confirmation)

func _disarm_delete_confirmation() -> void:
	_is_delete_confirming = false
	if _delete_confirm_tween and _delete_confirm_tween.is_valid():
		_delete_confirm_tween.kill()
		_delete_confirm_tween = null

	_update_delete_button_visuals()
	if is_instance_valid(status_label) and status_label.text.begins_with("Warning:"):
		status_label.text = ""

func _update_delete_button_visuals() -> void:
	if not is_instance_valid(delete_btn):
		return

	delete_btn.remove_theme_color_override("font_color")
	delete_btn.remove_theme_color_override("font_hover_color")
	delete_btn.remove_theme_color_override("font_pressed_color")
	delete_btn.remove_theme_stylebox_override("normal")
	delete_btn.remove_theme_stylebox_override("hover")

	var has_save: bool = SaveManager.has_save() if SaveManager else false
	var in_gameplay: bool = SaveManager.is_gameplay_active if SaveManager else false

	if in_gameplay or has_save:
		delete_btn.disabled = false
		delete_btn.text = "  DELETE SAVE DATA"
		delete_btn.add_theme_color_override("font_color", Color(0.78, 0.24, 0.24, 1.0))
	else:
		delete_btn.disabled = true
		delete_btn.text = "  NO SAVE DATA"
		delete_btn.add_theme_color_override("font_color", Color(0.60, 0.64, 0.68, 0.8))

func _execute_delete() -> void:
	_is_delete_confirming = false
	if _delete_confirm_tween and _delete_confirm_tween.is_valid():
		_delete_confirm_tween.kill()
		_delete_confirm_tween = null

	if is_instance_valid(SoundManager):
		SoundManager.play_drop()

	var was_in_gameplay: bool = SaveManager.is_gameplay_active if SaveManager else false

	if SaveManager:
		SaveManager.reset_game_data()

	if was_in_gameplay:
		SaveManager.is_gameplay_active = false
		if is_instance_valid(SoundManager):
			SoundManager.play_bgm(SoundManager.BGM_MENU)
		get_tree().change_scene_to_file.call_deferred("res://scenes/main_menu.tscn")
	else:
		_update_delete_button_visuals()
		if is_instance_valid(status_label):
			status_label.text = "Save data deleted successfully!"
			status_label.add_theme_color_override("font_color", Color(0.18, 0.65, 0.32))
