extends GutTest
## Unit tests for debug console commands

# =============================================================================
# Test Helpers
# =============================================================================

var registry: CommandRegistry
var inventory: Inventory
var tile_world: TileWorld
var context: Dictionary


func before_each() -> void:
	registry = CommandRegistry.new()
	inventory = Inventory.new()
	tile_world = TileWorld.new(42)

	# Register all commands
	registry.register(HelpCommand.new())
	registry.register(ClearCommand.new())
	registry.register(GiveCommand.new())
	registry.register(FlyCommand.new())
	registry.register(NoclipCommand.new())
	registry.register(TeleportCommand.new())
	registry.register(SpawnCommand.new())
	registry.register(SeedCommand.new())
	registry.register(DimensionCommand.new())
	registry.register(GodCommand.new())
	registry.register(SetTimeCommand.new())

	context = {
		"registry": registry,
		"inventory": inventory,
		"world": tile_world,
	}


# =============================================================================
# BaseCommand Tests
# =============================================================================

func test_base_command_defaults():
	var cmd = BaseCommand.new()
	assert_eq(cmd.get_name(), "", "BaseCommand name should be empty")
	assert_eq(cmd.get_description(), "", "BaseCommand description should be empty")
	assert_eq(cmd.get_usage(), "", "BaseCommand usage should be empty")
	assert_eq(cmd.execute([], {}), "Command not implemented.", "BaseCommand should return not implemented")


# =============================================================================
# HelpCommand Tests
# =============================================================================

func test_help_command_name():
	var cmd = HelpCommand.new()
	assert_eq(cmd.get_name(), "help", "Help command name should be 'help'")


func test_help_command_list_all():
	var result = registry.execute("help", context)
	assert_true(result.contains("Available commands"), "Should list available commands header")
	assert_true(result.contains("help"), "Should list help command")
	assert_true(result.contains("give"), "Should list give command")
	assert_true(result.contains("fly"), "Should list fly command")


func test_help_command_specific():
	var result = registry.execute("help give", context)
	assert_true(result.contains("give"), "Should show give command info")
	assert_true(result.contains("Usage"), "Should show usage info")


func test_help_command_unknown():
	var result = registry.execute("help nonexistent", context)
	assert_true(result.contains("Unknown command"), "Should report unknown command")


# =============================================================================
# ClearCommand Tests
# =============================================================================

func test_clear_command_name():
	var cmd = ClearCommand.new()
	assert_eq(cmd.get_name(), "clear", "Clear command name should be 'clear'")


func test_clear_command_returns_empty():
	var result = registry.execute("clear", context)
	assert_eq(result, "", "Clear command should return empty string")


# =============================================================================
# GiveCommand Tests
# =============================================================================

func test_give_command_name():
	var cmd = GiveCommand.new()
	assert_eq(cmd.get_name(), "give", "Give command name should be 'give'")


func test_give_command_no_args():
	var result = registry.execute("give", context)
	assert_true(result.contains("Usage"), "Should show usage when no args")


func test_give_command_single_item():
	var result = registry.execute("give dirt", context)
	assert_true(result.contains("Added"), "Should confirm item added")
	assert_true(result.contains("Dirt"), "Should mention item name")
	assert_true(inventory.has_item(ItemData.ItemType.DIRT, 1), "Inventory should have the item")


func test_give_command_with_count():
	var result = registry.execute("give stone 10", context)
	assert_true(result.contains("Added"), "Should confirm items added")
	assert_true(result.contains("10"), "Should mention count")
	assert_true(inventory.has_item(ItemData.ItemType.STONE, 10), "Inventory should have 10 stones")


func test_give_command_unknown_item():
	var result = registry.execute("give unobtanium", context)
	assert_true(result.contains("Unknown item"), "Should report unknown item")


func test_give_command_multi_word_item():
	var result = registry.execute("give iron ore 5", context)
	assert_true(result.contains("Added"), "Should handle multi-word item names")
	assert_true(inventory.has_item(ItemData.ItemType.IRON_ORE, 5), "Should have iron ore")


func test_give_command_underscore_item():
	var result = registry.execute("give iron_ore 3", context)
	assert_true(result.contains("Added"), "Should handle underscore item names")
	assert_true(inventory.has_item(ItemData.ItemType.IRON_ORE, 3), "Should have iron ore")


func test_give_command_no_inventory():
	var ctx = {"registry": registry}
	var result = registry.execute("give dirt", ctx)
	assert_true(result.contains("Error"), "Should error when no inventory")


# =============================================================================
# FlyCommand Tests
# =============================================================================

func test_fly_command_name():
	var cmd = FlyCommand.new()
	assert_eq(cmd.get_name(), "fly", "Fly command name should be 'fly'")


func test_fly_command_no_player():
	var result = registry.execute("fly", context)
	assert_true(result.contains("Error"), "Should error when no player in context")


# =============================================================================
# NoclipCommand Tests
# =============================================================================

func test_noclip_command_name():
	var cmd = NoclipCommand.new()
	assert_eq(cmd.get_name(), "noclip", "Noclip command name should be 'noclip'")


func test_noclip_command_no_player():
	var result = registry.execute("noclip", context)
	assert_true(result.contains("Error"), "Should error when no player in context")


# =============================================================================
# TeleportCommand Tests
# =============================================================================

func test_tp_command_name():
	var cmd = TeleportCommand.new()
	assert_eq(cmd.get_name(), "tp", "Teleport command name should be 'tp'")


