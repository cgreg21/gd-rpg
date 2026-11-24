extends CanvasLayer
## Replaces the active RPGMap inside RPGDisplayRoot with a short fade.

const FADE_DURATION := 0.25
const SAVE_PATH := "user://valbrume_save.json"
const SAVE_VERSION := 2
const MAP_SCENES := {
	"valbrume": "res://examples/demo/demo.tscn",
	"valbrume_route": "res://examples/demo/route.tscn",
	"valbrume_sanctuary": "res://examples/demo/sanctuary.tscn"
}

var pending_spawn_id: StringName
var transfer_data: Dictionary = {}
var pending_load: Dictionary = {}
var transitioning := false
var fade_rect: ColorRect

func _ready() -> void:
	layer = 100
	fade_rect = ColorRect.new()
	fade_rect.name = "Fade"
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_rect.color = Color.BLACK
	fade_rect.color.a = 0.0
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.visible = false
	add_child(fade_rect)

func take_spawn_id() -> StringName:
	var spawn_id := pending_spawn_id
	pending_spawn_id = &""
	return spawn_id

func set_transfer_data(data: Dictionary) -> void:
	transfer_data = data.duplicate(true)

func get_transfer_data() -> Dictionary:
	return transfer_data.duplicate(true)

func save_game(map_id: StringName, scene_path: String, position: Vector2) -> bool:
	if not MAP_SCENES.has(String(map_id)) or MAP_SCENES[String(map_id)] != scene_path:
		return false
	var data := {
		"version": SAVE_VERSION,
		"map": String(map_id),
		"scene": scene_path,
		"position": [position.x, position.y],
		"transfer": transfer_data.duplicate(true)
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	return true

func load_game(current_map_id: StringName) -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return false
	var data: Dictionary = parsed
	var saved_map := String(data.get("map", ""))
	var scene_path := String(data.get("scene", ""))
	var position: Variant = data.get("position")
	var saved_transfer: Variant = data.get("transfer")
	if data.get("version") != SAVE_VERSION or not MAP_SCENES.has(saved_map) or MAP_SCENES[saved_map] != scene_path:
		return false
	if not position is Array or position.size() != 2 or not saved_transfer is Dictionary:
		return false
	for coordinate in position:
		if not (coordinate is int or coordinate is float):
			return false
	if not _is_valid_transfer(saved_transfer):
		return false
	transfer_data = saved_transfer.duplicate(true)
	pending_load = {"map": saved_map, "position": Vector2(float(position[0]), float(position[1]))}
	if saved_map != String(current_map_id):
		transition_to(scene_path, &"default")
	return true

func _is_valid_transfer(data: Dictionary) -> bool:
	if data.is_empty():
		return true
	for key in ["hp", "mp", "experience", "gold"]:
		var value: Variant = data.get(key)
		if not (value is int or value is float) or int(value) != value:
			return false
	if data.hp < 1 or data.hp > 5 or data.mp < 0 or data.mp > 3 or data.experience < 0 or data.gold < 0:
		return false
	for key in ["has_crystal", "chest_opened", "door_opened", "slime_defeated"]:
		if not data.get(key) is bool:
			return false
	var items: Variant = data.get("inventory")
	if not items is Dictionary:
		return false
	for item_id in items:
		var amount: Variant = items[item_id]
		if not item_id in ["potion", "old_key"] or not (amount is int or amount is float) or int(amount) != amount or amount < 0:
			return false
	if items.get("potion", 0) > 9 or items.get("old_key", 0) > 1:
		return false
	return true

func take_loaded_position(map_id: StringName) -> Vector2:
	if pending_load.is_empty() or pending_load.get("map") != String(map_id):
		return Vector2.INF
	var position: Vector2 = pending_load.position
	pending_load.clear()
	return position

func transition_to(scene_path: String, spawn_id: StringName = &"default") -> void:
	if transitioning:
		return
	var packed_scene := load(scene_path) as PackedScene
	var display := get_tree().current_scene as RPGDisplayRoot
	if packed_scene == null or display == null or display.internal_viewport == null:
		push_error("Map transition requires a valid map scene and RPGDisplayRoot: %s" % scene_path)
		return
	var next_map := packed_scene.instantiate()
	if not next_map is RPGMap:
		next_map.queue_free()
		push_error("Map scene must inherit RPGMap: %s" % scene_path)
		return

	transitioning = true
	fade_rect.visible = true
	await _fade_to(1.0)
	pending_spawn_id = spawn_id
	var viewport := display.internal_viewport
	if viewport.get_child_count() > 0:
		var current_map := viewport.get_child(0)
		viewport.remove_child(current_map)
		current_map.queue_free()
	viewport.add_child(next_map)
	await get_tree().process_frame
	await _fade_to(0.0)
	fade_rect.visible = false
	transitioning = false

func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", alpha, FADE_DURATION)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	await tween.finished
