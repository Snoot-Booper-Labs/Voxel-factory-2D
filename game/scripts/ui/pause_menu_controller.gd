class_name PauseMenuController
extends Control
## System menu that pauses the game and shows Resume/Save/Load/Options/Exit.
##
## Uses get_tree().paused to freeze gameplay while keeping this menu
## interactive via PROCESS_MODE_WHEN_PAUSED. Emits signals so Main can
## delegate Save/Load to the existing SaveManager.

signal save_requested
signal load_requested

var _is_open: bool = false
var _options_menu: OptionsMenuController

# UI references (set after _ready or by the scene tree)
var _overlay: ColorRect
var _panel: PanelContainer
var _resume_button: Button
var _save_button: Button
var _load_button: Button
var _options_button: Button
var _exit_button: Button
var _confirm_dialog: ConfirmationDialog
var _save_feedback_label: Label
var _save_feedback_timer: Timer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	_build_ui()


# =============================================================================
# Public API
# =============================================================================

## Show the pause menu and pause the game.
func open() -> void:
	if _is_open:
		return
	_is_open = true
	visible = true
	get_tree().paused = true


## Hide the pause menu and unpause the game.
func close() -> void:
	if not _is_open:
		return
	# Close options submenu if it's showing
	if _options_menu and _options_menu.is_open():
		_options_menu.close()
	_is_open = false
	visible = false
	get_tree().paused = false


## Toggle the pause menu open/closed.
func toggle() -> void:
	if _is_open:
		close()
	else:
		open()


## Whether the pause menu is currently displayed.
func is_open() -> bool:
	return _is_open


## Whether the options submenu is currently displayed.
func is_options_open() -> bool:
	return _options_menu != null and _options_menu.is_open()


## Set the Camera2D reference, forwarded to the options menu for zoom control.
func set_camera(camera: Camera2D) -> void:
	if _options_menu:
		_options_menu.set_camera(camera)


# =============================================================================
# UI Construction
# =============================================================================

func _build_ui() -> void:
	# Semi-transparent fullscreen overlay
	_overlay = ColorRect.new()
	_overlay.name = "Overlay"
	_overlay.color = Color(0, 0, 0, 0.5)
	_overlay.anchors_preset = Control.PRESET_FULL_RECT
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)

	# Centered panel
	_panel = PanelContainer.new()
	_panel.name = "MenuPanel"
	_panel.anchors_preset = Control.PRESET_CENTER
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_panel.custom_minimum_size = Vector2(300, 300)
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "ButtonColumn"
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	# Buttons
	_resume_button = _make_button("Resume", vbox)
	_save_button = _make_button("Save", vbox)
	_load_button = _make_button("Load", vbox)
	_options_button = _make_button("Options", vbox)
	_exit_button = _make_button("Exit", vbox)

	_resume_button.pressed.connect(_on_resume)
	_save_button.pressed.connect(_on_save)
	_load_button.pressed.connect(_on_load)
	_options_button.pressed.connect(_on_options)
	_exit_button.pressed.connect(_on_exit)

	# Save feedback label (hidden by default)
	_save_feedback_label = Label.new()
	_save_feedback_label.name = "SaveFeedback"
	_save_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_save_feedback_label.add_theme_font_size_override("font_size", 14)
	_save_feedback_label.visible = false
	vbox.add_child(_save_feedback_label)

	# Timer for hiding save feedback
	_save_feedback_timer = Timer.new()
	_save_feedback_timer.name = "SaveFeedbackTimer"
	_save_feedback_timer.one_shot = true
	_save_feedback_timer.wait_time = 2.0
	_save_feedback_timer.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_save_feedback_timer.timeout.connect(_hide_save_feedback)
	add_child(_save_feedback_timer)

	# Exit confirmation dialog
	_confirm_dialog = ConfirmationDialog.new()
	_confirm_dialog.name = "ExitConfirmDialog"
	_confirm_dialog.title = "Exit Game"
	_confirm_dialog.dialog_text = "Are you sure you want to exit?"
	_confirm_dialog.ok_button_text = "Exit"
	_confirm_dialog.cancel_button_text = "Cancel"
	_confirm_dialog.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_confirm_dialog.confirmed.connect(_on_exit_confirmed)
	add_child(_confirm_dialog)

	# Options submenu (starts hidden)
	_options_menu = OptionsMenuController.new()
	_options_menu.name = "OptionsMenu"
	_options_menu.back_pressed.connect(_on_options_back)
	add_child(_options_menu)


func _make_button(label: String, parent: VBoxContainer) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.name = label + "Button"
	btn.custom_minimum_size = Vector2(220, 40)
	parent.add_child(btn)
	return btn


# =============================================================================
# Button Handlers
# =============================================================================

func _on_resume() -> void:
	close()


func _on_save() -> void:
	save_requested.emit()


func _on_load() -> void:
	load_requested.emit()
	close()


func _on_options() -> void:
	_panel.visible = false
	_options_menu.open()


func _on_options_back() -> void:
	_options_menu.close()
	_panel.visible = true


func _on_exit() -> void:
	_confirm_dialog.popup_centered()


func _on_exit_confirmed() -> void:
	get_tree().quit()


# =============================================================================
# Save Feedback
# =============================================================================

## Show a brief feedback message after save completes.
func show_save_feedback(success: bool) -> void:
	if success:
		_save_feedback_label.text = "Game saved!"
		_save_feedback_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	else:
		_save_feedback_label.text = "Save failed!"
		_save_feedback_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	_save_feedback_label.visible = true
	_save_feedback_timer.start()


func _hide_save_feedback() -> void:
	_save_feedback_label.visible = false


# =============================================================================
# Getters for testing
# =============================================================================

func get_resume_button() -> Button:
	return _resume_button

func get_save_button() -> Button:
	return _save_button

func get_load_button() -> Button:
	return _load_button

func get_options_button() -> Button:
	return _options_button

func get_exit_button() -> Button:
	return _exit_button

func get_confirm_dialog() -> ConfirmationDialog:
	return _confirm_dialog

func get_options_menu() -> OptionsMenuController:
	return _options_menu

func get_save_feedback_label() -> Label:
	return _save_feedback_label
