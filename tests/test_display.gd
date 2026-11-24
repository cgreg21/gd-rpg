extends SceneTree

func _initialize() -> void:
	var width := int(ProjectSettings.get_setting("display/window/size/viewport_width"))
	var height := int(ProjectSettings.get_setting("display/window/size/viewport_height"))
	var window_width := int(ProjectSettings.get_setting("display/window/size/window_width_override"))
	var window_height := int(ProjectSettings.get_setting("display/window/size/window_height_override"))

	assert(width == 1920, "Expected native output width 1920, got %d" % width)
	assert(height == 1080, "Expected native output height 1080, got %d" % height)
	assert(window_width == width, "Window width must match the native output viewport")
	assert(window_height == height, "Window height must match the native output viewport")

	var display_scene := load("res://examples/demo/display.tscn") as PackedScene
	assert(display_scene != null, "Demo must use the native-resolution display root")
	var display := display_scene.instantiate() as RPGDisplayRoot
	assert(display != null, "Display scene must instantiate RPGDisplayRoot")
	assert(display.content_scene != null, "Display root must have a content scene")
	assert(RPGDisplayRoot.INTERNAL_SIZE == Vector2i(640,  360), "Internal game viewport must stay at 640x360")

	root.add_child(display)
	await process_frame
	assert(display.internal_viewport != null, "Display root must create its internal viewport")
	assert(display.internal_viewport.size == Vector2i(640, 360), "Internal viewport must not be resized to the window")
	var game_texture := display.get_node("GameTexture") as TextureRect
	assert(game_texture != null, "Internal viewport texture must be displayed by a TextureRect")
	assert(game_texture.texture == display.internal_viewport.get_texture(), "TextureRect must display the internal viewport")
	assert(game_texture.stretch_mode == TextureRect.STRETCH_SCALE, "Game texture must scale to the output viewport")
	assert(game_texture.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Game texture must use nearest filtering")

	print("Display tests passed: fixed 640x360 render scaled to 1920x1080.")
	quit()
