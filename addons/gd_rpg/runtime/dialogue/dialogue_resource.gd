class_name RPGDialogue
extends Resource
## A minimal data-driven dialogue sequence.

@export var dialogue_id: StringName
@export var lines: Array[String] = []

func is_valid() -> bool:
	return not dialogue_id.is_empty() and not lines.is_empty()
