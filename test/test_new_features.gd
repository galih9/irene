extends Node

func _ready() -> void:
	print("=== VERIFYING NEW MERGE FEATURES ===")

	var board_scene: PackedScene = load("res://scenes/board.tscn")
	var board: Board = board_scene.instantiate()
	add_child(board)
	board.clear_board()

	# -------------------------------------------------------------
	# 1. Test Item Outline Shader & Highlights
	# -------------------------------------------------------------
	print("\n--- 1. Testing Item Outline Shader ---")
	var item_view_scene: PackedScene = load("res://scenes/item_view.tscn")
	var item_view: ItemView = item_view_scene.instantiate()
	add_child(item_view)
	item_view.setup(ItemDatabase.get_item("pantry_1"), ItemView.ItemState.NORMAL)

	var sprite: Sprite2D = item_view.get_node("Visuals/Sprite")
	assert(sprite.material is ShaderMaterial, "Sprite must have a ShaderMaterial")
	var sm: ShaderMaterial = sprite.material as ShaderMaterial
	assert(sm.shader != null, "Shader must be assigned")
	assert(sm.get_shader_parameter("enable_outline") == true, "Normal item must have outline enabled")
	var normal_color: Color = sm.get_shader_parameter("outline_color")
	assert(normal_color.r > 0.9 and normal_color.g > 0.9 and normal_color.b > 0.9, "Normal outline must be crisp white")

	# Test Locked item outline
	item_view.item_state = ItemView.ItemState.LOCKED
	assert(sm.get_shader_parameter("enable_outline") == true, "Locked item must have outline enabled")
	var locked_color: Color = sm.get_shader_parameter("outline_color")
	assert(locked_color.a < 0.6, "Locked outline should have lower opacity")

	# Test Boxed item outline
	item_view.item_state = ItemView.ItemState.BOXED
	assert(sm.get_shader_parameter("enable_outline") == false, "Boxed item outline must be disabled")

	# Test Merge highlight on normal item
	item_view.item_state = ItemView.ItemState.NORMAL
	item_view.set_merge_highlight(true)
	var hl_color: Color = sm.get_shader_parameter("outline_color")
	assert(hl_color.g > 0.9 and hl_color.r < 0.5, "Merge highlight outline must be vibrant green")
	item_view.set_merge_highlight(false)
	var reset_color: Color = sm.get_shader_parameter("outline_color")
	assert(reset_color.r > 0.9 and reset_color.g > 0.9, "Outline must reset to white")
	item_view.queue_free()
	print("[OK] Item outline shader successfully verified!")

	# -------------------------------------------------------------
	# 2. Test Category Sizing (Small, Medium, Normal)
	# -------------------------------------------------------------
	print("\n--- 2. Testing Category Sizing ---")
	var view_low: ItemView = item_view_scene.instantiate()
	var view_mid: ItemView = item_view_scene.instantiate()
	var view_high: ItemView = item_view_scene.instantiate()
	add_child(view_low)
	add_child(view_mid)
	add_child(view_high)

	# 10-tier Pantry chain:
	# Tier 1 -> Small, Tier 5 -> Medium, Tier 8 -> Normal
	view_low.setup(ItemDatabase.get_item("pantry_1"))
	view_mid.setup(ItemDatabase.get_item("pantry_5"))
	view_high.setup(ItemDatabase.get_item("pantry_8"))

	assert(view_low.get_size_category() == ItemView.ItemSizeCategory.SMALL, "pantry_1 must be SMALL category")
	assert(view_mid.get_size_category() == ItemView.ItemSizeCategory.MEDIUM, "pantry_5 must be MEDIUM category")
	assert(view_high.get_size_category() == ItemView.ItemSizeCategory.NORMAL, "pantry_8 must be NORMAL category")

	assert(view_low.get_category_target_size() == 50.0, "SMALL category target size must be 50.0px")
	assert(view_mid.get_category_target_size() == 60.0, "MEDIUM category target size must be 60.0px")
	assert(view_high.get_category_target_size() == 70.0, "NORMAL category target size must be 70.0px")

	var low_sprite: Sprite2D = view_low.get_node("Visuals/Sprite")
	var mid_sprite: Sprite2D = view_mid.get_node("Visuals/Sprite")
	var high_sprite: Sprite2D = view_high.get_node("Visuals/Sprite")

	# Verify visual scales reflect the size progression
	assert(low_sprite.scale.x < mid_sprite.scale.x, "Lower tier scale must be smaller than middle tier scale")
	assert(mid_sprite.scale.x < high_sprite.scale.x, "Middle tier scale must be smaller than higher tier scale")

	view_low.queue_free()
	view_mid.queue_free()
	view_high.queue_free()
	print("[OK] Category sizing (small, medium, normal) successfully verified!")

	# -------------------------------------------------------------
	# 3. Test Forced Tutorial Overlay
	# -------------------------------------------------------------
	print("\n--- 3. Testing Forced Tutorial Overlay ---")
	var overlay_scene: PackedScene = load("res://scenes/forced_tutorial_overlay.tscn")
	var overlay = overlay_scene.instantiate()
	add_child(overlay)

	var src_coord := Vector2i(3, 4)
	var tgt_coord := Vector2i(2, 4)
	overlay.setup(board, src_coord, tgt_coord)

	assert(overlay.is_active == true, "Forced tutorial overlay must be active")
	assert(overlay.visible == true, "Forced tutorial overlay must be visible")
	assert(overlay.backdrop != null, "Overlay must have a backdrop ColorRect")
	assert(overlay.backdrop.material is ShaderMaterial, "Backdrop must use cutout shader material")

	var src_screen_pos := board.to_global(board.get_cell_center(src_coord.x, src_coord.y))
	# Taps on source item cell must pass through (not absorbed)
	assert(overlay._has_point(src_screen_pos) == false, "Source cell must allow touch input through")

	# Taps anywhere outside source cell must be absorbed
	var outside_pos := Vector2(20.0, 20.0)
	assert(overlay._has_point(outside_pos) == true, "Outside points must be absorbed by forced overlay")

	# Hand guide sprite
	assert(overlay.hand != null, "Overlay must have a hand guide sprite")
	assert(overlay.hand.texture != null, "Hand guide must have a texture")

	overlay.dismiss()
	print("[OK] Forced tutorial overlay successfully verified!")

	# -------------------------------------------------------------
	# 4. Test Merge Sparkling Effect
	# -------------------------------------------------------------
	print("\n--- 4. Testing Merge Sparkling Effect ---")
	var sparkles_scene: PackedScene = load("res://scenes/fx/merge_sparkles.tscn")
	var sparkles = sparkles_scene.instantiate()
	add_child(sparkles)

	assert(sparkles.particles != null, "MergeSparkles must have CPUParticles2D")
	assert(sparkles.particles.texture != null, "Particles must have a star texture")
	assert(sparkles.particles.emitting == true, "Particles must be emitting on ready")

	# Test board spawning sparkles
	var prev_children_count := board.get_child_count()
	board.spawn_merge_sparkles(Vector2(200, 200))
	assert(board.get_child_count() > prev_children_count, "Board must spawn MergeSparkles as child")
	sparkles.queue_free()
	board.queue_free()
	print("[OK] Merge sparkling effect successfully verified!")

	print("\n=== ALL 4 USER REQUIREMENTS VERIFIED SUCCESSFULLY! ===")
	get_tree().quit(0)
