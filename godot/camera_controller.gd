extends Node

var player: CharacterBody3D
var camera: Camera3D
var camera_offset := Vector3(0, 5.5, 7.2)
var min_zoom := 0.55
var max_zoom := 1.75
var zoom_scale := 1.0

func _process(delta):
    if player == null or camera == null or not is_instance_valid(player) or not is_instance_valid(camera):
        _find_game_nodes()
        return
    var wanted_offset := camera_offset * zoom_scale
    camera.global_position = camera.global_position.lerp(player.global_position + wanted_offset, clamp(8.0 * delta, 0.0, 1.0))
    camera.look_at(player.global_position + Vector3(0, 0.55, 0), Vector3.UP)

func _input(event):
    # Mobile gameplay uses several fingers at once for joystick, sprint, jump and use.
    # Do not interpret those gameplay touches as a pinch gesture; that was making
    # the camera shift while moving and made the movement direction feel reversed.
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            zoom_scale = clamp(zoom_scale - 0.08, min_zoom, max_zoom)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            zoom_scale = clamp(zoom_scale + 0.08, min_zoom, max_zoom)

func _find_game_nodes():
    var scene := get_tree().current_scene
    if scene == null:return
    var scene_player = scene.get("player")
    var scene_camera = scene.get("camera")
    if scene_player is CharacterBody3D:player = scene_player
    if scene_camera is Camera3D:camera = scene_camera
