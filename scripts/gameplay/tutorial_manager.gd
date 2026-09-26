class_name TutorialManager
extends Node

enum TutorialStep {
	NONE = 0,
	MERGE_LEFT = 1,
	MERGE_RIGHT = 2,
	SPAWN_ITEM = 3,
	UNLOCK_FIRST_ITEM = 4,
	UNLOCK_THREE_SLOTS = 5,
	DELIVER_QUESTS = 6,
	CLAIM_REWARD = 7,
	CONSUME_REWARD = 8,
	STORE_IN_INVENTORY = 9,
	COMPLETED = 10,
	FIRST_QUEST = 11,
	FIRST_PRODUCER_UNBOX = 12,
	FIRST_SPAWNER_EXHAUST = 13,
	FIRST_SELL = 14,
	FIRST_BACKPACK_STORE = 15,
	CLAIM_PROGRESSION = 16
}

var current_step: TutorialStep = TutorialStep.NONE
var is_completed: bool = false
var locked_cleared_count: int = 0
const REQUIRED_LOCKED_CLEARS: int = 3
var stored_inventory_count: int = 0
var board_full_count: int = 0
var _first_spawned_coord: Vector2i = Vector2i(-1, -1)
var _reward_chest_coord: Vector2i = Vector2i(-1, -1)
var _shown_flags: Dictionary = {}

var board_ref: Board = null
var popup_modal_ref: IrenePopupModal = null
var toast_ref: IreneToast = null
var bottom_nav_bar_ref: BottomNavBar = null

func _ready() -> void:
	GameEvents.item_merged.connect(_on_item_merged)
	GameEvents.item_spawned.connect(_on_item_spawned)
	GameEvents.locked_item_cleared.connect(_on_locked_item_cleared)
	GameEvents.quest_completed.connect(_on_quest_completed)
	GameEvents.item_unboxed.connect(_on_item_unboxed)
	GameEvents.spawner_exhausted.connect(_on_spawner_exhausted)
	GameEvents.item_sold.connect(_on_item_sold)
	GameEvents.item_stored_in_inventory.connect(_on_item_stored_in_inventory)
	GameEvents.coin_consumed.connect(_on_coin_consumed)
	GameEvents.board_full_attempted.connect(_on_board_full_attempted)
	GameEvents.progression_changed.connect(_on_progression_changed)
	GameEvents.board_changed.connect(_check_first_quest_highlight)

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
		TutorialStep.UNLOCK_FIRST_ITEM:
			_show_step_4_unlock_first_item()
		TutorialStep.CLAIM_PROGRESSION:
			_show_step_claim_progression()
		TutorialStep.UNLOCK_THREE_SLOTS:
			_show_step_5_unlock_three_slots()
		TutorialStep.DELIVER_QUESTS:
			_show_step_6_deliver_quests()
		TutorialStep.CLAIM_REWARD:
			_show_step_7_claim_reward()
		TutorialStep.CONSUME_REWARD:
			_show_step_8_consume_reward()
		TutorialStep.STORE_IN_INVENTORY:
			_show_step_9_store_in_inventory()
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
		TutorialStep.UNLOCK_FIRST_ITEM:
			_show_step_4_unlock_first_item()
		TutorialStep.CLAIM_PROGRESSION:
			_show_step_claim_progression()
		TutorialStep.UNLOCK_THREE_SLOTS:
			if toast_ref:
				toast_ref.show_toast("Clear locked items by merging matching ingredients! (%d/3)" % locked_cleared_count, "thinking", 6.0)
		TutorialStep.DELIVER_QUESTS:
			if toast_ref:
				toast_ref.show_toast("Deliver customer orders above to unlock the Backpack and Shop! (%d/5)" % QuestManager.get_completed_count(), "explain", 6.0)
			_check_first_quest_highlight()
		TutorialStep.CLAIM_REWARD:
			_show_step_7_claim_reward()
		TutorialStep.CONSUME_REWARD:
			_show_step_8_consume_reward()
		TutorialStep.STORE_IN_INVENTORY:
			_show_step_9_store_in_inventory()

