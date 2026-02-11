class_name InputManager
extends Node

var player_controller: PlayerController
var mining_controller: MiningController
var placement_controller: PlacementController
var hotbar_ui: HotbarUI
var inventory_ui: InventoryUI

func setup(player: PlayerController, mining: MiningController, placement: PlacementController, hotbar: HotbarUI, inv_ui: InventoryUI) -> void:
	player_controller = player
	mining_controller = mining
	placement_controller = placement
	hotbar_ui = hotbar
	inventory_ui = inv_ui

func _process(_delta: float) -> void:
	if player_controller:
		# Update player position for range checks
		var player_pos = player_controller.global_position
		if mining_controller:
			mining_controller.set_player_position(player_pos)
		if placement_controller:
			placement_controller.set_player_position(player_pos)

	_handle_movement()
	_handle_jump()
	_handle_actions()
	_handle_hotbar_selection()
	_handle_ui()


func _handle_movement() -> void:
	if player_controller == null:
		return
	var direction = 0.0
	if Input.is_action_pressed("move_left"):
		direction -= 1.0
	if Input.is_action_pressed("move_right"):
		direction += 1.0
	player_controller.set_move_direction(direction)
	
	if Input.is_key_pressed(KEY_SHIFT):
		player_controller.set_wants_walk(true)
	else:
		player_controller.set_wants_walk(false)


func _handle_jump() -> void:
	if player_controller == null:
		return
	if Input.is_action_just_pressed("jump"):
		player_controller.jump()


func _handle_actions() -> void:
	if player_controller == null:
		return

	# simple click-to-interact
	if Input.is_action_pressed("mine"):
		if mining_controller:
			mining_controller.try_mine_at(player_controller.get_global_mouse_position())

	if Input.is_action_just_pressed("place"):
		if placement_controller:
			placement_controller.try_place_at(player_controller.get_global_mouse_position())


func _handle_ui() -> void:
	if Input.is_action_just_pressed("inventory_toggle"):
		if inventory_ui:
			inventory_ui.toggle()


func _handle_hotbar_selection() -> void:
	for i in range(9):
		var action = "hotbar_%d" % (i + 1)
		if Input.is_action_just_pressed(action):
			if hotbar_ui:
				hotbar_ui.select_slot(i)
			if placement_controller:
				placement_controller.set_selected_slot(i)
