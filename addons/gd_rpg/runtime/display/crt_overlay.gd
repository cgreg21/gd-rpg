extends ColorRect
class_name RPGCRTOverlay
## Optional final-pass CRT overlay. Keep the ColorRect above the game UI only when desired.

@export_range(0.0, 1.0, 0.01) var effect_strength: float = 0.65:
	set(value):
		effect_strength = clampf(value, 0.0, 1.0)
		_update_material()

@export var enabled: bool = false:
	set(value):
		enabled = value
		visible = value
		_update_material()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_update_material()

func set_preset(preset: StringName) -> void:
	match preset:
		&"clean":
			effect_strength = 0.0
			enabled = false
		&"crt":
			effect_strength = 0.45
			enabled = true
		&"crt_strong":
			effect_strength = 0.8
			enabled = true
		_:
			push_warning("Unknown CRT preset: %s" % preset)

func _update_material() -> void:
	var shader_material := material as ShaderMaterial
	if shader_material != null:
		shader_material.set_shader_parameter("strength", effect_strength)
