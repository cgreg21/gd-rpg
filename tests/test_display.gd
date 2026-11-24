extends SceneTree

func _initialize() -> void:
	var width := int(ProjectSettings.get_setting("display/window/size/viewport_width"))
	var height := int(ProjectSettings.get_setting("display/window/size/viewport_height"))
	var window_width := int(ProjectSettings.get_setting("display/window/size/window_width_override"))
	var window_height := int(ProjectSettings.get_setting("display/window/size/window_height_override"))

	assert(width == 640, "Expected 640px internal width, got %d" % width)
	assert(height == 360, "Expected 360px internal height, got %d" % height)
	assert(window_width % width == 0, "Window width must use integer scaling")
	assert(window_height % height == 0, "Window height must use integer scaling")
	assert(window_width / width == window_height / height, "Horizontal and vertical scale must match")

	print("Display tests passed: %dx%d internal, %dx%d output, %dx integer scale." % [
		width, height, window_width, window_height, window_width / width
	])
	quit()
