@tool
class_name PlayerController
extends CharacterBody2D
## Player movement controller for side-view platformer
##
## Handles gravity, horizontal movement, and jumping.
## Uses move_and_slide() for physics-based movement.
@onready var player_animated_sprite = $PlayerSpriteAnimation2D

# Movement constants
const SPEED = 200.0
const JUMP_VELOCITY = -400.0 # Negative because Y-up means jump goes up
const GRAVITY = 980.0 # Pixels per second squared

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

	# Update animations
	if not is_on_floor():
		player_animated_sprite.play("jump")
	else:
		if velocity.x != 0:
			if velocity.x > 100:
				player_animated_sprite.play("run")
			else:
				player_animated_sprite.play("walk")
		else:
			player_animated_sprite.play("idle")

	if velocity.x != 0:
		player_animated_sprite.flip_h = velocity.x < 0


func set_move_direction(direction: float) -> void:
	move_direction = clamp(direction, -1.0, 1.0)


func jump() -> void:
	wants_jump = true


func stop() -> void:
	move_direction = 0.0
	wants_jump = false
