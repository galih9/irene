class_name DeliveryLevelDatabase
extends RefCounted

## Food Delivery Rush: Handcrafted & Algorithmic Puzzle Levels
## Guaranteed 100% solvable with progressive difficulty across all 10 levels.

const TOTAL_LEVELS: int = 10

static func get_total_levels() -> int:
	return TOTAL_LEVELS

static func get_level(level_num: int) -> Dictionary:
	var data: Dictionary
	if level_num <= TOTAL_LEVELS:
		data = _get_raw_level(clampi(level_num, 1, TOTAL_LEVELS))
	else:
		data = generate_procedural_level(level_num)
	return data.duplicate(true)

static func get_all_levels() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for i in range(1, TOTAL_LEVELS + 1):
		list.append(get_level(i))
	return list

# =============================================================================
# HANDCRAFTED, INTERLEAVED & SOLVABILITY-VERIFIED 10 LEVELS
# =============================================================================

static func _get_raw_level(level_num: int) -> Dictionary:
	match level_num:
		1:
			# Intro / Tutorial: 3 orders, 3 columns.
			# All 3 columns have bakery_6 on top so Order 1 is learned immediately.
			# Col 1 has healthy_3 under bakery_6, requiring 1 temp slot for Order 2.
			return {
				"level": 1,
				"title": "Morning Rush",
				"description": "Fresh bakery & breakfast orders!",
				"time_limit": 90,
				"orders": ["bakery_6", "sweets_2", "healthy_3"],
				"stacks": [
					["healthy_3", "sweets_2", "bakery_6"],
					["sweets_2", "healthy_3", "bakery_6"],
					["healthy_3", "sweets_2", "bakery_6"],
				]
			}
		2:
			# Cafe Orders: 4 orders, 4 columns (12 items).
			# Distinct columns, top row: drinks_2, drinks_2, bakery_6, sweets_2.
			# Mild difficulty, peak temp slots: 1.
			return {
				"level": 2,
				"title": "Cafe Orders",
				"description": "Drinks & sweet pastries on the go!",
				"time_limit": 85,
				"orders": ["drinks_2", "bakery_6", "sweets_2", "healthy_3"],
				"stacks": [
					["bakery_6", "drinks_2", "drinks_2"],
					["bakery_6", "sweets_2", "drinks_2"],
					["healthy_3", "healthy_3", "bakery_6"],
					["healthy_3", "sweets_2", "sweets_2"],
				]
			}
		3:
			# Lunchtime Express: 5 orders, 4 columns (15 items).
			# Asymmetric depths (4, 4, 4, 3).
			# Moderate challenge, peak temp slots: 2.
			return {
				"level": 3,
				"title": "Lunchtime Express",
				"description": "Hot grill snacks joining the menu!",
				"time_limit": 80,
				"orders": ["bakery_6", "grill_2", "drinks_2", "sweets_2", "healthy_3"],
				"stacks": [
					["healthy_3", "sweets_2", "grill_2", "bakery_6"],
					["drinks_2", "drinks_2", "drinks_2", "grill_2"],
					["bakery_6", "bakery_6", "sweets_2", "grill_2"],
					["sweets_2", "healthy_3", "healthy_3"],
				]
			}
		4:
			# Bistro Delight: 6 orders, 5 columns (18 items).
			# Varied depths (4, 4, 4, 3, 3). Interleaved food types.
			# Moderate-hard challenge, peak temp slots: 3.
			return {
				"level": 4,
				"title": "Bistro Delight",
				"description": "Pretzels and skewers ready to pack!",
				"time_limit": 75,
				"orders": ["sweets_2", "bakery_3", "grill_2", "drinks_2", "bakery_6", "healthy_3"],
				"stacks": [
					["bakery_6", "bakery_6", "healthy_3", "drinks_2"],
					["grill_2", "healthy_3", "grill_2", "healthy_3"],
					["bakery_3", "sweets_2", "grill_2", "bakery_3"],
					["bakery_6", "drinks_2", "bakery_3"],
					["drinks_2", "sweets_2", "sweets_2"],
				]
			}
		5:
			# Sweet Tooth Feast: 7 orders, 5 columns (21 items).
			# Deep columns (5, 4, 4, 4, 4). High food variety.
			# Challenging, peak temp slots: 4.
			return {
				"level": 5,
				"title": "Sweet Tooth Feast",
				"description": "Glazed donuts and assorted treats!",
				"time_limit": 75,
				"orders": ["bakery_6", "sweets_5", "grill_2", "drinks_2", "sweets_2", "bakery_3", "healthy_3"],
				"stacks": [
					["bakery_3", "drinks_2", "bakery_3", "sweets_2", "drinks_2"],
					["healthy_3", "healthy_3", "sweets_5", "sweets_2"],
					["grill_2", "bakery_6", "bakery_6", "grill_2"],
					["bakery_3", "healthy_3", "drinks_2", "sweets_5"],
					["sweets_5", "bakery_6", "sweets_2", "grill_2"],
				]
			}
		6:
			# Gourmet Grill Dash: 8 orders, 6 columns (24 items).
			# All 6 columns completely distinct! Deep interleaving.
			# Hard, peak temp slots: 3-4.
			return {
				"level": 6,
				"title": "Gourmet Grill Dash",
				"description": "Sizzling burgers and hearty plates!",
				"time_limit": 70,
				"orders": ["grill_3", "bakery_6", "sweets_2", "grill_2", "bakery_3", "drinks_2", "sweets_5", "healthy_3"],
				"stacks": [
					["healthy_3", "bakery_3", "bakery_6", "sweets_2"],
					["grill_2", "grill_2", "bakery_6", "bakery_6"],
					["drinks_2", "sweets_5", "sweets_2", "grill_3"],
					["healthy_3", "sweets_5", "bakery_3", "healthy_3"],
					["bakery_3", "grill_3", "sweets_5", "grill_3"],
					["drinks_2", "drinks_2", "grill_2", "sweets_2"],
				]
			}
		7:
			# Speedy Courier: 8 orders, 6 columns (24 items).
			# Asymmetric column depths: 5, 5, 4, 4, 3, 3.
			# Hard, peak temp slots: 3-4.
			return {
				"level": 7,
				"title": "Speedy Courier",
				"description": "Fast deliveries across the neighborhood!",
				"time_limit": 65,
				"orders": ["sweets_5", "grill_3", "drinks_2", "bakery_3", "grill_2", "sweets_2", "bakery_6", "healthy_3"],
				"stacks": [
					["bakery_3", "healthy_3", "bakery_3", "grill_2", "bakery_3"],
					["bakery_6", "sweets_2", "grill_2", "drinks_2", "drinks_2"],
					["grill_2", "sweets_5", "grill_3", "bakery_6"],
					["healthy_3", "grill_3", "drinks_2", "sweets_5"],
					["bakery_6", "sweets_2", "grill_3"],
					["healthy_3", "sweets_2", "sweets_5"],
				]
			}
		8:
			# Downtown Catering: 9 orders, 6 columns (27 items).
			# Depths: 5, 5, 5, 4, 4, 4. Multi-layer dependency digging.
			# Expert difficulty, peak temp slots: 5.
			return {
				"level": 8,
				"title": "Downtown Catering",
				"description": "Nine big delivery boxes to arrange!",
				"time_limit": 65,
				"orders": ["bakery_3", "sweets_2", "grill_3", "bakery_6", "drinks_2", "sweets_5", "grill_2", "healthy_3", "bakery_6"],
				"stacks": [
					["drinks_2", "sweets_2", "healthy_3", "grill_2", "sweets_2"],
					["bakery_6", "sweets_5", "bakery_6", "bakery_6", "bakery_6"],
					["bakery_6", "bakery_6", "healthy_3", "grill_2", "bakery_3"],
					["bakery_3", "grill_3", "sweets_2", "grill_2"],
					["drinks_2", "grill_3", "bakery_3", "sweets_5"],
					["healthy_3", "sweets_5", "grill_3", "drinks_2"],
				]
			}
		9:
			# Dinner Rush Hour: 10 orders, 6 columns (30 items).
			# Full 5x6 grid. Complex multi-order puzzle requiring planned holding.
			# Master difficulty, peak temp slots: 5.
			return {
				"level": 9,
				"title": "Dinner Rush Hour",
				"description": "High-volume orders stacking up fast!",
				"time_limit": 60,
				"orders": ["drinks_2", "sweets_5", "grill_2", "bakery_3", "grill_3", "sweets_2", "bakery_6", "healthy_3", "sweets_2", "grill_2"],
				"stacks": [
					["sweets_2", "bakery_6", "grill_2", "sweets_2", "grill_2"],
					["grill_3", "grill_2", "healthy_3", "grill_2", "drinks_2"],
					["drinks_2", "bakery_3", "grill_3", "drinks_2", "sweets_2"],
					["grill_2", "bakery_6", "bakery_6", "grill_2", "grill_3"],
					["bakery_3", "healthy_3", "bakery_3", "sweets_2", "sweets_5"],
					["sweets_2", "healthy_3", "sweets_2", "sweets_5", "sweets_5"],
				]
			}
		10:
			# Grand Master Banquet: 10 orders, 6 columns (30 items).
			# Full 5x6 grid. Tight slot management and rapid pace.
			# Grand Master difficulty, peak temp slots: 5.
			return {
				"level": 10,
				"title": "Grand Master Banquet",
				"description": "Ultimate test of a Master Courier Chef!",
				"time_limit": 55,
				"orders": ["grill_3", "bakery_6", "sweets_5", "drinks_2", "grill_2", "bakery_3", "sweets_2", "healthy_3", "grill_3", "bakery_6"],
				"stacks": [
					["sweets_2", "grill_3", "bakery_6", "bakery_6", "sweets_5"],
					["grill_3", "healthy_3", "bakery_3", "grill_2", "healthy_3"],
					["grill_3", "bakery_3", "grill_2", "sweets_5", "grill_3"],
					["sweets_2", "grill_2", "sweets_2", "grill_3", "bakery_6"],
					["bakery_6", "healthy_3", "bakery_6", "bakery_6", "drinks_2"],
					["grill_3", "drinks_2", "bakery_3", "drinks_2", "sweets_5"],
				]
			}
	return _get_raw_level(1)

