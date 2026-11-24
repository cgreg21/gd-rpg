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
	var save_file := FileAccess.open("user://saves/slot_01.sav", FileAccess.READ)
	assert(save_file != null, "Map save must create the save file")
	assert(save_file.get_32() == 0x47525047, "Binary save must start with the GD RPG signature")
	assert(save_file.get_32() == 4, "Binary save must include its format version")
	var save_data: Variant = save_file.get_var(false)
	save_file.close()
	assert(save_data.map == "valbrume_route" and save_data.position == [123.0, 234.0], "Map save must record the active map and exact position")
	assert(save_data.transfer.gold == 25 and save_data.transfer.inventory.potion == 2, "Map save must retain the party and inventory snapshot")
	assert(router.get_save_metadata(1).map == "valbrume_route", "Save metadata must expose the saved map")
	assert(router.get_save_metadata(1).slot == 1, "Save metadata must identify its slot")
	assert(router.save_game(&"valbrume", "res://examples/demo/demo.tscn", Vector2(12, 34), 2), "A second slot must save independently")
	assert(router.get_save_metadata(2).map == "valbrume", "Second slot metadata must be independent")
	var invalid_save := FileAccess.open("user://saves/slot_03.sav", FileAccess.WRITE)
	invalid_save.store_32(0x47525047)
	invalid_save.store_32(4)
	invalid_save.store_var({"slot": 3, "saved_at": 1, "play_time": INF, "map": "valbrume", "scene": "res://examples/demo/demo.tscn", "position": [0.0, 0.0], "transfer": {}}, false)
	invalid_save.close()
	assert(router.get_save_metadata(3).is_empty(), "Save metadata must reject non-finite play time")
	assert(not router.load_game(&"valbrume", 3), "Loading must reject malformed save data")
	invalid_save = FileAccess.open("user://saves/slot_03.sav", FileAccess.WRITE)
	invalid_save.store_32(0x47525047)
	invalid_save.store_32(3)
	invalid_save.store_var({"slot": 3}, false)
	invalid_save.close()
	assert(router.get_save_metadata(3).is_empty(), "Outdated save versions must be ignored")
	assert(router.get_save_metadata(3).is_empty(), "An unused slot must have no metadata")
	assert(not router.save_game(&"valbrume", "res://examples/demo/demo.tscn", Vector2.ZERO, 4), "Unknown slots must be rejected")
	assert(not router.save_game(&"unknown_map", "res://missing.tscn", Vector2.ZERO), "Router must reject unknown map paths")
	assert(not router._is_valid_transfer({"hp": 99}), "Router must reject invalid party snapshots")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://saves/slot_01.sav"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://saves/slot_02.sav"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://saves/slot_03.sav"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://saves"))

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
