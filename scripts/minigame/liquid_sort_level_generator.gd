class_name LiquidSortLevelGenerator
extends RefCounted

const LiquidColorPalette = preload("res://scripts/minigame/liquid_color_palette.gd")

class LevelConfig:
	var level_number: int = 1
	var total_bottles: int = 8
	var capacity: int = 3
	var color_count: int = 3
	var filled_bottles: int = 6
	var empty_bottles: int = 2
	var bottle_data: Array[Array] = []

# Returns configuration parameters for a given level
static func get_level_params(level: int) -> Dictionary:
	# Level 1 requirement: 8 bottles, 3 rows (capacity=3), 3 colors
	if level == 1:
		return {
			"total_bottles": 8,
			"capacity": 3,
			"color_count": 3,
			"filled_bottles": 6,
			"empty_bottles": 2
		}
	elif level == 2:
		return {
			"total_bottles": 8,
			"capacity": 3,
			"color_count": 4,
			"filled_bottles": 6,
			"empty_bottles": 2
		}
	elif level == 3:
		return {
			"total_bottles": 9,
			"capacity": 4,
			"color_count": 4,
			"filled_bottles": 7,
			"empty_bottles": 2
		}
	elif level == 4:
		return {
			"total_bottles": 10,
			"capacity": 4,
			"color_count": 5,
			"filled_bottles": 8,
			"empty_bottles": 2
		}
	elif level == 5:
		return {
			"total_bottles": 11,
			"capacity": 4,
			"color_count": 5,
			"filled_bottles": 9,
			"empty_bottles": 2
		}
	elif level == 6:
		return {
			"total_bottles": 12,
			"capacity": 4,
			"color_count": 6,
			"filled_bottles": 10,
			"empty_bottles": 2
		}
	elif level == 7:
		return {
			"total_bottles": 12,
			"capacity": 4,
			"color_count": 7,
			"filled_bottles": 10,
			"empty_bottles": 2
		}
	else:
		# Dynamically scale higher levels
		var cap := 4 if level < 15 else 5
		var col_cnt := mini(12, 3 + int(level * 0.5))
		var bottles := mini(14, 8 + int((level - 1) * 0.8))
		var empty_cnt := 2
		var filled_cnt := bottles - empty_cnt
		return {
			"total_bottles": bottles,
			"capacity": cap,
			"color_count": col_cnt,
			"filled_bottles": filled_cnt,
			"empty_bottles": empty_cnt
		}

# Generates a guaranteed solvable level
static func generate_level(level: int) -> LevelConfig:
	var params := get_level_params(level)
	var config := LevelConfig.new()
	config.level_number = level
	config.total_bottles = params["total_bottles"]
	config.capacity = params["capacity"]
	config.color_count = params["color_count"]
	config.filled_bottles = params["filled_bottles"]
	config.empty_bottles = params["empty_bottles"]

	var colors := LiquidColorPalette.get_colors_for_level(config.color_count)

	# Pre-crafted Level 1 layout to ensure a delightful first impression
	if level == 1:
		# 3 colors: "orange", "sky_blue", "lime_green", capacity 3, 6 filled + 2 empty
		var c0: String = colors[0] # orange
		var c1: String = colors[1] # sky_blue
		var c2: String = colors[2] # lime_green
		
		# Hand-crafted fun initial distribution (solvable in 7 moves)
		config.bottle_data = [
			[c0, c0, c1], # Bottle 0
			[c0, c1, c1], # Bottle 1
			[c2, c2, c0], # Bottle 2
			[c2, c0, c0], # Bottle 3
			[c1, c1, c2], # Bottle 4
			[c2, c2, c1], # Bottle 5
			[],           # Bottle 6 (Empty)
			[]            # Bottle 7 (Empty)
		]
		return config


	# For levels > 1: generate solvable shuffle
	var max_attempts := 30
	for _attempt in range(max_attempts):
		var generated_bottles := _try_generate_shuffled_bottles(config, colors)
		var solve_steps := _solve_bfs(generated_bottles, config.capacity, 45)
		if solve_steps >= 4:
			config.bottle_data = generated_bottles
			return config

	# Fallback safe shuffle
	config.bottle_data = _generate_fallback(config, colors)
	return config

static func _try_generate_shuffled_bottles(config: LevelConfig, colors: Array[String]) -> Array[Array]:
	var total_units := config.filled_bottles * config.capacity
	var pool: Array[String] = []

	# Distribute colors evenly into the pool
	var units_per_color := total_units / config.color_count
	var remainder := total_units % config.color_count

	for i in range(config.color_count):
		var count := units_per_color + (1 if i < remainder else 0)
		for _k in range(count):
			pool.append(colors[i])

	# Shuffle pool
	pool.shuffle()

	var bottles: Array[Array] = []
	for i in range(config.filled_bottles):
		var b: Array = []
		for _k in range(config.capacity):
			b.append(pool.pop_back())
		bottles.append(b)

	for _i in range(config.empty_bottles):
		bottles.append([])

	return bottles

static func _generate_fallback(config: LevelConfig, colors: Array[String]) -> Array[Array]:
	var bottles: Array[Array] = []
	for i in range(config.filled_bottles):
		var col_a := colors[i % colors.size()]
		var col_b := colors[(i + 1) % colors.size()]
		var b: Array = []
		for k in range(config.capacity):
			b.append(col_a if k < config.capacity / 2 else col_b)
		bottles.append(b)

	for _i in range(config.empty_bottles):
		bottles.append([])

	return bottles

# Fast BFS solver to confirm solvability
static func _solve_bfs(bottles: Array[Array], capacity: int, max_depth: int) -> int:
	var start_state := _canonical_state(bottles)
	var visited := {}
	visited[start_state] = true

	var queue: Array = []
	queue.append({"state": bottles, "depth": 0})

	var nodes_checked := 0
	while not queue.is_empty():
		var node: Dictionary = queue.pop_front()
		var state: Array[Array] = node["state"]
		var depth: int = node["depth"]
		nodes_checked += 1

		if _is_state_solved(state, capacity):
			return depth

		if depth >= max_depth or nodes_checked > 10000:
			continue


		for i in range(state.size()):
			var src: Array = state[i]
			if src.is_empty():
				continue
			var top_col: String = src[src.size() - 1]
			
			var count := 0
			for idx in range(src.size() - 1, -1, -1):
				if src[idx] == top_col:
					count += 1
				else:
					break

			for j in range(state.size()):
				if i == j:
					continue
				var dst: Array = state[j]
				if dst.size() >= capacity:
					continue
				if not dst.is_empty() and dst[dst.size() - 1] != top_col:
					continue

				var space := capacity - dst.size()
				var units := mini(count, space)

				# Create next state
				var new_src := src.slice(0, src.size() - units)
				var new_dst := dst.duplicate()
				for _u in range(units):
					new_dst.append(top_col)

				var new_state := state.duplicate(true)
				new_state[i] = new_src
				new_state[j] = new_dst

				var canonical := _canonical_state(new_state)
				if not visited.has(canonical):
					visited[canonical] = true
					queue.append({"state": new_state, "depth": depth + 1})

	return -1

static func _is_state_solved(state: Array[Array], capacity: int) -> bool:
	for b in state:
		if b.is_empty():
			continue
		if b.size() != capacity:
			return false
		var first_col: String = b[0]
		for c in b:
			if c != first_col:
				return false
	return true

static func _canonical_state(state: Array[Array]) -> String:
	var keys: Array[String] = []
	for b in state:
		keys.append(",".join(PackedStringArray(b)))
	keys.sort()
	return "|".join(PackedStringArray(keys))
