@tool
class_name RPGPixelCamera
extends Camera2D
## Offsets the camera by the fractional remainder of its world position.

@export var pixel_snap: bool = true

func _process(_delta: float) -> void:
	if pixel_snap:
		offset = global_position.round() - global_position
	else:
		offset = Vector2.ZERO
