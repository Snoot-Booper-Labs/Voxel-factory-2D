class_name SpriteDB
extends Resource
## Static database mapping ItemTypes to icon atlas regions and entity sprite paths.
##
## Uses load() + FileAccess.file_exists() pattern (matching world_renderer.gd)
## for headless/CI safety. Swapping any PNG with a same-dimension replacement
## requires zero code changes.

# =============================================================================
# Constants
# =============================================================================

## Path to the item icon atlas (8 columns × 4 rows, 16×16 per cell)
const ITEM_ICON_ATLAS_PATH := "res://resources/icons/items/item_icon_atlas.png"

## Icon cell size in pixels
const ICON_SIZE := 16

## Atlas grid dimensions
const ATLAS_COLUMNS := 8
const ATLAS_ROWS := 4

## Entity sprite sheet paths
const ENTITY_SPRITES := {
	"miner_body": "res://resources/sprites/entities/miner_body.png",
	"miner_head": "res://resources/sprites/entities/miner_head.png",
	"conveyor": "res://resources/sprites/entities/conveyor.png",
	"item_entity": "res://resources/sprites/entities/item_entity.png",
}


# =============================================================================
# Item Icon Atlas Layout
# =============================================================================

## Maps ItemData.ItemType → Vector2i(column, row) in the icon atlas.
## Missing entries get a fallback color-rect icon.
static var _icon_positions: Dictionary = {
	# Row 0: Block items
	ItemData.ItemType.NONE: Vector2i(0, 0),
	ItemData.ItemType.DIRT: Vector2i(1, 0),
	ItemData.ItemType.STONE: Vector2i(2, 0),
	ItemData.ItemType.WOOD: Vector2i(3, 0),
	ItemData.ItemType.LEAVES: Vector2i(4, 0),
	ItemData.ItemType.SAND: Vector2i(5, 0),
	ItemData.ItemType.GRASS: Vector2i(6, 0),
	ItemData.ItemType.COBBLESTONE: Vector2i(7, 0),
	# Row 1: More blocks + entities
	ItemData.ItemType.PLANKS: Vector2i(0, 1),
	ItemData.ItemType.BEDROCK: Vector2i(1, 1),
	ItemData.ItemType.MINER: Vector2i(2, 1),
	ItemData.ItemType.CONVEYOR: Vector2i(3, 1),
	# Row 2: Materials
	ItemData.ItemType.COAL: Vector2i(0, 2),
	ItemData.ItemType.IRON_ORE: Vector2i(1, 2),
	ItemData.ItemType.GOLD_ORE: Vector2i(2, 2),
	ItemData.ItemType.IRON_INGOT: Vector2i(3, 2),
	ItemData.ItemType.GOLD_INGOT: Vector2i(4, 2),
	ItemData.ItemType.DIAMOND: Vector2i(5, 2),
	# Row 3: Tools
	ItemData.ItemType.WOODEN_PICKAXE: Vector2i(0, 3),
	ItemData.ItemType.STONE_PICKAXE: Vector2i(1, 3),
	ItemData.ItemType.IRON_PICKAXE: Vector2i(2, 3),
	ItemData.ItemType.WOODEN_AXE: Vector2i(3, 3),
	ItemData.ItemType.STONE_AXE: Vector2i(4, 3),
	ItemData.ItemType.IRON_AXE: Vector2i(5, 3),
	ItemData.ItemType.WOODEN_SHOVEL: Vector2i(6, 3),
	ItemData.ItemType.STONE_SHOVEL: Vector2i(7, 3),
	ItemData.ItemType.IRON_SHOVEL: Vector2i(7, 3),  # shares last cell (will get own when atlas expands)
}


# =============================================================================
# Cached atlas texture
# =============================================================================

static var _atlas_texture: Texture2D = null
static var _atlas_loaded: bool = false


static func _load_atlas() -> void:
	if _atlas_loaded:
		return
	_atlas_loaded = true
	if FileAccess.file_exists(ITEM_ICON_ATLAS_PATH):
		_atlas_texture = load(ITEM_ICON_ATLAS_PATH)


# =============================================================================
# Public API
# =============================================================================

## Returns an AtlasTexture for the given item type's icon.
## Returns null if the atlas is unavailable (headless mode) or item type unknown.
static func get_item_icon(item_type: int) -> AtlasTexture:
	_load_atlas()
	if _atlas_texture == null:
		return null
	if not _icon_positions.has(item_type):
		return null

	var grid_pos: Vector2i = _icon_positions[item_type]
	var atlas := AtlasTexture.new()
	atlas.atlas = _atlas_texture
	atlas.region = Rect2(
		grid_pos.x * ICON_SIZE,
		grid_pos.y * ICON_SIZE,
		ICON_SIZE,
		ICON_SIZE
	)
	return atlas


## Returns the atlas grid position for an item type, or Vector2i(-1, -1) if unknown.
static func get_icon_position(item_type: int) -> Vector2i:
	if _icon_positions.has(item_type):
		return _icon_positions[item_type]
	return Vector2i(-1, -1)


## Returns true if the item type has a registered icon position.
static func has_icon(item_type: int) -> bool:
	return _icon_positions.has(item_type)


## Load an entity sprite sheet by key (e.g. "miner_body", "conveyor").
## Returns null if file not found (headless safety).
static func get_entity_sprite(sprite_key: String) -> Texture2D:
	if not ENTITY_SPRITES.has(sprite_key):
		return null
	var path: String = ENTITY_SPRITES[sprite_key]
	if not FileAccess.file_exists(path):
		return null
	return load(path)



## Returns the number of registered icon positions (for testing).
static func get_icon_count() -> int:
	return _icon_positions.size()


## Reset cached atlas (useful for testing).
static func _reset_cache() -> void:
	_atlas_texture = null
	_atlas_loaded = false
