class_name StartupLoadingScreen
extends Control

## Dedicated startup loading screen displayed after the splash screen.
## Plays ambient music immediately, preloads game scenes in background,
## displays dynamic tips and progress bar with a 5-second duration,
## then cleanly transitions to the main menu.

const NEXT_SCENE_PATH: String = "res://scenes/main_menu.tscn"
const AppVersion = preload("res://scripts/core/app_version.gd")
const PRELOAD_SCENE_PATHS: Array[String] = [
	"res://scenes/main_menu.tscn",
	"res://main.tscn"
]
const MIN_LOAD_DURATION: float = 5.0

const TIPS: Array[String] = [
	"💡 Tip: Feed farm animals once to prepare them for merging!",
	"💡 Tip: Water your fruit trees to harvest fresh, delicious fruits!",
	"💡 Tip: Backpack items preserve all their remaining charges and status!",
	"💡 Tip: Complete quests to earn coins, gems, and expand your backpack!",
	"💡 Tip: Merge higher tier items to discover exciting new items!"
]

@onready var background_rect: ColorRect = $Background
@onready var icon_rect: TextureRect = $CenterContainer/VBox/IconContainer/Icon
@onready var title_label: Label = $CenterContainer/VBox/TitleLabel
@onready var progress_bar: ProgressBar = $CenterContainer/VBox/ProgressBar
@onready var percent_label: Label = $CenterContainer/VBox/PercentLabel
@onready var tip_label: Label = $CenterContainer/VBox/TipLabel
@onready var version_label: Label = $VersionLabel
@onready var fade_overlay: ColorRect = $FadeOverlay

var _elapsed_time: float = 0.0
var _display_progress: float = 0.0
var _target_progress: float = 0.0
var _tip_timer: float = 0.0
var _current_tip_index: int = 0
var _is_transitioning: bool = false
var _scenes_loaded: bool = false

func _ready() -> void:
	# 1. Start ambient music immediately
	if is_instance_valid(SoundManager):
		SoundManager.play_bgm(SoundManager.BGM_MENU)

	# 2. Set version display
	if is_instance_valid(version_label):
		version_label.text = AppVersion.get_version_string()

	# 3. Initialize tip
	if is_instance_valid(tip_label) and not TIPS.is_empty():
		tip_label.text = TIPS[0]

	# 4. Request background threaded loading for primary scenes
	for path in PRELOAD_SCENE_PATHS:
		if ResourceLoader.exists(path):
			ResourceLoader.load_threaded_request(path)

	# 5. Icon gentle pulsing animation
	if is_instance_valid(icon_rect):
		icon_rect.pivot_offset = icon_rect.size * 0.5
		var tween := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(icon_rect, "scale", Vector2(1.08, 1.08), 1.2)
		tween.tween_property(icon_rect, "scale", Vector2(0.95, 0.95), 1.2)

	# 6. Fade in from black
	if is_instance_valid(fade_overlay):
		fade_overlay.visible = true
		fade_overlay.modulate = Color(1, 1, 1, 1)
		var fade_in := create_tween()
		fade_in.tween_property(fade_overlay, "modulate:a", 0.0, 0.35)

func _process(delta: float) -> void:
	_elapsed_time += delta
	_tip_timer += delta

	# Cycle tips every 2.5 seconds
	if _tip_timer >= 2.5 and not TIPS.is_empty():
		_tip_timer = 0.0
		_current_tip_index = (_current_tip_index + 1) % TIPS.size()
		if is_instance_valid(tip_label):
			var tip_tween := create_tween()
			tip_tween.tween_property(tip_label, "modulate:a", 0.0, 0.2)
			tip_tween.tween_callback(func():
				tip_label.text = TIPS[_current_tip_index]
			)
			tip_tween.tween_property(tip_label, "modulate:a", 1.0, 0.2)

	# Check background resource loading progress
	var all_loaded := true
	var load_progress_sum := 0.0
	for path in PRELOAD_SCENE_PATHS:
		var progress_arr: Array = []
		var status := ResourceLoader.load_threaded_get_status(path, progress_arr)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			load_progress_sum += 1.0
		elif status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			all_loaded = false
			if not progress_arr.is_empty():
				load_progress_sum += float(progress_arr[0])
		else:
			all_loaded = false
	_scenes_loaded = all_loaded

	var asset_ratio := load_progress_sum / float(maxi(1, PRELOAD_SCENE_PATHS.size()))
	var time_ratio := clampf(_elapsed_time / MIN_LOAD_DURATION, 0.0, 1.0)
	# Target progress combines actual asset loading and the 5.0-second timer
	_target_progress = minf(time_ratio, (asset_ratio * 0.5) + (time_ratio * 0.5))
	if _elapsed_time >= MIN_LOAD_DURATION and _scenes_loaded:
		_target_progress = 1.0

	_display_progress = move_toward(_display_progress, _target_progress, delta * 0.75)

	if is_instance_valid(progress_bar):
		progress_bar.value = _display_progress * 100.0
	if is_instance_valid(percent_label):
		percent_label.text = "%d%%" % int(_display_progress * 100.0)

	# Check if 5-second minimum duration and loading are complete
	if _elapsed_time >= MIN_LOAD_DURATION and _display_progress >= 0.99 and not _is_transitioning:
		_start_transition_to_menu()

func _start_transition_to_menu() -> void:
	_is_transitioning = true
	if is_instance_valid(fade_overlay):
		fade_overlay.visible = true
		var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(fade_overlay, "modulate:a", 1.0, 0.4)
		tween.tween_callback(_change_to_main_menu)
	else:
		_change_to_main_menu()

func _change_to_main_menu() -> void:
	var err := get_tree().change_scene_to_file(NEXT_SCENE_PATH)
	if err != OK:
		push_error("StartupLoadingScreen: Failed to transition to %s (error %d)" % [NEXT_SCENE_PATH, err])
