class_name SaveManager
extends Node
## Orchestrates save/load operations for the entire game state
##
## Coordinates entity owners to produce a single JSON save file.
## Each component serializes itself; SaveManager just collects and writes.
## Supports manual save/load and periodic auto-save.

const SAVE_VERSION := "0.1.0"
const SAVE_DIR := "user://saves/"
const DEFAULT_SAVE_FILE := "save.json"
const AUTO_SAVE_INTERVAL := 300.0  # seconds (5 minutes)

signal game_saved(path: String)
signal game_loaded(path: String)
signal save_error(message: String)

var _auto_save_timer: Timer
var _auto_save_enabled: bool = false

## References set by Main before use
var tile_world: TileWorld
var player_inventory: Inventory
var player_node: PlayerController
var scene_tree: SceneTree
var entity_parent: Node


func _ready() -> void:
	_ensure_save_dir()
	_setup_auto_save_timer()


# =============================================================================
# Public API
# =============================================================================

## Save the current game state to the given filename.
## Returns true on success.
func save_game(filename: String = DEFAULT_SAVE_FILE) -> bool:
	if tile_world == null or player_inventory == null or player_node == null:
		save_error.emit("Cannot save: missing game references")
		return false

	var data := _build_save_data()
	var json_string := JSON.stringify(data, "\t")

	var path := SAVE_DIR + filename
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		var err_msg := "Failed to open save file: %s (error %d)" % [path, FileAccess.get_open_error()]
		save_error.emit(err_msg)
		return false

	file.store_string(json_string)
	file.close()

	game_saved.emit(path)
	return true


## Load game state from the given filename.
## Returns the parsed save dictionary, or an empty dictionary on failure.
## The caller (Main) is responsible for applying the loaded state.
func load_game(filename: String = DEFAULT_SAVE_FILE) -> Dictionary:
	var path := SAVE_DIR + filename

	if not FileAccess.file_exists(path):
		save_error.emit("Save file not found: %s" % path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		save_error.emit("Failed to open save file: %s" % path)
		return {}

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_result := json.parse(json_string)
	if parse_result != OK:
		save_error.emit("Failed to parse save file: %s" % json.get_error_message())
		return {}

	var data: Dictionary = json.data
	if not _validate_save_data(data):
		save_error.emit("Invalid save data format")
		return {}

	game_loaded.emit(path)
	return data


## Check if a save file exists
func has_save(filename: String = DEFAULT_SAVE_FILE) -> bool:
	return FileAccess.file_exists(SAVE_DIR + filename)


## Enable or disable auto-save
func set_auto_save(enabled: bool) -> void:
	_auto_save_enabled = enabled
	if enabled:
		_auto_save_timer.start(AUTO_SAVE_INTERVAL)
	else:
		_auto_save_timer.stop()


## Delete a save file. Returns true on success.
func delete_save(filename: String = DEFAULT_SAVE_FILE) -> bool:
	var path := SAVE_DIR + filename
	if FileAccess.file_exists(path):
		var err := DirAccess.remove_absolute(path)
		return err == OK
	return false


# =============================================================================
# Save Data Construction
# =============================================================================

func _build_save_data() -> Dictionary:
	var player_data := player_node.serialize()
	player_data["inventory"] = player_inventory.serialize()

	var data := {
		"version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"world": tile_world.serialize(),
		"player": player_data,
		"entities": _serialize_entities(),
	}
	return data


func _serialize_entities() -> Array:
	if scene_tree == null:
		return []
	return EntitySaver.serialize_all(scene_tree)


# =============================================================================
# Validation
# =============================================================================

func _validate_save_data(data: Dictionary) -> bool:
	if not data.has("version"):
		return false
	if not data.has("world"):
		return false
	if not data.has("player"):
		return false
	return true


# =============================================================================
# Auto-save
# =============================================================================

func _setup_auto_save_timer() -> void:
	_auto_save_timer = Timer.new()
	_auto_save_timer.one_shot = false
	_auto_save_timer.wait_time = AUTO_SAVE_INTERVAL
	_auto_save_timer.timeout.connect(_on_auto_save)
	add_child(_auto_save_timer)


func _on_auto_save() -> void:
	if _auto_save_enabled:
		save_game("autosave.json")


# =============================================================================
# Utilities
# =============================================================================

func _ensure_save_dir() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)
