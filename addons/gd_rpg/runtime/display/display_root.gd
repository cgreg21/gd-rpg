extends Control
class_name RPGDisplayRoot
## Renders game content at 640x360, scales it to the window, then applies CRT.

const INTERNAL_SIZE := Vector2i(640, 360)

@export var content_scene: PackedScene

var internal_viewport: SubViewport
var crt_overlay: RPGCRTOverlay

func _ready() -> void:
	_build_viewport()
	_build_crt_overlay()

func _build_viewport() -> void:
	internal_viewport = SubViewport.new()
	internal_viewport.name = "InternalViewport"
	internal_viewport.size = INTERNAL_SIZE
	internal_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	internal_viewport.handle_input_locally = false
	add_child(internal_viewport)

	if content_scene == null:
		push_error("RPGDisplayRoot requires a content_scene.")
		return

	internal_viewport.add_child(content_scene.instantiate())

	var game_texture := TextureRect.new()
	game_texture.name = "GameTexture"
	game_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_texture.texture = internal_viewport.get_texture()
	game_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	game_texture.stretch_mode = TextureRect.STRETCH_SCALE
	game_texture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	game_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(game_texture)

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
