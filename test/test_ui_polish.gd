extends Node
## Run: godot --headless --path . res://test/test_ui_polish.tscn
## Uses a disposable save path; never reads or writes the player's progress.

var failures: int = 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _ready() -> void:
	SaveManager.save_file_path = "user://ui_polish_test_unused.json"
	SaveManager.auto_save_enabled = false
	var menu: Control = load("res://scenes/main_menu.tscn").instantiate()
	add_child(menu)
	await get_tree().process_frame
	check(menu.tap_to_play_area.focus_mode == Control.FOCUS_ALL, "Play action must support keyboard focus")
	check(menu.tap_to_play_area.size.x < 600.0, "Play action must be an explicit button")
	for landscape in [false, true]:
		OrientationManager.set_landscape(landscape, false)
		get_tree().root.size = Vector2i(1600, 900) if landscape else Vector2i(720, 1600)
		await get_tree().process_frame
		menu.options_btn.grab_focus()
		menu._on_options_pressed()
		await get_tree().create_timer(0.3).timeout
		var modal: Control = menu.option_modal
		check(modal.scale == Vector2.ONE, "Backdrop must remain full screen during animation")
		check(get_viewport().gui_get_focus_owner() == modal.close_btn, "Dialog must receive focus")
		var tab := InputEventAction.new()
		tab.action = "ui_focus_next"
		tab.pressed = true
		for index in range(12):
			Input.parse_input_event(tab)
			await get_tree().process_frame
			check(modal.is_ancestor_of(get_viewport().gui_get_focus_owner()), "Tab focus must stay in the dialog")
		var escape := InputEventAction.new()
		escape.action = "ui_cancel"
		escape.pressed = true
		Input.parse_input_event(escape)
		await get_tree().create_timer(0.3).timeout
		check(not modal.visible, "Escape must dismiss the dialog")
		check(get_viewport().gui_get_focus_owner() == menu.options_btn, "Dismissal must restore focus")
	menu.queue_free()
	await get_tree().process_frame
	var nav: BottomNavBar = load("res://scenes/bottom_nav_bar.tscn").instantiate()
	add_child(nav)
	for vertical in [false, true]:
		nav.set_layout_vertical(vertical)
		for button in nav.hbox.get_children():
			button.visible = true
		await get_tree().process_frame
		check(nav.inventory_title.is_visible_in_tree(), "Backpack label must be visible on touch devices")
		check(str(BottomNavBar.MILESTONE_BACKPACK) in nav.inventory_btn.tooltip_text, "Unlock copy must match gameplay")
		check(nav.hbox.get_combined_minimum_size().x <= (200 if vertical else 664), "Navigation must fit its allotted width")
		if vertical:
			check(nav.hbox.get_combined_minimum_size().y <= 552, "All six navigation actions must fit vertically")
	for scene_name in ["inventory", "shop", "progression", "level_selection", "minigame_selection"]:
		var dialog: Control = load("res://scenes/%s_modal.tscn" % scene_name).instantiate()
		add_child(dialog)
		if scene_name == "shop":
			dialog.open_shop()
		else:
			dialog.open_modal()
		await get_tree().create_timer(0.3).timeout
		check(dialog.scale == Vector2.ONE, "%s backdrop must cover the viewport" % scene_name)
		var cancel := InputEventAction.new()
		cancel.action = "ui_cancel"
		cancel.pressed = true
		Input.parse_input_event(cancel)
		await get_tree().create_timer(0.2).timeout
		check(not dialog.visible, "%s must close with Escape" % scene_name)
		dialog.queue_free()
		await get_tree().process_frame
	var card: QuestCard = load("res://scenes/quest_card.tscn").instantiate()
	add_child(card)
	var quest := QuestData.new()
	quest.id = "ui_test"
	quest.customer_name = "Test customer"
	var available: Array[String] = []
	card.setup(quest, false, available)
	check(card.background.has_theme_stylebox_override("panel"), "Regular orders must retain their readable card background")
	print("UI POLISH: %d failures" % failures)
	get_tree().quit(0 if failures == 0 else 1)
