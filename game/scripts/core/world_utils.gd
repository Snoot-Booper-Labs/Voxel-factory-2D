class_name WorldUtils
extends Object

## Utility class for world coordinate conversions and constants
##
## Centralizes handling of Tile and Chunk sizes, and conversion between
## World (Screen) coordinates, Tile coordinates, and Chunk coordinates.
##
## Coordinate System:
## - World/Screen X: Right is Positive
## - World/Screen Y: Down is Positive (Godot default)
## - Tile X: Right is Positive
## - Tile Y: Up is Positive (Altitude), so Tile Y = -World Y / TILE_SIZE

const TILE_SIZE: int = 16
const CHUNK_SIZE: int = 16

## Convert world (screen) position to tile grid coordinates
static func world_to_tile(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(world_pos.x / float(TILE_SIZE))),
		- int(floor(world_pos.y / float(TILE_SIZE)))
	)

## Convert tile grid coordinates to world (screen) position (top-left of tile)
static func tile_to_world(tile_pos: Vector2i) -> Vector2:
	return Vector2(
		float(tile_pos.x * TILE_SIZE),
		float(-tile_pos.y * TILE_SIZE)
	)

## Convert tile coordinates to chunk coordinates
static func tile_to_chunk(tile_pos: Vector2i) -> Vector2i:
	return Vector2i(
		int(floor(float(tile_pos.x) / float(CHUNK_SIZE))),
		int(floor(float(tile_pos.y) / float(CHUNK_SIZE)))
	)

## Convert world coordinates directly to chunk coordinates
static func world_to_chunk(world_pos: Vector2) -> Vector2i:
	var tile_pos = world_to_tile(world_pos)
	return tile_to_chunk(tile_pos)

## Align a world position to the tile grid (snapping to top-left of the tile)
static func snap_to_grid(world_pos: Vector2) -> Vector2:
	var tile_pos = world_to_tile(world_pos)
	return tile_to_world(tile_pos)
