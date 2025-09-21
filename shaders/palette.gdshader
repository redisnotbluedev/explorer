shader_type spatial;

uniform sampler2D base_texture;
uniform vec3 colors_from[8] : source_color;
uniform vec3 colors_to[8] : source_color;
uniform float thresholds[8];
uniform int active_swaps : hint_range(0, 8);

void fragment() {
	vec4 tex = texture(base_texture, UV);
	vec3 original_color = tex.rgb;

	for (int i = 0; i < active_swaps; i++) {
		if (distance(tex.rgb, colors_from[i]) < thresholds[i]) {
			vec3 offset = original_color - colors_from[i];

			tex.rgb = colors_to[i] + offset;
			break;
		}
	}

	ALBEDO = tex.rgb;
}