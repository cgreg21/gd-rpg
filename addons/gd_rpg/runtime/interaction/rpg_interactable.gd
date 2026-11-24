@tool
class_name RPGInteractable
extends Area2D
## Add to an Area2D to expose a simple interaction signal.

signal interacted(actor: Node)

@export var interaction_name: String = "Interact"

func interact(actor: Node) -> void:
	interacted.emit(actor)
