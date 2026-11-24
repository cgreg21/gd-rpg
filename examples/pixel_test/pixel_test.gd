extends Node2D
## Small pixel-grid test scene: move the square with the arrow keys and toggle CRT with F3.

var player_position := Vector2i(160, 90)
var crt_overlay: RPGCRTOverlay

func _ready() -> void:
	queue_redraw()
	crt_overlay = RPGCRTOverlay.new()
	crt_overlay.name = "CRTOverlay"
	crt_overlay.set_script(load("res://addons/gd_rpg/runtime/display/crt_overlay.gd"))
	var shader_material := ShaderMaterial.new()
	shader_material.shader = load("res://addons/gd_rpg/runtime/display/crt.gdshader")
	crt_overlay.material = shader_material
	add_child(crt_overlay)
	var ui := CanvasLayer.new()
	add_child(ui)
	var label := Label.new()
	label.position = Vector2(6, 5)
	label.text = "PIXEL TEST  |  Arrows: move  |  F3: CRT"
	ui.add_child(label)

func _process(_delta: float) -> void:
	var direction := Vector2i(
		int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left")),
		int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
	)
	if direction != Vector2i.ZERO:
		player_position += direction
		player_position.x = clampi(player_position.x, 4, 316)
		player_position.y = clampi(player_position.y, 4, 176)
		queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		crt_overlay.enabled = not crt_overlay.enabled

func _draw() -> void:
	for x in range(0, 320, 16):
		for y in range(0, 180, 16):
			var shade := Color("#304b3d") if (x / 16 + y / 16) % 2 == 0 else Color("#263b35")
			draw_rect(Rect2(x, y, 16, 16), shade)
	draw_rect(Rect2(player_position - Vector2i(3, 5), Vector2i(7, 10)), Color("#f2c078"))
	draw_rect(Rect2(8, 150, 304, 1), Color("#8eb8e8"))
