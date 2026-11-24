@tool
class_name RPGPixelCamera
extends Camera2D
## Camera2D that rounds its world position to whole virtual pixels.

@export var pixel_snap: bool = true

func _process(_delta: float) -> void:
	if pixel_snap:
		global_position = global_position.round()
