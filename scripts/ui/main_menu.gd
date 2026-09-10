class_name MainMenu
extends Control

@onready var continue_btn: Button = $UI/CenterContainer/VBox/Buttons/ContinueBtn
@onready var save_info_label: Label = $UI/CenterContainer/VBox/Buttons/SaveInfoLabel
@onready var new_game_btn: Button = $UI/CenterContainer/VBox/Buttons/NewGameBtn
@onready var options_btn: Button = $UI/CenterContainer/VBox/Buttons/OptionsBtn
@onready var quit_btn: Button = $UI/CenterContainer/VBox/Buttons/QuitBtn
@onready var title_badge: Control = $UI/CenterContainer/VBox/TitleContainer

@onready var option_modal: OptionModal = $Modals/OptionModal

func _ready() -> void:
	continue_btn.pressed.connect(_on_continue_pressed)
	new_game_btn.pressed.connect(_on_new_game_pressed)
	options_btn.pressed.connect(_on_options_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)

	if OS.has_feature("web"):
		quit_btn.visible = false

	_update_save_state()
	_animate_title()

func _update_save_state() -> void:
	var has_save := SaveManager.has_save()
	continue_btn.disabled = not has_save
	continue_btn.modulate.a = 1.0 if has_save else 0.45

	if has_save:
		var info := SaveManager.get_save_info()
		save_info_label.text = "Saved: %s  •  %d Gold  %d Gems  %d Energy" % [
			info.get("timestamp", ""),
			info.get("coins", 0),
			info.get("gems", 0),
			info.get("energy", 0)
		]
		save_info_label.add_theme_color_override("font_color", Color(0.88, 0.84, 0.78, 0.85))
	else:
		save_info_label.text = "Start a fresh adventure below!"
		save_info_label.add_theme_color_override("font_color", Color(0.72, 0.68, 0.64, 0.75))

func _animate_title() -> void:
	if not title_badge:
		return
	title_badge.pivot_offset = title_badge.size * 0.5
	var tween := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(title_badge, "scale", Vector2(1.03, 1.03), 1.6)
	tween.tween_property(title_badge, "scale", Vector2(0.98, 0.98), 1.6)

func _on_continue_pressed() -> void:
	SoundManager.play_pickup()
	SaveManager.should_load_on_start = true
	get_tree().change_scene_to_file("res://main.tscn")

func _on_new_game_pressed() -> void:
	SoundManager.play_pickup()
	SaveManager.should_load_on_start = false
	get_tree().change_scene_to_file("res://main.tscn")

func _on_options_pressed() -> void:
	SoundManager.play_pickup()
	if option_modal:
		# In main menu, we can hide the MenuBtn inside OptionModal since we are already on Main Menu
		if option_modal.has_node("Panel/Margin/VBox/Content/MenuBtn"):
			option_modal.get_node("Panel/Margin/VBox/Content/MenuBtn").visible = false
		option_modal.open_modal()

func _on_quit_pressed() -> void:
	SoundManager.play_drop()
	get_tree().quit()
