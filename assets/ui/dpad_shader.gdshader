shader_type canvas_item;

uniform int active_dir = 0;
uniform vec4 press_color : source_color = vec4(0.5, 0.5, 0.5, 1.0);

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	
	bool is_white = (tex_color.r > 0.8 && tex_color.g > 0.8 && tex_color.b > 0.8);
	
	if (is_white) {
		if (active_dir == 1 && UV.y < 0.4 && UV.x > 0.3 && UV.x < 0.7) {
			tex_color.rgb = press_color.rgb;
		} else if (active_dir == 2 && UV.y > 0.6 && UV.x > 0.3 && UV.x < 0.7) {
			tex_color.rgb = press_color.rgb;
		} else if (active_dir == 3 && UV.x < 0.4 && UV.y > 0.3 && UV.y < 0.7) {
			tex_color.rgb = press_color.rgb;
		} else if (active_dir == 4 && UV.x > 0.6 && UV.y > 0.3 && UV.y < 0.7) {
			tex_color.rgb = press_color.rgb;
		}
	}
	
	COLOR = tex_color;
}
