class_name ClothLevelLibrary
extends RefCounted

const LEVEL_DIRECTORY := "res://resources/cloth_levels"
const UNLOCK_COST_STEP := 50

## Drop another JSON file in LEVEL_DIRECTORY; no manifest or code change needed.
static func load_levels() -> Array[Dictionary]:
	var levels: Array[Dictionary] = []
	var files := DirAccess.get_files_at(LEVEL_DIRECTORY)
	files.sort()
	for filename in files:
		if filename.get_extension().to_lower() != "json":
			continue
		var json := JSON.new()
		var error := json.parse(FileAccess.get_file_as_string(LEVEL_DIRECTORY.path_join(filename)))
		if error != OK:
			push_warning("Cloth level %s: %s" % [filename, json.get_error_message()])
			continue
		var validation := validate_rows(json.data)
		if not validation.is_empty():
			push_warning("Cloth level %s: %s" % [filename, validation])
			continue
		var cells: Array = json.data.duplicate(true)
		for row in cells:
			for cell in row:
				cell["color"] = "#" + Color.html(cell["color"]).to_html(false).to_upper()
		levels.append({"id": filename, "rows": cells, "cost": levels.size() * UNLOCK_COST_STEP})
	return levels

static func validate_rows(data: Variant) -> String:
	if not data is Array or data.is_empty():
		return "Expected a non-empty array of rows."
	if not data[0] is Array or data[0].is_empty():
		return "Rows must be non-empty arrays."
	var width: int = data[0].size()
	for row in data:
		if not row is Array or row.size() != width:
			return "Every row must contain the same number of cells."
		for cell in row:
			if not cell is Dictionary or not cell.get("color") is String:
				return "Every cell must be an object with a color string."
			var color: String = cell["color"]
			if color.length() != 7 or not color.begins_with("#") or not Color.html_is_valid(color):
				return "Cell colors must use #RRGGBB format."
	return ""
