shader_type canvas_item;

uniform int shape_type : hint_range(0, 1) = 0;
uniform vec4 border_color : source_color = vec4(1.0);
uniform float border_thickness : hint_range(0.0, 0.1) = 0.04;
uniform vec4 tile_color : source_color = vec4(1.0);
uniform float shape_size : hint_range(0.1, 0.5) = 0.42;  
uniform float corner_radius : hint_range(0.0, 0.2) = 0.05;

float sd_hexagon(vec2 p, float r) {
	const vec3 k = vec3(-0.866025404, 0.5, 0.577350269);
	p = abs(p);
	p -= 2.0 * min(dot(k.xy, p), 0.0) * k.xy;
	p -= vec2(clamp(p.x, -k.z * r, k.z * r), r);
	return length(p) * sign(p.y);
}

float sd_rounded_box(vec2 p, vec2 b, float r) {
	vec2 d = abs(p) - b + vec2(r);
	return min(max(d.x, d.y), 0.0) + length(max(d, vec2(0.0))) - r;
}

void fragment() {
	vec2 st = UV - vec2(0.5);
	float dist = 0.0;

	if (shape_type == 0) {
		dist = sd_hexagon(st, shape_size - corner_radius) - corner_radius;
	} else {
		vec2 box_half_size = vec2(shape_size) - vec2(corner_radius);
		dist = sd_rounded_box(st, box_half_size, corner_radius);
	}

	float fill_alpha = 1.0 - smoothstep(-0.005, 0.005, dist);
	float inner_alpha = 1.0 - smoothstep(-0.005, 0.005, dist + border_thickness);

	vec4 tex_color = texture(TEXTURE, UV) * tile_color;
	vec4 final_color = mix(border_color, tex_color, inner_alpha);

	COLOR = vec4(final_color.rgb, final_color.a * fill_alpha * COLOR.a);
}