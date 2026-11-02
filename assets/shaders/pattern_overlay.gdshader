shader_type canvas_item;

uniform vec4 stripe_color : source_color = vec4(1.0, 0.95, 0.80, 0.42);
uniform float stripe_scale = 24.0;
uniform float speed = 1.5;
uniform int pattern_mode : hint_range(0, 1) = 0; // 0 = diagonal stripes, 1 = polka dots
uniform float softness : hint_range(0.01, 0.45) = 0.12;

void fragment() {
	vec4 base_col = texture(TEXTURE, UV) * COLOR;
	vec2 anim_uv = UV * stripe_scale + vec2(TIME * speed * 0.25, -TIME * speed * 0.15);
	
	float mask = 0.0;
	if (pattern_mode == 0) {
		// Smooth anti-aliased diagonal stripes
		float diag = fract((UV.x + UV.y) * (stripe_scale * 0.5) - TIME * speed * 0.2);
		mask = smoothstep(0.5 - softness, 0.5, diag) - smoothstep(0.85 - softness, 0.85, diag);
	} else {
		// Cute staggered polka dots
		vec2 grid = fract(anim_uv * 0.5) - vec2(0.5);
		float d = length(grid);
		mask = 1.0 - smoothstep(0.22 - softness * 0.5, 0.22 + softness * 0.5, d);
	}
	
	// Subtle breathing modulation for inspection highlight
	float breathe = 0.85 + 0.15 * sin(TIME * speed * 2.0);
	float alpha_mix = mask * stripe_color.a * breathe;
	
	vec3 out_rgb = mix(base_col.rgb, stripe_color.rgb, alpha_mix);
	float out_alpha = max(base_col.a, alpha_mix);
	COLOR = vec4(out_rgb, out_alpha);
}