# --- Step 1: Merge Left ---
func _show_step_1_merge_left() -> void:
	if board_ref:
		board_ref.clear_tutorial_highlights()
		board_ref.highlight_tutorial_cell(_get_cell(Vector2i(3, 4)), true)
		board_ref.highlight_tutorial_cell(_get_cell(Vector2i(2, 4)), true)

	var msg := "Welcome to Irene's Kitchen!\nLet's get cooking! See that Foodbox in the center? Drag it to the left and merge it with the matching locked Foodbox to unlock it!"
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

	var msg := "Awesome job! You unlocked your first item and upgraded it to a Tier 2 Foodbox!\nNow drag that Foodbox to the right and merge it with the locked Tier 2 Foodbox!"
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

	var msg := "Look at that! Tier 3 Foodbox is an ingredient producer!\nTap on your new Pantry Box to produce your very first kitchen ingredient! (Uses 1 Energy)"
	if popup_modal_ref:
		popup_modal_ref.show_dialogue(msg, "explain", func():
			if toast_ref:
				toast_ref.show_toast("Tap the Pantry Box to produce fresh ingredients!", "explain", 6.0)
		)

# --- Step 4: Unlock First Item ---
func _show_step_4_unlock_first_item() -> void:
	var locked_egg_coord := _get_cell(Vector2i(3, 3))
	if board_ref:
		board_ref.clear_tutorial_highlights()
		if _first_spawned_coord != Vector2i(-1, -1):
			board_ref.highlight_tutorial_cell(_first_spawned_coord, true)
		board_ref.highlight_tutorial_cell(locked_egg_coord, true)

	var msg := "Great job! You produced a Fresh Egg!\nNow drag your newly spawned Egg and merge it onto the locked Egg nearby to unlock your first ingredient!"
	if popup_modal_ref:
		popup_modal_ref.show_dialogue(msg, "explain", func():
			if toast_ref:
				toast_ref.show_toast("Drag the Egg onto the matching locked Egg to unlock it!", "explain", 6.0)
		)
	elif toast_ref:
		toast_ref.show_toast("Drag the Egg onto the matching locked Egg to unlock it!", "explain", 6.0)

# --- Step: Claim Progression (Feature 1) ---
func _show_step_claim_progression() -> void:
	if board_ref:
		board_ref.clear_tutorial_highlights()

	if is_instance_valid(bottom_nav_bar_ref):
		bottom_nav_bar_ref.play_progression_pulse()
		bottom_nav_bar_ref.set_progression_highlight(true)

	if ProgressionManager.get_unclaimed_count() <= 0:
		# If user already claimed, skip smoothly to unlocking 3 slots
		get_tree().create_timer(0.3).timeout.connect(func():
			_set_step(TutorialStep.UNLOCK_THREE_SLOTS)
		)
		return

	var msg := "Incredible! Look at the bottom navigation bar!\nSee that red badge on the 'Progress' button? Every time you merge and discover new items, your progress is tracked in your Culinary Codex!\nTap the Progress button to claim your discovery rewards!"
	if popup_modal_ref:
		popup_modal_ref.show_dialogue(msg, "admire", func():
			if toast_ref:
				toast_ref.show_toast("Tap the Progress button below to claim your discovery rewards!", "explain", 8.0)
		)
	elif toast_ref:
		toast_ref.show_toast("Tap the Progress button below to claim your discovery rewards!", "explain", 8.0)

func _on_progression_changed() -> void:
	if current_step == TutorialStep.CLAIM_PROGRESSION:
		if is_instance_valid(bottom_nav_bar_ref):
			bottom_nav_bar_ref.set_progression_highlight(false)
		if toast_ref:
			toast_ref.show_toast("Discovery rewards claimed! Check Progress whenever you discover new items!", "happy", 5.0)
		get_tree().create_timer(0.4).timeout.connect(func():
			_set_step(TutorialStep.UNLOCK_THREE_SLOTS)
		)

# --- Step 5: Unlock 3 More Slots ---
func _show_step_5_unlock_three_slots() -> void:
	if board_ref:
		board_ref.clear_tutorial_highlights()

	locked_cleared_count = 0
	var msg := "Brilliant! Unlocking items clears the fog and opens up more kitchen space!\nNow tap your Pantry Box to produce more ingredients, and merge them with matching locked items across the board.\nClear 3 more locked slots to expand your kitchen!"
	if popup_modal_ref:
		popup_modal_ref.show_dialogue(msg, "thinking", func():
			if toast_ref:
				toast_ref.show_toast("Clear locked items by merging matching ingredients! (0/3)", "thinking", 6.0)
		)
	elif toast_ref:
		toast_ref.show_toast("Clear locked items by merging matching ingredients! (0/3)", "thinking", 6.0)

