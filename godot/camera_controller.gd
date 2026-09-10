extends Node

var player: CharacterBody3D
var camera: Camera3D
var camera_offset := Vector3(0, 5.5, 7.2)
var touches := {}
var pinch_distance := 0.0
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
    if event is InputEventScreenTouch:
        if event.pressed:
            touches[event.index] = event.position
        else:
            touches.erase(event.index)
        if touches.size() >= 2:
            pinch_distance = _touch_distance()
        else:
            pinch_distance = 0.0
    elif event is InputEventScreenDrag:
        touches[event.index] = event.position
        if touches.size() >= 2:
            var now := _touch_distance()
            if pinch_distance > 0.0:
                var change := now - pinch_distance
                zoom_scale = clamp(zoom_scale - change * 0.0025, min_zoom, max_zoom)
            pinch_distance = now
    elif event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            zoom_scale = clamp(zoom_scale - 0.08, min_zoom, max_zoom)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            zoom_scale = clamp(zoom_scale + 0.08, min_zoom, max_zoom)

func _touch_distance()->float:
    if touches.size() < 2:return 0.0
    var keys := touches.keys()
    var a:Vector2 = touches[keys[0]]
    var b:Vector2 = touches[keys[1]]
    return a.distance_to(b)

func _find_game_nodes():
    var scene := get_tree().current_scene
    if scene == null:return
    var scene_player = scene.get("player")
    var scene_camera = scene.get("camera")
    if scene_player is CharacterBody3D:player = scene_player
    if scene_camera is Camera3D:camera = scene_camera
