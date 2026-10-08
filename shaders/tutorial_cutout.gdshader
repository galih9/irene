shader_type canvas_item;

uniform vec4 backdrop_color : source_color = vec4(0.0, 0.0, 0.0, 0.75);
uniform vec2 screen_size = vec2(720.0, 1280.0);
uniform vec2 cutout_a_center = vec2(360.0, 640.0);
uniform vec2 cutout_a_size = vec2(88.0, 88.0);
uniform vec2 cutout_b_center = vec2(360.0, 640.0);
uniform vec2 cutout_b_size = vec2(88.0, 88.0);
uniform float corner_radius = 14.0;
uniform float feather = 2.0;
uniform vec4 glow_color : source_color = vec4(1.0, 0.88, 0.35, 0.85);

float sd_round_box(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + vec2(r);
	return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

void fragment() {
	vec2 p = UV * screen_size;
	float dist_a = sd_round_box(p - cutout_a_center, cutout_a_size * 0.5, corner_radius);
	float dist_b = 99999.0;
	if (cutout_b_size.x > 0.0) {
		dist_b = sd_round_box(p - cutout_b_center, cutout_b_size * 0.5, corner_radius);
	}
	float d = min(dist_a, dist_b);

	if (d <= 0.0) {
		COLOR = vec4(0.0);
	} else if (d < 3.5) {
		float rim = 1.0 - (d / 3.5);
		float pulse = 0.75 + 0.25 * sin(TIME * 4.0);
		vec4 rim_col = vec4(glow_color.rgb, glow_color.a * rim * pulse);
		COLOR = mix(backdrop_color, rim_col, rim);
	} else if (d < 3.5 + feather) {
		float f = (d - 3.5) / feather;
		COLOR = backdrop_color * f;
	} else {
		COLOR = backdrop_color;
	}
}
