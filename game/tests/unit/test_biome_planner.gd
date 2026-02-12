extends GutTest
## Unit tests for BiomeData and BiomePlanner - Voronoi-based biome distribution

# =============================================================================
# BiomeData Tests
# =============================================================================

func test_biome_data_class_exists():
	# BiomeData class should exist
	var biome_data = BiomeData.new()
	assert_not_null(biome_data, "BiomeData class should exist")


func test_biome_type_enum_exists():
	# BiomeType enum should have expected values
	assert_eq(BiomeData.BiomeType.PLAINS, 0, "PLAINS should be 0")
	assert_eq(BiomeData.BiomeType.FOREST, 1, "FOREST should be 1")
	assert_eq(BiomeData.BiomeType.DESERT, 2, "DESERT should be 2")
	assert_eq(BiomeData.BiomeType.MOUNTAINS, 3, "MOUNTAINS should be 3")
	assert_eq(BiomeData.BiomeType.OCEAN, 4, "OCEAN should be 4")


func test_biome_type_enum_has_all_biomes():
	# Verify all required biome types exist
	assert_true(BiomeData.BiomeType.has("PLAINS"), "Should have PLAINS")
	assert_true(BiomeData.BiomeType.has("FOREST"), "Should have FOREST")
	assert_true(BiomeData.BiomeType.has("DESERT"), "Should have DESERT")
	assert_true(BiomeData.BiomeType.has("MOUNTAINS"), "Should have MOUNTAINS")
	assert_true(BiomeData.BiomeType.has("OCEAN"), "Should have OCEAN")


func test_biome_params_exist():
	# biome_params should have entries for all biome types
	assert_true(BiomeData.biome_params.has(BiomeData.BiomeType.PLAINS), "Should have PLAINS params")
	assert_true(BiomeData.biome_params.has(BiomeData.BiomeType.FOREST), "Should have FOREST params")
	assert_true(BiomeData.biome_params.has(BiomeData.BiomeType.DESERT), "Should have DESERT params")
	assert_true(BiomeData.biome_params.has(BiomeData.BiomeType.MOUNTAINS), "Should have MOUNTAINS params")
	assert_true(BiomeData.biome_params.has(BiomeData.BiomeType.OCEAN), "Should have OCEAN params")


func test_biome_params_have_required_fields():
	# Each biome param should have required fields
	var plains = BiomeData.biome_params[BiomeData.BiomeType.PLAINS]
	assert_true(plains.has("name"), "Should have name")
	assert_true(plains.has("height_range"), "Should have height_range")
	assert_true(plains.has("surface_block"), "Should have surface_block")
	assert_true(plains.has("subsurface_block"), "Should have subsurface_block")
	assert_true(plains.has("vegetation_density"), "Should have vegetation_density")
	assert_true(plains.has("temperature"), "Should have temperature")
	assert_true(plains.has("humidity"), "Should have humidity")


func test_get_biome_name_returns_correct_name():
	# get_biome_name should return human-readable names
	assert_eq(BiomeData.get_biome_name(BiomeData.BiomeType.PLAINS), "Plains", "PLAINS name should be 'Plains'")
	assert_eq(BiomeData.get_biome_name(BiomeData.BiomeType.FOREST), "Forest", "FOREST name should be 'Forest'")
	assert_eq(BiomeData.get_biome_name(BiomeData.BiomeType.DESERT), "Desert", "DESERT name should be 'Desert'")


func test_get_biome_name_returns_unknown_for_invalid():
	# get_biome_name should return "Unknown" for invalid biomes
	assert_eq(BiomeData.get_biome_name(999), "Unknown", "Unknown biome should have name 'Unknown'")


func test_get_biome_params_returns_correct_params():
	# get_biome_params should return the correct dictionary
	var plains_params = BiomeData.get_biome_params(BiomeData.BiomeType.PLAINS)
	assert_eq(plains_params["name"], "Plains", "PLAINS params should have correct name")


func test_get_biome_params_returns_empty_for_invalid():
	# get_biome_params should return empty dictionary for invalid biomes
	var invalid_params = BiomeData.get_biome_params(999)
	assert_true(invalid_params.is_empty(), "Invalid biome should return empty params")


func test_get_biome_from_climate_desert():
	# Hot and dry should return DESERT
	# Hot + Dry (temp > 0.6, humid < 0.4) -> DESERT
	var biome = BiomeData.get_biome_from_climate(0.8, 0.2)
	assert_eq(biome, BiomeData.BiomeType.DESERT, "Hot and dry should be DESERT")


func test_get_biome_from_climate_mountains():
	# Cold should return MOUNTAINS
	# Cold + Any (temp < 0.3) -> MOUNTAINS
	var biome = BiomeData.get_biome_from_climate(0.1, 0.5)
	assert_eq(biome, BiomeData.BiomeType.MOUNTAINS, "Cold should be MOUNTAINS")