# --- Step 6: Deliver Quests (with Feature 3 Delivery Highlight) ---
func _show_step_6_deliver_quests() -> void:
	if board_ref:
		board_ref.clear_tutorial_highlights()

	var cnt := QuestManager.get_completed_count()
	var msg := "Customers are arriving with orders!\nCheck the Order Cards above. Produce and merge the requested ingredients, then tap the flashing DELIVER button to earn Gold, Gems, and EXP!\nComplete 5 orders to unlock the Backpack and the Shop! (%d/5 completed)" % cnt
	if popup_modal_ref:
		popup_modal_ref.show_dialogue(msg, "explain", func():
			_check_first_quest_highlight()
			if toast_ref:
				toast_ref.show_toast("Deliver customer orders above to unlock Backpack & Shop! (%d/5)" % cnt, "explain", 6.0)
		)
	elif toast_ref:
		_check_first_quest_highlight()
		toast_ref.show_toast("Deliver customer orders above to unlock Backpack & Shop! (%d/5)" % cnt, "explain", 6.0)

func _check_first_quest_highlight() -> void:
	if current_step != TutorialStep.DELIVER_QUESTS:
		return
	if QuestManager.get_completed_count() > 0:
		return
	if not QuestManager.instance:
		return
	var card := QuestManager.instance.get_first_card()
	if not is_instance_valid(card):
		return

	if card.is_ready_to_deliver:
		card.set_delivery_highlight(true)
		if toast_ref and not _shown_flags.get("first_deliver_hint", false):
			_shown_flags["first_deliver_hint"] = true
			toast_ref.show_toast("Order ready! Tap the flashing DELIVER button on the Order Card!", "happy", 6.0)
	else:
		card.set_delivery_highlight(false)

# --- Step 7: Claim Reward ---
func _show_step_7_claim_reward() -> void:
	if board_ref:
		board_ref.clear_tutorial_highlights()

	# Place reward chest in temporary queue
	ProgressionManager.push_reward("chest_yellow_1")

	if is_instance_valid(bottom_nav_bar_ref):
		bottom_nav_bar_ref.animate_reward_wobble()

	var msg := "Congratulations! Completing 5 orders unlocked both your Backpack and the Shop!\nI've sent you a special Reward Chest! Tap the shining tile in the bottom navigation bar to place it on the board!"
	if popup_modal_ref:
		popup_modal_ref.show_dialogue(msg, "admire", func():
			if toast_ref:
				toast_ref.show_toast("Tap the shining bottom reward tile to place your Reward Chest!", "happy", 6.0)
		)
	elif toast_ref:
		toast_ref.show_toast("Tap the shining bottom reward tile to place your Reward Chest!", "happy", 6.0)

# --- Step 8: Consume Reward ---
func _show_step_8_consume_reward() -> void:
	if board_ref and _reward_chest_coord != Vector2i(-1, -1):
		board_ref.clear_tutorial_highlights()
		board_ref.highlight_tutorial_cell(_reward_chest_coord, true)

	var msg := "There's your Reward Chest! Tap it repeatedly to open it and collect all the coins and supplies!"
	if toast_ref:
		toast_ref.show_toast(msg, "happy", 6.0)

# --- Step 9: Store in Inventory ---
func _show_step_9_store_in_inventory() -> void:
	if board_ref:
		board_ref.clear_tutorial_highlights()

	if is_instance_valid(bottom_nav_bar_ref):
		bottom_nav_bar_ref.play_inventory_pulse()

	stored_inventory_count = 0
	var msg := "Look at that - your board is getting crowded!\nThat's what your newly unlocked Backpack is for! Drag any item from your board directly onto the Backpack button below to store it safely!"
	if popup_modal_ref:
		popup_modal_ref.show_dialogue(msg, "explain", func():
			if toast_ref:
				toast_ref.show_toast("Drag an item to the Backpack button below to store it!", "explain", 6.0)
		)
	elif toast_ref:
		toast_ref.show_toast("Drag an item to the Backpack button below to store it!", "explain", 6.0)

