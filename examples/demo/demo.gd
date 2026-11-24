extends RPGMap

const WORLD_SIZE := Vector2(640, 360)
const HERO_SHEET: Texture2D = preload("res://examples/demo/assets/hero.svg")
const PLAYER_START := Vector2(300, 210)
const NPC_POSITION := Vector2(430, 150)
const SLIME_POSITION := Vector2(190, 145)
const CRYSTAL_POSITION := Vector2(520, 270)
const CHEST_POSITION := Vector2(570, 235)

var player: RPGCharacter
var hero_animation: AnimatedSprite2D
var dialogue_runner: RPGDialogueRunner
var dialogue_label: Label
var status_label: Label
var hp_label: Label
var prompt_label: Label
var npc: Node2D
var slime: Node2D
var crystal: Node2D
var chest: Node2D
var chest_opened := false
var has_crystal := false
var slime_defeated := false
var player_hp := 5
var player_mp := 3
var experience := 0
var gold := 0
var inventory: RPGInventory
var inventory_panel: PanelContainer
var inventory_label: Label
var inventory_open := false
var slime_hp := 3
var battle_active := false
var defending := false
var battle_label: Label
var message_time := 0.0

func _ready() -> void:
	map_id = &"valbrume"
	_build_world()
	_build_player()
	_build_characters()
	_build_inventory()
	_build_hud()
	_show_message("Valbrume — Parle à Lila, récupère le cristal et chasse le slime !")

func _process(delta: float) -> void:
	message_time = maxf(0.0, message_time - delta)
	if player == null:
		return
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction.length() > 0.1:
		if absf(direction.x) > absf(direction.y):
			hero_animation.animation = "right" if direction.x > 0.0 else "left"
		else:
			hero_animation.animation = "front" if direction.y > 0.0 else "back"
		if not hero_animation.is_playing():
			hero_animation.play()
	else:
		hero_animation.stop()
		hero_animation.frame = 0
	_update_prompt()
	if message_time <= 0.0 and not battle_active:
		status_label.text = _objective_text()

func _unhandled_input(event: InputEvent) -> void:
	if player == null:
		return
	if inventory_open:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_I, KEY_ESCAPE]:
			_toggle_inventory()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_I and not battle_active:
		_toggle_inventory()
		return
	if battle_active:
		if event is InputEventKey and event.pressed and not event.echo:
			match event.keycode:
				KEY_1, KEY_E, KEY_ENTER:
					_battle_action("attack")
				KEY_2:
					_battle_action("skill")
				KEY_3:
					_battle_action("item")
				KEY_4:
					_battle_action("defend")
		return
	if not event.is_action_pressed("interact"):
		return
	var distance_npc := player.global_position.distance_to(NPC_POSITION)
	var distance_crystal := player.global_position.distance_to(CRYSTAL_POSITION)
	var distance_slime := player.global_position.distance_to(SLIME_POSITION)
	var distance_chest := player.global_position.distance_to(CHEST_POSITION)
	if distance_npc < 42.0:
		_talk_to_npc()
	elif distance_crystal < 30.0 and not has_crystal:
		_collect_crystal()
	elif distance_slime < 42.0 and not slime_defeated:
		_start_battle()
	elif distance_chest < 38.0 and not chest_opened:
		_open_chest()
	else:
		_show_message("Il n'y a rien à faire ici.")

