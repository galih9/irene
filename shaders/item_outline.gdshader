shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 0.95);
uniform float outline_width : hint_range(0.0, 10.0) = 2.2;
uniform bool enable_outline = true;
uniform float inner_stroke_amount : hint_range(0.0, 1.0) = 0.25;
uniform float pulse_speed : hint_range(0.0, 10.0) = 0.0;
uniform float pulse_intensity : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	if (!enable_outline) {
		COLOR = col * COLOR;
	} else if (col.a > 0.05) {
		// Inside the item sprite
		if (inner_stroke_amount > 0.0) {
			// Subtle inner edge enhancement for crisper pop
			vec2 inner_step = TEXTURE_PIXEL_SIZE * 1.2;
			float min_neighbor_a = min(
				min(texture(TEXTURE, UV + vec2(inner_step.x, 0.0)).a, texture(TEXTURE, UV - vec2(inner_step.x, 0.0)).a),
				min(texture(TEXTURE, UV + vec2(0.0, inner_step.y)).a, texture(TEXTURE, UV - vec2(0.0, inner_step.y)).a)
			);
			if (min_neighbor_a < 0.4) {
				col.rgb = mix(col.rgb, outline_color.rgb, inner_stroke_amount);
			}
		}
		COLOR = col * COLOR;
	} else {
		// Outside the sprite - create crisp outer outline
		vec2 size = TEXTURE_PIXEL_SIZE * outline_width;
		float max_a = 0.0;

		const int SAMPLES = 16;
		for (int i = 0; i < SAMPLES; i++) {
			float angle = float(i) * (TAU / float(SAMPLES));
			vec2 offset = vec2(cos(angle), sin(angle)) * size;
			max_a = max(max_a, texture(TEXTURE, UV + offset).a);
		}

		if (max_a > 0.05) {
			float a = smoothstep(0.05, 0.9, max_a) * outline_color.a * COLOR.a;
			vec3 rgb = outline_color.rgb;
			if (pulse_intensity > 0.0 && pulse_speed > 0.0) {
				float pulse = 0.5 + 0.5 * sin(TIME * pulse_speed);
				rgb = mix(rgb, vec3(1.0), pulse * pulse_intensity);
			}
			COLOR = vec4(rgb, a);
		} else {
			COLOR = vec4(0.0);
		}
	}
}
