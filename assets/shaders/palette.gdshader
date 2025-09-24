shader_type spatial;

uniform sampler2D base_texture;
uniform vec3 colours_from[8] : source_color;
uniform vec3 colours_to[8] : source_color;
uniform float thresholds[8];
uniform int active_swaps : hint_range(0, 8);

void fragment() {
	vec4 tex = texture(base_texture, UV);
	vec3 original_colour = tex.rgb;

	for (int i = 0; i < active_swaps; i++) {
		if (distance(tex.rgb, colours_from[i]) < thresholds[i]) {
			vec3 offset = original_colour - colours_from[i];

			tex.rgb = colours_to[i] + offset;
			break;
		}
	}

	ALBEDO = tex.rgb;
}