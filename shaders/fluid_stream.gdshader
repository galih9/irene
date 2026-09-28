shader_type canvas_item;

uniform vec4 stream_color : source_color = vec4(0.28, 0.62, 0.98, 1.0);
uniform float flow_speed : hint_range(0.0, 20.0) = 4.0;
uniform float highlight_strength : hint_range(0.0, 1.0) = 0.35;
uniform float edge_darken : hint_range(0.0, 1.0) = 0.18;

void fragment() {
	// In Godot 4 Line2D with LINE_TEXTURE_STRETCH:
	// UV.x runs along stream length (0.0 at spout -> 1.0 at receiving neck)
	// UV.y runs across stream width (0.0 left edge, 0.5 center, 1.0 right edge)
	float width_dist = abs(UV.y - 0.5);

	// Smooth antialiased circular cross-section profile across stream width
	float alpha_edge = 1.0 - smoothstep(0.40, 0.50, width_dist);
	if (alpha_edge <= 0.01) {
		discard;
	}

	// 1. Sleek specular highlight running along the stream
	// Positioned slightly off-center (at y = 0.36) for 3D cylindrical specular reflection
	float highlight_dist = abs(UV.y - 0.36);
	float specular = smoothstep(0.18, 0.02, highlight_dist) * highlight_strength;

	// 2. Subtle laminar flow sheen moving downwards along stream (UV.x)
	float flow_wave = sin(UV.x * 14.0 - TIME * flow_speed);
	specular += smoothstep(0.16, 0.04, highlight_dist) * max(flow_wave * 0.12, 0.0);

	// 3. Subtle edge darkening for 3D cylindrical liquid depth
	float edge = smoothstep(0.25, 0.48, width_dist) * edge_darken;

	// 4. Faithful current liquid color preservation
	vec3 base_rgb = stream_color.rgb;
	vec3 rgb = base_rgb * (1.0 - edge);
	rgb = mix(rgb, vec3(1.0), clamp(specular, 0.0, 0.75));

	COLOR = vec4(rgb, stream_color.a * alpha_edge);
}
