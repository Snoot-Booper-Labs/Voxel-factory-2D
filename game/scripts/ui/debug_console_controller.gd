## Debug console UI controller
## Handles show/hide, text input, command history, tab completion, and output display
class_name DebugConsoleController
extends PanelContainer

# =============================================================================
# Constants
# =============================================================================

const MAX_HISTORY_SIZE = 50
const MAX_OUTPUT_LINES = 200

# =============================================================================
# Signals
# =============================================================================

signal console_opened
signal console_closed

# =============================================================================
# Properties
# =============================================================================

var command_registry: CommandRegistry
var _context: Dictionary = {}
var _history: Array[String] = []
var _history_index: int = -1
var _current_input: String = ""

## UI nodes built in _ready
var _output_label: RichTextLabel
var _input_field: LineEdit

# =============================================================================
# Lifecycle
# =============================================================================

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()


func _build_ui() -> void:
	# Configure the PanelContainer itself
	custom_minimum_size = Vector2(0, 300)

	# Use anchors to fill the top of the screen
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 0.0
	offset_bottom = 300

	# Add a StyleBoxFlat for background
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.1, 0.9)
	style.border_color = Color(0.3, 0.3, 0.5, 0.8)
	style.border_width_bottom = 2
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	add_theme_stylebox_override("panel", style)

	# VBoxContainer for layout
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(vbox)

	# Output area (scrollable rich text)
	_output_label = RichTextLabel.new()
	_output_label.bbcode_enabled = true
	_output_label.scroll_following = true
	_output_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_output_label.add_theme_color_override("default_color", Color(0.8, 0.9, 0.8))
	_output_label.add_theme_font_size_override("normal_font_size", 14)
	vbox.add_child(_output_label)

	# Input field
	_input_field = LineEdit.new()
	_input_field.placeholder_text = "Enter command..."
	_input_field.custom_minimum_size = Vector2(0, 30)

	var input_style := StyleBoxFlat.new()
	input_style.bg_color = Color(0.08, 0.08, 0.15, 1.0)
	input_style.border_color = Color(0.3, 0.4, 0.6, 0.8)
	input_style.border_width_top = 1
	input_style.content_margin_left = 8
	input_style.content_margin_right = 8
	_input_field.add_theme_stylebox_override("normal", input_style)
	_input_field.add_theme_color_override("font_color", Color(0.9, 1.0, 0.9))
	_input_field.add_theme_font_size_override("font_size", 14)

	_input_field.text_submitted.connect(_on_input_submitted)
	vbox.add_child(_input_field)

	# Print welcome message
	_append_output("[color=cyan]Debug Console[/color] — Type [color=yellow]help[/color] for available commands.")


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventKey and event.pressed:
		match event.physical_keycode:
			KEY_UP:
				_navigate_history(-1)
				get_viewport().set_input_as_handled()
			KEY_DOWN:
				_navigate_history(1)
				get_viewport().set_input_as_handled()
			KEY_TAB:
				_handle_tab_completion()
				get_viewport().set_input_as_handled()
			KEY_ESCAPE:
				close()
				get_viewport().set_input_as_handled()


# =============================================================================
# Public API
# =============================================================================

## Setup the console with a registry and context
func setup(registry: CommandRegistry, context: Dictionary) -> void:
	command_registry = registry
	_context = context


## Update the context dictionary (called when game state changes)
func set_context(context: Dictionary) -> void:
	_context = context


## Open the console overlay
func open() -> void:
	if visible:
		return
	visible = true
	_input_field.grab_focus()
	_input_field.clear()
	_history_index = -1
	console_opened.emit()


## Close the console overlay
func close() -> void:
	if not visible:
		return
	visible = false
	_input_field.release_focus()
	console_closed.emit()


## Toggle the console open/closed
func toggle() -> void:
	if visible:
		close()
	else:
		open()


## Returns true if the console is currently visible
func is_open() -> bool:
	return visible


## Append text to the output area
func append_output(text: String) -> void:
	_append_output(text)


## Clear all output text
func clear_output() -> void:
	if _output_label:
		_output_label.clear()


# =============================================================================
# Private Methods
# =============================================================================

func _append_output(text: String) -> void:
	if _output_label == null:
		return
	_output_label.append_text(text + "\n")


func _on_input_submitted(text: String) -> void:
	if text.strip_edges().is_empty():
		_input_field.clear()
		return

	# Echo the command
	_append_output("[color=gray]> %s[/color]" % text)

	# Add to history
	if _history.is_empty() or _history[0] != text:
		_history.insert(0, text)
		if _history.size() > MAX_HISTORY_SIZE:
			_history.resize(MAX_HISTORY_SIZE)
	_history_index = -1

	# Execute
	if command_registry:
		# Pass console reference in context so commands can access clear_output etc.
		_context["console"] = self
		var result := command_registry.execute(text, _context)
		if not result.is_empty():
			_append_output(result)

	_input_field.clear()


func _navigate_history(direction: int) -> void:
	if _history.is_empty():
		return

	if _history_index == -1 and direction == -1:
		# Save current input before navigating
		_current_input = _input_field.text
		_history_index = 0
	elif direction == -1:
		_history_index = mini(_history_index + 1, _history.size() - 1)
	elif direction == 1:
		_history_index = maxi(_history_index - 1, -1)

	if _history_index == -1:
		_input_field.text = _current_input
	else:
		_input_field.text = _history[_history_index]

	# Move caret to end
	_input_field.caret_column = _input_field.text.length()


func _handle_tab_completion() -> void:
	if command_registry == null:
		return

	var text := _input_field.text.strip_edges()
	if text.is_empty():
		return

	# Only complete the first word (command name)
	var parts := text.split(" ", false)
	if parts.size() > 1:
		return  # Don't tab-complete arguments

	var matches := command_registry.get_completions(parts[0])
	if matches.size() == 1:
		_input_field.text = matches[0] + " "
		_input_field.caret_column = _input_field.text.length()
	elif matches.size() > 1:
		_append_output("[color=gray]%s[/color]" % "  ".join(matches))
		# Complete to longest common prefix
		var prefix := _find_common_prefix(matches)
		if prefix.length() > parts[0].length():
			_input_field.text = prefix
			_input_field.caret_column = _input_field.text.length()


func _find_common_prefix(strings: Array) -> String:
	if strings.is_empty():
		return ""
	var prefix: String = strings[0]
	for i in range(1, strings.size()):
		var s: String = strings[i]
		var j := 0
		while j < prefix.length() and j < s.length() and prefix[j] == s[j]:
			j += 1
		prefix = prefix.substr(0, j)
	return prefix
