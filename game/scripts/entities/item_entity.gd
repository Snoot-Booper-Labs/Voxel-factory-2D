## ItemEntity - A visual item that exists in the game world
## Can be picked up by the player, output from miners, or ride conveyor belts.
## Nearby items of the same type merge (stack) on the ground.
## Despawns after a configurable timeout.
class_name ItemEntity
extends Area2D

# =============================================================================
# Signals
# =============================================================================
signal picked_up(item_type: int, count: int)
signal despawned(item_type: int, count: int)
signal merged(item_type: int, new_count: int)

# =============================================================================
# Constants
# =============================================================================

## How close two items must be (in pixels) to merge
const MERGE_RADIUS: float = 24.0

## How often to check for nearby items to merge with (seconds)
const MERGE_CHECK_INTERVAL: float = 0.5

## Default time before a dropped item despawns (seconds). 0 = never.
const DEFAULT_DESPAWN_TIME: float = 300.0

## Short pickup immunity after spawning so the player doesn't instantly grab drops
const PICKUP_DELAY: float = 0.5

## Bobbing animation amplitude (pixels)
const BOB_AMPLITUDE: float = 2.0

## Bobbing animation speed (radians per second)
const BOB_SPEED: float = 3.0

## Size of the item sprite (pixels, square)
const SPRITE_SIZE: float = 10.0

## Item-type to color mapping for visual representation
## Until real sprite assets exist, each item type gets a distinct color.
static var _item_colors: Dictionary = {
	ItemData.ItemType.DIRT: Color(0.55, 0.35, 0.18),
	ItemData.ItemType.STONE: Color(0.5, 0.5, 0.5),
	ItemData.ItemType.WOOD: Color(0.55, 0.35, 0.05),
	ItemData.ItemType.LEAVES: Color(0.2, 0.55, 0.15),
	ItemData.ItemType.SAND: Color(0.85, 0.8, 0.55),
	ItemData.ItemType.GRASS: Color(0.3, 0.6, 0.2),
	ItemData.ItemType.COBBLESTONE: Color(0.45, 0.45, 0.45),
	ItemData.ItemType.PLANKS: Color(0.7, 0.5, 0.25),
	ItemData.ItemType.BEDROCK: Color(0.2, 0.2, 0.2),
	ItemData.ItemType.COAL: Color(0.15, 0.15, 0.15),
	ItemData.ItemType.IRON_ORE: Color(0.7, 0.55, 0.45),
	ItemData.ItemType.GOLD_ORE: Color(0.85, 0.75, 0.2),
	ItemData.ItemType.IRON_INGOT: Color(0.75, 0.75, 0.75),
	ItemData.ItemType.GOLD_INGOT: Color(0.95, 0.85, 0.15),
	ItemData.ItemType.DIAMOND: Color(0.4, 0.85, 0.9),
}

# =============================================================================
# Properties
# =============================================================================

## The type of item this entity represents
var item_type: int = ItemData.ItemType.NONE

## How many of this item are stacked
var count: int = 1

## Whether this item can currently be picked up
var _pickup_ready: bool = false

## Time accumulator for bobbing animation
var _bob_time: float = 0.0

## Base Y position for bobbing (set on spawn)
var _base_y: float = 0.0

## Time accumulator for merge checks
var _merge_timer: float = 0.0

## Whether this item is currently on a conveyor belt
var on_belt: bool = false

## Whether this entity is being absorbed by a merge (will be freed)
var _merging: bool = false

## Reference to the visual Sprite2D (created in _ready or setup)
var _sprite: Sprite2D

## Reference to the count label
var _count_label: Label

## Reference to the collision shape
var _collision_shape: CollisionShape2D

## Despawn timer node
var _despawn_timer: Timer


# =============================================================================
# Lifecycle
# =============================================================================

func _ready() -> void:
	add_to_group("item_entities")
	_base_y = position.y

	# Create visual nodes if not already present (scene instantiation adds them)
	if not has_node("Sprite"):
		_create_visuals()
	else:
		_sprite = $Sprite as Sprite2D
		_count_label = $CountLabel
		_collision_shape = $CollisionShape2D

	_update_visuals()

	# Pickup delay
	_pickup_ready = false
	var pickup_timer := get_tree().create_timer(PICKUP_DELAY)
	pickup_timer.timeout.connect(func(): _pickup_ready = true)

	# Connect body entered for player pickup
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if _merging:
		return

	# Bobbing animation (only when not on belt)
	if not on_belt:
		_bob_time += delta
		position.y = _base_y + sin(_bob_time * BOB_SPEED) * BOB_AMPLITUDE

	# Periodic merge check
	_merge_timer += delta
	if _merge_timer >= MERGE_CHECK_INTERVAL:
		_merge_timer = 0.0
		_try_merge_nearby()


# =============================================================================
# Public API
# =============================================================================

## Initialize this item entity with a type, count, and world position.
## Call after instantiation but before adding to the scene tree, or in _ready.
func setup(p_item_type: int, p_count: int, world_pos: Vector2, p_despawn_time: float = DEFAULT_DESPAWN_TIME) -> void:
	item_type = p_item_type
	count = p_count
	position = world_pos
	_base_y = world_pos.y

	if is_inside_tree():
		_update_visuals()
		_setup_despawn_timer(p_despawn_time)


## Try to pick up this item into the given inventory.
## Returns the number of items actually picked up (may be less than count if inventory full).
func try_pickup(inventory: Inventory) -> int:
	if not _pickup_ready or _merging:
		return 0

	var remaining := inventory.add_item(item_type, count)
	var picked := count - remaining

	if picked > 0:
		picked_up.emit(item_type, picked)
		if remaining <= 0:
			queue_free()
		else:
			count = remaining
			_update_visuals()

	return picked


