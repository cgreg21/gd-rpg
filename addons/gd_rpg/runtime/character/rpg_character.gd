class_name RPGCharacter
extends CharacterBody2D
## Simple top-down 8-direction controller. Replace the visual child with an AnimatedSprite2D.

@export var move_speed: float = 100.0
@export var input_enabled: bool = true

func _physics_process(_delta: float) -> void:
	if not input_enabled:
		velocity = Vector2.ZERO
	else:
		velocity = Input.get_vector("move_left", "move_right", "move_up", "move_down") * move_speed
	move_and_slide()

func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled
	if not enabled:
		velocity = Vector2.ZERO
