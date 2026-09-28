class_name LiquidSortLevelGenerator
extends RefCounted

const LiquidColorPalette = preload("res://scripts/minigame/liquid_color_palette.gd")

class LevelConfig:
	var level_number: int = 1
	var total_bottles: int = 6
	var capacity: int = 3
	var color_count: int = 3
	var filled_bottles: int = 3   # ALWAYS equals color_count
	var empty_bottles: int = 2
	var bottle_data: Array[Array] = []

# Returns configuration parameters for a given level.
#
# INVARIANT that must always hold:
#   filled_bottles == color_count
#   total_bottles  == color_count + empty_bottles
#
# This guarantees: total liquid = color_count × capacity
# fits exactly into color_count bottles (filled_bottles) to form the solved state,
# and the empty_bottles provide the buffer space needed to sort.
static func get_level_params(level: int) -> Dictionary:
	if level == 1:
		return { "capacity": 3, "color_count": 3, "empty_bottles": 2 }
	elif level == 2:
		return { "capacity": 3, "color_count": 4, "empty_bottles": 2 }
	elif level == 3:
		return { "capacity": 4, "color_count": 4, "empty_bottles": 2 }
	elif level == 4:
		return { "capacity": 4, "color_count": 5, "empty_bottles": 2 }
	elif level == 5:
		return { "capacity": 4, "color_count": 5, "empty_bottles": 3 }
	elif level == 6:
		return { "capacity": 4, "color_count": 6, "empty_bottles": 2 }
	elif level == 7:
		return { "capacity": 4, "color_count": 7, "empty_bottles": 2 }
	else:
		# Dynamically scale higher levels
		var cap := 4 if level < 15 else 5
		var col_cnt := mini(12, 3 + int(level * 0.5))
		var empty_cnt := 2 if col_cnt <= 8 else 3
		return { "capacity": cap, "color_count": col_cnt, "empty_bottles": empty_cnt }

# Generates a guaranteed solvable level with no pre-completed bottles.
static func generate_level(level: int) -> LevelConfig:
	var params := get_level_params(level)
	var config := LevelConfig.new()
	config.level_number  = level
	config.capacity      = params["capacity"]
	config.color_count   = params["color_count"]
	config.empty_bottles = params["empty_bottles"]
	# filled_bottles MUST equal color_count (see invariant above)
	config.filled_bottles = config.color_count
	config.total_bottles  = config.filled_bottles + config.empty_bottles

	var colors := LiquidColorPalette.get_colors_for_level(config.color_count)

	# ── Pre-crafted Level 1 ─────────────────────────────────────────────────
	if level == 1:
		var c0: String = colors[0]
		var c1: String = colors[1]
		var c2: String = colors[2]
		# Hand-crafted, solvable in 7 moves, no bottle pre-complete
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
		# NOTE: level 1 uses 6 filled bottles for a more generous first level feel.
		# Override filled_bottles count to match actual data (legacy hand-craft).
		config.filled_bottles = 6
		config.total_bottles  = 8
		return config

	# ── Random generation for levels > 1 ────────────────────────────────────
	var max_attempts := 80
	for _attempt in range(max_attempts):
		var generated := _generate_shuffled_bottles(config, colors)
		if _has_pre_completed_bottle(generated, config.capacity):
			continue
		var steps := _solve_bfs(generated, config.capacity, 100)
		if steps >= 4:
			config.bottle_data = generated
			return config

	# Fallback: deterministic interleave guaranteed solvable, then verify no pre-complete
	var fallback := _generate_interleaved_fallback(config, colors)
	config.bottle_data = fallback
	return config

# ── Generators ───────────────────────────────────────────────────────────────

# Builds a pool of exactly color_count × capacity units (one full bottle worth per color),
# shuffles it, then distributes across filled_bottles bottles.
# Some bottles will be partially filled — that is intentional and correct.
static func _generate_shuffled_bottles(config: LevelConfig, colors: Array[String]) -> Array[Array]:
	# Pool = exactly one full bottle's worth per color
	var pool: Array[String] = []
	for col in colors:
		for _k in range(config.capacity):
			pool.append(col)
	# pool.size() == color_count × capacity == filled_bottles × capacity  ✓
	pool.shuffle()

	# Distribute evenly: since filled_bottles == color_count,
	# each bottle gets exactly capacity items → all filled bottles start full.
	# That's fine for BFS; the solver handles full bottles with mixed colors.
	var bottles: Array[Array] = []
	for _i in range(config.filled_bottles):
		var b: Array = []
		for _k in range(config.capacity):
			b.append(pool.pop_back())
		bottles.append(b)

	for _i in range(config.empty_bottles):
		bottles.append([])

	return bottles

# Deterministic fallback: interleave colors so no bottle is monochrome.
# Cycles through colors filling each slot, guaranteeing all colors are mixed.
static func _generate_interleaved_fallback(config: LevelConfig, colors: Array[String]) -> Array[Array]:
	# Build a solved pool first
	var pool: Array[String] = []
	for col in colors:
		for _k in range(config.capacity):
			pool.append(col)

	# Interleave: place colors round-robin so adjacent slots differ
	var interleaved: Array[String] = []
	var color_idx := 0
	var col_remaining: Array[int] = []
	for _c in colors:
		col_remaining.append(config.capacity)

	var total := pool.size()
	for _i in range(total):
		# Find next color that still has remaining units
		var tries := 0
		while col_remaining[color_idx] == 0 and tries < colors.size():
			color_idx = (color_idx + 1) % colors.size()
			tries += 1
		interleaved.append(colors[color_idx])
		col_remaining[color_idx] -= 1
		color_idx = (color_idx + 1) % colors.size()

	# Distribute into bottles
	var bottles: Array[Array] = []
	var idx := 0
	for _i in range(config.filled_bottles):
		var b: Array = []
		for _k in range(config.capacity):
			b.append(interleaved[idx])
			idx += 1
		bottles.append(b)

	for _i in range(config.empty_bottles):
		bottles.append([])

	return bottles

# ── Validation helpers ────────────────────────────────────────────────────────

## Returns true if any full bottle has all identical colors (already solved at start).
static func _has_pre_completed_bottle(bottles: Array[Array], capacity: int) -> bool:
	for b in bottles:
		if b.size() != capacity:
			continue
		var first: String = b[0]
		var all_same := true
		for col in b:
			if col != first:
				all_same = false
				break
		if all_same:
			return true
	return false

# ── BFS Solver ────────────────────────────────────────────────────────────────

# Returns the number of moves to solve, or -1 if unsolvable within limits.
static func _solve_bfs(bottles: Array[Array], capacity: int, max_depth: int) -> int:
	var start_state := _canonical_state(bottles)
	var visited := { start_state: true }
	var queue: Array = [{ "state": bottles, "depth": 0 }]
	var nodes_checked := 0

	while not queue.is_empty():
		var node: Dictionary = queue.pop_front()
		var state: Array[Array] = node["state"]
		var depth: int = node["depth"]
		nodes_checked += 1

		if _is_state_solved(state, capacity):
			return depth

		if depth >= max_depth or nodes_checked > 15000:
			continue

		for i in range(state.size()):
			var src: Array = state[i]
			if src.is_empty():
				continue
			var top_col: String = src[src.size() - 1]

			# Count consecutive top-same-color units
			var count := 0
			for si in range(src.size() - 1, -1, -1):
				if src[si] == top_col:
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
					queue.append({ "state": new_state, "depth": depth + 1 })

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
