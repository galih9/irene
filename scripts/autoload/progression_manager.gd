extends Node

# Tracks discovered items and whether their discovery reward was claimed
var _unlocked_items: Dictionary = {} # item_id -> bool
var _claimed_rewards: Dictionary = {} # item_id -> bool

# Player Level & EXP
var player_level: int = 1
var player_exp: int = 0

func _ready() -> void:
	GameEvents.item_merged.connect(_on_item_merged)
	GameEvents.item_spawned.connect(_on_item_spawned)

func _on_item_merged(_source_id: String, _target_id: String, result_id: String, world_pos: Vector2) -> void:
	if unlock_item(result_id):
		var item_data := ItemDatabase.get_item(result_id)
		var item_name := item_data.display_name if item_data else result_id
		GameEvents.show_floating_text.emit("Discovered: %s!" % item_name, world_pos + Vector2(0, -70), Color(0.9, 0.7, 1.0))

func _on_item_spawned(item_id: String, _world_pos: Vector2) -> void:
	unlock_item(item_id, true)

func unlock_item(item_id: String, silent: bool = false) -> bool:
	if item_id.is_empty():
		return false
	if _unlocked_items.get(item_id, false):
		return false

	_unlocked_items[item_id] = true
	if not _claimed_rewards.has(item_id):
		_claimed_rewards[item_id] = false

	if not silent:
		SoundManager.play_merge()

	GameEvents.progression_changed.emit()
	return true

func is_unlocked(item_id: String) -> bool:
	return _unlocked_items.get(item_id, false)

func is_claimed(item_id: String) -> bool:
	return _claimed_rewards.get(item_id, false)

func get_reward_for_item(item_id: String) -> Dictionary:
	var item := ItemDatabase.get_item(item_id)
	var tier := item.tier if item else 1
	var coins := 15 + (tier - 1) * 20
	var gems := 0
	if tier >= 5:
		gems = 5
	elif tier >= 4:
		gems = 2
	elif tier >= 3:
		gems = 1
	var exp_reward := 5 + (tier - 1) * 8
	return {"coins": coins, "gems": gems, "exp": exp_reward}

func claim_reward(item_id: String) -> Dictionary:
	if not is_unlocked(item_id) or is_claimed(item_id):
		return {}

	_claimed_rewards[item_id] = true
	var reward := get_reward_for_item(item_id)
	
	if reward.coins > 0:
		EconomyManager.add_coins(reward.coins)
	if reward.gems > 0:
		EconomyManager.add_gems(reward.gems)
	if reward.has("exp") and reward.exp > 0:
		add_exp(reward.exp)

	GameEvents.progression_changed.emit()
	return reward

func get_unclaimed_count() -> int:
	var count := 0
	for item_id in _unlocked_items.keys():
		if _unlocked_items[item_id] and not _claimed_rewards.get(item_id, false):
			count += 1
	return count

func get_total_unlocked_count() -> int:
	var count := 0
	for val in _unlocked_items.values():
		if val:
			count += 1
	return count

func get_total_items_count() -> int:
	return ItemDatabase.get_all_items().size()

func get_chain_unlocked_count(chain_id: String) -> int:
	var count := 0
	var chain_items: Array = ItemDatabase.get_chain(chain_id)
	for item in chain_items:
		if is_unlocked(item.id):
			count += 1
	return count

# =============================================================================
# PLAYER LEVEL & EXP
# =============================================================================

func get_exp_required_for_level(lvl: int) -> int:
	if lvl <= 1:
		return 10
	return 10 + (lvl - 1) * 15 + int(pow(lvl - 1, 1.3) * 5)

func get_current_level_req() -> int:
	return get_exp_required_for_level(player_level)

func add_exp(amount: int) -> void:
	if amount <= 0:
		return
	player_exp += amount
	var req := get_current_level_req()
	while player_exp >= req:
		player_exp -= req
		player_level += 1
		_on_level_up(player_level)
		req = get_current_level_req()
	GameEvents.player_exp_changed.emit(player_level, player_exp, req)

func _on_level_up(new_lvl: int) -> void:
	SoundManager.play_quest()
	EconomyManager.add_energy(30)
	EconomyManager.add_coins(new_lvl * 50)
	if new_lvl % 2 == 0:
		EconomyManager.add_gems(2)
	GameEvents.player_leveled_up.emit(new_lvl)
	GameEvents.show_floating_text.emit("LEVEL UP! Level %d!" % new_lvl, Vector2(360, 400), Color(0.95, 0.75, 1.0))

func serialize_data() -> Dictionary:
	return {
		"unlocked_items": _unlocked_items.duplicate(),
		"claimed_rewards": _claimed_rewards.duplicate(),
		"player_level": player_level,
		"player_exp": player_exp
	}

func load_data(unlocked: Dictionary, claimed: Dictionary, level: int = 1, exp_val: int = 0) -> void:
	_unlocked_items = unlocked.duplicate()
	_claimed_rewards = claimed.duplicate()
	player_level = maxi(1, level)
	player_exp = maxi(0, exp_val)
	GameEvents.progression_changed.emit()
	GameEvents.player_exp_changed.emit(player_level, player_exp, get_current_level_req())

func reset_all() -> void:
	_unlocked_items.clear()
	_claimed_rewards.clear()
	player_level = 1
	player_exp = 0
	GameEvents.progression_changed.emit()
	GameEvents.player_exp_changed.emit(player_level, player_exp, get_current_level_req())
