class_name RPGCharacter
extends CharacterBody2D
## Simple top-down 8-direction controller. Replace the visual child with an AnimatedSprite2D.

@export var move_speed: float = 100.0
@export var input_enabled: bool = true

func _physics_process(_delta: float) -> void:
	if input_enabled:
		velocity = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") * move_speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()

func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled
	if not enabled:
		velocity = Vector2.ZERO
