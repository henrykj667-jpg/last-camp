extends Node

var player: CharacterBody3D
var camera: Camera3D
var camera_offset := Vector3(0, 5.5, 7.2)

func _process(delta):
    if player == null or camera == null or not is_instance_valid(player) or not is_instance_valid(camera):
        _find_game_nodes()
        return
    camera.global_position = camera.global_position.lerp(player.global_position + camera_offset, clamp(8.0 * delta, 0.0, 1.0))
    camera.look_at(player.global_position + Vector3(0, 0.55, 0), Vector3.UP)

func _find_game_nodes():
    var scene := get_tree().current_scene
    if scene == null:return
    var scene_player = scene.get("player")
    var scene_camera = scene.get("camera")
    if scene_player is CharacterBody3D:player = scene_player
    if scene_camera is Camera3D:camera = scene_camera
