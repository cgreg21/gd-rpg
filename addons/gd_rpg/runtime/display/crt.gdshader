shader_type canvas_item;

uniform float strength : hint_range(0.0, 1.0) = 0.65;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.18;
uniform float grille_strength : hint_range(0.0, 1.0) = 0.08;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.22;
uniform float curvature : hint_range(0.0, 0.15) = 0.025;

void fragment() {
	vec2 centered = UV * 2.0 - 1.0;
	vec2 curved = centered * (1.0 + dot(centered, centered) * curvature);
	vec2 uv = curved * 0.5 + 0.5;

	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, strength);
		return;
	}

	float scanline = 1.0 - scanline_strength * (0.5 + 0.5 * sin(UV.y * 180.0 * 3.14159265));
	float grille = 1.0 - grille_strength * (0.5 + 0.5 * cos(UV.x * 320.0 * 3.14159265));
	float vignette = 1.0 - vignette_strength * dot(centered, centered) * 0.5;
	float shade = clamp(scanline * grille * vignette, 0.0, 1.0);
	float alpha = strength * (1.0 - shade);
	COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
