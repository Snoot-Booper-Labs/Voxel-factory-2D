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


## Calculate the range of chunks covered by a world-space rectangle
## Returns a Rect2i where position is the top-left (min) chunk and size is the span
static func get_chunk_bounds_from_world_rect(world_rect: Rect2) -> Rect2i:
	# Add a buffer of 1 chunk to ensure edges are covered
	var buffer = Vector2(CHUNK_SIZE * TILE_SIZE, CHUNK_SIZE * TILE_SIZE)
	
	var top_left = world_rect.position - buffer
	var bottom_right = world_rect.end + buffer
	
	# Convert world corners to chunk coordinates
	# Note: World Y is down (positive), but Tile Y is up (positive).
	var chunk_a = world_to_chunk(top_left)
	var chunk_b = world_to_chunk(bottom_right)
	
	var min_chunk = Vector2i(
		min(chunk_a.x, chunk_b.x),
		min(chunk_a.y, chunk_b.y)
	)
	var max_chunk = Vector2i(
		max(chunk_a.x, chunk_b.x),
		max(chunk_a.y, chunk_b.y)
	)
	
	# Rect2i stores position and size. Ensure at least 1x1.
	return Rect2i(min_chunk, max_chunk - min_chunk + Vector2i(1, 1))
