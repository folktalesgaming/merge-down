shader_type canvas_item;

uniform float radius : hint_range(0.0, 0.5) = 0.15;
uniform vec4 tile_color : source_color = vec4(1.0);

float sd_rounded_box(vec2 p, vec2 b, float r) {
    vec2 d = abs(p) - b + vec2(r);
    return min(max(d.x, d.y), 0.0) + length(max(d, vec2(0.0))) - r;
}

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV) * tile_color;
    
    vec2 p = UV - vec2(0.5);
    vec2 size = vec2(0.5);
    
    float dist = sd_rounded_box(p, size, radius);
    
    float alpha_mask = 1.0 - smoothstep(-0.01, 0.0, dist);
    
    COLOR = vec4(tex_color.rgb, tex_color.a * alpha_mask);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
