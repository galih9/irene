shader_type canvas_item;

uniform sampler2D inner_mask : filter_linear, repeat_disable;

// Capacity and active layer count
uniform int capacity : hint_range(1, 8) = 3;
uniform int layer_count : hint_range(0, 8) = 3;

// Layer colors (index 0 is bottom-most, up to 7)
uniform vec4 layer_colors[8] : source_color;

// Relative heights for each layer (1.0 = standard layer segment)
uniform float layer_heights[8];

// Overall fill amount (0.0 = empty, 1.0 = completely full)
uniform float fill_amount : hint_range(0.0, 1.0) = 1.0;

// Tilt angle in radians (positive = tilt right/clockwise, negative = tilt left/counter-clockwise)
uniform float tilt_angle : hint_range(-3.14159, 3.14159) = 0.0;

// Wave dynamics
uniform float wave_amplitude : hint_range(0.0, 0.05) = 0.012;
uniform float wave_frequency : hint_range(1.0, 30.0) = 15.0;
uniform float wave_speed : hint_range(0.0, 15.0) = 4.5;
uniform float wave_phase : hint_range(0.0, 6.28) = 0.0;

// Bubble animation speed and enable
uniform float bubble_speed : hint_range(0.0, 2.0) = 0.15;
uniform bool show_bubbles = true;

// Bottle physical normalized dimensions
const float Y_BOTTOM = 0.885;
const float Y_TOP_FULL = 0.285;
const float X_CENTER = 0.500;

void fragment() {
	// 1. Check inner mask for bottle glass boundary
	float mask = texture(inner_mask, UV).r;
	if (mask < 0.03 || fill_amount <= 0.001 || layer_count <= 0) {
		discard;
	}
	float edge_alpha = smoothstep(0.03, 0.22, mask);

	float total_usable_h = Y_BOTTOM - Y_TOP_FULL;

	// Calculate cumulative total height of all active layers
	float current_total_layer_units = 0.0;
	for (int i = 0; i < layer_count; i++) {
		current_total_layer_units += layer_heights[i];
	}

	if (current_total_layer_units <= 0.001) {
		discard;
	}

	float effective_fill = clamp(current_total_layer_units / float(capacity), 0.0, 1.0) * fill_amount;
	float current_fill_height = effective_fill * total_usable_h;
	float surface_center_y = Y_BOTTOM - current_fill_height;

	// 2. Liquid Surface Calculation with Tilt & Waves
	vec2 P = UV - vec2(X_CENTER, surface_center_y);

	// Normal and Tangent vectors rotated by tilt_angle
	// Positive tilt_angle = clockwise tilt in Godot 2D space (+X right, +Y down)
	// Normal points downward along gravity into the liquid
	float current_tilt = (abs(tilt_angle) < 0.001) ? 0.0 : tilt_angle;
	vec2 norm = vec2(sin(current_tilt), cos(current_tilt));
	vec2 tang = vec2(cos(current_tilt), -sin(current_tilt));

	float u = dot(P, tang);
	float dist_from_surface = dot(P, norm);

	// Dynamic wave along the surface tangent
	float effective_amp = wave_amplitude * clamp(effective_fill * 2.0, 0.0, 1.0);
	float wave = sin(u * wave_frequency + TIME * wave_speed + wave_phase) * effective_amp;

	float dist_wave = dist_from_surface - wave;

	// If above surface line, discard / clear
	if (dist_wave < -0.002) {
		discard;
	}

	float surface_alpha = clamp((dist_wave + 0.002) * 200.0, 0.0, 1.0);

	// 3. Determine which layer this pixel belongs to
	// Projection from bottom along the bottle axis / gravity normal
	vec2 P_bottom = UV - vec2(X_CENTER, Y_BOTTOM);
	// Distance from bottom upward along norm
	float dist_from_bottom = -dot(P_bottom, norm);

	// Unit height of one full layer segment along the normal
	float unit_h = total_usable_h / float(capacity);

	int active_idx = 0;
	float accumulated_h = 0.0;
	float layer_dist_to_next = 1.0;

	for (int i = 0; i < 8; i++) {
		if (i >= layer_count) break;
		float seg_h = max(layer_heights[i], 0.0001) * unit_h;
		float next_h = accumulated_h + seg_h;
		if (dist_from_bottom <= next_h || i == layer_count - 1) {
			active_idx = i;
			layer_dist_to_next = next_h - dist_from_bottom;
			break;
		}
		accumulated_h = next_h;
	}

	vec4 base_color = layer_colors[active_idx];

	// 4. Subtle layer interface line (distinction between layers)
	float interface_line = 0.0;
	if (active_idx < layer_count - 1 && layer_dist_to_next >= 0.0 && layer_dist_to_next < 0.007) {
		interface_line = smoothstep(0.007, 0.0, layer_dist_to_next) * 0.28;
	}

	// 5. Procedural rising bubbles inside liquid
	vec3 bubble_effect = vec3(0.0);
	if (show_bubbles) {
		vec2 b_coords = vec2(UV.x * 14.0, (UV.y + TIME * bubble_speed) * 16.0);
		vec2 b_grid = floor(b_coords);
		vec2 b_f = fract(b_coords) - 0.5;
		float b_rnd = fract(sin(dot(b_grid, vec2(127.1, 311.7))) * 43758.5453123);
		if (b_rnd > 0.74) {
			float b_radius = 0.09 + (b_rnd - 0.74) * 0.35;
			float b_d = length(b_f);
			if (b_d < b_radius) {
				float ring = smoothstep(b_radius, b_radius - 0.035, b_d) - smoothstep(b_radius - 0.035, b_radius - 0.07, b_d);
				float glow = smoothstep(b_radius, 0.0, b_d) * 0.3;
				bubble_effect = vec3(1.0) * (ring * 0.75 + glow);
			}
		}
	}

	// 6. Cylindrical Glass Depth Shading
	float x_offset = abs(UV.x - X_CENTER);
	float cyl_depth = 1.0 - pow(clamp(x_offset / 0.24, 0.0, 1.0), 2.5) * 0.22;

	// Bottom contour subtle shadow
	float bottom_ao = 1.0 - smoothstep(0.85, Y_BOTTOM, UV.y) * 0.15;

	// 7. Surface Foam / Meniscus highlight at the very top
	float foam = 0.0;
	if (dist_wave >= 0.0 && dist_wave < 0.016) {
		foam = smoothstep(0.016, 0.0, dist_wave) * 0.45;
	}

	// 8. Composite Final Color
	vec3 rgb = base_color.rgb * cyl_depth * bottom_ao;
	rgb = mix(rgb, vec3(0.1, 0.1, 0.15), interface_line); // subtle dark meniscus line between layers
	rgb += bubble_effect;
	rgb = mix(rgb, vec3(1.0), foam); // top wave white foam sheen

	float final_alpha = base_color.a * edge_alpha * surface_alpha;
	COLOR = vec4(rgb, final_alpha);
}