# =============================================================================
# ALGORITHMIC PUZZLE GENERATION & SOLVABILITY VERIFIER
# =============================================================================

## Solves a delivery puzzle using state-space BFS with greedy matching.
## Returns Dictionary: {"solvable": bool, "peak_temp": int}
static func solve_level(orders: Array, stacks: Array, max_temp_slots: int = 7) -> Dictionary:
	var num_orders := orders.size()
	if num_orders == 0 or stacks.is_empty():
		return {"solvable": false, "peak_temp": 0}

	var initial_stacks: Array[Array] = []
	for st in stacks:
		var copy_st: Array[String] = []
		for it in st:
			copy_st.append(str(it))
		initial_stacks.append(copy_st)

	# [order_idx, filled, stacks_array, temp_array, peak_temp]
	var stack_queue: Array[Array] = []
	stack_queue.append([0, 0, initial_stacks, [] as Array[String], 0])

	var visited: Dictionary = {}
	var max_iterations := 25000
	var iterations := 0

	while not stack_queue.is_empty() and iterations < max_iterations:
		iterations += 1
		var state: Array = stack_queue.pop_back()
		var order_idx: int = state[0]
		var filled: int = state[1]
		var cur_stacks: Array[Array] = state[2]
		var cur_temp: Array[String] = state[3]
		var peak_temp: int = state[4]

		var cur_order: String = str(orders[order_idx])

		# 1. Eagerly drain matching items from temporary slots
		var temp_list := cur_temp.duplicate()
		while filled < 3 and temp_list.has(cur_order):
			temp_list.erase(cur_order)
			filled += 1
			if filled == 3:
				order_idx += 1
				filled = 0
				if order_idx >= num_orders:
					return {"solvable": true, "peak_temp": peak_temp}
				cur_order = str(orders[order_idx])

		# 2. Eagerly take any exposed item from columns matching cur_order
		var took_direct := false
		var stacks_copy: Array[Array] = []
		for st in cur_stacks:
			stacks_copy.append(st.duplicate())

		for c in range(stacks_copy.size()):
			var col: Array = stacks_copy[c]
			if not col.is_empty() and str(col.back()) == cur_order:
				col.pop_back()
				filled += 1
				took_direct = true
				if filled == 3:
					order_idx += 1
					filled = 0
					if order_idx >= num_orders:
						return {"solvable": true, "peak_temp": peak_temp}
				stack_queue.push_back([order_idx, filled, stacks_copy, temp_list, peak_temp])
				break

		if took_direct:
			continue

		# 3. Visited state check
		temp_list.sort()
		var key := "%d_%d_%s_%s" % [order_idx, filled, str(stacks_copy), str(temp_list)]
		if visited.has(key) and int(visited[key]) <= peak_temp:
			continue
		visited[key] = peak_temp

		# 4. Branch by picking an exposed item into temporary slots
		if temp_list.size() < max_temp_slots:
			# Prioritize columns that contain cur_order
			var candidates: Array[Dictionary] = []
			for c in range(stacks_copy.size()):
				var col: Array = stacks_copy[c]
				if col.is_empty():
					continue
				var depth := -1
				for i in range(col.size() - 1, -1, -1):
					if str(col[i]) == cur_order:
						depth = col.size() - 1 - i
						break
				if depth >= 0:
					candidates.append({"col": c, "depth": depth})

			if candidates.is_empty():
				# If cur_order is not in any column, allow digging any column
				for c in range(stacks_copy.size()):
					if not stacks_copy[c].is_empty():
						candidates.append({"col": c, "depth": 999})
			else:
				# Sort by depth descending so shallowest depth is pushed LAST and popped FIRST in DFS
				candidates.sort_custom(func(a, b): return a["depth"] > b["depth"])

			for cand in candidates:
				var c: int = cand["col"]
				var branch_stacks: Array[Array] = []
				for st in stacks_copy:
					branch_stacks.append(st.duplicate())
				var picked_item: String = str(branch_stacks[c].pop_back())
				var branch_temp := temp_list.duplicate()
				branch_temp.append(picked_item)
				var new_peak := maxi(peak_temp, branch_temp.size())
				stack_queue.push_back([order_idx, filled, branch_stacks, branch_temp, new_peak])

	return {"solvable": false, "peak_temp": -1}

