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
