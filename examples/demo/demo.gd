extends RPGMap

var player: RPGCharacter
var dialogue_label: Label
var dialogue_runner: RPGDialogueRunner
var crt_overlay: RPGCRTOverlay

func _ready() -> void:
	map_id = &"demo"
	_build_demo()
	_start_intro()

func _build_demo() -> void:
	var background := ColorRect.new()
	background.color = Color("#263b35")
	background.size = Vector2(640, 360)
	background.z_index = -10
	add_child(background)

	for x in range(0, 640, 32):
		for y in range(0, 360, 32):
			var tile := ColorRect.new()
			tile.position = Vector2(x + 2, y + 2)
			tile.size = Vector2(28, 28)
			tile.color = Color("#304b3d") if (x / 32 + y / 32) % 2 == 0 else Color("#2b4438")
			add_child(tile)

	var spawn_points := Node2D.new()
	spawn_points.name = "SpawnPoints"
	add_child(spawn_points)
	var default_spawn := Marker2D.new()
	default_spawn.name = "default"
	default_spawn.position = Vector2(320, 204)
	spawn_points.add_child(default_spawn)

	player = RPGCharacter.new()
	player.move_speed = 100.0
	player.position = get_spawn_position()
	add_child(player)

	var camera := RPGPixelCamera.new()
	camera.position_smoothing_enabled = false
	player.add_child(camera)

	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([Vector2(0, -12), Vector2(10, -4), Vector2(8, 12), Vector2(-8, 12), Vector2(-10, -4)])
	visual.color = Color("#f2c078")
	player.add_child(visual)

	var npc := Polygon2D.new()
	npc.polygon = visual.polygon
	npc.color = Color("#8eb8e8")
	npc.position = Vector2(320, 140)
	add_child(npc)

	var ui := CanvasLayer.new()
	add_child(ui)
	var info_label := Label.new()
	info_label.position = Vector2(12, 8)
	info_label.text = "GD RPG  |  Arrows: move  |  E: talk  |  F3: CRT"
	info_label.add_theme_font_size_override("font_size", 16)
	ui.add_child(info_label)
	dialogue_label = Label.new()
	dialogue_label.position = Vector2(12, 296)
	dialogue_label.size = Vector2(616, 56)
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.add_theme_font_size_override("font_size", 16)
	dialogue_label.add_theme_color_override("font_color", Color.WHITE)
	ui.add_child(dialogue_label)

	dialogue_runner = RPGDialogueRunner.new()
	add_child(dialogue_runner)
	dialogue_runner.line_started.connect(func(text: String, _index: int) -> void: dialogue_label.text = text)
	dialogue_runner.dialogue_finished.connect(func() -> void: dialogue_label.text = "Explore. E: talk  |  F3: CRT")

	var crt_layer := CanvasLayer.new()
	crt_layer.layer = 10
	add_child(crt_layer)
	crt_overlay = RPGCRTOverlay.new()
	var shader_material := ShaderMaterial.new()
	shader_material.shader = preload("res://addons/gd_rpg/runtime/display/crt.gdshader")
	crt_overlay.material = shader_material
	crt_overlay.enabled = OS.get_environment("GD_RPG_SCREENSHOT_CRT") == "1"
	crt_layer.add_child(crt_overlay)

func _start_intro() -> void:
	var intro := RPGDialogue.new()
	intro.dialogue_id = &"intro"
	intro.lines = ["Welcome, traveller. This small world is powered by GD RPG Engine.", "Move with the arrow keys. Press E near the traveller to speak."]
	dialogue_runner.start(intro)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		crt_overlay.enabled = not crt_overlay.enabled
	if event.is_action_pressed("interact") and player != null and player.position.distance_to(Vector2(320, 140)) < 100.0:
		var dialogue := RPGDialogue.new()
		dialogue.dialogue_id = &"traveller"
		dialogue.lines = ["The road ahead leads to a forgotten kingdom.", "The ATB battle system is the next step in our journey."]
		dialogue_runner.start(dialogue)
	elif event.is_action_pressed("ui_accept") and dialogue_runner.is_running:
		dialogue_runner.advance()