func _finish_tutorial() -> void:
	is_completed = true
	current_step = TutorialStep.COMPLETED
	if board_ref:
		board_ref.clear_tutorial_highlights()

	var msg := "Fantastic job! You've mastered all the kitchen basics! You're now free to cook, merge, deliver orders, and unlock new areas at your own pace!\nHave fun in Irene's Kitchen!"
	if popup_modal_ref:
		popup_modal_ref.show_dialogue(msg, "admire", func():
			if toast_ref:
				toast_ref.show_toast("Kitchen tutorial complete! Have fun cooking!", "happy", 5.0)
		)
	elif toast_ref:
		toast_ref.show_toast("Kitchen tutorial complete! Have fun cooking!", "happy", 5.0)

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

func _on_item_spawned(item_id: String, world_pos: Vector2) -> void:
	if is_completed:
		return

	if current_step == TutorialStep.SPAWN_ITEM:
		if board_ref:
			_first_spawned_coord = board_ref.world_to_grid(world_pos)
		get_tree().create_timer(0.35).timeout.connect(func():
			_set_step(TutorialStep.UNLOCK_FIRST_ITEM)
		)
	elif current_step == TutorialStep.CLAIM_REWARD and item_id.begins_with("chest"):
		if board_ref:
			_reward_chest_coord = board_ref.world_to_grid(world_pos)
		get_tree().create_timer(0.35).timeout.connect(func():
			_set_step(TutorialStep.CONSUME_REWARD)
		)

func _on_locked_item_cleared(_coord: Vector2i, _item_id: String) -> void:
	if is_completed:
		return

	if current_step == TutorialStep.UNLOCK_FIRST_ITEM:
		get_tree().create_timer(0.4).timeout.connect(func():
			_set_step(TutorialStep.CLAIM_PROGRESSION)
		)
	elif current_step == TutorialStep.UNLOCK_THREE_SLOTS:
		locked_cleared_count += 1
		if locked_cleared_count < REQUIRED_LOCKED_CLEARS:
			if toast_ref:
				toast_ref.show_toast("Great job! Cleared %d/3 locked slots!" % locked_cleared_count, "happy", 4.0)
		else:
			get_tree().create_timer(0.4).timeout.connect(func():
				_set_step(TutorialStep.DELIVER_QUESTS)
			)

func _on_quest_completed(quest: QuestData) -> void:
	if QuestManager.instance:
		var card := QuestManager.instance.get_first_card()
		if is_instance_valid(card):
			card.set_delivery_highlight(false)

	if current_step == TutorialStep.DELIVER_QUESTS:
		var cnt := QuestManager.get_completed_count()
		if cnt >= 5:
			get_tree().create_timer(0.4).timeout.connect(func():
				_set_step(TutorialStep.CLAIM_REWARD)
			)
		else:
			if toast_ref:
				toast_ref.show_toast("Order delivered! (%d/5 orders completed)" % cnt, "happy", 4.0)
		return

	if _shown_flags.get("first_quest", false):
		return
	_shown_flags["first_quest"] = true
	GameEvents.tutorial_step_changed.emit(TutorialStep.FIRST_QUEST as int)
	if toast_ref:
		toast_ref.show_toast("Order complete! Delivering orders gives Gold, Gems, and EXP to level up your kitchen!", "happy", 6.0)

func _on_spawner_exhausted(spawner_id: String) -> void:
	if current_step == TutorialStep.CONSUME_REWARD and spawner_id.begins_with("chest"):
		get_tree().create_timer(0.4).timeout.connect(func():
			_set_step(TutorialStep.STORE_IN_INVENTORY)
		)
		return

	if _shown_flags.get("first_spawner_exhaust", false):
		return
	_shown_flags["first_spawner_exhaust"] = true
	GameEvents.tutorial_step_changed.emit(TutorialStep.FIRST_SPAWNER_EXHAUST as int)
	if toast_ref:
		toast_ref.show_toast("Producer out of charges! It will recharge over time, or merge matching ones to refill immediately.", "explain", 6.0)

func _on_item_sold(_item_id: String, value: int) -> void:
	if _shown_flags.get("first_sell", false):
		return
	_shown_flags["first_sell"] = true
	GameEvents.tutorial_step_changed.emit(TutorialStep.FIRST_SELL as int)
	if toast_ref:
		toast_ref.show_toast("Item sold for %d Gold! You can sell extra items anytime from the info panel below." % value, "happy", 5.5)

