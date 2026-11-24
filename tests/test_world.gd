extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var map := RPGMap.new()
	map.map_id = &"test_map"

	var spawn_points := Node2D.new()
	spawn_points.name = "SpawnPoints"
	map.add_child(spawn_points)

	var default_spawn := Marker2D.new()
	default_spawn.name = "default"
	default_spawn.position = Vector2(32, 48)
	spawn_points.add_child(default_spawn)
	root.add_child(map)

	assert(map.has_spawn_point(&"default"))
	assert(map.get_spawn_position() == Vector2(32, 48))
	assert(map.get_spawn_position(&"missing") == Vector2(32, 48))

	var east_spawn := Marker2D.new()
	east_spawn.name = "east"
	east_spawn.position = Vector2(96, 48)
	spawn_points.add_child(east_spawn)
	map.set_entry_spawn(&"east")
	assert(map.get_spawn_position() == Vector2(96, 48), "Map must use the requested entry spawn")
	assert(map.get_spawn_position(&"default") == Vector2(32, 48), "Explicit spawn must override the requested entry")
	map.set_entry_spawn(&"missing")
	assert(map.get_spawn_position() == Vector2(32, 48), "Unknown entry spawn must fall back to default")

	var router := root.get_node("RPGMapRouter")
	router.pending_spawn_id = &"east"
	assert(router.take_spawn_id() == &"east", "Router must provide the pending spawn once")
	assert(router.take_spawn_id().is_empty(), "Router must clear a consumed spawn")
	router.set_transfer_data({"gold": 25, "inventory": {"potion": 2}})
	var transfer: Dictionary = router.get_transfer_data()
	assert(transfer.gold == 25 and transfer.inventory.potion == 2, "Router must preserve map transfer data")
	transfer.gold = 0
	assert(router.get_transfer_data().gold == 25, "Transfer data must be returned as a copy")
	router.set_transfer_data({"hp": 4, "mp": 1, "experience": 20, "gold": 25, "inventory": {"potion": 2}, "has_crystal": true, "chest_opened": true, "door_opened": false, "slime_defeated": false})
	assert(router.save_game(&"valbrume_route", "res://examples/demo/route.tscn", Vector2(123, 234)), "Router must save any supported map position")
	var save_file := FileAccess.open("user://valbrume_save.sav", FileAccess.READ)
	assert(save_file != null, "Map save must create the save file")
	assert(save_file.get_32() == 0x47525047, "Binary save must start with the GD RPG signature")
	assert(save_file.get_32() == 3, "Binary save must include its format version")
	var save_data: Variant = save_file.get_var(false)
	save_file.close()
	assert(save_data.map == "valbrume_route" and save_data.position == [123.0, 234.0], "Map save must record the active map and exact position")
	assert(save_data.transfer.gold == 25 and save_data.transfer.inventory.potion == 2, "Map save must retain the party and inventory snapshot")
	assert(not router.save_game(&"unknown_map", "res://missing.tscn", Vector2.ZERO), "Router must reject unknown map paths")
	assert(not router._is_valid_transfer({"hp": 99}), "Router must reject invalid party snapshots")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://valbrume_save.json"))

	var anchor := Node2D.new()
	anchor.position = Vector2(10.4, 8.7)
	root.add_child(anchor)
	var camera := RPGPixelCamera.new()
	anchor.add_child(camera)
	camera._process(0.0)
	assert(camera.offset.is_equal_approx(anchor.global_position.round() - anchor.global_position))
	anchor.position = Vector2(11.2, 9.1)
	camera._process(0.0)
	assert(camera.offset.is_equal_approx(anchor.global_position.round() - anchor.global_position))

	print("World and pixel camera tests passed.")
	quit()
