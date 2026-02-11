extends GutTest
## Unit tests for WorldUtils

func test_tile_size_constant() -> void:
	assert_eq(WorldUtils.TILE_SIZE, 16, "Tile size should be 16 pixels")

func test_chunk_size_constant() -> void:
	assert_eq(WorldUtils.CHUNK_SIZE, 16, "Chunk size should be 16 tiles")

# =============================================================================
# Coordinate Conversion Tests
# Note: Screen Y is down, world Y is up, so world_to_tile negates Y
# =============================================================================

func test_world_to_tile_conversion() -> void:
	# Screen (32, -48) -> tile (2, 3) because -(-48)/16 = 3
	var result = WorldUtils.world_to_tile(Vector2(32, -48))
	assert_eq(result, Vector2i(2, 3))

func test_world_to_tile_negative() -> void:
	# Screen (-16, 32) -> tile (-1, -2) because -(32)/16 = -2
	var result = WorldUtils.world_to_tile(Vector2(-16, 32))
	assert_eq(result, Vector2i(-1, -2))

func test_world_to_tile_fractional() -> void:
	# Screen (17, -33) -> tile (1, 2) because -(-33)/16 = 2 (floor) - OLD LOGIC
	# New Logic: -33 is in [-48, -32) which is Tile 3.
	var result = WorldUtils.world_to_tile(Vector2(17, -33))
	assert_eq(result, Vector2i(1, 3))

func test_world_to_tile_zero() -> void:
	var result = WorldUtils.world_to_tile(Vector2(0, 0))
	assert_eq(result, Vector2i(0, 0))

func test_tile_to_world_conversion() -> void:
	# tile (2, 3) -> Screen (32, -48)
	var result = WorldUtils.tile_to_world(Vector2i(2, 3))
	assert_eq(result, Vector2(32, -48))

func test_tile_to_world_negative() -> void:
	# tile (-1, -2) -> Screen (-16, 32)
	var result = WorldUtils.tile_to_world(Vector2i(-1, -2))
	assert_eq(result, Vector2(-16, 32))

func test_tile_to_chunk_conversion() -> void:
	# tile (32, 32) -> chunk (2, 2)
	var result = WorldUtils.tile_to_chunk(Vector2i(32, 32))
	assert_eq(result, Vector2i(2, 2))

func test_tile_to_chunk_negative() -> void:
	# tile (-16, -16) -> chunk (-1, -1)
	var result = WorldUtils.tile_to_chunk(Vector2i(-16, -16))
	assert_eq(result, Vector2i(-1, -1))

func test_world_to_chunk_conversion() -> void:
	# world (16*16, -16*16) -> tile (16, 16) -> chunk (1, 1)
	# wait, tile Y is negative world Y.
	# world Y = -256 -> tile Y = 16. chunk Y = 1.
	var result = WorldUtils.world_to_chunk(Vector2(256, -256))
	assert_eq(result, Vector2i(1, 1))

func test_snap_to_grid() -> void:
	# Snaps to top-left of tile
	# world (18, -18) -> tile (1, 2) (Tile 2 covers [-32, -16)) -> world (16, -32)
	var result = WorldUtils.snap_to_grid(Vector2(18, -18))
	assert_eq(result, Vector2(16, -32))
