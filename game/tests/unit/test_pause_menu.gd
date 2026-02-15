extends GutTest

var pause_menu: PauseMenuController


func before_each() -> void:
	pause_menu = PauseMenuController.new()
	add_child(pause_menu)
	await get_tree().process_frame
	# Ensure game is unpaused before each test
	get_tree().paused = false


func after_each() -> void:
	# Ensure game is unpaused after each test so GUT can continue
	get_tree().paused = false
	pause_menu.queue_free()


# =============================================================================
# Initial State
# =============================================================================

func test_starts_closed() -> void:
	assert_false(pause_menu.is_open())
	assert_false(pause_menu.visible)


func test_starts_with_game_unpaused() -> void:
	assert_false(get_tree().paused)


# =============================================================================
# Open / Close
# =============================================================================

func test_open_shows_menu() -> void:
	pause_menu.open()
	assert_true(pause_menu.is_open())
	assert_true(pause_menu.visible)


func test_open_pauses_game() -> void:
	pause_menu.open()
	assert_true(get_tree().paused)


func test_close_hides_menu() -> void:
	pause_menu.open()
	pause_menu.close()
	assert_false(pause_menu.is_open())
	assert_false(pause_menu.visible)


func test_close_unpauses_game() -> void:
	pause_menu.open()
	pause_menu.close()
	assert_false(get_tree().paused)


func test_toggle_opens_when_closed() -> void:
	pause_menu.toggle()
	assert_true(pause_menu.is_open())
	assert_true(get_tree().paused)


func test_toggle_closes_when_open() -> void:
	pause_menu.open()
	pause_menu.toggle()
	assert_false(pause_menu.is_open())
	assert_false(get_tree().paused)


func test_open_twice_does_not_error() -> void:
	pause_menu.open()
	pause_menu.open()
	assert_true(pause_menu.is_open())


func test_close_twice_does_not_error() -> void:
	pause_menu.open()
	pause_menu.close()
	pause_menu.close()
	assert_false(pause_menu.is_open())


# =============================================================================
# Process Mode
# =============================================================================

func test_process_mode_is_when_paused() -> void:
	assert_eq(pause_menu.process_mode, Node.PROCESS_MODE_WHEN_PAUSED)


# =============================================================================
# UI Elements Exist
# =============================================================================

func test_has_resume_button() -> void:
	assert_not_null(pause_menu.get_resume_button())
	assert_eq(pause_menu.get_resume_button().text, "Resume")


func test_has_save_button() -> void:
	assert_not_null(pause_menu.get_save_button())
	assert_eq(pause_menu.get_save_button().text, "Save")


func test_has_load_button() -> void:
	assert_not_null(pause_menu.get_load_button())
	assert_eq(pause_menu.get_load_button().text, "Load")


func test_has_options_button() -> void:
	assert_not_null(pause_menu.get_options_button())
	assert_eq(pause_menu.get_options_button().text, "Options")


func test_has_exit_button() -> void:
	assert_not_null(pause_menu.get_exit_button())
	assert_eq(pause_menu.get_exit_button().text, "Exit")


func test_has_confirm_dialog() -> void:
	assert_not_null(pause_menu.get_confirm_dialog())


# =============================================================================
# Resume Button
# =============================================================================

func test_resume_button_closes_menu() -> void:
	pause_menu.open()
	pause_menu.get_resume_button().pressed.emit()
	assert_false(pause_menu.is_open())
	assert_false(get_tree().paused)


# =============================================================================
# Save Button
# =============================================================================

func test_save_button_emits_save_requested() -> void:
	pause_menu.open()
	watch_signals(pause_menu)
	pause_menu.get_save_button().pressed.emit()
	assert_signal_emitted(pause_menu, "save_requested")


func test_save_button_keeps_menu_open() -> void:
	pause_menu.open()
	pause_menu.get_save_button().pressed.emit()
	assert_true(pause_menu.is_open(), "Menu should stay open after save")


# =============================================================================
# Load Button
# =============================================================================

func test_load_button_emits_load_requested() -> void:
	pause_menu.open()
	watch_signals(pause_menu)
	pause_menu.get_load_button().pressed.emit()
	assert_signal_emitted(pause_menu, "load_requested")


func test_load_button_closes_menu() -> void:
	pause_menu.open()
	pause_menu.get_load_button().pressed.emit()
	assert_false(pause_menu.is_open(), "Menu should close after load")


# =============================================================================
# Options Submenu
# =============================================================================

func test_options_button_hides_main_panel() -> void:
	pause_menu.open()
	pause_menu.get_options_button().pressed.emit()
	assert_false(pause_menu._panel.visible, "Main panel should hide when options opens")


func test_options_button_opens_options_menu() -> void:
	pause_menu.open()
	pause_menu.get_options_button().pressed.emit()
	assert_true(pause_menu.is_options_open(), "Options menu should be open")


func test_options_back_restores_main_panel() -> void:
	pause_menu.open()
	pause_menu.get_options_button().pressed.emit()
	pause_menu.get_options_menu().get_back_button().pressed.emit()
	assert_true(pause_menu._panel.visible, "Main panel should be visible after options back")
	assert_false(pause_menu.is_options_open(), "Options should be closed")


func test_close_while_options_open_closes_everything() -> void:
	pause_menu.open()
	pause_menu.get_options_button().pressed.emit()
	pause_menu.close()
	assert_false(pause_menu.is_open())
	assert_false(pause_menu.is_options_open())
	assert_false(get_tree().paused)


# =============================================================================
# Exit Confirmation
# =============================================================================

func test_exit_button_shows_confirmation() -> void:
	pause_menu.open()
	pause_menu.get_exit_button().pressed.emit()
	assert_true(pause_menu.get_confirm_dialog().visible, "Confirm dialog should be visible")


# =============================================================================
# Save Feedback
# =============================================================================

func test_save_feedback_shows_success() -> void:
	pause_menu.open()
	pause_menu.show_save_feedback(true)
	var label = pause_menu.get_save_feedback_label()
	assert_true(label.visible)
	assert_eq(label.text, "Game saved!")


func test_save_feedback_shows_failure() -> void:
	pause_menu.open()
	pause_menu.show_save_feedback(false)
	var label = pause_menu.get_save_feedback_label()
	assert_true(label.visible)
	assert_eq(label.text, "Save failed!")
