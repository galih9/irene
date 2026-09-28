class_name LiquidColorPalette
extends RefCounted

# Predefined palette matching the reference image vibrant liquid shades
const COLORS: Dictionary = {
	"orange": {
		"name": "Amber Orange",
		"main": Color(0.96, 0.52, 0.08, 1.0),
		"highlight": Color(1.0, 0.72, 0.35, 1.0),
		"dark": Color(0.72, 0.34, 0.04, 1.0)
	},
	"sky_blue": {
		"name": "Sky Blue",
		"main": Color(0.28, 0.62, 0.98, 1.0),
		"highlight": Color(0.58, 0.82, 1.0, 1.0),
		"dark": Color(0.14, 0.38, 0.76, 1.0)
	},
	"lime_green": {
		"name": "Lime Green",
		"main": Color(0.58, 0.82, 0.28, 1.0),
		"highlight": Color(0.78, 0.95, 0.52, 1.0),
		"dark": Color(0.38, 0.58, 0.14, 1.0)
	},
	"magenta": {
		"name": "Royal Magenta",
		"main": Color(0.68, 0.16, 0.72, 1.0),
		"highlight": Color(0.88, 0.42, 0.92, 1.0),
		"dark": Color(0.44, 0.08, 0.48, 1.0)
	},
	"pink": {
		"name": "Rose Pink",
		"main": Color(0.95, 0.46, 0.68, 1.0),
		"highlight": Color(1.0, 0.72, 0.86, 1.0),
		"dark": Color(0.72, 0.25, 0.46, 1.0)
	},
	"teal": {
		"name": "Deep Teal",
		"main": Color(0.08, 0.55, 0.52, 1.0),
		"highlight": Color(0.28, 0.78, 0.74, 1.0),
		"dark": Color(0.04, 0.35, 0.34, 1.0)
	},
	"navy_blue": {
		"name": "Royal Navy",
		"main": Color(0.12, 0.30, 0.75, 1.0),
		"highlight": Color(0.32, 0.52, 0.95, 1.0),
		"dark": Color(0.06, 0.18, 0.52, 1.0)
	},
	"yellow": {
		"name": "Sunny Yellow",
		"main": Color(0.98, 0.78, 0.14, 1.0),
		"highlight": Color(1.0, 0.92, 0.45, 1.0),
		"dark": Color(0.75, 0.55, 0.06, 1.0)
	},
	"olive": {
		"name": "Olive Green",
		"main": Color(0.44, 0.52, 0.16, 1.0),
		"highlight": Color(0.62, 0.72, 0.28, 1.0),
		"dark": Color(0.28, 0.35, 0.08, 1.0)
	},
	"slate_gray": {
		"name": "Slate Steel",
		"main": Color(0.46, 0.52, 0.60, 1.0),
		"highlight": Color(0.68, 0.74, 0.82, 1.0),
		"dark": Color(0.28, 0.32, 0.38, 1.0)
	},
	"crimson": {
		"name": "Ruby Red",
		"main": Color(0.85, 0.18, 0.25, 1.0),
		"highlight": Color(0.98, 0.42, 0.48, 1.0),
		"dark": Color(0.58, 0.08, 0.14, 1.0)
	},
	"lavender": {
		"name": "Soft Lavender",
		"main": Color(0.56, 0.52, 0.88, 1.0),
		"highlight": Color(0.78, 0.74, 0.98, 1.0),
		"dark": Color(0.36, 0.32, 0.65, 1.0)
	}
}

# Standard ordered keys for deterministic level color selection
const ORDERED_KEYS: Array[String] = [
	"orange",
	"sky_blue",
	"lime_green",
	"magenta",
	"pink",
	"teal",
	"navy_blue",
	"yellow",
	"olive",
	"slate_gray",
	"crimson",
	"lavender"
]

static func get_color(key: String) -> Color:
	if COLORS.has(key):
		return COLORS[key]["main"]
	return Color.WHITE

static func get_color_data(key: String) -> Dictionary:
	if COLORS.has(key):
		return COLORS[key]
	return {
		"name": key,
		"main": Color.WHITE,
		"highlight": Color.WHITE,
		"dark": Color.DARK_GRAY
	}

static func get_colors_for_level(count: int) -> Array[String]:
	var result: Array[String] = []
	var total := ORDERED_KEYS.size()
	for i in range(count):
		result.append(ORDERED_KEYS[i % total])
	return result
