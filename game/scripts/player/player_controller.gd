@tool
class_name PlayerController
extends CharacterBody2D
## Player movement controller for side-view platformer
##
## Handles gravity, horizontal movement, and jumping.
## Uses move_and_slide() for physics-based movement.
@onready var player_animated_sprite = $PlayerSpriteAnimation2D

@export var movement_data: Resource

# =============================================================================
# Debug Mode State
# =============================================================================

## Whether fly mode is active (disables gravity, allows vertical movement)
var fly_mode: bool = false

## Whether noclip mode is active (disables collision + enables fly)
var noclip_mode: bool = false

## Vertical input direction for fly mode (-1 down, 0 none, 1 up)
var fly_vertical_direction: float = 0.0

## Speed multiplier for fly mode
const FLY_SPEED: float = 400.0


func _ready() -> void:
	if not movement_data:
		movement_data = load("res://resources/player/default_movement_data.tres")
	# Jump velocity should be negative because Godot physics is inverted
	if movement_data.jump_velocity > 0:
		movement_data.jump_velocity *= -1


# Movement state
var move_direction: float = 0.0 # -1 left, 0 none, 1 right
var wants_jump: bool = false
var wants_walk: bool = false
var _last_logged_pos: Vector2 = Vector2.INF


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if not movement_data:
		return

	if fly_mode or noclip_mode:
		_physics_process_fly(delta)
		return

	# Apply gravity
	if not is_on_floor():
		velocity.y += movement_data.gravity * delta

	# Handle jump
	if wants_jump and is_on_floor():
		velocity.y = movement_data.jump_velocity
	wants_jump = false # Reset jump request

	# Determine speed based on walk state
	var current_speed = movement_data.walk_speed if wants_walk else movement_data.speed

	# Horizontal movement
	velocity.x = move_direction * current_speed

	move_and_slide()

	# Update animations
	if not is_on_floor():
		player_animated_sprite.play("jump")
	else:
		if velocity.x != 0:
			if abs(velocity.x) > movement_data.walk_speed:
				player_animated_sprite.play("run")
			else:
				player_animated_sprite.play("walk")
		else:
			player_animated_sprite.play("idle")

	if velocity.x != 0:
		player_animated_sprite.flip_h = velocity.x < 0


## Physics process for fly/noclip mode — free movement, no gravity
func _physics_process_fly(_delta: float) -> void:
	velocity.x = move_direction * FLY_SPEED
	# In Godot screen space, negative Y is up
	velocity.y = -fly_vertical_direction * FLY_SPEED

	if noclip_mode:
		# Move directly without collision detection
		position += velocity * _delta
		velocity = Vector2.ZERO
	else:
		move_and_slide()

	# Simple animation handling in fly mode
	if velocity.length() > 0:
		player_animated_sprite.play("jump")
	else:
		player_animated_sprite.play("idle")

	if velocity.x != 0:
		player_animated_sprite.flip_h = velocity.x < 0


func set_move_direction(direction: float) -> void:
	move_direction = clamp(direction, -1.0, 1.0)


func set_wants_walk(walking: bool) -> void:
	wants_walk = walking


func jump() -> void:
	wants_jump = true


func stop() -> void:
	move_direction = 0.0
	wants_jump = false
	wants_walk = false
	fly_vertical_direction = 0.0


## Set vertical fly direction (-1 down, 0 none, 1 up)
func set_fly_vertical(direction: float) -> void:
	fly_vertical_direction = clamp(direction, -1.0, 1.0)


## Toggle fly mode on/off. Returns the new state.
func toggle_fly_mode() -> bool:
	fly_mode = not fly_mode
	if not fly_mode:
		fly_vertical_direction = 0.0
	return fly_mode


## Toggle noclip mode on/off. Also enables/disables fly mode. Returns the new state.
func toggle_noclip_mode() -> bool:
	noclip_mode = not noclip_mode
	fly_mode = noclip_mode
	if not noclip_mode:
		fly_vertical_direction = 0.0
	return noclip_mode


## Returns true if fly or noclip mode is active
func is_flying() -> bool:
	return fly_mode or noclip_mode


## Serialize player state to a dictionary
func serialize() -> Dictionary:
	return {
		"position": {"x": position.x, "y": position.y},
	}


## Restore player state from a dictionary
func deserialize(data: Dictionary) -> void:
	var pos_data: Dictionary = data.get("position", {})
	if pos_data.has("x") and pos_data.has("y"):
		position = Vector2(float(pos_data["x"]), float(pos_data["y"]))
