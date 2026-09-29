# Cloth levels

Add a JSON file to this folder and restart the game. Files are loaded in
filename order, so use names like `level_11.json`, `level_12.json`, etc. No manifest
or GDScript changes are needed. Keep existing filenames stable: paid unlocks are
saved by filename. The export presets include this folder's JSON files.

Each file contains one level, with rows from **top to bottom** and cells from
**left to right**. All rows must have the same nonzero number of cells. Colors
must be six-digit RGB hex strings (`#RRGGBB`, case insensitive).

```json
[
  [{"color": "#FFFFF0", "id": "top-left"}, {"color": "#80D995"}],
  [{"color": "#80D995"}, {"color": "#FFFFF0"}]
]
```

Additional cell properties are accepted and preserved in `BigCloth.cell_data`;
they travel with the cell when it falls. Only `color` affects gameplay today.
Malformed files are skipped with an explanation in the Godot debugger/output.

The first listed level is free. Each later level costs `50 × (level number − 1)`
gold to unlock once (50 for level 2 through 450 for level 10). Gold uses the
existing game coin balance. Adjust `UNLOCK_COST_STEP` in
`scripts/minigame/cloth_level_library.gd` to change this pricing. Players can buy
any listed level independently; replaying an unlocked level is free.

The ten included patterns use up to three colors each and are tested to clear
with three roller slots. More colors are supported, but test their layer order
and slot requirements. Rollers are derived deterministically from the cell color
counts and configured capacity. A partial roller leaves when its color is fully
exhausted. Auto mode selects exposed colors and avoids docking duplicates.

For comfortable mobile layouts, start with grids similar to the included levels
(3–6 columns and 2–6 rows).

Run the gameplay and persistence regression tests:

```sh
godot --headless --path . test/test_cloth_levels.tscn
godot --headless --path . test/test_minigame.tscn
```
