extends Node2D

const PLAYER_SCENE_SCRIPT = preload("res://addons/gd_rpg/runtime/character/rpg_character.gd")

var player: RPGCharacter
var info_label: Label
var dialogue_label: Label
var dialogue_runner: RPGDialogueRunner

func _ready() -> void:
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
			tile.position = Vector2(x + 1, y + 1)
			tile.size = Vector2(30, 30)
			tile.color = Color("#304b3d") if (x / 32 + y / 32) % 2 == 0 else Color("#2b4438")
			add_child(tile)

	player = RPGCharacter.new()
	player.position = Vector2(320, 205)
	add_child(player)
	player.add_to_group("player")
	player.set_script(PLAYER_SCENE_SCRIPT)

	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([Vector2(0, -12), Vector2(9, -3), Vector2(7, 11), Vector2(-7, 11), Vector2(-9, -3)])
	visual.color = Color("#f2c078")
	player.add_child(visual)

	var npc := Polygon2D.new()
	npc.polygon = PackedVector2Array([Vector2(0, -12), Vector2(9, -3), Vector2(7, 11), Vector2(-7, 11), Vector2(-9, -3)])
	npc.color = Color("#8eb8e8")
	npc.position = Vector2(0, -65)
	player.add_child(npc)

	var ui := CanvasLayer.new()
	add_child(ui)
	info_label = Label.new()
	info_label.position = Vector2(12, 10)
	info_label.text = "GD RPG Engine  |  WASD / arrows: move  |  E: talk"
	ui.add_child(info_label)
	dialogue_label = Label.new()
	dialogue_label.position = Vector2(12, 305)
	dialogue_label.size = Vector2(616, 44)
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.add_theme_color_override("font_color", Color.WHITE)
	dialogue_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	dialogue_label.add_theme_constant_override("shadow_offset_x", 2)
	dialogue_label.add_theme_constant_override("shadow_offset_y", 2)
	ui.add_child(dialogue_label)

	dialogue_runner = RPGDialogueRunner.new()
	add_child(dialogue_runner)
	dialogue_runner.line_started.connect(func(text: String, _index: int) -> void: dialogue_label.text = text)
	dialogue_runner.dialogue_finished.connect(func() -> void: dialogue_label.text = "Explore the map. Press E near the traveller to speak.")

func _start_intro() -> void:
	var intro := RPGDialogue.new()
	intro.dialogue_id = &"intro"
	intro.lines = ["Welcome, traveller. This small world is powered by GD RPG Engine.", "Move with WASD or the arrow keys. Press E to speak again."]
	dialogue_runner.start(intro)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and player != null and player.position.distance_to(Vector2(320, 140)) < 100.0:
		var dialogue := RPGDialogue.new()
		dialogue.dialogue_id = &"traveller"
		dialogue.lines = ["The road ahead leads to a forgotten kingdom.", "The ATB battle system is the next step in our journey."]
		dialogue_runner.start(dialogue)
	elif event.is_action_pressed("ui_accept") and dialogue_runner.is_running:
		dialogue_runner.advance()
