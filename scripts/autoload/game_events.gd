extends Node

# Board and Item interactions
signal item_drag_started(item_view: Node)
signal item_drag_ended(item_view: Node)
signal item_merged(source_id: String, target_id: String, result_id: String, world_pos: Vector2)
signal item_spawned(item_id: String, world_pos: Vector2)
signal item_consumed(item_data: ItemData, world_pos: Vector2)
signal board_changed()
signal inventory_changed()

# Economy & Quests
signal currency_changed(currency_name: String, new_amount: int, delta: int)
signal quest_completed(quest: QuestData)

# UI & Feedback
signal show_floating_text(text: String, world_pos: Vector2, color: Color)
signal request_shop_open()
signal request_progression_open()
signal request_inventory_open()
signal request_options_open()
signal request_debug_toggle()
signal progression_changed()
signal reward_queue_changed()
signal player_exp_changed(level: int, current_exp: int, required_exp: int)
signal player_leveled_up(new_level: int)
