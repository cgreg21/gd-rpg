extends RefCounted
class_name DemoWastelandWorld
## Builds deterministic post-apocalyptic TileMapLayer terrain for the sample maps.

const TILESET: Texture2D = preload("res://examples/demo/assets/wasteland_tileset.png")
const MAP_WIDTH := 40
const MAP_HEIGHT := 23
const SOURCE_ID := 0

static func build(parent: Node2D, map_kind: StringName) -> void:
	var tile_set := _create_tile_set()
	var ground := TileMapLayer.new()
	ground.name = "WastelandGround"
	ground.tile_set = tile_set
	ground.z_index = -30
	ground.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(ground)

	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			ground.set_cell(Vector2i(x, y), SOURCE_ID, _ground_tile(map_kind, x, y))

	var props := TileMapLayer.new()
	props.name = "WastelandProps"
	props.tile_set = tile_set
	props.z_index = -8
	props.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(props)
	for placement in _prop_placements(map_kind):
		props.set_cell(placement[0], SOURCE_ID, placement[1])

static func _create_tile_set() -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(16, 16)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = TILESET
	atlas.texture_region_size = Vector2i(16, 16)
	for y in range(8):
		for x in range(8):
			atlas.create_tile(Vector2i(x, y))
	tile_set.add_source(atlas, SOURCE_ID)
	return tile_set

static func _ground_tile(map_kind: StringName, x: int, y: int) -> Vector2i:
	var variant := posmod(x * 3 + y * 5, 8)
	if map_kind == &"village":
		if (x <= 8 and y >= 4 and y <= 8) or (x <= 2 and y >= 8):
			return Vector2i(variant, 3)
		if (y >= 15 and y <= 17) or (x >= 16 and x <= 19 and y >= 7 and y <= 17) or (x >= 18 and x <= 31 and y >= 7 and y <= 9):
			return Vector2i(posmod(x + y, 3), 0)
		return Vector2i(variant, 1)
	if map_kind == &"route":
		if y >= 9 and y <= 13:
			return Vector2i(posmod(x + y, 3), 0)
		return Vector2i(variant, 1)
	return Vector2i(variant, 2)

static func _prop_placements(map_kind: StringName) -> Array:
	match map_kind:
		&"village":
			return [
				[Vector2i(2, 2), Vector2i(0, 7)],
				[Vector2i(5, 8), Vector2i(1, 7)],
				[Vector2i(34, 3), Vector2i(5, 7)],
				[Vector2i(35, 17), Vector2i(7, 6)],
				[Vector2i(3, 19), Vector2i(0, 6)],
				[Vector2i(36, 19), Vector2i(4, 6)],
				[Vector2i(32, 8), Vector2i(1, 6)]
			]
		&"route":
			return [
				[Vector2i(3, 3), Vector2i(0, 7)],
				[Vector2i(10, 3), Vector2i(1, 7)],
				[Vector2i(20, 2), Vector2i(2, 7)],
				[Vector2i(35, 3), Vector2i(7, 6)],
				[Vector2i(4, 18), Vector2i(0, 6)],
				[Vector2i(31, 17), Vector2i(5, 6)],
				[Vector2i(18, 7), Vector2i(4, 6)]
			]
		_:
			return [
				[Vector2i(4, 3), Vector2i(3, 6)],
				[Vector2i(34, 3), Vector2i(0, 6)],
				[Vector2i(5, 18), Vector2i(4, 6)],
				[Vector2i(34, 18), Vector2i(7, 6)],
				[Vector2i(20, 2), Vector2i(5, 7)],
				[Vector2i(7, 7), Vector2i(2, 6)]
			]
