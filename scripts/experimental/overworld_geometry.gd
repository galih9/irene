class_name OverworldGeometry
extends RefCounted

## Utility class for isometric grid math, multi-cell footprint conversions,
## and dynamic footprint polygon generation.
##
## Compatible with Godot TileSet layout:
## - tile_shape: TILE_SHAPE_ISOMETRIC (1)
## - tile_layout: TILE_LAYOUT_DIAMOND_RIGHT (4)
## - tile_size: (256, 128)

const DEFAULT_TILE_SIZE: Vector2 = Vector2(256.0, 128.0)

## Returns the offset in local pixels of cell (x, y) relative to cell (0, 0).
## In Diamond Right layout:
## +X steps right-up (+128, -64)
## +Y steps right-down (+128, +64)
static func get_cell_offset(cell: Vector2i, tile_size: Vector2 = DEFAULT_TILE_SIZE) -> Vector2:
	var wh: float = tile_size.x * 0.5
	var hh: float = tile_size.y * 0.5
	return Vector2(wh * (cell.x + cell.y), hh * (-cell.x + cell.y))

## Returns the 4 corner points of a single isometric diamond given its center.
static func get_tile_diamond(center: Vector2, tile_size: Vector2 = DEFAULT_TILE_SIZE) -> PackedVector2Array:
	var wh: float = tile_size.x * 0.5
	var hh: float = tile_size.y * 0.5
	return PackedVector2Array([
		center + Vector2(0.0, -hh),
		center + Vector2(wh, 0.0),
		center + Vector2(0.0, hh),
		center + Vector2(-wh, 0.0)
	])

## Generates the exact boundary polygon for an arbitrary multi-tile footprint
## relative to its geometric center.
## [param footprint] Array of Vector2i cell offsets (e.g. [[(0,0)]], [[(0,0), (1,0)]], etc.)
## [param tile_size] Isometric tile size (default 256x128)
## [param inset] Optional inward inset in pixels (useful for soft contact shadows)
static func get_footprint_polygon(
	footprint: Array[Vector2i],
	tile_size: Vector2 = DEFAULT_TILE_SIZE,
	inset: float = 0.0
) -> PackedVector2Array:
	if footprint.is_empty():
		return PackedVector2Array()

	var wh: float = tile_size.x * 0.5
	var hh: float = tile_size.y * 0.5

	# Calculate cell centers
	var cell_centers: Array[Vector2] = []
	var sum := Vector2.ZERO
	for off in footprint:
		var p := get_cell_offset(off, tile_size)
		cell_centers.append(p)
		sum += p
	var center := sum / float(footprint.size())

	# Merge individual cell diamonds into unified perimeter
	var merged_polys: Array[PackedVector2Array] = []
	for c in cell_centers:
		var rel := c - center
		var diamond := PackedVector2Array([
			rel + Vector2(0.0, -hh),
			rel + Vector2(wh, 0.0),
			rel + Vector2(0.0, hh),
			rel + Vector2(-wh, 0.0)
		])
		if merged_polys.is_empty():
			merged_polys.append(diamond)
		else:
			var next_merged := Geometry2D.merge_polygons(merged_polys[0], diamond)
			if not next_merged.is_empty():
				merged_polys = next_merged

	if merged_polys.is_empty():
		return PackedVector2Array()

	var result := merged_polys[0]
	if inset > 0.0:
		var insets := Geometry2D.offset_polygon(result, -inset)
		if not insets.is_empty():
			result = insets[0]

	return result
