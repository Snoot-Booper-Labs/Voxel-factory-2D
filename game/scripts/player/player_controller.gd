@tool
class_name PlayerController
extends CharacterBody2D
## Player movement controller for side-view platformer
##
## Handles gravity, horizontal movement, and jumping.
## Uses move_and_slide() for physics-based movement.
@onready var player_animated_sprite = $PlayerSpriteAnimation2D

@export var movement_data: Resource


func _ready() -> void:
	if not movement_data:
		movement_data = load("res://game/resources/player/default_movement_data.tres")


# Movement state
var move_direction: float = 0.0 # -1 left, 0 none, 1 right
var wants_jump: bool = false
var wants_walk: bool = false


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	if not movement_data:
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
			# Use walk speed threshold for animation logic if needed, 
			# but generally if moving and wants_walk is true, play walk.
			# Or rely on speed check. 
			# Since walk_speed is 100, we might need to adjust the animation threshold logic 
			# or just check detailed state.
			# Let's use simple logic: if abs(velocity.x) > walk_speed, run, else walk.
			# But if walk_speed is exactly 100, > 100 might fail for walk. 
			# Let's say > walk_speed + epsilon for run.
			# Or better: check wants_walk. But velocity is the source of truth for physics.
			if abs(velocity.x) > movement_data.walk_speed:
				player_animated_sprite.play("run")
			else:
				player_animated_sprite.play("walk")
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