func test_tp_command_no_args():
	var result = registry.execute("tp", context)
	assert_true(result.contains("Usage"), "Should show usage when no args")


func test_tp_command_one_arg():
	var result = registry.execute("tp 5", context)
	assert_true(result.contains("Usage"), "Should require both x and y")


func test_tp_command_non_integer():
	context["player"] = null  # Will be checked after arg validation
	var result = registry.execute("tp abc def", context)
	assert_true(result.contains("Error"), "Should error on non-integer coordinates")


func test_tp_command_no_player():
	var result = registry.execute("tp 10 20", context)
	assert_true(result.contains("Error"), "Should error when no player")


# =============================================================================
# SpawnCommand Tests
# =============================================================================

func test_spawn_command_name():
	var cmd = SpawnCommand.new()
	assert_eq(cmd.get_name(), "spawn", "Spawn command name should be 'spawn'")


func test_spawn_command_no_args():
	var result = registry.execute("spawn", context)
	assert_true(result.contains("Usage"), "Should show usage when no args")


func test_spawn_command_unknown_entity():
	context["player"] = null  # Need player for spawn
	var result = registry.execute("spawn dragon", context)
	assert_true(result.contains("Error") or result.contains("Unknown"), "Should error on unknown entity type")


# =============================================================================
# SeedCommand Tests
# =============================================================================

func test_seed_command_name():
	var cmd = SeedCommand.new()
	assert_eq(cmd.get_name(), "seed", "Seed command name should be 'seed'")


func test_seed_command_shows_seed():
	var result = registry.execute("seed", context)
	assert_true(result.contains("42"), "Should show the world seed value")


func test_seed_command_no_world():
	var ctx = {"registry": registry}
	var result = registry.execute("seed", ctx)
	assert_true(result.contains("Error"), "Should error when no world")


# =============================================================================
# DimensionCommand Tests
# =============================================================================

func test_dim_command_name():
	var cmd = DimensionCommand.new()
	assert_eq(cmd.get_name(), "dim", "Dimension command name should be 'dim'")


func test_dim_command_no_args():
	var result = registry.execute("dim", context)
	assert_true(result.contains("Usage"), "Should show usage when no args")


func test_dim_command_no_system():
	var result = registry.execute("dim 1", context)
	assert_true(result.contains("Error"), "Should error when no dimension system")


func test_dim_command_with_system():
	var dim_system = DimensionSystem.new()
	dim_system.setup(42)
	context["dimension_system"] = dim_system
	var result = registry.execute("dim 0", context)
	assert_true(result.contains("Switched") or result.contains("0"), "Should switch to dimension 0")
	dim_system.free()


func test_dim_command_creates_new():
	var dim_system = DimensionSystem.new()
	dim_system.setup(42)
	context["dimension_system"] = dim_system
	var result = registry.execute("dim 5", context)
	assert_true(result.contains("Switched") or result.contains("5"), "Should create and switch to new dimension")
	assert_true(dim_system.has_dimension(5), "Dimension 5 should exist")
	dim_system.free()


# =============================================================================
# GodCommand Tests
# =============================================================================

func test_god_command_name():
	var cmd = GodCommand.new()
	assert_eq(cmd.get_name(), "god", "God command name should be 'god'")


func test_god_command_placeholder():
	var result = registry.execute("god", context)
	assert_true(result.contains("not yet implemented") or result.contains("toggled"), "God command should indicate placeholder status")


# =============================================================================
# SetTimeCommand Tests
# =============================================================================

func test_set_time_command_name():
	var cmd = SetTimeCommand.new()
	assert_eq(cmd.get_name(), "set_time", "SetTime command name should be 'set_time'")


func test_set_time_command_no_args():
	var result = registry.execute("set_time", context)
	assert_true(result.contains("Usage"), "Should show usage when no args")


func test_set_time_command_non_number():
	var result = registry.execute("set_time abc", context)
	assert_true(result.contains("Error"), "Should error on non-numeric input")


func test_set_time_command_placeholder():
	var result = registry.execute("set_time 12.5", context)
	assert_true(result.contains("not yet implemented") or result.contains("12.5"), "Should indicate placeholder and show value")


# =============================================================================
# All Commands Registered Test
# =============================================================================

func test_all_commands_registered():
	var names = registry.get_command_names()
	assert_true(names.has("help"), "help should be registered")
	assert_true(names.has("clear"), "clear should be registered")
	assert_true(names.has("give"), "give should be registered")
	assert_true(names.has("fly"), "fly should be registered")
	assert_true(names.has("noclip"), "noclip should be registered")
	assert_true(names.has("tp"), "tp should be registered")
	assert_true(names.has("seed"), "seed should be registered")
	assert_true(names.has("dim"), "dim should be registered")
	assert_true(names.has("god"), "god should be registered")
	assert_true(names.has("set_time"), "set_time should be registered")


func test_all_commands_have_name():
	for name in registry.get_command_names():
		var cmd = registry.get_command(name as String)
		assert_ne(cmd.get_name(), "", "Command '%s' should have a non-empty name" % name)


func test_all_commands_have_description():
	for name in registry.get_command_names():
		var cmd = registry.get_command(name as String)
		assert_ne(cmd.get_description(), "", "Command '%s' should have a non-empty description" % name)


func test_all_commands_have_usage():
	for name in registry.get_command_names():
		var cmd = registry.get_command(name as String)
		assert_ne(cmd.get_usage(), "", "Command '%s' should have a non-empty usage" % name)
