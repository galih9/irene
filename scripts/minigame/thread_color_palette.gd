class_name ThreadColorPalette
extends RefCounted

## Centralized color palette configuration for the Thread Rolling Minigame.
## Easily extendable to add unlimited new colors and themes.

const COLORS: Dictionary = {
	"red": {
		"name": "Coral Red",
		"main": Color(0.96, 0.45, 0.45, 1.0),
		"light": Color(1.0, 0.72, 0.72, 1.0),
		"dark": Color(0.78, 0.28, 0.28, 1.0),
		"thread": Color(0.96, 0.40, 0.40, 1.0),
		"accent": Color(1.0, 0.85, 0.85, 1.0),
	},
	"blue": {
		"name": "Sky Blue",
		"main": Color(0.42, 0.72, 0.98, 1.0),
		"light": Color(0.70, 0.88, 1.0, 1.0),
		"dark": Color(0.22, 0.50, 0.82, 1.0),
		"thread": Color(0.35, 0.68, 0.98, 1.0),
		"accent": Color(0.85, 0.94, 1.0, 1.0),
	},
	"green": {
		"name": "Mint Green",
		"main": Color(0.50, 0.85, 0.58, 1.0),
		"light": Color(0.75, 0.95, 0.80, 1.0),
		"dark": Color(0.28, 0.68, 0.36, 1.0),
		"thread": Color(0.40, 0.82, 0.48, 1.0),
		"accent": Color(0.88, 0.98, 0.90, 1.0),
	},
	"yellow": {
		"name": "Golden Yellow",
		"main": Color(0.98, 0.82, 0.32, 1.0),
		"light": Color(1.0, 0.92, 0.60, 1.0),
		"dark": Color(0.85, 0.62, 0.15, 1.0),
		"thread": Color(0.98, 0.80, 0.22, 1.0),
		"accent": Color(1.0, 0.96, 0.82, 1.0),
	},
	"purple": {
		"name": "Lilac Purple",
		"main": Color(0.75, 0.55, 0.92, 1.0),
		"light": Color(0.88, 0.75, 1.0, 1.0),
		"dark": Color(0.55, 0.35, 0.76, 1.0),
		"thread": Color(0.72, 0.48, 0.92, 1.0),
		"accent": Color(0.94, 0.88, 1.0, 1.0),
	},
	"orange": {
		"name": "Tangerine Orange",
		"main": Color(0.98, 0.58, 0.28, 1.0),
		"light": Color(1.0, 0.78, 0.55, 1.0),
		"dark": Color(0.85, 0.42, 0.12, 1.0),
		"thread": Color(0.98, 0.55, 0.20, 1.0),
		"accent": Color(1.0, 0.90, 0.80, 1.0),
	},
	"pink": {
		"name": "Blush Pink",
		"main": Color(0.98, 0.60, 0.75, 1.0),
		"light": Color(1.0, 0.80, 0.90, 1.0),
		"dark": Color(0.82, 0.38, 0.55, 1.0),
		"thread": Color(0.98, 0.52, 0.70, 1.0),
		"accent": Color(1.0, 0.92, 0.96, 1.0),
	},
	"teal": {
		"name": "Ocean Teal",
		"main": Color(0.28, 0.78, 0.78, 1.0),
		"light": Color(0.60, 0.92, 0.92, 1.0),
		"dark": Color(0.15, 0.58, 0.58, 1.0),
		"thread": Color(0.25, 0.75, 0.75, 1.0),
		"accent": Color(0.82, 0.96, 0.96, 1.0),
	}
}

static func get_color_data(color_id: String) -> Dictionary:
	if COLORS.has(color_id):
		return COLORS[color_id]
	return COLORS["green"]

static func get_main_color(color_id: String) -> Color:
	return get_color_data(color_id).get("main", Color.WHITE)

static func get_light_color(color_id: String) -> Color:
	return get_color_data(color_id).get("light", Color.WHITE)

static func get_dark_color(color_id: String) -> Color:
	return get_color_data(color_id).get("dark", Color.BLACK)

static func get_thread_color(color_id: String) -> Color:
	return get_color_data(color_id).get("thread", Color.WHITE)

static func get_all_color_keys() -> Array[String]:
	var keys: Array[String] = []
	for k in COLORS.keys():
		keys.append(str(k))
	return keys

static func get_palette_subset(count: int) -> Array[String]:
	var all_keys := ["red", "blue", "green", "yellow", "purple", "orange", "pink", "teal"]
	var subset: Array[String] = []
	var limit := clampi(count, 1, all_keys.size())
	for i in range(limit):
		subset.append(all_keys[i])
	return subset
