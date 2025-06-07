shader_type canvas_item;

const int NUM_AVOID_COLORS = 8;
uniform vec4 avoidance_colors[NUM_AVOID_COLORS];

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	float tolerance = 0.01;
	bool skip = false;

	for (int i = 0; i < NUM_AVOID_COLORS; i++) {
		if (all(lessThan(abs(tex_color.rgb - avoidance_colors[i].rgb), vec3(tolerance)))) {
			skip = true;
			break;
		}
	}

	if (skip) {
		COLOR = tex_color;
	} else {
		float gray = tex_color.r * 0.299 + tex_color.g * 0.587 + tex_color.b * 0.114;
		COLOR = vec4(vec3(gray), tex_color.a);
	}
}
