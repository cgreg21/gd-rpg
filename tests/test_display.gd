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
	assert(RPGDisplayRoot.INTERNAL_SIZE == Vector2i(640, 360), "Internal game viewport must stay at 640x360")

	print("Display tests passed: 640x360 game viewport, 1920x1080 final shader output.")
	quit()