func _build_world() -> void:
	var spawn_points := Node2D.new()
	spawn_points.name = "SpawnPoints"
	add_child(spawn_points)
	var spawn := Marker2D.new()
	spawn.name = "default"
	spawn.position = PLAYER_START
	spawn_points.add_child(spawn)

	var ground := ColorRect.new()
	ground.size = WORLD_SIZE
	ground.color = Color("#477b45")
	ground.z_index = -20
	add_child(ground)
	for x in range(0, 640, 32):
		for y in range(0, 360, 32):
			var tile := ColorRect.new()
			tile.position = Vector2(x + 1, y + 1)
			tile.size = Vector2(30, 30)
			tile.color = Color("#548b4c") if (x / 32 + y / 32) % 2 == 0 else Color("#4d8246")
			tile.z_index = -19
			add_child(tile)

	# A winding stone path through a small cliffside village.
	_draw_rect(Vector2(0, 250), Vector2(640, 46), "#a88a61", -5)
	_draw_rect(Vector2(255, 120), Vector2(72, 160), "#a88a61", -5)
	_draw_rect(Vector2(300, 120), Vector2(210, 44), "#a88a61", -5)
	_draw_rect(Vector2(0, 70), Vector2(145, 66), "#286f9a", -4)
	_draw_rect(Vector2(0, 130), Vector2(38, 230), "#286f9a", -4)
	_draw_rect(Vector2(8, 75), Vector2(125, 5), "#59a9c5", -3)
	_draw_rect(Vector2(36, 125), Vector2(5, 220), "#59a9c5", -3)

	_build_house(Vector2(350, 55))
	_build_tree(Vector2(105, 195))
	_build_tree(Vector2(560, 110))
	_build_tree(Vector2(90, 315))
	_build_tree(Vector2(590, 315))
	_build_fence(Vector2(365, 215), 5)
	_add_wall(Vector2(320, 18), Vector2(300, 10))
	_add_wall(Vector2(320, 345), Vector2(640, 12))
	_add_wall(Vector2(5, 180), Vector2(10, 360))
	_add_wall(Vector2(635, 180), Vector2(10, 360))

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
	for animation_name in ["front", "back", "left", "right"]:
		frames.add_animation(animation_name)
		frames.set_animation_speed(animation_name, 7.0)
		frames.set_animation_loop(animation_name, true)
	var indexes := {"front": [0, 1], "back": [2, 3], "left": [4, 5], "right": [6, 7]}
	for animation_name in indexes:
		for frame_index in indexes[animation_name]:
			var atlas := AtlasTexture.new()
			atlas.atlas = HERO_SHEET
			atlas.region = Rect2(frame_index * 32, 0, 32, 48)
			frames.add_frame(animation_name, atlas)
	hero_animation = AnimatedSprite2D.new()
	hero_animation.sprite_frames = frames
	hero_animation.animation = "front"
	hero_animation.position = Vector2(0, -12)
	hero_animation.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	player.add_child(hero_animation)
	var camera := RPGPixelCamera.new()
	camera.position_smoothing_enabled = false
	player.add_child(camera)

func _build_characters() -> void:
	npc = _make_person(Color("#e6c16c"), Color("#6b9c9b"), Vector2(430, 150))
	npc.name = "Lila"
	add_child(npc)
	_add_name_tag(npc, "Lila")

	crystal = Node2D.new()
	crystal.position = CRYSTAL_POSITION
	add_child(crystal)
	_draw_diamond(crystal, Color("#7de7f2"))
	_add_name_tag(crystal, "Cristal")

	slime = Node2D.new()
	slime.position = SLIME_POSITION
	add_child(slime)
	_draw_slime(slime)
	_add_name_tag(slime, "Slime")

	chest = Node2D.new()
	chest.position = CHEST_POSITION
	add_child(chest)
	_draw_chest(chest)
	_add_name_tag(chest, "Coffre")

func _build_inventory() -> void:
	inventory = RPGInventory.new()
	inventory.name = "Inventory"
	add_child(inventory)
	var potion := RPGItemData.new()
	potion.item_id = &"potion"
	potion.display_name = "Potion"
	potion.description = "Restaure 3 PV."
	potion.max_stack = 9
	potion.hp_restore = 3
	inventory.register_item(potion)
	inventory.add_item(potion.item_id)

	var key := RPGItemData.new()
	key.item_id = &"old_key"
	key.display_name = "Vieille clé"
	key.description = "Une clé rouillée trouvée dans un coffre."
	key.max_stack = 1
	inventory.register_item(key)

func _build_hud() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)
	var top := PanelContainer.new()
	top.position = Vector2(10, 8)
	top.size = Vector2(620, 38)
	top.add_theme_stylebox_override("panel", _panel_style("#17263c", "#d9bd82"))
	ui.add_child(top)
	var row := HBoxContainer.new()
	top.add_child(row)
	var title := Label.new()
	title.text = "VALBRUME  •  JOUR 1"
	title.add_theme_color_override("font_color", Color("#f5e4bb"))
	title.add_theme_font_size_override("font_size", 15)
	row.add_child(title)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	hp_label = Label.new()
	hp_label.text = "PV 5/5  •  PM 3/3"
	hp_label.add_theme_color_override("font_color", Color("#9de0a0"))
	hp_label.add_theme_font_size_override("font_size", 15)
	row.add_child(hp_label)

	_build_inventory_menu(ui)

	var bottom := PanelContainer.new()
	bottom.position = Vector2(10, 300)
	bottom.size = Vector2(620, 50)
	bottom.add_theme_stylebox_override("panel", _panel_style("#17263c", "#d9bd82"))
	ui.add_child(bottom)
	var content := VBoxContainer.new()
	bottom.add_child(content)
	dialogue_label = Label.new()
	dialogue_label.text = "Les collines de Valbrume sont baignées par la lumière du matin."
	dialogue_label.add_theme_color_override("font_color", Color("#fff2d4"))
	dialogue_label.add_theme_font_size_override("font_size", 14)
	content.add_child(dialogue_label)
	status_label = Label.new()
	status_label.text = _objective_text()
	status_label.add_theme_color_override("font_color", Color("#e4c77e"))
	status_label.add_theme_font_size_override("font_size", 11)
	content.add_child(status_label)
	prompt_label = Label.new()
	prompt_label.position = Vector2(455, 52)
	prompt_label.add_theme_color_override("font_color", Color("#fff2d4"))
	prompt_label.add_theme_font_size_override("font_size", 12)
	ui.add_child(prompt_label)

	dialogue_runner = RPGDialogueRunner.new()
	add_child(dialogue_runner)
	dialogue_runner.line_started.connect(func(line: String, _index: int) -> void: dialogue_label.text = line)

