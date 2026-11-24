extends SceneTree

func _initialize() -> void:
	var scene := load("res://examples/demo/demo.tscn") as PackedScene
	assert(scene != null, "Playable demo scene must exist")
	var demo := scene.instantiate()
	root.add_child(demo)
	await process_frame

	assert(demo.get("player") is RPGCharacter, "Demo must create a controllable RPGCharacter")
	assert(demo.get("hero_animation") is AnimatedSprite2D, "Hero must use an animated pixel-art sprite")
	assert(demo.get("npc") != null, "Demo must create its quest NPC")
	assert(demo.get("crystal") != null, "Demo must create its collectible")
	assert(demo.get("slime") != null, "Demo must create its encounter")
	assert(demo.get("dialogue_runner") is RPGDialogueRunner, "Demo must use the dialogue runner")

	var animation := demo.get("hero_animation") as AnimatedSprite2D
	for direction in ["front", "back", "left", "right"]:
		assert(animation.sprite_frames.has_animation(direction), "Missing hero direction: %s" % direction)
		assert(animation.sprite_frames.get_frame_count(direction) == 2, "Each direction must have two animation frames")

	print("Demo tests passed: animated hero, NPC, collectible and slime encounter.")
	demo.queue_free()
	quit()
