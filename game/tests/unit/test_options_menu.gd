extends GutTest

var options_menu: OptionsMenuController
var camera: Camera2D


func before_each() -> void:
	options_menu = OptionsMenuController.new()
	add_child(options_menu)
	await get_tree().process_frame
	# Create a test camera for zoom slider tests
	camera = Camera2D.new()
	camera.zoom = Vector2(1, 1)
	add_child(camera)


func after_each() -> void:
	options_menu.queue_free()
	camera.queue_free()


# =============================================================================
# Initial State
# =============================================================================

func test_starts_closed() -> void:
	assert_false(options_menu.is_open())
	assert_false(options_menu.visible)


func test_process_mode_is_when_paused() -> void:
	assert_eq(options_menu.process_mode, Node.PROCESS_MODE_WHEN_PAUSED)


# =============================================================================
# Open / Close
# =============================================================================

func test_open_shows_menu() -> void:
	options_menu.open()
	assert_true(options_menu.is_open())
	assert_true(options_menu.visible)


func test_close_hides_menu() -> void:
	options_menu.open()
	options_menu.close()
	assert_false(options_menu.is_open())
	assert_false(options_menu.visible)


# =============================================================================
# UI Elements
# =============================================================================

func test_has_back_button() -> void:
	assert_not_null(options_menu.get_back_button())
	assert_eq(options_menu.get_back_button().text, "Back")


func test_has_tab_container() -> void:
	assert_not_null(options_menu.get_tab_container())


func test_has_three_tabs() -> void:
	assert_eq(options_menu.get_tab_container().get_tab_count(), 3)


func test_tab_names() -> void:
	var tabs = options_menu.get_tab_container()
	assert_eq(tabs.get_tab_title(0), "Audio")
	assert_eq(tabs.get_tab_title(1), "Video")
	assert_eq(tabs.get_tab_title(2), "Controls")


# =============================================================================
# Back Button
# =============================================================================

func test_back_button_emits_signal() -> void:
	options_menu.open()
	watch_signals(options_menu)
	options_menu.get_back_button().pressed.emit()
	assert_signal_emitted(options_menu, "back_pressed")


# =============================================================================
# Zoom Slider — UI Elements
# =============================================================================

func test_has_zoom_slider() -> void:
	assert_not_null(options_menu.get_zoom_slider())


func test_has_zoom_label() -> void:
	assert_not_null(options_menu.get_zoom_label())


func test_zoom_slider_default_value() -> void:
	assert_eq(options_menu.get_zoom_slider().value, 1.0)


func test_zoom_slider_range() -> void:
	var slider = options_menu.get_zoom_slider()
	assert_eq(slider.min_value, 1.0)
	assert_eq(slider.max_value, 4.0)
	assert_eq(slider.step, 1.0)


func test_zoom_label_default_text() -> void:
	assert_eq(options_menu.get_zoom_label().text, "1x")


# =============================================================================
# Zoom Slider — Camera Integration
# =============================================================================

func test_set_camera_stores_reference() -> void:
	options_menu.set_camera(camera)
	# Changing slider should now affect the camera
	options_menu.get_zoom_slider().value = 3.0
	assert_eq(camera.zoom, Vector2(3, 3))


func test_zoom_slider_changes_camera_zoom() -> void:
	options_menu.set_camera(camera)
	options_menu.get_zoom_slider().value = 2.0
	assert_eq(camera.zoom, Vector2(2, 2))
	options_menu.get_zoom_slider().value = 4.0
	assert_eq(camera.zoom, Vector2(4, 4))


func test_zoom_slider_updates_label() -> void:
	options_menu.set_camera(camera)
	options_menu.get_zoom_slider().value = 3.0
	assert_eq(options_menu.get_zoom_label().text, "3x")


func test_zoom_slider_without_camera_does_not_crash() -> void:
	# No camera set — should not error
	options_menu.get_zoom_slider().value = 2.0
	assert_eq(options_menu.get_zoom_label().text, "2x")


func test_open_syncs_slider_to_camera() -> void:
	camera.zoom = Vector2(3, 3)
	options_menu.set_camera(camera)
	options_menu.open()
	assert_eq(options_menu.get_zoom_slider().value, 3.0)


func test_set_camera_syncs_slider() -> void:
	camera.zoom = Vector2(2, 2)
	options_menu.set_camera(camera)
	assert_eq(options_menu.get_zoom_slider().value, 2.0)
