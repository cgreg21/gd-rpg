extends Node2D

var player: RPGCharacter
var dialogue_label: Label
var dialogue_runner: RPGDialogueRunner

func _ready() -> void:
	_build_demo()
	_start_intro()

func _build_demo() -> void:
	var background := ColorRect.new()
	background.color = Color("#263b35")
	background.size = Vector2(320, 180)
	background.z_index = -10
	add_child(background)

	for x in range(0, 320, 16):
		for y in range(0, 180, 16):
			var tile := ColorRect.new()
			tile.position = Vector2(x + 1, y + 1)
			tile.size = Vector2(14, 14)
			tile.color = Color("#304b3d") if (x / 16 + y / 16) % 2 == 0 else Color("#2b4438")
			add_child(tile)

	player = RPGCharacter.new()
	player.move_speed = 50.0
	player.position = Vector2(160, 102)
	add_child(player)

	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([Vector2(0, -6), Vector2(5, -2), Vector2(4, 6), Vector2(-4, 6), Vector2(-5, -2)])
	visual.color = Color("#f2c078")
	player.add_child(visual)

	var npc := Polygon2D.new()
	npc.polygon = visual.polygon
	npc.color = Color("#8eb8e8")
	npc.position = Vector2(0, -32)
	player.add_child(npc)

	var ui := CanvasLayer.new()
	add_child(ui)
	var info_label := Label.new()
	info_label.position = Vector2(6, 4)
	info_label.text = "GD RPG  |  Arrows: move  |  E: talk"
	ui.add_child(info_label)
	dialogue_label = Label.new()
	dialogue_label.position = Vector2(6, 148)
	dialogue_label.size = Vector2(308, 28)
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.add_theme_font_size_override("font_size", 8)
	dialogue_label.add_theme_color_override("font_color", Color.WHITE)
	ui.add_child(dialogue_label)

	dialogue_runner = RPGDialogueRunner.new()
	add_child(dialogue_runner)
	dialogue_runner.line_started.connect(func(text: String, _index: int) -> void: dialogue_label.text = text)
	dialogue_runner.dialogue_finished.connect(func() -> void: dialogue_label.text = "Explore. Press E near the traveller to speak.")

func _start_intro() -> void:
	var intro := RPGDialogue.new()
	intro.dialogue_id = &"intro"
	intro.lines = ["Welcome, traveller. This small world is powered by GD RPG Engine.", "Move with the arrow keys. Press E near the traveller to speak."]
	dialogue_runner.start(intro)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and player != null and player.position.distance_to(Vector2(160, 70)) < 50.0:
		var dialogue := RPGDialogue.new()
		dialogue.dialogue_id = &"traveller"
		dialogue.lines = ["The road ahead leads to a forgotten kingdom.", "The ATB battle system is the next step in our journey."]
		dialogue_runner.start(dialogue)
	elif event.is_action_pressed("ui_accept") and dialogue_runner.is_running:
		dialogue_runner.advance()
