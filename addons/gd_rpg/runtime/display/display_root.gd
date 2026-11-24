extends Control
class_name RPGDisplayRoot
## Renders game content at 640x360, then applies CRT at the native window resolution.

const INTERNAL_SIZE := Vector2i(640, 360)

@export var content_scene: PackedScene

var crt_overlay: RPGCRTOverlay

func _ready() -> void:
	_build_viewport()
	_build_crt_overlay()

func _build_viewport() -> void:
	var container := SubViewportContainer.new()
	container.name = "GameViewport"
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.stretch = true
	container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(container)

	var viewport := SubViewport.new()
	viewport.name = "InternalViewport"
	viewport.size = INTERNAL_SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.handle_input_locally = false
	container.add_child(viewport)

	if content_scene == null:
		push_error("RPGDisplayRoot requires a content_scene.")
		return

	var content := content_scene.instantiate()
	viewport.add_child(content)

func _build_crt_overlay() -> void:
	crt_overlay = RPGCRTOverlay.new()
	crt_overlay.name = "CRTOverlay"
	var shader_material := ShaderMaterial.new()
	shader_material.shader = preload("res://addons/gd_rpg/runtime/display/crt.gdshader")
	crt_overlay.material = shader_material
	crt_overlay.enabled = OS.get_environment("GD_RPG_SCREENSHOT_CRT") == "1"
	add_child(crt_overlay)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		crt_overlay.enabled = not crt_overlay.enabled
