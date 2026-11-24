class_name RPGActorData
extends Resource
## Data shared by playable characters and enemies.

@export var actor_id: StringName
@export var display_name: String = "Actor"
@export var max_hp: int = 100
@export var max_mp: int = 20
@export var attack: int = 10
@export var defense: int = 5
@export var speed: float = 1.0
@export var portrait: Texture2D
@export var battle_sprite: Texture2D

func is_valid() -> bool:
	return not actor_id.is_empty() and max_hp > 0 and max_mp >= 0
