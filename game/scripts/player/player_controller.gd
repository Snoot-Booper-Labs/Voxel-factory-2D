@tool
class_name PlayerController
extends CharacterBody2D
## Player movement controller for side-view platformer
##
## Handles gravity, horizontal movement, and jumping.
## Uses move_and_slide() for physics-based movement.

# Movement constants
const SPEED = 200.0
const JUMP_VELOCITY = -400.0 # Negative because Y-up means jump goes up
const GRAVITY = 980.0 # Pixels per second squared

## The texture to display for the player
@export var texture: Texture2D:
	set(value):
		texture = value
		if has_node("Sprite2D"):
			$Sprite2D.texture = value

@export var hframes: int = 1:
	set(value):
		hframes = value
		if has_node("Sprite2D"):
			$Sprite2D.hframes = value

@export var vframes: int = 1:
	set(value):
		vframes = value
		if has_node("Sprite2D"):
			$Sprite2D.vframes = value

@export var frame: int = 0:
	set(value):
		frame = value
		if has_node("Sprite2D"):
			$Sprite2D.frame = value

# Movement state
var move_direction: float = 0.0 # -1 left, 0 none, 1 right
var wants_jump: bool = false


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	# Apply gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Handle jump
	if wants_jump and is_on_floor():
		velocity.y = JUMP_VELOCITY
	wants_jump = false

	# Horizontal movement
	velocity.x = move_direction * SPEED

	move_and_slide()


func set_move_direction(direction: float) -> void:
	move_direction = clamp(direction, -1.0, 1.0)


func jump() -> void:
	wants_jump = true


func stop() -> void:
	move_direction = 0.0
	wants_jump = false
