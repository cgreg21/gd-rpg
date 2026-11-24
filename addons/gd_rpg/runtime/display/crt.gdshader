shader_type canvas_item;

// Full-screen CRT pass applied after the 640x360 image is enlarged to 1080p.
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform float crt_enabled : hint_range(0.0, 1.0) = 0.0;
uniform float strength : hint_range(0.0, 1.0) = 1.0;
uniform float curvature : hint_range(0.0, 0.20) = 0.085;
uniform float curvature_vertical : hint_range(0.0, 0.20) = 0.075;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.48;
uniform float grille_strength : hint_range(0.0, 1.0) = 0.10;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.28;
uniform float chromatic_aberration : hint_range(0.0, 0.02) = 0.0015;
uniform float bloom_strength : hint_range(0.0, 1.0) = 0.08;

vec2 curve_uv(vec2 uv) {
	vec2 p = uv * 2.0 - 1.0;
	float r2 = dot(p, p);
	p.x *= 1.0 + curvature * r2;
	p.y *= 1.0 + curvature_vertical * r2;
	return p * 0.5 + 0.5;
}

void fragment() {
	vec2 screen_uv = SCREEN_UV;
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

	// One dark 3-pixel output band between each pair of source pixel rows.
	// This matches the 640x360 -> 1920x1080 integer upscale exactly.
	float source_row = floor(screen_uv.y * 360.0);
	float scanline_phase = mod(source_row, 2.0);
	float scanline = mix(1.0 - scanline_strength, 1.0, scanline_phase);
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
	COLOR = vec4(crt_image, 1.0);
}
