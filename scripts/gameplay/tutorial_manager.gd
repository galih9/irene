class_name TutorialManager
extends Node

enum TutorialStep {
	NONE = 0,
	MERGE_LEFT = 1,
	MERGE_RIGHT = 2,
	SPAWN_ITEM = 3,
	CLEAR_LOCKED = 4,
	REWARD_CHEST = 5,
	COMPLETED = 6
}

var current_step: TutorialStep = TutorialStep.NONE
var is_completed: bool = false
var locked_cleared_count: int = 0
const REQUIRED_LOCKED_CLEARS: int = 3

var board_ref: Board = null
var popup_modal_ref: IrenePopupModal = null
var toast_ref: IreneToast = null
var bottom_nav_bar_ref: BottomNavBar = null

func _ready() -> void:
	GameEvents.item_merged.connect(_on_item_merged)
	GameEvents.item_spawned.connect(_on_item_spawned)
	GameEvents.locked_item_cleared.connect(_on_locked_item_cleared)

func setup(board: Board, modal: IrenePopupModal, toast: IreneToast, nav_bar: BottomNavBar) -> void:
	board_ref = board
	popup_modal_ref = modal
	toast_ref = toast
	bottom_nav_bar_ref = nav_bar

func start_tutorial_if_needed() -> void:
	if is_completed:
		return

	if current_step == TutorialStep.NONE:
		# Small delay on fresh start for board to settle
		get_tree().create_timer(0.4).timeout.connect(func():
			_set_step(TutorialStep.MERGE_LEFT)
		)
	else:
		# Resume saved step
		_resume_step(current_step)

func _set_step(step: TutorialStep) -> void:
	current_step = step
	GameEvents.tutorial_step_changed.emit(step as int)

	match step:
		TutorialStep.MERGE_LEFT:
			_show_step_1_merge_left()
		TutorialStep.MERGE_RIGHT:
			_show_step_2_merge_right()
		TutorialStep.SPAWN_ITEM:
			_show_step_3_spawn_item()
		TutorialStep.CLEAR_LOCKED:
			_show_step_4_clear_locked()
		TutorialStep.REWARD_CHEST:
			_show_step_5_reward_chest()
		TutorialStep.COMPLETED:
			_finish_tutorial()

func _get_cell(coord: Vector2i) -> Vector2i:
	if board_ref and board_ref.cols == 9:
		return board_ref.map_coord_for_orientation(coord, true)
	return coord

func _resume_step(step: TutorialStep) -> void:
	match step:
		TutorialStep.MERGE_LEFT:
			if board_ref:
				board_ref.highlight_tutorial_cell(_get_cell(Vector2i(3, 4)), true)
				board_ref.highlight_tutorial_cell(_get_cell(Vector2i(2, 4)), true)
			if toast_ref:
				toast_ref.show_toast("Drag the center Foodbox to the locked Foodbox on the left!", "explain", 6.0)
		TutorialStep.MERGE_RIGHT:
			if board_ref:
				board_ref.highlight_tutorial_cell(_get_cell(Vector2i(2, 4)), true)
				board_ref.highlight_tutorial_cell(_get_cell(Vector2i(4, 4)), true)
			if toast_ref:
				toast_ref.show_toast("Merge your Tier 2 Foodbox into the locked one on the right!", "happy", 6.0)
		TutorialStep.SPAWN_ITEM:
			if board_ref:
				board_ref.highlight_tutorial_cell(_get_cell(Vector2i(4, 4)), true)
			if toast_ref:
				toast_ref.show_toast("Tap the Pantry Box to produce fresh ingredients!", "explain", 6.0)
		TutorialStep.CLEAR_LOCKED:
			if toast_ref:
				toast_ref.show_toast("Clear locked items by merging matching ingredients! (%d/3)" % locked_cleared_count, "thinking", 6.0)
		TutorialStep.REWARD_CHEST:
			_show_step_5_reward_chest()

# --- Step 1: Merge Left ---
func _show_step_1_merge_left() -> void:
	if board_ref:
		board_ref.clear_tutorial_highlights()
		board_ref.highlight_tutorial_cell(_get_cell(Vector2i(3, 4)), true)
		board_ref.highlight_tutorial_cell(_get_cell(Vector2i(2, 4)), true)

	var msg := "Welcome to Irene's Kitchen! 🍳\nLet's get cooking! See that Foodbox in the center? Drag it to the left and merge it with the matching locked Foodbox to unlock it!"
	if popup_modal_ref:
		popup_modal_ref.show_dialogue(msg, "greeting", func():
			if toast_ref:
				toast_ref.show_toast("Drag the center Foodbox to the locked Foodbox on the left!", "explain", 6.0)
		)

# --- Step 2: Merge Right ---
func _show_step_2_merge_right() -> void:
	if board_ref:
		board_ref.clear_tutorial_highlights()
		board_ref.highlight_tutorial_cell(_get_cell(Vector2i(2, 4)), true)
		board_ref.highlight_tutorial_cell(_get_cell(Vector2i(4, 4)), true)

	var msg := "Awesome job! ⭐ You unlocked your first item and upgraded it to a Tier 2 Foodbox!\nNow drag that Foodbox to the right and merge it with the locked Tier 2 Foodbox!"
	if popup_modal_ref:
		popup_modal_ref.show_dialogue(msg, "happy", func():
			if toast_ref:
				toast_ref.show_toast("Merge your Tier 2 Foodbox into the locked one on the right!", "happy", 6.0)
		)

