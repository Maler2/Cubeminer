shader_type canvas_item;
render_mode blend_mix;

uniform sampler2D tex : source_color, filter_nearest;
uniform int hframes : hint_range(1, 64) = 7;
uniform int vframes : hint_range(1, 64) = 1;

varying float v_lifetime;
varying float v_random;

void vertex() {
	v_lifetime = INSTANCE_CUSTOM.x;
	v_random = INSTANCE_CUSTOM.y;
}

void fragment() {
	int total_frames = hframes * vframes;
	float progress = fract(v_lifetime + v_random * 0.3);
	int frame = int(progress * float(total_frames));
	if (frame >= total_frames) frame = total_frames - 1;

	int col = frame % hframes;
	int row = frame / hframes;

	float fw = 1.0 / float(hframes);
	float fh = 1.0 / float(vframes);

	vec2 uv_anim = vec2(
		UV.x * fw + float(col) * fw,
		UV.y * fh + float(row) * fh
	);

	COLOR = texture(tex, uv_anim) * COLOR;
}