func _build_inventory_menu(ui: CanvasLayer) -> void:
	inventory_panel = PanelContainer.new()
	inventory_panel.name = "InventoryMenu"
	inventory_panel.position = Vector2(150, 92)
	inventory_panel.size = Vector2(340, 176)
	inventory_panel.add_theme_stylebox_override("panel", _panel_style("#17263c", "#d9bd82"))
	inventory_panel.visible = false
	ui.add_child(inventory_panel)

	inventory_label = Label.new()
	inventory_label.add_theme_color_override("font_color", Color("#fff2d4"))
	inventory_label.add_theme_font_size_override("font_size", 14)
	inventory_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inventory_panel.add_child(inventory_label)
	_update_inventory_menu()

func _toggle_inventory() -> void:
	inventory_open = not inventory_open
	inventory_panel.visible = inventory_open
	player.set_input_enabled(not inventory_open)
	if inventory_open:
		_update_inventory_menu()

func _update_inventory_menu() -> void:
	if inventory_label == null:
		return
	var lines := ["INVENTAIRE", ""]
	for item_id in inventory.item_ids():
		var item := inventory.get_item(item_id)
		lines.append("%s  x%d" % [item.display_name, inventory.count(item_id)])
		lines.append(item.description)
		lines.append("")
	if lines.size() == 2:
		lines.append("Aucun objet.")
	lines.append("I / Échap : fermer")
	inventory_label.text = "\\n".join(lines)

func _talk_to_npc() -> void:
	var dialogue := RPGDialogue.new()
	dialogue.dialogue_id = &"lila"
	if slime_defeated:
		dialogue.lines = ["Tu as vaincu le slime ! Le vieux chemin est de nouveau sûr.", "Prends ces quelques pièces et repose-toi. Valbrume te doit une fière chandelle."]
	elif has_crystal:
		dialogue.lines = ["Tu as trouvé le cristal ! Il réagit à la présence du slime.", "Le petit monstre bloque le vieux chemin. Tu peux le vaincre avec E."]
	else:
		dialogue.lines = ["Bonjour, voyageur. Je suis Lila, gardienne de Valbrume.", "Un cristal bleu est tombé près du vieux pont. Peux-tu le retrouver ?", "Un slime rôde aussi sur le chemin. Méfie-toi !"]
	dialogue_runner.start(dialogue)

func _collect_crystal() -> void:
	has_crystal = true
	crystal.queue_free()
	_show_message("Cristal azur obtenu ! L'objet pulse d'une étrange énergie.")
	status_label.text = _objective_text()

func _start_battle() -> void:
	battle_active = true
	defending = false
	player.set_input_enabled(false)
	_show_message("Un SLIME surgit ! Choisis une commande.")
	_draw_battle_overlay(true)

func _battle_action(action: String) -> void:
	var damage := 0
	match action:
		"attack":
			damage = 1
		"skill":
			if player_mp < 2:
				_show_message("Pas assez de PM pour Éclat azur.")
				return
			player_mp -= 2
			damage = 2
		"item":
			if _use_potion():
				_enemy_turn()
			return
		"defend":
			defending = true
			_show_message("Tu te mets en garde.")
			_enemy_turn()
			return
		_:
			return
	slime_hp = maxi(0, slime_hp - damage)
	if slime_hp == 0:
		_end_battle(true)
		return
	_show_message("Tu infliges %d dégâts au slime." % damage)
	_enemy_turn()

func _use_potion() -> bool:
	var potion := inventory.get_item(&"potion")
	if potion == null or inventory.count(&"potion") == 0:
		_show_message("Tu n'as plus de potion.")
		return false
	if player_hp == 5:
		_show_message("Tes PV sont déjà au maximum.")
		return false
	inventory.remove_item(&"potion")
	player_hp = mini(5, player_hp + potion.hp_restore)
	defending = false
	_update_battle_hud()
	_update_inventory_menu()
	_show_message("Potion utilisée : %d PV récupérés." % potion.hp_restore)
	return true