## Get the max stack size for this item type
func get_max_stack() -> int:
	return ItemData.get_max_stack(item_type)


## Serialize this item entity for saving
func serialize() -> Dictionary:
	return {
		"type": "ItemEntity",
		"item_type": item_type,
		"count": count,
		"position": {"x": position.x, "y": _base_y},
		"on_belt": on_belt,
	}


## Restore state from saved data. Call after adding to scene tree.
func deserialize(data: Dictionary) -> void:
	item_type = int(data.get("item_type", ItemData.ItemType.NONE))
	count = int(data.get("count", 1))
	on_belt = data.get("on_belt", false)

	var pos_data: Dictionary = data.get("position", {})
	position = Vector2(
		float(pos_data.get("x", 0.0)),
		float(pos_data.get("y", 0.0))
	)
	_base_y = position.y

	_update_visuals()


# =============================================================================
# Pickup
# =============================================================================

func _on_body_entered(body: Node2D) -> void:
	if not _pickup_ready or _merging:
		return

	if body is PlayerController:
		# Find the player's inventory via the Main scene
		var main := _get_main()
		if main and main.inventory:
			try_pickup(main.inventory)


func _get_main() -> Main:
	var node := get_tree().current_scene
	if node is Main:
		return node as Main
	return null


# =============================================================================
# Merging
# =============================================================================

func _try_merge_nearby() -> void:
	if _merging or not is_inside_tree():
		return

	var max_stack := get_max_stack()
	if count >= max_stack:
		return

	var items := get_tree().get_nodes_in_group("item_entities")
	for node in items:
		if node == self or not is_instance_valid(node):
			continue
		var other: ItemEntity = node as ItemEntity
		if other == null or other._merging:
			continue
		if other.item_type != item_type:
			continue
		if other.on_belt or on_belt:
			continue

		var dist := position.distance_to(other.position)
		if dist > MERGE_RADIUS:
			continue

		# Merge other into self
		var space := max_stack - count
		if space <= 0:
			break

		var to_merge := mini(other.count, space)
		count += to_merge
		other.count -= to_merge

		if other.count <= 0:
			other._merging = true
			other.queue_free()
		else:
			other._update_visuals()

		merged.emit(item_type, count)
		_update_visuals()

		if count >= max_stack:
			break


# =============================================================================
# Despawn
# =============================================================================

func _setup_despawn_timer(time: float) -> void:
	if time <= 0.0:
		return

	if _despawn_timer != null:
		_despawn_timer.queue_free()

	_despawn_timer = Timer.new()
	_despawn_timer.one_shot = true
	_despawn_timer.wait_time = time
	_despawn_timer.timeout.connect(_on_despawn)
	add_child(_despawn_timer)
	_despawn_timer.start()


func _on_despawn() -> void:
	despawned.emit(item_type, count)
	queue_free()


## Reset the despawn timer (e.g. after a merge)
func reset_despawn_timer() -> void:
	if _despawn_timer and is_instance_valid(_despawn_timer):
		_despawn_timer.start()


# =============================================================================
# Visuals
# =============================================================================

func _create_visuals() -> void:
	# Collision shape for pickup detection
	_collision_shape = CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = SPRITE_SIZE
	_collision_shape.shape = shape
	_collision_shape.name = "CollisionShape2D"
	add_child(_collision_shape)

	# Sprite2D with icon from SpriteDB (centered by default)
	_sprite = Sprite2D.new()
	_sprite.name = "Sprite"
	add_child(_sprite)

	# Count label (shown when count > 1)
	_count_label = Label.new()
	_count_label.name = "CountLabel"
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_count_label.position = Vector2(-SPRITE_SIZE, SPRITE_SIZE / 2.0)
	_count_label.size = Vector2(SPRITE_SIZE * 2, 14)
	_count_label.add_theme_font_size_override("font_size", 8)
	add_child(_count_label)


func _update_visuals() -> void:
	if _sprite:
		var icon: AtlasTexture = SpriteDB.get_item_icon(item_type)
		if icon:
			_sprite.texture = icon
		else:
			# Fallback: use the entity sprite sheet when no icon atlas available
			var fallback: Texture2D = SpriteDB.get_entity_sprite("item_entity")
			if fallback:
				_sprite.texture = fallback
			# Tint with item color for visual distinction
			_sprite.modulate = _get_item_color(item_type)
	if _count_label:
		if count > 1:
			_count_label.text = str(count)
			_count_label.visible = true
		else:
			_count_label.text = ""
			_count_label.visible = false


static func _get_item_color(p_item_type: int) -> Color:
	if _item_colors.has(p_item_type):
		return _item_colors[p_item_type]
	# Fallback: generate a color from the item type id
	var hue := fmod(float(p_item_type) * 0.618033988749, 1.0)
	return Color.from_hsv(hue, 0.6, 0.8)


# =============================================================================
# Factory
# =============================================================================

## Convenience: create and configure an ItemEntity, add it to a parent node.
## Returns the new ItemEntity.
static func spawn(parent: Node, p_item_type: int, p_count: int, world_pos: Vector2, p_despawn_time: float = DEFAULT_DESPAWN_TIME) -> ItemEntity:
	var scene := load("res://scenes/entities/item_entity.tscn")
	if scene == null:
		push_error("ItemEntity scene not found at res://scenes/entities/item_entity.tscn")
		return null

	var entity: ItemEntity = scene.instantiate()
	entity.item_type = p_item_type
	entity.count = p_count
	entity.position = world_pos
	entity._base_y = world_pos.y
	parent.add_child(entity)

	# Setup despawn after adding to tree so timer works
	entity._setup_despawn_timer(p_despawn_time)
	return entity
