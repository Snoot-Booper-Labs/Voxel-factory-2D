extends GutTest

var player: PlayerController


func before_each() -> void:
	player = PlayerController.new()
	var sprite = AnimatedSprite2D.new()
	sprite.name = "PlayerSpriteAnimation2D"
	var frames = SpriteFrames.new()
	frames.add_animation("jump")
	frames.add_animation("run")
	frames.add_animation("walk")
	frames.add_animation("idle")
	sprite.sprite_frames = frames
	player.add_child(sprite)
	add_child(player)


func after_each() -> void:
	player.queue_free()


func test_player_controller_exists() -> void:
	assert_not_null(player)
	assert_true(player is CharacterBody2D)


func test_set_move_direction_right() -> void:
	player.set_move_direction(1.0)
	assert_eq(player.move_direction, 1.0)


func test_set_move_direction_left() -> void:
	player.set_move_direction(-1.0)
	assert_eq(player.move_direction, -1.0)


func test_set_move_direction_clamped_high() -> void:
	player.set_move_direction(5.0)
	assert_eq(player.move_direction, 1.0)


func test_set_move_direction_clamped_low() -> void:
	player.set_move_direction(-5.0)
	assert_eq(player.move_direction, -1.0)


func test_jump_sets_wants_jump() -> void:
	player.jump()
	assert_true(player.wants_jump)


func test_stop_resets_move_direction() -> void:
	player.set_move_direction(1.0)
	player.stop()
	assert_eq(player.move_direction, 0.0)


func test_stop_resets_wants_jump() -> void:
	player.jump()
	player.stop()
	assert_false(player.wants_jump)


func test_gravity_increases_downward_velocity() -> void:
	var initial_y = player.velocity.y
	player._physics_process(0.1)
	assert_gt(player.velocity.y, initial_y, "Gravity should increase downward velocity")


func test_horizontal_movement_sets_velocity() -> void:
	player.set_move_direction(1.0)
	player._physics_process(0.016)
	assert_eq(player.velocity.x, PlayerController.SPEED)


func test_horizontal_movement_left() -> void:
	player.set_move_direction(-1.0)
	player._physics_process(0.016)
	assert_eq(player.velocity.x, -PlayerController.SPEED)


func test_physics_process_clears_wants_jump() -> void:
	player.jump()
	player._physics_process(0.016)
	assert_false(player.wants_jump)
