class_name InputManager
extends Node

var player_controller: PlayerController
var mining_controller: MiningController
var placement_controller: PlacementController
var hotbar_ui: HotbarUI
var inventory_ui: InventoryUI
var miner_inventory_ui: InventoryUI
var active_miner_entity: Miner = null

const MAX_INTERACTION_DISTANCE = 64.0


func setup(player: PlayerController, mining: MiningController, placement: PlacementController, hotbar: HotbarUI, inv_ui: InventoryUI, miner_inv_ui: InventoryUI) -> void:
	player_controller = player
	mining_controller = mining
	placement_controller = placement
	hotbar_ui = hotbar
	inventory_ui = inv_ui
	miner_inventory_ui = miner_inv_ui

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
	_check_miner_distance()


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

	# Block mining/placing when inventory is open
	if inventory_ui and inventory_ui.is_open():
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

	if Input.is_action_just_pressed("interact"):
		_handle_interaction()

	if Input.is_key_pressed(KEY_ESCAPE):
		if inventory_ui and inventory_ui.is_open():
			# Cancel held item first, then close on next ESC press
			if inventory_ui.is_holding():
				inventory_ui.cancel_held()
			else:
				inventory_ui.close()

		_close_miner_inventory()


func _check_miner_distance() -> void:
	if active_miner_entity == null or not is_instance_valid(active_miner_entity):
		if miner_inventory_ui and miner_inventory_ui.is_open():
			_close_miner_inventory()
		return

	if player_controller:
		var dist = player_controller.global_position.distance_to(active_miner_entity.global_position)
		if dist > MAX_INTERACTION_DISTANCE:
			_close_miner_inventory()


func _handle_interaction() -> void:
	if player_controller == null:
		return

	# Check if miner UI is already open, if so close it
	if miner_inventory_ui and miner_inventory_ui.is_open():
		_close_miner_inventory()
		return

	# Find nearest miner within range
	var miners = get_tree().get_nodes_in_group("miners")
	var nearest_miner: Miner = null
	var min_dist = 64.0 # 2 tiles

	for miner in miners:
		if miner is Miner:
			var dist = player_controller.global_position.distance_to(miner.global_position)
			if dist < min_dist:
				min_dist = dist
				nearest_miner = miner

	if nearest_miner:
		if miner_inventory_ui:
			miner_inventory_ui.setup(nearest_miner.get_inventory())
			miner_inventory_ui.open()
			active_miner_entity = nearest_miner


func _close_miner_inventory() -> void:
	if miner_inventory_ui:
		miner_inventory_ui.close()
	active_miner_entity = null


func _handle_hotbar_selection() -> void:
	for i in range(9):
		var action = "hotbar_%d" % (i + 1)
		if Input.is_action_just_pressed(action):
			if hotbar_ui:
				hotbar_ui.select_slot(i)
			if placement_controller:
				placement_controller.set_selected_slot(i)
