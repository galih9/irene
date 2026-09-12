class_name OrientationManagerScript
extends Node

signal orientation_changed(is_landscape: bool)

const SETTINGS_FILE_PATH: String = "user://orientation_settings.json"
const CANVAS_PORTRAIT: Vector2i = Vector2i(720, 1600)
const CANVAS_LANDSCAPE: Vector2i = Vector2i(1600, 900)

var is_landscape: bool = false
var _initialized: bool = false

func _ready() -> void:
	_init_orientation()

func _init_orientation() -> void:
	if _initialized:
		return
	_initialized = true

	# 1. Check if user already has a saved orientation setting
	var saved_setting: Variant = _load_saved_orientation()

	var target_landscape: bool = false
	if saved_setting != null:
		target_landscape = bool(saved_setting)
	else:
		# First time opening: check device screen
		target_landscape = detect_device_screen_landscape()

	set_landscape(target_landscape, false)

func detect_device_screen_landscape() -> bool:
	var screen_size: Vector2i = DisplayServer.screen_get_size()
	if screen_size == Vector2i.ZERO:
		screen_size = DisplayServer.window_get_size()

	# If wide width (width > height), automatically landscape on first opening
	# If small width (width <= height), automatically portrait
	return screen_size.x > screen_size.y

func set_landscape(enable: bool, save_setting: bool = true) -> void:
	is_landscape = enable

	# Apply canvas content scale size
	var root_viewport: Window = get_tree().root
	if is_instance_valid(root_viewport):
		root_viewport.content_scale_size = CANVAS_LANDSCAPE if is_landscape else CANVAS_PORTRAIT

	# Mobile / handheld screen orientation
	if OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"):
		if is_landscape:
			DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)
		else:
			DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	elif not OS.has_feature("web"):
		# On Desktop (Windows/macOS/Linux): adapt window size if orientation flipped
		_adapt_desktop_window_size()

	if save_setting:
		_save_orientation(is_landscape)

	orientation_changed.emit(is_landscape)

func toggle_orientation() -> void:
	set_landscape(not is_landscape, true)

func _adapt_desktop_window_size() -> void:
	var win_size: Vector2i = DisplayServer.window_get_size()
	if win_size == Vector2i.ZERO:
		return

	# If window aspect doesn't match orientation mode, adjust desktop window
	var win_is_landscape: bool = win_size.x > win_size.y
	if is_landscape and not win_is_landscape:
		# Flip to landscape
		var new_size := Vector2i(maxi(win_size.y, 960), mini(win_size.x, 600))
		DisplayServer.window_set_size(new_size)
		_center_window_on_screen(new_size)
	elif not is_landscape and win_is_landscape:
		# Flip to portrait
		var new_size := Vector2i(mini(win_size.y, 600), maxi(win_size.x, 960))
		DisplayServer.window_set_size(new_size)
		_center_window_on_screen(new_size)

func _center_window_on_screen(size: Vector2i) -> void:
	var screen_idx: int = DisplayServer.window_get_current_screen()
	var screen_rect: Rect2i = DisplayServer.screen_get_usable_rect(screen_idx)
	var new_pos := screen_rect.position + (screen_rect.size - size) / 2
	DisplayServer.window_set_position(new_pos)

func _save_orientation(val: bool) -> void:
	var file := FileAccess.open(SETTINGS_FILE_PATH, FileAccess.WRITE)
	if file:
		var data := {"is_landscape": val}
		file.store_string(JSON.stringify(data))
		file.close()

func _load_saved_orientation() -> Variant:
	if not FileAccess.file_exists(SETTINGS_FILE_PATH):
		return null
	var file := FileAccess.open(SETTINGS_FILE_PATH, FileAccess.READ)
	if not file:
		return null
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) == OK and json.data is Dictionary:
		var d: Dictionary = json.data
		if d.has("is_landscape"):
			return d.get("is_landscape")
	return null
