class_name RPGItemData
extends Resource
## Data definition for a stackable RPG item.

@export var item_id: StringName
@export var display_name: String = "Item"
@export_multiline var description: String
@export_range(1, 999) var max_stack: int = 99
@export_range(0, 999) var hp_restore: int = 0

func is_valid() -> bool:
	return not item_id.is_empty() and max_stack > 0 and hp_restore >= 0
