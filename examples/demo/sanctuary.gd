extends RPGMap
## Compact interior map unlocked by the Valbrume sanctuary key.

const HERO_SHEET: Texture2D = preload("res://examples/demo/assets/hero.svg")
const EXIT_POSITION := Vector2(320, 305)

var player: RPGCharacter
var prompt: Label

func _ready() -> void:
	map_id = &"valbrume_sanctuary"
	set_entry_spawn(RPGMapRouter.take_spawn_id())
	_build_world()
	_build_player()
	_build_ui()
	var saved_position := RPGMapRouter.take_loaded_position(map_id)
	if saved_position != Vector2.INF:
		player.position = saved_position

func _unhandled_input(event: InputEvent) -> void:
	if player == null:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_F5, KEY_F6, KEY_F7]:
			_store_map_save(event.keycode - KEY_F4)
			return
		if event.keycode in [KEY_F9, KEY_F10, KEY_F11]:
			_load_map_save(event.keycode - KEY_F8)
			return
	if not event.is_action_pressed("interact"):
		return
	if player.global_position.distance_to(EXIT_POSITION) < 48.0:
		player.set_input_enabled(false)
		RPGMapRouter.transition_to("res://examples/demo/demo.tscn", &"sanctuary_return")

func _store_map_save(slot: int = 1) -> void:
	var saved := RPGMapRouter.save_game(map_id, "res://examples/demo/sanctuary.tscn", player.position, slot)
	prompt.text = "Emplacement %d sauvegardé" % slot if saved else "Échec de sauvegarde"

func _load_map_save(slot: int = 1) -> void:
	if not RPGMapRouter.load_game(map_id, slot):
		prompt.text = "Sauvegarde absente ou invalide"
		return
	var saved_position := RPGMapRouter.take_loaded_position(map_id)
	if saved_position != Vector2.INF:
		player.position = saved_position
	prompt.text = "Emplacement %d chargé" % slot

func _process(_delta: float) -> void:
	if player != null:
		prompt.visible = player.global_position.distance_to(EXIT_POSITION) < 58.0

func _build_world() -> void:
	var points := Node2D.new()
	points.name = "SpawnPoints"
	add_child(points)
	for spawn_data in [["default", Vector2(320, 245)], ["village_entry", Vector2(320, 245)]]:
		var marker := Marker2D.new()
		marker.name = spawn_data[0]
		marker.position = spawn_data[1]
		points.add_child(marker)
	_draw_rect(Vector2.ZERO, Vector2(640, 360), "#252b42", -10)
	_draw_rect(Vector2(32, 24), Vector2(576, 312), "#77654e", -5)
	_draw_rect(Vector2(48, 40), Vector2(544, 280), "#b9a27a", -4)
	_draw_rect(Vector2(48, 40), Vector2(544, 12), "#594936", -3)
	_draw_rect(Vector2(48, 308), Vector2(544, 12), "#594936", -3)
	for x in range(80, 600, 64):
		_draw_rect(Vector2(x, 70), Vector2(4, 200), "#a18b68", -2)
	_draw_rect(Vector2(292, 48), Vector2(56, 18), "#e6c77f", -1)
	_draw_rect(Vector2(308, 66), Vector2(24, 5), "#fff0bd", 0)
	_draw_rect(EXIT_POSITION - Vector2(30, 12), Vector2(60, 22), "#5c4030", -1)

func _build_player() -> void:
	player = RPGCharacter.new()
	player.name = "Hero"
	player.move_speed = 112.0
	player.position = get_spawn_position()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(15, 12)
	collision.shape = shape
	collision.position = Vector2(0, 15)
	player.add_child(collision)
	add_child(player)
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for direction in ["front", "back", "left", "right"]:
		frames.add_animation(direction)
		frames.set_animation_speed(direction, 7.0)
		frames.set_animation_loop(direction, true)
	var indexes := {"front": [0, 1], "back": [2, 3], "left": [4, 5], "right": [6, 7]}
	for direction in indexes:
		for frame_index in indexes[direction]:
			var atlas := AtlasTexture.new()
			atlas.atlas = HERO_SHEET
			atlas.region = Rect2(frame_index * 32, 0, 32, 48)
			frames.add_frame(direction, atlas)
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.animation = "front"
	sprite.position = Vector2(0, -12)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	player.add_child(sprite)
	var camera := RPGPixelCamera.new()
	camera.position_smoothing_enabled = false
	player.add_child(camera)

func _build_ui() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)
	var title := Label.new()
	title.position = Vector2(14, 12)
	title.text = "SANCTUAIRE ANCIEN"
	title.add_theme_color_override("font_color", Color("#fff0c8"))
	title.add_theme_font_size_override("font_size", 15)
	ui.add_child(title)
	prompt = Label.new()
	prompt.position = Vector2(360, 320)
	prompt.text = "E : Retourner à Valbrume"
	prompt.add_theme_color_override("font_color", Color("#fff0c8"))
	prompt.add_theme_font_size_override("font_size", 13)
	prompt.visible = false
	ui.add_child(prompt)

func _draw_rect(position: Vector2, size: Vector2, color: String, z: int) -> void:
	var rect := ColorRect.new()
	rect.position = position
	rect.size = size
	rect.color = Color(color)
	rect.z_index = z
	add_child(rect)