func _on_item_stored_in_inventory(_item_id: String) -> void:
	if current_step == TutorialStep.STORE_IN_INVENTORY:
		stored_inventory_count += 1
		if stored_inventory_count >= 1:
			get_tree().create_timer(0.4).timeout.connect(func():
				_finish_tutorial()
			)
			return

	if _shown_flags.get("first_backpack_store", false):
		return
	_shown_flags["first_backpack_store"] = true
	GameEvents.tutorial_step_changed.emit(TutorialStep.FIRST_BACKPACK_STORE as int)
	if toast_ref:
		toast_ref.show_toast("Item stored in your Backpack! Tap the Backpack button anytime to open and retrieve items.", "happy", 5.5)

func _on_item_unboxed(item_id: String) -> void:
	if _shown_flags.get("first_producer_unbox", false):
		return
	var item_data := ItemDatabase.get_item(item_id)
	var chain_id := item_data.chain_id if item_data else item_id.split("_")[0]
	if chain_id in ["oven", "fridge", "rack"]:
		_shown_flags["first_producer_unbox"] = true
		GameEvents.tutorial_step_changed.emit(TutorialStep.FIRST_PRODUCER_UNBOX as int)
		if toast_ref:
			var produces_desc := "new items"
			match chain_id:
				"oven": produces_desc = "savory meats and baked cakes"
				"fridge": produces_desc = "refreshing chilled drinks"
				"rack": produces_desc = "useful kitchen utensils"
			toast_ref.show_toast("You unboxed an %s! Merge it to Tier 3 to produce %s!" % [item_data.display_name if item_data else "ingredient producer", produces_desc], "explain", 6.5)

func _on_coin_consumed(_amount: int) -> void:
	if not is_completed:
		return
	if _shown_flags.get("first_coin_spent_guide", false):
		return
	if QuestManager.instance and not QuestManager.instance.is_shop_unlocked():
		return
	_shown_flags["first_coin_spent_guide"] = true
	if is_instance_valid(bottom_nav_bar_ref) and is_instance_valid(bottom_nav_bar_ref.shop_btn):
		var tween := create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		bottom_nav_bar_ref.shop_btn.pivot_offset = bottom_nav_bar_ref.shop_btn.size * 0.5
		tween.tween_property(bottom_nav_bar_ref.shop_btn, "scale", Vector2(1.15, 0.85), 0.1)
		tween.tween_property(bottom_nav_bar_ref.shop_btn, "scale", Vector2.ONE, 0.2)
	if toast_ref:
		toast_ref.show_toast("You collected Gold! Visit the Shop to spend coins on energy, chests, and supplies!", "happy", 6.5)

func _on_board_full_attempted() -> void:
	board_full_count += 1
	if board_full_count >= 3 and not _shown_flags.get("board_full_sell_guide", false):
		_shown_flags["board_full_sell_guide"] = true
		if toast_ref:
			toast_ref.show_toast("Board is full! Tap any item and press the Sell ($) button below to free up space and earn Gold!", "explain", 7.0)

# --- Serialization for Save/Load ---
func serialize_data() -> Dictionary:
	return {
		"current_step": current_step as int,
		"is_completed": is_completed,
		"locked_cleared_count": locked_cleared_count,
		"stored_inventory_count": stored_inventory_count,
		"board_full_count": board_full_count,
		"_first_spawned_coord": [_first_spawned_coord.x, _first_spawned_coord.y],
		"_reward_chest_coord": [_reward_chest_coord.x, _reward_chest_coord.y],
		"shown_flags": _shown_flags.duplicate()
	}

func load_data(data: Dictionary) -> void:
	current_step = (data.get("current_step", TutorialStep.NONE as int)) as TutorialStep
	is_completed = data.get("is_completed", false)
	locked_cleared_count = int(data.get("locked_cleared_count", 0))
	stored_inventory_count = int(data.get("stored_inventory_count", 0))
	board_full_count = int(data.get("board_full_count", 0))
	var fsc = data.get("_first_spawned_coord", [-1, -1])
	if fsc is Array and fsc.size() >= 2:
		_first_spawned_coord = Vector2i(int(fsc[0]), int(fsc[1]))
	var rcc = data.get("_reward_chest_coord", [-1, -1])
	if rcc is Array and rcc.size() >= 2:
		_reward_chest_coord = Vector2i(int(rcc[0]), int(rcc[1]))
	_shown_flags = data.get("shown_flags", {}).duplicate()
