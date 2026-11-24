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

	demo._start_battle()
	assert(demo.get("battle_active"), "Starting an encounter must open the battle menu")
	demo._battle_action("skill")
	assert(demo.get("slime_hp") == 1, "The skill must deal two damage")
	assert(demo.get("player_mp") == 1, "The skill must consume two MP")
	assert(demo.get("player_hp") == 4, "The enemy must counter after the skill")
	demo._battle_action("item")
	assert(demo.get("potion_count") == 0, "Using an item must consume one potion")
	assert(demo.get("player_hp") == 4, "The potion must heal before the enemy counter")
	demo._battle_action("defend")
	assert(demo.get("player_hp") == 4, "Defend must block the enemy counter")
	demo._battle_action("attack")
	assert(demo.get("slime_defeated"), "Defeating the slime must end the encounter")
	assert(not demo.get("battle_active"), "Victory must return to exploration")

	print("Demo tests passed: animated hero, quest, battle commands, skills, items and defense.")
	demo.queue_free()
	quit()
