extends CanvasLayer
## Replaces the active RPGMap inside RPGDisplayRoot with a short fade.

const FADE_DURATION := 0.25

var pending_spawn_id: StringName
var transfer_data: Dictionary = {}
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
