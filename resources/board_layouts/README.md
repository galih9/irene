# Board layouts

Each file here is the **starting board** for one area:

| File | Board |
|---|---|
| `kitchen.json` | Irene's Kitchen |
| `farm.json` | Ivan's Farm |
| `witch.json` | Witch's Haven |

A layout is only used when a board is created fresh (new game, first visit, or
when the farm/witch board is detected as stuck). Existing saves keep their own
board state, so delete your save (or use *New Game*) to see layout changes.

## Format

```json
{
	"board_id": "kitchen",
	"cols": 7,
	"rows": 9,
	"discovered_items": ["pantry_1"],
	"items": [
		{"col": 3, "row": 4, "item_id": "pantry_1", "state": "normal", "unlock_level": 1},
		{"col": 2, "row": 4, "item_id": "pantry_1", "state": "locked", "unlock_level": 1},
		{"col": 0, "row": 0, "item_id": "sweets_2", "state": "hidden", "unlock_level": 5}
	]
}
```

- **Coordinates are always portrait**: `col` 0–6 (left → right), `row` 0–8
  (top → bottom). Landscape boards are rotated automatically.
- Cells not listed in `items` start **empty**.
- `item_id` must exist in the item database; unknown ids are skipped with a
  warning in the Godot output.
- `discovered_items` (optional) marks items as discovered in the collection.
  Items placed with `"state": "normal"` are discovered automatically.

### Item fields

| Field | Required | Values |
|---|---|---|
| `col`, `row` | yes | Portrait grid position |
| `item_id` | yes | e.g. `egg_1`, `barn_2`, `mystic_tree_1` |
| `state` | no (default `normal`) | `normal`, `locked`, `boxed`, `hidden` (or `0`–`3`) |
| `unlock_level` | no (default `1`) | Player level needed to open a box |
| `box_variant` | no (default auto) | Index of the box image (`0`, `1`, `2`, …) |
| `web_variant` | no (default auto) | Index of the web image on locked items |

### States

| State | Player sees | How it opens |
|---|---|---|
| `normal` | Usable item | — |
| `locked` | Item behind a web | Merge a matching item onto it → `normal` |
| `boxed` | Box with "Lv.X" | Player reaches `unlock_level` → `locked` |
| `hidden` | Fog-covered cell | A neighbouring cell is opened → `boxed` if `unlock_level > 1`, else `locked` |

Consumable items cannot be `locked`/`boxed`/`hidden`; they are replaced with
`egg_1` by the board.

## Tutorial note

The kitchen tutorial highlights cells `(3,4)`, `(2,4)` and `(4,4)` and expects
the `foodbox_1` → `foodbox_1` → `foodbox_2` merge chain there. Keep that starter
area if you keep the tutorial.

## Export

`export_presets.cfg` includes `resources/board_layouts/*.json`, so new or edited
layouts ship with every export.
