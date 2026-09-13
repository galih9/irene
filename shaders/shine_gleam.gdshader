shader_type canvas_item;

uniform vec4 shine_color : source_color = vec4(1.0, 0.95, 0.7, 0.85);
uniform float shine_speed : hint_range(0.1, 5.0) = 0.9;
uniform float shine_width : hint_range(0.01, 1.0) = 0.24;
uniform float shine_pause : hint_range(0.0, 5.0) = 1.2;
uniform float angle : hint_range(0.0, 3.14159) = 0.785398; // 45 degrees
uniform float corner_radius : hint_range(0.0, 0.5) = 0.2; // rounded corners matching board tile

void fragment() {
	// Round corner clipping
	vec2 p = abs(UV - 0.5) - (vec2(0.5) - vec2(corner_radius));
	float d = length(max(p, 0.0)) - corner_radius;
	if (d > 0.0) {
		discard;
	}

	float cycle = (1.0 / shine_speed) + shine_pause;
	float t = mod(TIME, cycle) * shine_speed;
	float pos = UV.x * cos(angle) + UV.y * sin(angle);
	float sweep = t * (1.4 + shine_width * 2.0) - shine_width * 0.5;
	float dist = abs(pos - sweep);
	if (dist < shine_width) {
		float intensity = (1.0 - dist / shine_width);
		intensity = smoothstep(0.0, 1.0, intensity);
		COLOR = vec4(shine_color.rgb, intensity * shine_color.a);
	} else {
		COLOR = vec4(0.0);
	}
}
