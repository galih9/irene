class_name MainMenu
extends Control

const AppVersion = preload("res://scripts/core/app_version.gd")

@onready var menu_container: Control = $UI/MenuContainer
@onready var title_area: Control = $UI/MenuContainer/TitleArea
@onready var title_badge: Control = $UI/MenuContainer/TitleArea/TitleContainer
@onready var title_label: Label = $UI/MenuContainer/TitleArea/TitleContainer/Margin/VBox/Title
@onready var tap_to_play_area: Button = $UI/MenuContainer/TapToPlayArea
@onready var tap_prompt_area: Control = $UI/MenuContainer/TapPromptArea
@onready var tap_prompt_container: Control = $UI/MenuContainer/TapPromptArea/VBox
@onready var tap_label: Label = $UI/MenuContainer/TapPromptArea/VBox/TapLabel
@onready var save_info_label: Label = $UI/MenuContainer/TapPromptArea/VBox/SaveInfoLabel
@onready var bottom_area: Control = $UI/MenuContainer/BottomArea
@onready var options_btn: Button = $UI/MenuContainer/BottomArea/NavButtons/OptionsBtn
@onready var experimental_btn: Button = $UI/MenuContainer/BottomArea/NavButtons/ExperimentalBtn if has_node("UI/MenuContainer/BottomArea/NavButtons/ExperimentalBtn") else null
@onready var quit_btn: Button = $UI/MenuContainer/BottomArea/NavButtons/QuitBtn
@onready var background_rect: TextureRect = $Background
@onready var version_label: Label = $UI/VersionLabel if has_node("UI/VersionLabel") else null

# Backward-compatibility buttons (found in HiddenLegacy or fallback to tap_to_play_area)
@onready var continue_btn: Button = find_child("ContinueBtn", true, false) if has_node("UI/HiddenLegacy/ContinueBtn") else tap_to_play_area
@onready var new_game_btn: Button = find_child("NewGameBtn", true, false) if has_node("UI/HiddenLegacy/NewGameBtn") else tap_to_play_area

@onready var option_modal: OptionModal = $Modals/OptionModal

const BG_PORTRAIT = preload("res://assets/background/kitchen.jpeg")
const BG_LANDSCAPE = preload("res://assets/background/kitchen_landscape.jpg")

var _is_starting: bool = false
var _pulse_tween: Tween = null
var _title_tween: Tween = null

func _ready() -> void:
	if is_instance_valid(version_label):
		version_label.text = AppVersion.get_version_string()

	# Connect Tap to Play
	if is_instance_valid(tap_to_play_area):
		tap_to_play_area.pressed.connect(_on_tap_to_play)

	# Connect Bottom Nav buttons
	if is_instance_valid(options_btn):
		options_btn.pressed.connect(_on_options_pressed)
		_setup_button_hover(options_btn)

	if is_instance_valid(experimental_btn):
		experimental_btn.pressed.connect(_on_experimental_pressed)
		_setup_button_hover(experimental_btn)

	if is_instance_valid(quit_btn):
		quit_btn.pressed.connect(_on_quit_pressed)
		_setup_button_hover(quit_btn)

	# Legacy buttons
	if is_instance_valid(continue_btn) and continue_btn != tap_to_play_area:
		continue_btn.pressed.connect(_on_continue_pressed)
	if is_instance_valid(new_game_btn) and new_game_btn != tap_to_play_area:
		new_game_btn.pressed.connect(_on_new_game_pressed)

	if option_modal:
		option_modal.closed.connect(_on_options_closed)

	if is_instance_valid(OrientationManager):
		OrientationManager.orientation_changed.connect(_on_orientation_changed)
		_on_orientation_changed(OrientationManager.is_landscape)

	# Web version: Exit button is hidden
	if OS.has_feature("web"):
		quit_btn.visible = false

	if is_instance_valid(SoundManager):
		SoundManager.play_bgm(SoundManager.BGM_MENU)

	if SaveManager and not SaveManager.save_deleted.is_connected(_update_save_state):
		SaveManager.save_deleted.connect(_update_save_state)

	_update_save_state()
	tap_to_play_area.grab_focus.call_deferred()
	_animate_title()
	_animate_tap_prompt()

func _setup_button_hover(btn: Button) -> void:
	if not is_instance_valid(btn):
		return
	btn.pivot_offset = btn.custom_minimum_size * 0.5
	btn.mouse_entered.connect(func():
		if not btn.disabled:
			var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.12)
	)
	btn.mouse_exited.connect(func():
		var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(btn, "scale", Vector2.ONE, 0.1)
	)

