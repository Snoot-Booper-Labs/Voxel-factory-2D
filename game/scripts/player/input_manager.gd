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
    _handle_movement()
    _handle_hotbar_selection()

func _handle_movement() -> void:
    if player_controller == null:
        return
    var direction = 0.0
    if Input.is_action_pressed("move_left"):
        direction -= 1.0
    if Input.is_action_pressed("move_right"):
        direction += 1.0
    player_controller.set_move_direction(direction)

func _handle_hotbar_selection() -> void:
    for i in range(9):
        var action = "hotbar_%d" % (i + 1)
        if Input.is_action_just_pressed(action):
            if hotbar_ui:
                hotbar_ui.select_slot(i)
            if placement_controller:
                placement_controller.set_selected_slot(i)
