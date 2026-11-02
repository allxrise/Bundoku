shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(1.0, 0.85, 0.65, 1.0);
uniform float intensity : hint_range(0.0, 2.0) = 0.5;
uniform float pulse_speed : hint_range(0.1, 10.0) = 2.4;
uniform float shimmer_scale : hint_range(1.0, 20.0) = 6.0;
uniform float border_softness : hint_range(0.05, 0.5) = 0.28;

void fragment() {
	vec4 base_tex = texture(TEXTURE, UV) * COLOR;
	
	// Normalized distance from center for soft vignette/border glow
	vec2 centered_uv = UV * 2.0 - vec2(1.0);
	float dist = max(abs(centered_uv.x), abs(centered_uv.y));
	float radial_dist = length(centered_uv);
	
	// Soft border aura + gentle center warmth
	float edge_factor = smoothstep(1.0 - border_softness * 2.0, 1.0, dist);
	float inner_factor = 1.0 - smoothstep(0.0, 1.15, radial_dist);
	
	// Animated diagonal shimmer wave and breathing pulse
	float pulse = 0.5 + 0.5 * sin(TIME * pulse_speed);
	float shimmer = 0.5 + 0.5 * sin((UV.x + UV.y) * shimmer_scale - TIME * (pulse_speed * 1.35));
	float sparkle = pow(0.5 + 0.5 * sin((UV.x * 1.7 - UV.y * 1.3) * shimmer_scale * 1.5 + TIME * 3.2), 3.0);
	
	float combined_glow = (edge_factor * 0.65 + inner_factor * 0.35) * (0.65 + 0.35 * pulse);
	combined_glow += shimmer * 0.25 + sparkle * 0.15;
	combined_glow *= intensity;
	
	vec3 final_rgb = mix(base_tex.rgb, glow_color.rgb, clamp(combined_glow * glow_color.a, 0.0, 1.0));
	final_rgb += glow_color.rgb * sparkle * 0.18 * intensity;
	
	float final_alpha = max(base_tex.a, clamp(combined_glow * glow_color.a * 0.65, 0.0, 1.0));
	COLOR = vec4(final_rgb, final_alpha);
}
