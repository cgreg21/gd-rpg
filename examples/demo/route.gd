extends RPGMap
## Small connected forest route used to verify map transfers.

const HERO_SHEET: Texture2D = preload("res://examples/demo/assets/hero.svg")
const PORTAL_POSITION := Vector2(560, 180)

var player: RPGCharacter
var return_portal: Node2D
var prompt: Label

func _ready() -> void:
	map_id = &"valbrume_route"
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
	if player.global_position.distance_to(PORTAL_POSITION) < 42.0:
		player.set_input_enabled(false)
		RPGMapRouter.transition_to("res://examples/demo/demo.tscn", &"village_return")

func _store_map_save(slot: int = 1) -> void:
	var saved := RPGMapRouter.save_game(map_id, "res://examples/demo/route.tscn", player.position, slot)
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
	if player == null:
		return
	var near_portal := player.global_position.distance_to(PORTAL_POSITION) < 58.0
	prompt.visible = near_portal

func _build_world() -> void:
	var points := Node2D.new()
	points.name = "SpawnPoints"
	add_child(points)
	for spawn_data in [
		["default", Vector2(90, 180)],
		["village_gate", Vector2(90, 180)]
	]:
		var marker := Marker2D.new()
		marker.name = spawn_data[0]
		marker.position = spawn_data[1]
		points.add_child(marker)

	var ground := ColorRect.new()
	ground.size = Vector2(640, 360)
	ground.color = Color("#315d43")
	ground.z_index = -10
	add_child(ground)
	for x in range(0, 640, 32):
		for y in range(0, 360, 32):
			var tile := ColorRect.new()
			tile.position = Vector2(x + 1, y + 1)
			tile.size = Vector2(30, 30)
			tile.color = Color("#3d704b") if (x / 32 + y / 32) % 2 == 0 else Color("#376647")
			tile.z_index = -9
			add_child(tile)

	_draw_rect(Vector2(0, 145), Vector2(640, 70), "#987c55", -5)
	for tree_position in [Vector2(170, 95), Vector2(250, 275), Vector2(365, 85), Vector2(455, 275), Vector2(585, 90)]:
		_draw_tree(tree_position)
	return_portal = Node2D.new()
	return_portal.name = "ReturnPortal"
	return_portal.position = PORTAL_POSITION
	_draw_diamond(return_portal, Color("#8be6c5"))
	add_child(return_portal)

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
	prompt = Label.new()
	prompt.position = Vector2(420, 320)
	prompt.text = "E : Retourner à Valbrume"
	prompt.add_theme_color_override("font_color", Color("#fff2d4"))
	prompt.add_theme_font_size_override("font_size", 13)
	prompt.visible = false
	ui.add_child(prompt)
	var title := Label.new()
	title.position = Vector2(14, 12)
	title.text = "CHEMIN DES BOIS"
	title.add_theme_color_override("font_color", Color("#fff2d4"))
	title.add_theme_font_size_override("font_size", 15)
	ui.add_child(title)

func _draw_rect(position: Vector2, size: Vector2, color: String, z: int) -> void:
	var rect := ColorRect.new()
	rect.position = position
	rect.size = size
	rect.color = Color(color)
	rect.z_index = z
	add_child(rect)

func _draw_tree(position: Vector2) -> void:
	var trunk := ColorRect.new()
	trunk.position = position + Vector2(-5, 4)
	trunk.size = Vector2(10, 22)
	trunk.color = Color("#765034")
	add_child(trunk)
	var leaves := Polygon2D.new()
	leaves.position = position
	leaves.polygon = PackedVector2Array([Vector2(0, -22), Vector2(20, -4), Vector2(13, 14), Vector2(-13, 14), Vector2(-20, -4)])
	leaves.color = Color("#1f4f38")
	add_child(leaves)

func _draw_diamond(parent: Node2D, color: Color) -> void:
	var diamond := Polygon2D.new()
	diamond.polygon = PackedVector2Array([Vector2(0, -18), Vector2(13, 0), Vector2(0, 18), Vector2(-13, 0)])
	diamond.color = color
	parent.add_child(diamond)