func test_get_biome_from_climate_forest():
	# Moderate temp and wet should return FOREST
	# Any + Wet (humid > 0.6) -> FOREST
	var biome = BiomeData.get_biome_from_climate(0.5, 0.8)
	assert_eq(biome, BiomeData.BiomeType.FOREST, "Wet should be FOREST")


func test_get_biome_from_climate_ocean():
	# Very wet should return OCEAN
	# Any + Very Wet (humid > 0.85) -> OCEAN
	var biome = BiomeData.get_biome_from_climate(0.5, 0.95)
	assert_eq(biome, BiomeData.BiomeType.OCEAN, "Very wet should be OCEAN")


func test_get_biome_from_climate_plains():
	# Default moderate conditions should return PLAINS
	var biome = BiomeData.get_biome_from_climate(0.5, 0.5)
	assert_eq(biome, BiomeData.BiomeType.PLAINS, "Moderate conditions should be PLAINS")


# =============================================================================
# BiomePlanner Tests
# =============================================================================

func test_biome_planner_class_exists():
	# BiomePlanner class should exist
	var planner = BiomePlanner.new(12345)
	assert_not_null(planner, "BiomePlanner class should exist")


func test_biome_planner_stores_seed():
	# BiomePlanner should store the world seed
	var planner = BiomePlanner.new(42)
	assert_eq(planner.world_seed, 42, "BiomePlanner should store seed")


func test_biome_planner_has_noise_generators():
	# BiomePlanner should have temperature and humidity noise generators
	var planner = BiomePlanner.new(12345)
	assert_not_null(planner.temperature_noise, "Should have temperature noise")
	assert_not_null(planner.humidity_noise, "Should have humidity noise")


func test_get_biome_at_returns_valid_biome():
	# get_biome_at should return a valid biome type
	var planner = BiomePlanner.new(12345)
	var biome = planner.get_biome_at(100, 100)
	assert_true(biome >= 0 and biome <= 4, "Biome should be valid type (0-4)")


func test_get_biome_at_deterministic_same_seed():
	# Same seed should produce same biome at same position
	var planner1 = BiomePlanner.new(12345)
	var planner2 = BiomePlanner.new(12345)

	var biome1 = planner1.get_biome_at(100, 100)
	var biome2 = planner2.get_biome_at(100, 100)

	assert_eq(biome1, biome2, "Same seed should produce same biome at same position")


func test_get_biome_at_deterministic_multiple_calls():
	# Multiple calls to same position should return same biome
	var planner = BiomePlanner.new(12345)

	var biome1 = planner.get_biome_at(500, 500)
	var biome2 = planner.get_biome_at(500, 500)
	var biome3 = planner.get_biome_at(500, 500)

	assert_eq(biome1, biome2, "Multiple calls should return same biome")
	assert_eq(biome2, biome3, "Multiple calls should return same biome")


func test_get_biome_at_different_seed_may_differ():
	# Different seeds should produce different biomes at same position
	# (statistically very likely with these seeds)
	var planner1 = BiomePlanner.new(12345)
	var planner2 = BiomePlanner.new(99999)

	# Test multiple positions to find at least one difference
	var found_difference := false
	for i in range(10):
		var pos_x = i * 100
		var pos_y = i * 100
		if planner1.get_biome_at(pos_x, pos_y) != planner2.get_biome_at(pos_x, pos_y):
			found_difference = true
			break

	assert_true(found_difference, "Different seeds should produce different biomes somewhere")


func test_get_biome_at_different_positions():
	# Different positions may have different biomes
	# (testing across a large area to find variation)
	var planner = BiomePlanner.new(12345)

	var biomes_found := {}
	for x in range(0, 1000, 100):
		for y in range(0, 1000, 100):
			var biome = planner.get_biome_at(x, y)
			biomes_found[biome] = true

	# Should find at least 2 different biomes across a large area
	assert_true(biomes_found.size() >= 2, "Should find variation in biomes across large area")


func test_biome_planner_cell_size_constant():
	# BiomePlanner should have CELL_SIZE constant
	assert_eq(BiomePlanner.CELL_SIZE, 128, "CELL_SIZE should be 128")


func test_get_climate_at_returns_normalized_values():
	# get_climate_at should return temperature and humidity in [0, 1] range
	var planner = BiomePlanner.new(12345)
	var climate = planner.get_climate_at(100, 100)

	assert_true(climate.temperature >= 0.0 and climate.temperature <= 1.0,
		"Temperature should be normalized [0, 1]")
	assert_true(climate.humidity >= 0.0 and climate.humidity <= 1.0,
		"Humidity should be normalized [0, 1]")


func test_get_climate_at_deterministic():
	# Same position should return same climate values
	var planner = BiomePlanner.new(12345)

	var climate1 = planner.get_climate_at(200, 300)
	var climate2 = planner.get_climate_at(200, 300)

	assert_eq(climate1.temperature, climate2.temperature, "Temperature should be deterministic")
	assert_eq(climate1.humidity, climate2.humidity, "Humidity should be deterministic")
