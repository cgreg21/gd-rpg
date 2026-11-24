extends SceneTree

func _initialize() -> void:
	var test_finished := false
	create_timer(30.0).timeout.connect(func() -> void:
		if not test_finished:
			push_error("Playable demo tests timed out.")
			quit(1)
	)
	var scene := load("res://examples/demo/demo.tscn") as PackedScene
	assert(scene != null, "Playable demo scene must exist")
	var demo := scene.instantiate()
	root.add_child(demo)
	await process_frame

	assert(demo.get("player") is RPGCharacter, "Demo must create a controllable RPGCharacter")
	assert(demo.get("hero_animation") is AnimatedSprite2D, "Hero must use an animated pixel-art sprite")
	assert(demo.get("npc") != null, "Demo must create its quest NPC")
	assert(demo.get("crystal") != null, "Demo must create its collectible")
	assert(demo.get("chest") != null, "Demo must create its treasure chest")
	assert(demo.get("door") != null, "Demo must create its locked sanctuary door")
	assert(demo.get("slime") != null, "Demo must create its encounter")
	assert(demo.get("dialogue_runner") is RPGDialogueRunner, "Demo must use the dialogue runner")
	assert(demo.get("inventory") is RPGInventory, "Demo must use the reusable inventory")
	assert(demo.get("inventory").count(&"potion") == 1, "Demo must start with one potion")
	assert(demo.get("inventory").count(&"old_key") == 0, "Quest key must start outside the inventory")
	demo._open_door()
	assert(not demo.get("door_opened") and demo.get("gold") == 0, "Locked door must reject an absent key")
	assert(demo.get("inventory_panel") is PanelContainer, "Demo must create an inventory panel")
	assert(not demo.get("inventory_panel").visible, "Inventory menu must start closed")
	demo._toggle_inventory()
	assert(demo.get("inventory_panel").visible, "Inventory menu must open")
	assert(not demo.get("player").input_enabled, "Opening inventory must pause player movement")
	assert(demo.get("inventory_label").text.contains("Potion") and demo.get("inventory_label").text.contains("x1"), "Inventory menu must display item name and quantity")
	demo._toggle_inventory()
	assert(not demo.get("inventory_panel").visible, "Inventory menu must close")
	assert(demo.get("player").input_enabled, "Closing inventory must restore player movement")

	demo._open_chest()
	assert(demo.get("chest_opened"), "Chest must open")
	assert(demo.get("gold") == 10, "Chest must award ten gold")
	assert(demo.get("inventory").count(&"old_key") == 1, "Chest must add one quest key")
	assert(demo.get("chest").is_queued_for_deletion(), "Opened chest must be removed")
	demo._open_chest()
	assert(demo.get("gold") == 10 and demo.get("inventory").count(&"old_key") == 1, "Chest rewards must only be granted once")
	demo._toggle_inventory()
	assert(demo.get("inventory_label").text.contains("Vieille clé"), "Inventory menu must list quest items")
	demo._toggle_inventory()
	demo._open_door()
	assert(demo.get("door_opened"), "Old key must unlock the sanctuary door")
	assert(demo.get("inventory").count(&"old_key") == 0, "Unlocking must consume the old key")
	assert(demo.get("gold") == 30, "Sanctuary must award twenty gold")
	assert(demo.get("door").is_queued_for_deletion(), "Unlocked door must be removed")
	demo._open_door()
	assert(demo.get("gold") == 30, "Sanctuary reward must only be granted once")
	demo._toggle_inventory()
	assert(not demo.get("inventory_label").text.contains("Vieille clé"), "Consumed quest key must disappear from inventory")
	demo._toggle_inventory()

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
	assert(demo.get("inventory").count(&"potion") == 0, "Using an item must consume one potion")
	assert(demo.get("player_hp") == 4, "The potion must heal before the enemy counter")
	demo._battle_action("defend")
	assert(demo.get("player_hp") == 4, "Defend must block the enemy counter")
	demo._battle_action("attack")
	assert(demo.get("slime_defeated"), "Defeating the slime must end the encounter")
	assert(not demo.get("battle_active"), "Victory must return to exploration")
	assert(demo.get("experience") == 20, "Victory must award 20 experience")
	assert(demo.get("gold") == 45, "Chest, sanctuary and victory must award 45 gold total")
	demo._end_battle(true)
	assert(demo.get("experience") == 20 and demo.get("gold") == 45, "Victory rewards must only be granted once")
	demo._talk_to_npc()
	assert(demo.get("dialogue_runner").is_running, "NPC conclusion must start a dialogue")
	assert(demo.get("dialogue_label").text.contains("vaincu"), "NPC conclusion must acknowledge the victory")


	# Complete the crystal objective before checking save restoration.
	demo._collect_crystal()
	# Save and restore the complete Valbrume quest state.
	var saved_position: Vector2 = demo.get("player").position
	assert(demo._save_game(), "Demo progress must save")
	demo.set("gold", 0)
	demo.set("experience", 0)
	demo.set("has_crystal", false)
	demo.set("chest_opened", false)
	demo.set("door_opened", false)
	demo.set("slime_defeated", false)
	demo.get("player").position = Vector2.ZERO
	demo.get("inventory").add_item(&"potion", 1)
	assert(demo._load_game(), "A valid save must load")
	assert(demo.get("player").position == saved_position, "Loading must restore player position")
	assert(demo.get("gold") == 45 and demo.get("experience") == 20, "Loading must restore currency and experience")
	assert(demo.get("has_crystal") and demo.get("chest_opened") and demo.get("door_opened") and demo.get("slime_defeated"), "Loading must restore quest flags")
	assert(demo.get("inventory").count(&"potion") == 0 and demo.get("inventory").count(&"old_key") == 0, "Loading must restore inventory quantities")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://valbrume_save.json"))

	test_finished = true
	print("Demo tests passed: animated hero, quest, locked door, treasure, inventory and battle commands.")
	demo.queue_free()
	quit()
