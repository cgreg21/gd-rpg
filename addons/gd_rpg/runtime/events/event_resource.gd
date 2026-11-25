class_name RPGEvent
extends Resource
## A reusable, ordered list of event commands.

@export var event_id: StringName
@export var commands: Array[RPGEventCommand] = []

func is_valid() -> bool:
	if event_id.is_empty() or commands.is_empty():
		return false
	for command in commands:
		if command == null or not command.is_valid():
			return false
	return true