# --- Step 3: Spawn Item ---
func _show_step_3_spawn_item() -> void:
	if board_ref:
		board_ref.clear_tutorial_highlights()
		board_ref.highlight_tutorial_cell(_get_cell(Vector2i(4, 4)), true)

	var msg := "Look at that! Tier 3 Foodbox is an ingredient producer! ⚡\nTap on your new Pantry Box to produce your very first kitchen ingredient! (Uses 1 Energy)"
	if popup_modal_ref:
		popup_modal_ref.show_dialogue(msg, "explain", func():
			if toast_ref:
				toast_ref.show_toast("Tap the Pantry Box to produce fresh ingredients!", "explain", 6.0)
		)

# --- Step 4: Clear 3 Locked Items ---
func _show_step_4_clear_locked() -> void:
	if board_ref:
		board_ref.clear_tutorial_highlights()

	locked_cleared_count = 0
	var msg := "You're a natural! 🌟\nNow tap your Pantry Box to produce more ingredients, and merge them with matching locked items across the board.\nClear 3 locked items to open up more kitchen space!"
	if popup_modal_ref:
		popup_modal_ref.show_dialogue(msg, "thinking", func():
			if toast_ref:
				toast_ref.show_toast("Clear locked items by merging matching ingredients! (0/3)", "thinking", 6.0)
		)

# --- Step 5: Reward Chest ---
func _show_step_5_reward_chest() -> void:
	if board_ref:
		board_ref.clear_tutorial_highlights()

	var msg := "Incredible work! The kitchen is really coming together! 🎉\nHere is your reward: a special Mystic EXP Chest! I've placed it directly into your temporary reward slot below.\nTap the reward slot anytime to place it on the board!"
	if popup_modal_ref:
		popup_modal_ref.show_dialogue(msg, "admire", func():
			_deliver_tutorial_reward()
		)
	else:
		_deliver_tutorial_reward()

func _deliver_tutorial_reward() -> void:
	# Push purple chest reward into temporary queue
	ProgressionManager.push_reward("chest_purple_1")

	if is_instance_valid(bottom_nav_bar_ref):
		bottom_nav_bar_ref.animate_reward_wobble()

	if toast_ref:
		toast_ref.show_toast("Chest added to your reward slot! Tap below to place it.", "happy", 6.0)

	_finish_tutorial()

func _finish_tutorial() -> void:
	is_completed = true
	current_step = TutorialStep.COMPLETED
	if board_ref:
		board_ref.clear_tutorial_highlights()

	GameEvents.tutorial_step_changed.emit(TutorialStep.COMPLETED as int)

	# Auto-save tutorial completion state
	if SaveManager:
		SaveManager.save_game(false)

# --- Event Listeners ---
func _on_item_merged(source_id: String, target_id: String, result_id: String, _world_pos: Vector2) -> void:
	if is_completed:
		return

	match current_step:
		TutorialStep.MERGE_LEFT:
			# Merged foodbox_1 into foodbox_1 -> foodbox_2
			if result_id == "foodbox_2" or (source_id == "foodbox_1" and target_id == "foodbox_1"):
				get_tree().create_timer(0.35).timeout.connect(func():
					_set_step(TutorialStep.MERGE_RIGHT)
				)
		TutorialStep.MERGE_RIGHT:
			# Merged foodbox_2 into foodbox_2 -> foodbox_3
			if result_id == "foodbox_3" or (source_id == "foodbox_2" and target_id == "foodbox_2"):
				get_tree().create_timer(0.35).timeout.connect(func():
					_set_step(TutorialStep.SPAWN_ITEM)
				)

func _on_item_spawned(_item_id: String, _world_pos: Vector2) -> void:
	if is_completed:
		return

	if current_step == TutorialStep.SPAWN_ITEM:
		get_tree().create_timer(0.35).timeout.connect(func():
			_set_step(TutorialStep.CLEAR_LOCKED)
		)

func _on_locked_item_cleared(_coord: Vector2i, _item_id: String) -> void:
	if is_completed:
		return

	if current_step == TutorialStep.CLEAR_LOCKED:
		locked_cleared_count += 1
		if locked_cleared_count < REQUIRED_LOCKED_CLEARS:
			if toast_ref:
				toast_ref.show_toast("Great job! Cleared %d/3 locked items!" % locked_cleared_count, "happy", 4.5)
		else:
			get_tree().create_timer(0.4).timeout.connect(func():
				_set_step(TutorialStep.REWARD_CHEST)
			)

# --- Serialization for Save/Load ---
func serialize_data() -> Dictionary:
	return {
		"current_step": current_step as int,
		"is_completed": is_completed,
		"locked_cleared_count": locked_cleared_count
	}

func load_data(data: Dictionary) -> void:
	current_step = (data.get("current_step", TutorialStep.NONE as int)) as TutorialStep
	is_completed = data.get("is_completed", false)
	locked_cleared_count = int(data.get("locked_cleared_count", 0))
