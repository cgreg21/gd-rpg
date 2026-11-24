shader_type canvas_item;

// Final screen pass: sample the rendered frame, then bend and shade it like a CRT.
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform float strength : hint_range(0.0, 1.0) = 1.0;
uniform float curvature : hint_range(0.0, 0.20) = 0.085;
uniform float curvature_vertical : hint_range(0.0, 0.20) = 0.075;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.22;
uniform float grille_strength : hint_range(0.0, 1.0) = 0.10;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.28;
uniform float chromatic_aberration : hint_range(0.0, 0.02) = 0.0015;
uniform float bloom_strength : hint_range(0.0, 1.0) = 0.08;
uniform float corner_roundness : hint_range(0.0, 1.0) = 0.35;

vec2 curve_uv(vec2 uv) {
	vec2 p = uv * 2.0 - 1.0;
	float r2 = dot(p, p);
	p.x *= 1.0 + curvature * r2;
	p.y *= 1.0 + curvature_vertical * r2;
	return p * 0.5 + 0.5;
}

void fragment() {
	vec2 uv = curve_uv(SCREEN_UV);
	vec2 centered = SCREEN_UV * 2.0 - 1.0;
	float radius = dot(centered, centered);

	float edge_distance = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
	float rounded_corner = smoothstep(0.0, 0.035 * corner_roundness + 0.0001, edge_distance);
	float inside = step(0.0, uv.x) * step(uv.x, 1.0) * step(0.0, uv.y) * step(uv.y, 1.0);

	vec2 aberration = centered * radius * chromatic_aberration;
	float red = texture(screen_texture, clamp(uv + aberration, vec2(0.0), vec2(1.0))).r;
	float green = texture(screen_texture, clamp(uv, vec2(0.0), vec2(1.0))).g;
	float blue = texture(screen_texture, clamp(uv - aberration, vec2(0.0), vec2(1.0))).b;
	vec3 image = vec3(red, green, blue);

	// A restrained four-tap glow softens only bright phosphors.
	vec2 texel = SCREEN_PIXEL_SIZE * 1.5;
	vec3 glow = texture(screen_texture, clamp(uv + vec2(texel.x, 0.0), vec2(0.0), vec2(1.0))).rgb;
	glow += texture(screen_texture, clamp(uv - vec2(texel.x, 0.0), vec2(0.0), vec2(1.0))).rgb;
	glow += texture(screen_texture, clamp(uv + vec2(0.0, texel.y), vec2(0.0), vec2(1.0))).rgb;
	glow += texture(screen_texture, clamp(uv - vec2(0.0, texel.y), vec2(0.0), vec2(1.0))).rgb;
	glow *= 0.25;
	image += max(glow - image, vec3(0.0)) * bloom_strength;

	float scanline = 1.0 - scanline_strength * (0.5 + 0.5 * cos(SCREEN_UV.y / SCREEN_PIXEL_SIZE.y * 3.14159265));
	float grille_phase = mod(floor(SCREEN_UV.x / SCREEN_PIXEL_SIZE.x), 3.0);
	vec3 grille = vec3(1.0 - grille_strength * 0.35);
	if (grille_phase < 1.0) {
		grille.r = 1.0;
	} else if (grille_phase < 2.0) {
		grille.g = 1.0;
	} else {
		grille.b = 1.0;
	}
	float vignette = 1.0 - vignette_strength * smoothstep(0.15, 1.8, radius);
	vec3 crt_color = image * grille * scanline * vignette;

	float mask = inside * rounded_corner;
	vec3 clean_image = texture(screen_texture, SCREEN_UV).rgb;
	vec3 final_color = mix(clean_image, crt_color * mask, strength);
	COLOR = vec4(final_color, 1.0);
}
