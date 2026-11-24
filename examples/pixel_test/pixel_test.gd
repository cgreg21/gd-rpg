extends Node2D
## Pixel-grid test: move the marker with the arrow keys and toggle CRT with F3.

var player_position := Vector2i(320, 180)
var crt_overlay: RPGCRTOverlay

func _ready() -> void:
	queue_redraw()
	var crt_layer := CanvasLayer.new()
	crt_layer.layer = 10
	add_child(crt_layer)
	crt_overlay = RPGCRTOverlay.new()
	crt_overlay.name = "CRTOverlay"
	var shader_material := ShaderMaterial.new()
	shader_material.shader = load("res://addons/gd_rpg/runtime/display/crt.gdshader")
	crt_overlay.material = shader_material
	crt_overlay.enabled = OS.get_environment("GD_RPG_SCREENSHOT_CRT") == "1"
	crt_layer.add_child(crt_overlay)
	var ui := CanvasLayer.new()
	add_child(ui)
	var label := Label.new()
	label.position = Vector2(12, 10)
	label.text = "PIXEL TEST  |  Arrows: move  |  F3: CRT"
	label.add_theme_font_size_override("font_size", 16)
	ui.add_child(label)

func _process(_delta: float) -> void:
	var direction := Vector2i(
		int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left")),
		int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
	)
	if direction != Vector2i.ZERO:
		player_position += direction
		player_position.x = clampi(player_position.x, 8, 632)
		player_position.y = clampi(player_position.y, 8, 352)
		queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		crt_overlay.enabled = not crt_overlay.enabled

func _draw() -> void:
	for x in range(0, 640, 32):
		for y in range(0, 360, 32):
			var shade := Color("#304b3d") if (x / 32 + y / 32) % 2 == 0 else Color("#263b35")
			draw_rect(Rect2(x, y, 32, 32), shade)
	draw_rect(Rect2(player_position - Vector2i(6, 10), Vector2i(13, 20)), Color("#f2c078"))
	draw_rect(Rect2(16, 300, 608, 2), Color("#8eb8e8"))
