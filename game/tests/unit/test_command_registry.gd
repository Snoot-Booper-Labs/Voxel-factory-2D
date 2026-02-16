extends GutTest
## Unit tests for CommandRegistry — command registration, parsing, and execution

# =============================================================================
# Test Helpers
# =============================================================================

class MockCommand extends BaseCommand:
	var _name: String
	var _desc: String
	var _usage: String
	var _result: String
	var last_args: Array = []
	var last_context: Dictionary = {}
	var call_count: int = 0

	func _init(cmd_name: String = "mock", desc: String = "A mock command", usage: String = "mock [args]", result: String = "mock result") -> void:
		_name = cmd_name
		_desc = desc
		_usage = usage
		_result = result

	func get_name() -> String:
		return _name

	func get_description() -> String:
		return _desc

	func get_usage() -> String:
		return _usage

	func execute(args: Array, context: Dictionary) -> String:
		last_args = args
		last_context = context
		call_count += 1
		return _result


var registry: CommandRegistry


func before_each() -> void:
	registry = CommandRegistry.new()


# =============================================================================
# Registration Tests
# =============================================================================

func test_registry_exists():
	assert_not_null(registry, "CommandRegistry should be instantiable")


func test_register_command():
	var cmd = MockCommand.new("test")
	registry.register(cmd)
	assert_true(registry.has_command("test"), "Should have registered command")


func test_register_multiple_commands():
	registry.register(MockCommand.new("cmd1"))
	registry.register(MockCommand.new("cmd2"))
	registry.register(MockCommand.new("cmd3"))
	assert_true(registry.has_command("cmd1"), "Should have cmd1")
	assert_true(registry.has_command("cmd2"), "Should have cmd2")
	assert_true(registry.has_command("cmd3"), "Should have cmd3")


func test_register_empty_name_ignored():
	var cmd = MockCommand.new("")
	registry.register(cmd)
	assert_eq(registry.get_command_names().size(), 0, "Empty name command should not be registered")


func test_register_overwrites_existing():
	var cmd1 = MockCommand.new("test", "first")
	var cmd2 = MockCommand.new("test", "second")
	registry.register(cmd1)
	registry.register(cmd2)
	var result = registry.get_command("test")
	assert_eq(result.get_description(), "second", "Should overwrite existing command")


func test_unregister_command():
	registry.register(MockCommand.new("test"))
	var removed = registry.unregister("test")
	assert_true(removed, "Unregister should return true for existing command")
	assert_false(registry.has_command("test"), "Command should be removed")


func test_unregister_nonexistent():
	var removed = registry.unregister("nonexistent")
	assert_false(removed, "Unregister should return false for nonexistent command")


func test_has_command_false():
	assert_false(registry.has_command("nothing"), "Should return false for unregistered command")


func test_get_command_returns_instance():
	var cmd = MockCommand.new("test")
	registry.register(cmd)
	var result = registry.get_command("test")
	assert_eq(result, cmd, "Should return the registered command instance")


func test_get_command_returns_null():
	var result = registry.get_command("nothing")
	assert_null(result, "Should return null for unregistered command")


# =============================================================================
# Command Names Tests
# =============================================================================

func test_get_command_names_empty():
	var names = registry.get_command_names()
	assert_eq(names.size(), 0, "Should return empty array when no commands")


func test_get_command_names_sorted():
	registry.register(MockCommand.new("zebra"))
	registry.register(MockCommand.new("alpha"))
	registry.register(MockCommand.new("middle"))
	var names = registry.get_command_names()
	assert_eq(names.size(), 3, "Should return all command names")
	assert_eq(names[0], "alpha", "Names should be sorted alphabetically")
	assert_eq(names[1], "middle", "Names should be sorted alphabetically")
	assert_eq(names[2], "zebra", "Names should be sorted alphabetically")


# =============================================================================
# Execution Tests
# =============================================================================

func test_execute_empty_input():
	var result = registry.execute("", {})
	assert_eq(result, "", "Empty input should return empty string")