func _open_chest() -> void:
	if chest_opened:
		return
	chest_opened = true
	gold += 10
	inventory.add_item(&"old_key")
	chest.queue_free()
	_update_battle_hud()
	_update_inventory_menu()
	_show_message("Coffre ouvert ! +10 G et une vieille clé.")

func _enemy_turn() -> void:
	if not battle_active:
		return
	if defending:
		defending = false
		_show_message("Tu bloques complètement la riposte !")
	else:
		player_hp = maxi(0, player_hp - 1)
		_show_message("Le slime riposte : 1 dégât.")
	_update_battle_hud()
	if player_hp <= 0:
		_end_battle(false)
		return
	_update_battle_overlay()

func _end_battle(victory: bool) -> void:
	battle_active = false
	player.set_input_enabled(true)
	_draw_battle_overlay(false)
	if victory:
		if not slime_defeated:
			slime_defeated = true
			experience += 20
			gold += 15
			slime.queue_free()
			_show_message("Victoire ! +20 EXP, +15 G. Le chemin est libéré !")
		else:
			_show_message("Le slime a déjà été vaincu.")
		_update_battle_hud()
		status_label.text = _objective_text()
	else:
		player_hp = 1
		_update_battle_hud()
		_show_message("Tu es épuisé. Lila te soigne et le slime reprend sa place.")
		slime_hp = 3

func _update_battle_hud() -> void:
	hp_label.text = "PV %d/5  •  PM %d/3  •  EXP %d  •  %d G" % [player_hp, player_mp, experience, gold]

func _update_battle_overlay() -> void:
	if battle_label == null or not is_instance_valid(battle_label):
		return
	battle_label.text = _battle_menu_text()

func _battle_menu_text() -> String:
	return "COMBAT  •  SLIME %d PV\\n1 Attaquer   2 Éclat azur (2 PM)\\n3 Potion (%d)   4 Défendre" % [slime_hp, inventory.count(&"potion")]

func _draw_battle_overlay(show: bool) -> void:
	var existing := get_node_or_null("BattleHint")
	if existing != null:
		existing.queue_free()
	battle_label = null
	if not show:
		return
	var panel := PanelContainer.new()
	panel.name = "BattleHint"
	panel.position = Vector2(115, 92)
	panel.size = Vector2(410, 92)
	panel.add_theme_stylebox_override("panel", _panel_style("#202c4b", "#e7c879"))
	battle_label = Label.new()
	battle_label.text = _battle_menu_text()
	battle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	battle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	battle_label.add_theme_color_override("font_color", Color("#fff0c8"))
	battle_label.add_theme_font_size_override("font_size", 14)
	panel.add_child(battle_label)
	add_child(panel)

func _update_prompt() -> void:
	var nearest := 999.0
	var prompt := ""
	for candidate in [[NPC_POSITION, "E : Parler"], [CRYSTAL_POSITION, "E : Prendre"], [SLIME_POSITION, "E : Combattre"], [CHEST_POSITION, "E : Ouvrir le coffre"]]:
		var distance: float = player.global_position.distance_to(candidate[0])
		if distance < nearest:
			nearest = distance
			prompt = candidate[1]
	prompt_label.text = prompt if nearest < 55.0 else ""

func _objective_text() -> String:
	if not has_crystal:
		return "Objectif : retrouver le cristal azur près du pont"
	if not slime_defeated:
		return "Objectif : vaincre le slime sur le chemin"
	return "Quête terminée : Valbrume est en paix !"

func _show_message(message: String) -> void:
	dialogue_label.text = message
	message_time = 4.0

func _draw_rect(pos: Vector2, size: Vector2, color: String, z: int) -> void:
	var rect := ColorRect.new()
	rect.position = pos
	rect.size = size
	rect.color = Color(color)
	rect.z_index = z
	add_child(rect)

func _build_house(pos: Vector2) -> void:
	_draw_rect(pos, Vector2(150, 90), "#c6a06a", -2)
	_draw_rect(pos + Vector2(-8, -24), Vector2(166, 38), "#8e4534", -1)
	_draw_rect(pos + Vector2(14, 10), Vector2(38, 42), "#684333", 0)
	_draw_rect(pos + Vector2(92, 8), Vector2(30, 25), "#6da0ad", 0)
	_draw_rect(pos + Vector2(100, 8), Vector2(5, 25), "#e6d39a", 1)
	_draw_rect(pos + Vector2(92, 18), Vector2(30, 4), "#e6d39a", 1)
	_draw_rect(pos + Vector2(0, 58), Vector2(150, 8), "#8c6549", 1)