func _on_orientation_changed(is_landscape: bool) -> void:
	if is_instance_valid(background_rect):
		background_rect.texture = BG_LANDSCAPE if is_landscape else BG_PORTRAIT

	tap_to_play_area.anchor_top = 0.60 if is_landscape else 0.56
	tap_to_play_area.anchor_bottom = tap_to_play_area.anchor_top
	if is_landscape:
		if is_instance_valid(title_area):
			title_area.anchor_top = 0.30
			title_area.anchor_bottom = 0.30
		if is_instance_valid(tap_prompt_area):
			tap_prompt_area.anchor_top = 0.73
			tap_prompt_area.anchor_bottom = 0.73
		if is_instance_valid(bottom_area):
			bottom_area.offset_top = -110.0
			bottom_area.offset_bottom = -30.0
	else:
		if is_instance_valid(title_area):
			title_area.anchor_top = 0.28
			title_area.anchor_bottom = 0.28
		if is_instance_valid(tap_prompt_area):
			tap_prompt_area.anchor_top = 0.67
			tap_prompt_area.anchor_bottom = 0.67
		if is_instance_valid(bottom_area):
			bottom_area.offset_top = -140.0
			bottom_area.offset_bottom = -40.0

func _update_save_state() -> void:
	var has_save := SaveManager.has_save()
	tap_to_play_area.text = "Continue your story" if has_save else "Start your story"
	tap_label.text = "Welcome back. Settle in and keep merging." if has_save else "A little merge. A lovely new discovery."
	if has_save:
		var info := SaveManager.get_save_info()
		save_info_label.text = "%d gold  ·  %d gems  ·  Progress saved" % [info.get("coins", 0), info.get("gems", 0)]
	else:
		save_info_label.text = "Discover recipes, fulfill orders, and grow your world."
	save_info_label.add_theme_color_override("font_color", Color(0.93, 0.94, 0.85))

func _animate_title() -> void:
	title_badge.modulate.a = 0.0
	_title_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_title_tween.tween_property(title_badge, "modulate:a", 1.0, 0.45)

func _animate_tap_prompt() -> void:
	tap_prompt_container.modulate.a = 0.0
	_pulse_tween = create_tween()
	_pulse_tween.tween_property(tap_prompt_container, "modulate:a", 1.0, 0.45).set_delay(0.15)

func _on_tap_to_play() -> void:
	if _is_starting:
		return
	if option_modal and option_modal.visible:
		return
	_is_starting = true
	tap_to_play_area.disabled = true
	tap_to_play_area.text = "Opening your world…"

	if is_instance_valid(SoundManager):
		SoundManager.play_click()

	SaveManager.should_load_on_start = SaveManager.has_save()

	if is_instance_valid(tap_label):
		if _pulse_tween and _pulse_tween.is_valid():
			_pulse_tween.kill()
		var pop_tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pop_tween.tween_property(tap_label, "scale", Vector2(1.18, 1.18), 0.12)
		pop_tween.tween_callback(func():
			get_tree().change_scene_to_file("res://main.tscn")
		)
	else:
		get_tree().change_scene_to_file("res://main.tscn")

func _on_continue_pressed() -> void:
	_on_tap_to_play()

func _on_new_game_pressed() -> void:
	if is_instance_valid(SoundManager):
		SoundManager.play_click()
	SaveManager.should_load_on_start = false
	get_tree().change_scene_to_file("res://main.tscn")

func _on_options_pressed() -> void:
	if is_instance_valid(SoundManager):
		SoundManager.play_click()
	if option_modal:
		menu_container.visible = false
		option_modal.open_modal()
		var settings_panel := option_modal.get_node("Panel") as Control
		settings_panel.custom_minimum_size.y = 620.0
		settings_panel.offset_top = -310.0
		settings_panel.offset_bottom = 310.0
		if option_modal.has_node("Panel/Margin/VBox/Content/MenuBtn"):
			option_modal.get_node("Panel/Margin/VBox/Content/MenuBtn").visible = false
		if option_modal.has_node("Panel/Margin/VBox/Content/SaveBtn"):
			option_modal.get_node("Panel/Margin/VBox/Content/SaveBtn").visible = false
		if option_modal.has_node("Panel/Margin/VBox/Content/ResumeBtn"):
			option_modal.get_node("Panel/Margin/VBox/Content/ResumeBtn").text = "BACK"

func _on_options_closed() -> void:
	menu_container.visible = true
	_update_save_state()
	options_btn.grab_focus()

func _on_experimental_pressed() -> void:
	if is_instance_valid(SoundManager):
		SoundManager.play_click()
	get_tree().change_scene_to_file("res://scenes/experimental/world.tscn")

func _on_quit_pressed() -> void:
	if is_instance_valid(SoundManager):
		SoundManager.play_drop()
	get_tree().quit()
