extends Node

var player: CharacterBody3D
var camera: Camera3D
var camera_offset := Vector3(0, 5.5, 7.2)
var min_zoom := 0.55
var max_zoom := 1.75
var zoom_scale := 1.0

# Pinch zoom is deliberately isolated from the lower gameplay controls.
# A touch may join a pinch only if it STARTS in the upper 62% of the game view.
# That keeps joystick + jump/sprint/use touches from becoming accidental zooms.
var zoom_touches := {}
var pinch_distance := -1.0

func _process(delta):
    if player == null or camera == null or not is_instance_valid(player) or not is_instance_valid(camera):
        _find_game_nodes()
        return
    var wanted_offset := camera_offset * zoom_scale
    camera.global_position = camera.global_position.lerp(player.global_position + wanted_offset, clamp(8.0 * delta, 0.0, 1.0))
    camera.look_at(player.global_position + Vector3(0, 0.55, 0), Vector3.UP)

func _input(event):
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            zoom_scale = clamp(zoom_scale - 0.08, min_zoom, max_zoom)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            zoom_scale = clamp(zoom_scale + 0.08, min_zoom, max_zoom)
        return

    if event is InputEventScreenTouch:
        if event.pressed:
            if _can_start_zoom_touch(event.position):
                zoom_touches[event.index] = event.position
        else:
            zoom_touches.erase(event.index)
            pinch_distance = -1.0
        _update_pinch()
        return

    if event is InputEventScreenDrag and zoom_touches.has(event.index):
        zoom_touches[event.index] = event.position
        _update_pinch()

func _can_start_zoom_touch(pos:Vector2)->bool:
    var view_size:=get_viewport().get_visible_rect().size
    return pos.y < view_size.y * 0.62

func _update_pinch():
    if zoom_touches.size() != 2:
        pinch_distance = -1.0
        return
    var ids:=zoom_touches.keys()
    var a:Vector2=zoom_touches[ids[0]]
    var b:Vector2=zoom_touches[ids[1]]
    var distance:=a.distance_to(b)
    if pinch_distance > 0.0:
        var change:=distance-pinch_distance
        # Fingers apart = zoom in, together = zoom out.
        zoom_scale=clamp(zoom_scale-change*0.0035,min_zoom,max_zoom)
    pinch_distance=distance

func _find_game_nodes():
    var scene := get_tree().current_scene
    if scene == null:return
    var scene_player = scene.get("player")
    var scene_camera = scene.get("camera")
    if scene_player is CharacterBody3D:player = scene_player
    if scene_camera is Camera3D:camera = scene_camera
