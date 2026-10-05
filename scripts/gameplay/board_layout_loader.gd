class_name BoardLayoutLoader
extends RefCounted
## Loads hand-designed starting boards from res://resources/board_layouts/<board_id>.json.
##
## Layout coordinates are always written in portrait orientation (7 cols x 9 rows).
## When the board is in landscape (9 x 7), coordinates are rotated automatically.
## See resources/board_layouts/README.md for the file format.

const LAYOUT_DIRECTORY: String = "res://resources/board_layouts"
const PORTRAIT_COLS: int = 7
const PORTRAIT_ROWS: int = 9

const STATE_NAMES: Dictionary = {
	"normal": ItemView.ItemState.NORMAL,
	"locked": ItemView.ItemState.LOCKED,
	"boxed": ItemView.ItemState.BOXED,
	"hidden": ItemView.ItemState.HIDDEN,
}


static func get_layout_path(board_id: String) -> String:
	return LAYOUT_DIRECTORY.path_join("%s.json" % board_id)


## Reads and parses a layout file. Returns an empty Dictionary on failure.
static func load_layout(board_id: String) -> Dictionary:
	var path := get_layout_path(board_id)
	if not FileAccess.file_exists(path):
		push_error("Board layout not found: %s" % path)
		return {}

	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		push_error("Board layout %s: JSON error on line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return {}
	if typeof(json.data) != TYPE_DICTIONARY or typeof(json.data.get("items")) != TYPE_ARRAY:
		push_error("Board layout %s: expected an object with an \"items\" array." % path)
		return {}
	return json.data


## Converts a layout's items into the same entry format used by Board.load_items()
## (i.e. the save-file format), rotating coordinates for landscape if needed.
static func build_entries(layout: Dictionary, to_landscape: bool, board_id: String = "") -> Array:
	var entries: Array = []
	var occupied: Dictionary = {}

	for raw in layout.get("items", []):
		if typeof(raw) != TYPE_DICTIONARY:
			push_warning("Board layout %s: skipping non-object item entry." % board_id)
			continue
		var item: Dictionary = raw
		var item_id := str(item.get("item_id", ""))
		var col := int(item.get("col", -1))
		var row := int(item.get("row", -1))

		if item_id.is_empty() or ItemDatabase.get_item(item_id) == null:
			push_warning("Board layout %s: unknown item_id \"%s\" at (%d, %d), skipped." % [board_id, item_id, col, row])
			continue
		if col < 0 or col >= PORTRAIT_COLS or row < 0 or row >= PORTRAIT_ROWS:
			push_warning("Board layout %s: (%d, %d) is outside the %dx%d portrait grid, skipped." % [board_id, col, row, PORTRAIT_COLS, PORTRAIT_ROWS])
			continue

		var key := Vector2i(col, row)
		if occupied.has(key):
			push_warning("Board layout %s: duplicate cell (%d, %d); the later entry \"%s\" wins." % [board_id, col, row, item_id])
			entries.erase(occupied[key])

		var state := _parse_state(item.get("state", item.get("item_state", "normal")), board_id, item_id)
		var coord := key
		if to_landscape:
			# Same mapping as Board.map_coord_for_orientation(coord, true).
			coord = Vector2i(PORTRAIT_ROWS - 1 - row, col)

		var entry := {
			"col": coord.x,
			"row": coord.y,
			"item_id": item_id,
			"item_state": state,
			"unlock_level": maxi(1, int(item.get("unlock_level", 1))),
			"box_variant": int(item.get("box_variant", -1)),
			"web_variant": int(item.get("web_variant", -1)),
		}
		occupied[key] = entry
		entries.append(entry)
	return entries


## Clears the board and fills it with the layout for board_id.
## Returns false if the layout could not be loaded (the board is left empty).
static func apply_layout(board: Board, board_id: String) -> bool:
	var layout := load_layout(board_id)
	if layout.is_empty():
		board.clear_board(false)
		return false

	var is_landscape := (board.cols == PORTRAIT_ROWS and board.rows == PORTRAIT_COLS)
	board.board_theme = board_id
	board.load_items(build_entries(layout, is_landscape, board_id))

	for discovered_id in layout.get("discovered_items", []):
		ProgressionManager.unlock_item(str(discovered_id), true)
	return true


static func _parse_state(value: Variant, board_id: String, item_id: String) -> int:
	if typeof(value) == TYPE_STRING:
		var key := (value as String).strip_edges().to_lower()
		if STATE_NAMES.has(key):
			return STATE_NAMES[key]
		push_warning("Board layout %s: unknown state \"%s\" for %s, using \"normal\"." % [board_id, value, item_id])
		return ItemView.ItemState.NORMAL
	var num := int(value)
	if num < ItemView.ItemState.NORMAL or num > ItemView.ItemState.HIDDEN:
		push_warning("Board layout %s: invalid state %d for %s, using \"normal\"." % [board_id, num, item_id])
		return ItemView.ItemState.NORMAL
	return num
