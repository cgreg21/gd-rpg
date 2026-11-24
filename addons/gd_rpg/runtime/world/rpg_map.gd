@tool
class_name RPGMap
extends Node2D
## Base node for a map. Add Marker2D children under a SpawnPoints node.

@export var map_id: StringName
@export var default_spawn: StringName = &"default"

func has_spawn_point(spawn_id: StringName) -> bool:
	return _get_spawn_marker(spawn_id) != null

func get_spawn_position(spawn_id: StringName = &"") -> Vector2:
	var requested_spawn := spawn_id if not spawn_id.is_empty() else default_spawn
	var marker := _get_spawn_marker(requested_spawn)
	if marker == null and requested_spawn != default_spawn:
		marker = _get_spawn_marker(default_spawn)
	if marker == null:
		push_warning("Map '%s' has no spawn point '%s' or default spawn." % [map_id, requested_spawn])
		return global_position
	return marker.global_position

func _get_spawn_marker(spawn_id: StringName) -> Marker2D:
	return get_node_or_null(NodePath("SpawnPoints/" + String(spawn_id))) as Marker2D