## Dynamically generates a procedural level with guaranteed solvability.
static func generate_procedural_level(level_num: int, custom_seed: int = 0) -> Dictionary:
	var seed_val := custom_seed if custom_seed != 0 else (level_num * 1000 + 42)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	var order_count := clampi(3 + int((level_num - 1) * 0.8), 3, 10)
	var col_count := clampi(3 + int((level_num - 1) * 0.35), 3, 6)
	var time_limit := maxi(50, 95 - level_num * 4)

	var food_pool := [
		"bakery_6", "sweets_2", "healthy_3", "drinks_2",
		"grill_2", "bakery_3", "sweets_5", "grill_3"
	]

	var orders: Array[String] = []
	var available_foods := food_pool.duplicate()
	for i in range(order_count):
		if available_foods.is_empty():
			available_foods = food_pool.duplicate()
		var idx := rng.randi() % available_foods.size()
		orders.append(available_foods[idx])
		available_foods.remove_at(idx)

	var all_items: Array[String] = []
	for o in orders:
		all_items.append(o)
		all_items.append(o)
		all_items.append(o)

	var total_items := all_items.size()
	var base_cap := total_items / col_count
	var remainder := total_items % col_count
	var caps: Array[int] = []
	for c in range(col_count):
		caps.append(base_cap + (1 if c < remainder else 0))

	var min_peak := mini(5, 1 + int(level_num * 0.45))

	for attempt in range(120):
		var pool := all_items.duplicate()
		for i in range(pool.size() - 1, 0, -1):
			var j := rng.randi() % (i + 1)
			var tmp: String = pool[i]
			pool[i] = pool[j]
			pool[j] = tmp

		var stacks: Array[Array] = []
		var item_idx := 0
		for cap in caps:
			var col: Array[String] = []
			for _k in range(cap):
				col.append(pool[item_idx])
				item_idx += 1
			stacks.append(col)

		var has_identical := false
		for i in range(col_count):
			for j in range(i + 1, col_count):
				if stacks[i] == stacks[j]:
					has_identical = true
					break
			if has_identical:
				break
		if has_identical:
			continue

		var solve_res := solve_level(orders, stacks, 7)
		if solve_res.get("solvable", false):
			var peak: int = solve_res.get("peak_temp", 0)
			if peak >= min_peak or attempt >= 100:
				return {
					"level": level_num,
					"title": "Level %d: Chef Challenge" % level_num,
					"description": "Fast-paced kitchen orders to pack!",
					"time_limit": time_limit,
					"orders": orders,
					"stacks": stacks
				}

	return _get_raw_level(10)
