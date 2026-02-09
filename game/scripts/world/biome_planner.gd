class_name BiomePlanner
extends RefCounted
## Voronoi-based biome distribution using FastNoiseLite for deterministic climate

const CELL_SIZE: int = 128  # Voronoi cell size in tiles

var world_seed: int = 0
var temperature_noise: FastNoiseLite
var humidity_noise: FastNoiseLite

# Cache for performance
var _cell_cache: Dictionary = {}


func _init(seed_value: int = 0) -> void:
	world_seed = seed_value
	_setup_noise()


func _setup_noise() -> void:
	temperature_noise = FastNoiseLite.new()
	temperature_noise.seed = world_seed
	temperature_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	temperature_noise.frequency = 1.0 / 256.0

	humidity_noise = FastNoiseLite.new()
	humidity_noise.seed = world_seed + 1000
	humidity_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	humidity_noise.frequency = 1.0 / 256.0


func get_biome_at(x: int, y: int) -> int:
	# Find nearest Voronoi cell center
	var cell := _get_cell_for_position(x, y)
	return cell.biome_type


func get_climate_at(x: int, y: int) -> Dictionary:
	# Get climate values at a specific position (normalized 0-1)
	var cell := _get_cell_for_position(x, y)
	return {
		"temperature": cell.temperature,
		"humidity": cell.humidity
	}


func _get_cell_for_position(x: int, y: int) -> Dictionary:
	var cell_x := int(floor(float(x) / CELL_SIZE))
	var cell_y := int(floor(float(y) / CELL_SIZE))

	# Check 3x3 grid for nearest center
	var nearest_dist := INF
	var nearest_cell: Dictionary

	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var cx := cell_x + dx
			var cy := cell_y + dy
			var center := _get_cell_center(cx, cy)
			var dist := Vector2(x, y).distance_squared_to(center)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest_cell = _get_or_create_cell(cx, cy, center)

	return nearest_cell


func _get_cell_center(cell_x: int, cell_y: int) -> Vector2:
	# Deterministic jitter based on cell coordinates
	var hash_val := hash(Vector3i(cell_x, cell_y, world_seed))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash_val

	var base_x := cell_x * CELL_SIZE + CELL_SIZE / 2
	var base_y := cell_y * CELL_SIZE + CELL_SIZE / 2
	var jitter := CELL_SIZE / 3

	return Vector2(
		base_x + rng.randf_range(-jitter, jitter),
		base_y + rng.randf_range(-jitter, jitter)
	)


func _get_or_create_cell(cell_x: int, cell_y: int, center: Vector2) -> Dictionary:
	var key := Vector2i(cell_x, cell_y)
	if _cell_cache.has(key):
		return _cell_cache[key]

	# Get climate at cell center
	var temp := (temperature_noise.get_noise_2d(center.x, center.y) + 1.0) / 2.0
	var humid := (humidity_noise.get_noise_2d(center.x, center.y) + 1.0) / 2.0

	var cell := {
		"cell_x": cell_x,
		"cell_y": cell_y,
		"center": center,
		"temperature": temp,
		"humidity": humid,
		"biome_type": BiomeData.get_biome_from_climate(temp, humid)
	}

	_cell_cache[key] = cell
	return cell
