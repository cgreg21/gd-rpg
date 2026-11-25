class_name RPGEventCommand
extends Resource
## One small, editable instruction in an RPG event.

enum Type {
	SHOW_MESSAGE,
	WAIT,
	MOVE_CHARACTER,
	SET_SWITCH,
	TRANSFER_MAP
}

@export var type: Type = Type.SHOW_MESSAGE
@export_multiline var message: String = ""
@export_range(0.0, 60.0, 0.05) var duration: float = 0.5
@export var target_position: Vector2 = Vector2.ZERO
@export var switch_name: StringName
@export var switch_value: bool = true
@export_file("*.tscn") var scene_path: String
@export var spawn_id: StringName = &"default"

func is_valid() -> bool:
	match type:
		Type.SHOW_MESSAGE:
			return not message.strip_edges().is_empty()
		Type.WAIT:
			return is_finite(duration) and duration >= 0.0
		Type.MOVE_CHARACTER:
			return target_position.is_finite() and is_finite(duration) and duration > 0.0
		Type.SET_SWITCH:
			return not switch_name.is_empty()
		Type.TRANSFER_MAP:
			return not scene_path.is_empty()
	return false
