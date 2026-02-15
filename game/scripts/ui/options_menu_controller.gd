class_name OptionsMenuController
extends Control
## Options submenu for the pause menu.
##
## Shows Audio, Video, and Controls categories. Video tab contains a
## camera zoom slider (range 1-4, default 1). The Back button emits
## back_pressed so PauseMenuController can return to the main pause
## menu panel.

signal back_pressed

var _is_open: bool = false
var _camera: Camera2D

var _panel: PanelContainer
var _back_button: Button
var _tab_container: TabContainer
var _zoom_slider: HSlider
var _zoom_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	_build_ui()


# =============================================================================
# Public API
# =============================================================================

func open() -> void:
	_is_open = true
	visible = true
	_sync_zoom_slider()


func close() -> void:
	_is_open = false
	visible = false


func is_open() -> bool:
	return _is_open


## Set the Camera2D reference so the zoom slider can control it.
func set_camera(camera: Camera2D) -> void:
	_camera = camera
	_sync_zoom_slider()


## Sync the slider position with the camera's current zoom level.
func _sync_zoom_slider() -> void:
	if _zoom_slider and _camera:
		_zoom_slider.value = _camera.zoom.x


# =============================================================================
# UI Construction
# =============================================================================

func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.name = "OptionsPanel"
	_panel.anchors_preset = Control.PRESET_CENTER
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_panel.custom_minimum_size = Vector2(400, 300)
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "Options"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)

	# Tab container for categories
	_tab_container = TabContainer.new()
	_tab_container.name = "TabContainer"
	_tab_container.custom_minimum_size = Vector2(360, 200)
	vbox.add_child(_tab_container)

	_add_placeholder_tab("Audio", "Audio settings coming soon.")
	_build_video_tab()
	_add_placeholder_tab("Controls", "Control settings coming soon.")

	# Back button
	_back_button = Button.new()
	_back_button.text = "Back"
	_back_button.name = "BackButton"
	_back_button.custom_minimum_size = Vector2(100, 36)
	_back_button.pressed.connect(_on_back)
	vbox.add_child(_back_button)


func _add_placeholder_tab(tab_name: String, placeholder_text: String) -> void:
	var container := MarginContainer.new()
	container.name = tab_name
	container.add_theme_constant_override("margin_left", 16)
	container.add_theme_constant_override("margin_top", 16)
	_tab_container.add_child(container)

	var label := Label.new()
	label.text = placeholder_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	container.add_child(label)


func _build_video_tab() -> void:
	var container := MarginContainer.new()
	container.name = "Video"
	container.add_theme_constant_override("margin_left", 16)
	container.add_theme_constant_override("margin_top", 16)
	_tab_container.add_child(container)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	container.add_child(vbox)

	# Label for the zoom setting
	var title_label := Label.new()
	title_label.text = "Camera Zoom"
	vbox.add_child(title_label)

	# Horizontal row: slider + value label
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	vbox.add_child(hbox)

	_zoom_slider = HSlider.new()
	_zoom_slider.name = "ZoomSlider"
	_zoom_slider.min_value = 1.0
	_zoom_slider.max_value = 4.0
	_zoom_slider.step = 1.0
	_zoom_slider.value = 1.0
	_zoom_slider.custom_minimum_size = Vector2(200, 20)
	_zoom_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_zoom_slider.value_changed.connect(_on_zoom_changed)
	hbox.add_child(_zoom_slider)

	_zoom_label = Label.new()
	_zoom_label.name = "ZoomValueLabel"
	_zoom_label.text = "1x"
	_zoom_label.custom_minimum_size = Vector2(30, 0)
	hbox.add_child(_zoom_label)


func _on_zoom_changed(value: float) -> void:
	_zoom_label.text = "%dx" % int(value)
	if _camera:
		_camera.zoom = Vector2(value, value)


func _on_back() -> void:
	back_pressed.emit()


# =============================================================================
# Getters for testing
# =============================================================================

func get_back_button() -> Button:
	return _back_button

func get_tab_container() -> TabContainer:
	return _tab_container

func get_zoom_slider() -> HSlider:
	return _zoom_slider

func get_zoom_label() -> Label:
	return _zoom_label
