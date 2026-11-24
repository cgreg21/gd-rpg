shader_type canvas_item;

// One native-resolution pass for the CRT glass and its permanent outer housing.
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform float crt_enabled : hint_range(0.0, 1.0) = 0.0;
uniform float strength : hint_range(0.0, 1.0) = 1.0;
uniform float curvature : hint_range(0.0, 0.20) = 0.085;
uniform float curvature_vertical : hint_range(0.0, 0.20) = 0.075;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.22;
uniform float grille_strength : hint_range(0.0, 1.0) = 0.10;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.28;
uniform float chromatic_aberration : hint_range(0.0, 0.02) = 0.0015;
uniform float bloom_strength : hint_range(0.0, 1.0) = 0.08;
uniform float corner_roundness : hint_range(0.0, 1.0) = 0.35;

const float SCREEN_INSET = 0.055;

vec2 curve_uv(vec2 uv) {
	vec2 p = uv * 2.0 - 1.0;
	float r2 = dot(p, p);
	p.x *= 1.0 + curvature * r2;
	p.y *= 1.0 + curvature_vertical * r2;
	return p * 0.5 + 0.5;
}

float rounded_screen_mask(vec2 uv) {
	vec2 centered = abs(uv * 2.0 - 1.0);
	float radius = 0.075;
	vec2 corner = centered - vec2(1.0 - radius);
	float distance_to_corner = length(max(corner, vec2(0.0))) + min(max(corner.x, corner.y), 0.0) - radius;
	return 1.0 - smoothstep(0.0, 0.012, distance_to_corner);
}

void fragment() {
	vec2 outer_uv = SCREEN_UV;
	vec2 screen_uv = (outer_uv - vec2(SCREEN_INSET)) / (1.0 - 2.0 * SCREEN_INSET);
	bool inside_screen = all(greaterThanEqual(screen_uv, vec2(0.0))) && all(lessThanEqual(screen_uv, vec2(1.0)));

	// The screen samples the live framebuffer, not a baked reflection texture.
	vec2 curved_uv = curve_uv(screen_uv);
	vec2 display_uv = mix(screen_uv, curved_uv, crt_enabled);
	vec2 aberration = (display_uv * 2.0 - 1.0) * dot(display_uv * 2.0 - 1.0, display_uv * 2.0 - 1.0) * chromatic_aberration * crt_enabled;
	vec2 sample_uv = clamp(display_uv, vec2(0.0), vec2(1.0));
	float red = texture(screen_texture, clamp(sample_uv + aberration, vec2(0.0), vec2(1.0))).r;
	float green = texture(screen_texture, sample_uv).g;
	float blue = texture(screen_texture, clamp(sample_uv - aberration, vec2(0.0), vec2(1.0))).b;
	vec3 image = vec3(red, green, blue);

	vec2 texel = SCREEN_PIXEL_SIZE * 1.5;
	vec3 glow = texture(screen_texture, clamp(sample_uv + vec2(texel.x, 0.0), vec2(0.0), vec2(1.0))).rgb;
	glow += texture(screen_texture, clamp(sample_uv - vec2(texel.x, 0.0), vec2(0.0), vec2(1.0))).rgb;
	glow += texture(screen_texture, clamp(sample_uv + vec2(0.0, texel.y), vec2(0.0), vec2(1.0))).rgb;
	glow += texture(screen_texture, clamp(sample_uv - vec2(0.0, texel.y), vec2(0.0), vec2(1.0))).rgb;
	glow *= 0.25;
	image += max(glow - image, vec3(0.0)) * bloom_strength * crt_enabled;

	float scanline = 1.0 - scanline_strength * (0.5 + 0.5 * cos(screen_uv.y / SCREEN_PIXEL_SIZE.y * 3.14159265));
	float grille_phase = mod(floor(screen_uv.x / SCREEN_PIXEL_SIZE.x), 3.0);
	vec3 grille = vec3(1.0 - grille_strength * 0.35);
	if (grille_phase < 1.0) {
		grille.r = 1.0;
	} else if (grille_phase < 2.0) {
		grille.g = 1.0;
	} else {
		grille.b = 1.0;
	}
	float radius = dot(screen_uv * 2.0 - 1.0, screen_uv * 2.0 - 1.0);
	float vignette = 1.0 - vignette_strength * smoothstep(0.15, 1.8, radius);
	vec3 crt_image = image * mix(vec3(1.0), grille * scanline * vignette, crt_enabled * strength);

	// Slightly smoked, graphite-colored CRT housing with molded bevels.
	float top_light = 1.0 - smoothstep(0.0, 1.0, outer_uv.y);
	float side_shade = smoothstep(0.0, 0.8, min(outer_uv.x, 1.0 - outer_uv.x));
	vec3 bezel = mix(vec3(0.018, 0.022, 0.028), vec3(0.105, 0.112, 0.12), top_light * 0.55 + 0.12);
	bezel += vec3(0.025, 0.028, 0.032) * side_shade;
	float inner_edge = min(min(abs(outer_uv.x - SCREEN_INSET), abs(outer_uv.x - (1.0 - SCREEN_INSET))), min(abs(outer_uv.y - SCREEN_INSET), abs(outer_uv.y - (1.0 - SCREEN_INSET))));
	float bevel_highlight = exp(-inner_edge * 520.0) * 0.24;
	float bevel_shadow = exp(-inner_edge * 170.0) * 0.16;
	bezel += vec3(bevel_highlight);
	bezel -= vec3(bevel_shadow);

	// A moving-looking soft reflection is reconstructed from the current game frame.
	vec2 reflection_uv = clamp(vec2(outer_uv.x, 1.0 - outer_uv.y), vec2(SCREEN_INSET), vec2(1.0 - SCREEN_INSET));
	reflection_uv = (reflection_uv - vec2(SCREEN_INSET)) / (1.0 - 2.0 * SCREEN_INSET);
	vec3 reflected_game = texture(screen_texture, clamp(reflection_uv, vec2(0.0), vec2(1.0))).rgb;
	float reflected_luma = dot(reflected_game, vec3(0.2126, 0.7152, 0.0722));
	float reflection_band = exp(-pow((outer_uv.x * 0.72 + outer_uv.y * 1.18 - 0.76) * 5.0, 2.0));
	float housing_reflection = reflection_band * (0.025 + reflected_luma * 0.10);
	bezel += reflected_game * housing_reflection;
	bezel += vec3(0.16, 0.19, 0.22) * exp(-pow((outer_uv.x + outer_uv.y * 0.42 - 0.16) * 24.0, 2.0)) * 0.10;

	// A restrained diagonal glass sheen; its tint follows the live game image.
	float glass_sheen = exp(-pow((screen_uv.x * 0.72 + screen_uv.y * 0.58 - 0.34) * 8.0, 2.0));
	float glass_mask = inside_screen ? rounded_screen_mask(screen_uv) : 0.0;
	vec3 glass_reflection = reflected_game * (glass_sheen * 0.055) + vec3(0.72, 0.82, 0.92) * (glass_sheen * 0.035);
	vec3 screen_color = crt_image + glass_reflection;

	vec3 final_color = mix(bezel, screen_color, glass_mask);
	COLOR = vec4(final_color, 1.0);
}
