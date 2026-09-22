extends Node

# Board and Item interactions
signal item_drag_started(item_view: Node)
signal item_drag_ended(item_view: Node)
signal item_merged(source_id: String, target_id: String, result_id: String, world_pos: Vector2)
signal item_spawned(item_id: String, world_pos: Vector2)
signal item_consumed(item_data: ItemData, world_pos: Vector2)
signal board_changed()
signal inventory_changed()
signal item_selected(item_view: Node)

# Economy & Quests
signal currency_changed(currency_name: String, new_amount: int, delta: int)
signal quest_completed(quest: QuestData)
signal quest_count_changed(count: int)
signal quest_milestone_unlocked(milestone_name: String)

# Board actions & Tutorial events
signal item_unboxed(item_id: String)
signal spawner_exhausted(spawner_id: String)
signal item_sold(item_id: String, value: int)
signal item_stored_in_inventory(item_id: String)
signal board_full_attempted()
signal coin_consumed(amount: int)

# UI & Feedback
signal show_floating_text(text: String, world_pos: Vector2, color: Color)
signal request_shop_open()
signal request_progression_open()
signal request_inventory_open()
signal request_cage_open(cage_item: Node)
signal request_options_open()
signal request_debug_toggle()
signal progression_changed()
signal reward_queue_changed()
signal player_exp_changed(level: int, current_exp: int, required_exp: int)
signal player_leveled_up(new_level: int)

# Irene & Ivan Character Dialogue & Tutorial
signal locked_item_cleared(coord: Vector2i, item_id: String)
signal irene_dialogue_requested(text: String, emotion: String, callback: Callable)
signal character_dialogue_requested(character: String, text: String, emotion: String, callback: Callable)
signal irene_toast_requested(text: String, emotion: String, duration: float)
signal tutorial_step_changed(step: int)

# Map & Levels
signal map_unlocked()
signal request_map_open()
signal level_change_requested(target_level_id: String)