func test_execute_whitespace_only():
	var result = registry.execute("   ", {})
	assert_eq(result, "", "Whitespace-only input should return empty string")


func test_execute_unknown_command():
	var result = registry.execute("unknown", {})
	assert_true(result.contains("Unknown command"), "Should return error for unknown command")


func test_execute_simple_command():
	var cmd = MockCommand.new("test", "", "", "success")
	registry.register(cmd)
	var result = registry.execute("test", {})
	assert_eq(result, "success", "Should return command result")
	assert_eq(cmd.call_count, 1, "Command should be called once")


func test_execute_passes_args():
	var cmd = MockCommand.new("test")
	registry.register(cmd)
	registry.execute("test arg1 arg2 arg3", {})
	assert_eq(cmd.last_args.size(), 3, "Should pass 3 arguments")
	assert_eq(cmd.last_args[0], "arg1", "First arg should be 'arg1'")
	assert_eq(cmd.last_args[1], "arg2", "Second arg should be 'arg2'")
	assert_eq(cmd.last_args[2], "arg3", "Third arg should be 'arg3'")


func test_execute_passes_context():
	var cmd = MockCommand.new("test")
	registry.register(cmd)
	var ctx = {"key": "value"}
	registry.execute("test", ctx)
	assert_eq(cmd.last_context["key"], "value", "Should pass context to command")


func test_execute_case_insensitive():
	var cmd = MockCommand.new("test", "", "", "found")
	registry.register(cmd)
	var result = registry.execute("TEST", {})
	assert_eq(result, "found", "Command lookup should be case-insensitive")


func test_execute_strips_edges():
	var cmd = MockCommand.new("test", "", "", "found")
	registry.register(cmd)
	var result = registry.execute("  test  ", {})
	assert_eq(result, "found", "Should strip whitespace from input")


func test_execute_no_args():
	var cmd = MockCommand.new("test")
	registry.register(cmd)
	registry.execute("test", {})
	assert_eq(cmd.last_args.size(), 0, "Should pass empty args array when no arguments")


func test_execute_multiple_spaces_between_args():
	var cmd = MockCommand.new("test")
	registry.register(cmd)
	registry.execute("test  arg1   arg2", {})
	assert_eq(cmd.last_args.size(), 2, "Should split on multiple spaces correctly")
	assert_eq(cmd.last_args[0], "arg1", "First arg should be correct")
	assert_eq(cmd.last_args[1], "arg2", "Second arg should be correct")


# =============================================================================
# Tab Completion Tests
# =============================================================================

func test_get_completions_empty_registry():
	var matches = registry.get_completions("h")
	assert_eq(matches.size(), 0, "Should return no matches for empty registry")


func test_get_completions_no_match():
	registry.register(MockCommand.new("help"))
	var matches = registry.get_completions("z")
	assert_eq(matches.size(), 0, "Should return no matches for unmatched prefix")


func test_get_completions_single_match():
	registry.register(MockCommand.new("help"))
	registry.register(MockCommand.new("give"))
	var matches = registry.get_completions("h")
	assert_eq(matches.size(), 1, "Should return one match")
	assert_eq(matches[0], "help", "Should return matching command")


func test_get_completions_multiple_matches():
	registry.register(MockCommand.new("give"))
	registry.register(MockCommand.new("god"))
	registry.register(MockCommand.new("help"))
	var matches = registry.get_completions("g")
	assert_eq(matches.size(), 2, "Should return two matches")
	assert_eq(matches[0], "give", "Matches should be sorted")
	assert_eq(matches[1], "god", "Matches should be sorted")


func test_get_completions_exact_match():
	registry.register(MockCommand.new("help"))
	var matches = registry.get_completions("help")
	assert_eq(matches.size(), 1, "Exact match should return one result")


func test_get_completions_case_insensitive():
	registry.register(MockCommand.new("help"))
	var matches = registry.get_completions("H")
	assert_eq(matches.size(), 1, "Completion should be case-insensitive")
	assert_eq(matches[0], "help", "Should return matching command name")
