class_name SplashScreen
extends Control

## Pre-scene boot splash displayed on game startup.
## Plays boot.ogg, auto-crops/zooms for landscape and portrait viewports,
## and transitions cleanly to main_menu.tscn without any loading bar.

signal splash_completed()

const NEXT_SCENE_PATH: String = "res://scenes/main_menu.tscn"
const BOOT_SOUND_PATH: String = "res://assets/boot.ogg"
const SPLASH_TEXTURE_PATH: String = "res://assets/splash.png"
const SPLASH_DURATION: float = 3.0

@onready var background_color: ColorRect = $BackgroundColor
@onready var splash_image: TextureRect = $SplashImage
@onready var boot_audio: AudioStreamPlayer = $BootAudioPlayer
@onready var fade_overlay: ColorRect = $FadeOverlay

var _is_transitioning: bool = false
var _can_skip: bool = false

func _ready() -> void:
	# 1. Stop autoload BGM during splash so boot sound plays cleanly
	if is_instance_valid(SoundManager):
		SoundManager.stop_bgm()

	# 2. Hook up orientation & viewport size listeners
	if is_instance_valid(OrientationManager):
		OrientationManager.orientation_changed.connect(_on_orientation_changed)
		_apply_orientation_layout(OrientationManager.is_landscape)
	else:
		_apply_orientation_layout(_is_viewport_landscape())

	get_viewport().size_changed.connect(_on_viewport_size_changed)

	# 3. Setup audio player - plays boot sound exactly once on splash display
	if is_instance_valid(boot_audio):
		if boot_audio.stream == null and ResourceLoader.exists(BOOT_SOUND_PATH):
			boot_audio.stream = load(BOOT_SOUND_PATH)
		boot_audio.play()

	# 4. Fade in from background color
	if is_instance_valid(fade_overlay):
		fade_overlay.visible = true
		fade_overlay.modulate = Color(1, 1, 1, 1)
		var tween := create_tween()
		tween.tween_property(fade_overlay, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Allow skipping via input after a brief moment
	var skip_timer := get_tree().create_timer(0.4)
	skip_timer.timeout.connect(func(): _can_skip = true)

	# 3-second splash screen duration timer
	var splash_timer := get_tree().create_timer(SPLASH_DURATION)
	splash_timer.timeout.connect(func():
		if not _is_transitioning:
			_start_transition()
	)

func _unhandled_input(event: InputEvent) -> void:
	if not _can_skip or _is_transitioning:
		return
	if event is InputEventMouseButton and event.pressed:
		_start_transition(0.18)
	elif event is InputEventScreenTouch and event.pressed:
		_start_transition(0.18)
	elif event is InputEventKey and event.pressed:
		if event.keycode in [KEY_SPACE, KEY_ENTER, KEY_ESCAPE]:
			_start_transition(0.18)

func _on_viewport_size_changed() -> void:
	_apply_orientation_layout(_is_viewport_landscape())

func _on_orientation_changed(is_landscape: bool) -> void:
	_apply_orientation_layout(is_landscape)

func _is_viewport_landscape() -> bool:
	var vp_size := get_viewport_rect().size
	return vp_size.x > vp_size.y

func _apply_orientation_layout(is_landscape: bool) -> void:
	if not is_instance_valid(splash_image):
		return

	# Automatically crop and zoom centered image to fill the screen
	# STRETCH_KEEP_ASPECT_COVERED (6) ensures the image covers the entire viewport
	# and crops outer margins, keeping the center text perfectly visible
	splash_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	splash_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	splash_image.anchor_left = 0.0
	splash_image.anchor_top = 0.0
	splash_image.anchor_right = 1.0
	splash_image.anchor_bottom = 1.0
	splash_image.offset_left = 0.0
	splash_image.offset_top = 0.0
	splash_image.offset_right = 0.0
	splash_image.offset_bottom = 0.0

	# Keep pivot centered for any scale tweens or rotations
	splash_image.pivot_offset = splash_image.size / 2.0

func _start_transition(fade_duration: float = 0.3) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true

	# Fade out smoothly to brand background color
	if is_instance_valid(fade_overlay):
		fade_overlay.visible = true
		var tween := create_tween()
		tween.tween_property(fade_overlay, "modulate:a", 1.0, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_callback(_complete_transition)
	else:
		_complete_transition()

func _complete_transition() -> void:
	splash_completed.emit()

	# Start ambient BGM when entering main menu
	if is_instance_valid(SoundManager) and SoundManager.bgm_enabled:
		SoundManager.play_bgm(SoundManager.BGM_MENU)

	# Change scene to main menu
	var err := get_tree().change_scene_to_file(NEXT_SCENE_PATH)
	if err != OK:
		push_error("SplashScreen: Failed to transition to %s (error %d)" % [NEXT_SCENE_PATH, err])
