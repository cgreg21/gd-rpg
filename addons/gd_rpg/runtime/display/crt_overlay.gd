extends ColorRect
class_name RPGCRTOverlay
## Final CRT glass and housing pass. The bezel is always visible; F3 toggles phosphor effects.

@export_range(0.0, 1.0, 0.01) var effect_strength: float = 1.0:
	set(value):
		effect_strength = clampf(value, 0.0, 1.0)
		_update_material()

@export_range(0.0, 0.20, 0.001) var curvature: float = 0.085:
	set(value):
		curvature = clampf(value, 0.0, 0.20)
		_update_material()

@export_range(0.0, 0.20, 0.001) var curvature_vertical: float = 0.075:
	set(value):
		curvature_vertical = clampf(value, 0.0, 0.20)
		_update_material()

@export_range(0.0, 1.0, 0.01) var scanline_strength: float = 0.48:
	set(value):
		scanline_strength = clampf(value, 0.0, 1.0)
		_update_material()

@export_range(0.0, 1.0, 0.01) var grille_strength: float = 0.10:
	set(value):
		grille_strength = clampf(value, 0.0, 1.0)
		_update_material()

@export_range(0.0, 1.0, 0.01) var vignette_strength: float = 0.28:
	set(value):
		vignette_strength = clampf(value, 0.0, 1.0)
		_update_material()

@export_range(0.0, 0.02, 0.0001) var chromatic_aberration: float = 0.0015:
	set(value):
		chromatic_aberration = clampf(value, 0.0, 0.02)
		_update_material()

@export_range(0.0, 1.0, 0.01) var bloom_strength: float = 0.08:
	set(value):
		bloom_strength = clampf(value, 0.0, 1.0)
		_update_material()

@export_range(0.0, 1.0, 0.01) var corner_roundness: float = 0.35:
	set(value):
		corner_roundness = clampf(value, 0.0, 1.0)
		_update_material()

@export var enabled: bool = false:
	set(value):
		enabled = value
		_update_material()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = true
	_update_material()

func set_preset(preset: StringName) -> void:
	match preset:
		&"clean":
			enabled = false
		&"crt":
			_apply_preset(0.075, 0.065, 0.42, 0.08, 0.22, 0.001, 0.04, 0.25)
		&"crt_strong":
			_apply_preset(0.12, 0.10, 0.58, 0.14, 0.36, 0.0025, 0.12, 0.45)
		_:
			push_warning("Unknown CRT preset: %s" % preset)

func _apply_preset(
	new_curvature: float,
	new_vertical_curvature: float,
	new_scanlines: float,
	new_grille: float,
	new_vignette: float,
	new_aberration: float,
	new_bloom: float,
	new_corners: float
) -> void:
	curvature = new_curvature
	curvature_vertical = new_vertical_curvature
	scanline_strength = new_scanlines
	grille_strength = new_grille
	vignette_strength = new_vignette
	chromatic_aberration = new_aberration
	bloom_strength = new_bloom
	corner_roundness = new_corners
	enabled = true
	_update_material()

func _update_material() -> void:
	var shader_material := material as ShaderMaterial
	if shader_material == null:
		return
	shader_material.set_shader_parameter("crt_enabled", 1.0 if enabled else 0.0)
	shader_material.set_shader_parameter("strength", effect_strength)
	shader_material.set_shader_parameter("curvature", curvature)
	shader_material.set_shader_parameter("curvature_vertical", curvature_vertical)
	shader_material.set_shader_parameter("scanline_strength", scanline_strength)
	shader_material.set_shader_parameter("grille_strength", grille_strength)
	shader_material.set_shader_parameter("vignette_strength", vignette_strength)
	shader_material.set_shader_parameter("chromatic_aberration", chromatic_aberration)
	shader_material.set_shader_parameter("bloom_strength", bloom_strength)
	shader_material.set_shader_parameter("corner_roundness", corner_roundness)