func _build_tree(pos: Vector2) -> void:
	_draw_rect(pos + Vector2(-5, 5), Vector2(10, 24), "#70472d", 0)
	_draw_rect(pos + Vector2(-18, -18), Vector2(36, 28), "#245b3e", 1)
	_draw_rect(pos + Vector2(-12, -24), Vector2(24, 12), "#367b49", 2)
	_draw_rect(pos + Vector2(-9, -13), Vector2(8, 7), "#5b9851", 3)

func _build_fence(pos: Vector2, posts: int) -> void:
	_draw_rect(pos, Vector2(posts * 20, 4), "#805337", 1)
	_draw_rect(pos + Vector2(0, 13), Vector2(posts * 20, 4), "#805337", 1)
	for index in posts:
		_draw_rect(pos + Vector2(index * 20, -4), Vector2(4, 24), "#a16b3c", 2)

func _add_wall(pos: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func _make_person(hair: Color, clothes: Color, pos: Vector2) -> Node2D:
	var person := Node2D.new()
	person.position = pos
	var shadow := Polygon2D.new()
	shadow.polygon = PackedVector2Array([Vector2(-11, 8), Vector2(0, 4), Vector2(11, 8), Vector2(0, 12)])
	shadow.color = Color("#263c32")
	person.add_child(shadow)
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([Vector2(-8, -7), Vector2(-7, -17), Vector2(7, -17), Vector2(8, -7), Vector2(7, 8), Vector2(-7, 8)])
	body.color = clothes
	person.add_child(body)
	var head := Polygon2D.new()
	head.polygon = PackedVector2Array([Vector2(-7, -18), Vector2(-6, -28), Vector2(6, -28), Vector2(8, -18), Vector2(6, -9), Vector2(-6, -9)])
	head.color = Color("#e9b98b")
	person.add_child(head)
	var hair_shape := Polygon2D.new()
	hair_shape.polygon = PackedVector2Array([Vector2(-8, -19), Vector2(-7, -30), Vector2(5, -32), Vector2(9, -22), Vector2(4, -20), Vector2(0, -25), Vector2(-4, -19)])
	hair_shape.color = hair
	person.add_child(hair_shape)
	return person

func _draw_diamond(parent: Node2D, color: Color) -> void:
	var gem := Polygon2D.new()
	gem.polygon = PackedVector2Array([Vector2(0, -12), Vector2(9, -3), Vector2(0, 12), Vector2(-9, -3)])
	gem.color = color
	parent.add_child(gem)
	var shine := Polygon2D.new()
	shine.polygon = PackedVector2Array([Vector2(0, -8), Vector2(4, -3), Vector2(0, 1)])
	shine.color = Color("#e6ffff")
	parent.add_child(shine)

func _draw_chest(parent: Node2D) -> void:
	var body := ColorRect.new()
	body.position = Vector2(-12, -8)
	body.size = Vector2(24, 17)
	body.color = Color("#805337")
	parent.add_child(body)
	var lid := ColorRect.new()
	lid.position = Vector2(-13, -11)
	lid.size = Vector2(26, 6)
	lid.color = Color("#c18a4d")
	parent.add_child(lid)
	var lock := ColorRect.new()
	lock.position = Vector2(-2, -4)
	lock.size = Vector2(4, 7)
	lock.color = Color("#e7c879")
	parent.add_child(lock)

func _draw_slime(parent: Node2D) -> void:
	var blob := Polygon2D.new()
	blob.polygon = PackedVector2Array([Vector2(-15, 7), Vector2(-13, -3), Vector2(-7, -10), Vector2(7, -10), Vector2(14, -2), Vector2(15, 7), Vector2(8, 11), Vector2(-9, 11)])
	blob.color = Color("#67c6a0")
	parent.add_child(blob)
	var eyes := Polygon2D.new()
	eyes.polygon = PackedVector2Array([Vector2(-7, -2), Vector2(-3, -2), Vector2(-3, 3), Vector2(-7, 3), Vector2(4, -2), Vector2(8, -2), Vector2(8, 3), Vector2(4, 3)])
	eyes.color = Color("#173b43")
	parent.add_child(eyes)

func _add_name_tag(target: Node2D, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.position = Vector2(-28, -44)
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color("#fff0c8"))
	target.add_child(label)

func _panel_style(background: String, border: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(background)
	style.border_color = Color(border)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style
