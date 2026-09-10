extends Node

var player: CharacterBody3D
var camera: Camera3D
var yaw := 0.0
var pitch := deg_to_rad(-32.0)
var distance := 8.6
var min_distance := 3.8
var max_distance := 14.0
var drag_touch := -1
var last_drag := Vector2.ZERO
var touches := {}
var pinch_distance := 0.0
var ready_to_control := false

func _process(delta):
    if not ready_to_control:
        _find_game_nodes()
        if player != null and camera != null:
            var offset := camera.global_position - player.global_position
            distance = clamp(offset.length(), min_distance, max_distance)
            yaw = atan2(offset.x, offset.z)
            pitch = asin(clamp(offset.y / max(distance, 0.01), -0.9, 0.9))
            ready_to_control = true
    if not ready_to_control:return
    pitch = clamp(pitch, deg_to_rad(-68.0), deg_to_rad(-12.0))
    distance = clamp(distance, min_distance, max_distance)
    var horizontal := cos(pitch) * distance
    var offset := Vector3(sin(yaw) * horizontal, -sin(pitch) * distance, cos(yaw) * horizontal)
    var target := player.global_position + Vector3(0, .65, 0)
    camera.global_position = camera.global_position.lerp(target + offset, clamp(12.0 * delta, 0.0, 1.0))
    camera.look_at(target, Vector3.UP)

func _input(event):
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:distance -= .8
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:distance += .8
        elif event.button_index == MOUSE_BUTTON_RIGHT:
            drag_touch = -2 if event.pressed else -1
            last_drag = event.position
    elif event is InputEventMouseMotion and drag_touch == -2:
        _orbit(event.relative)
    elif event is InputEventScreenTouch:
        if event.pressed:
            touches[event.index] = event.position
            if touches.size() == 1 and event.position.x > get_viewport().get_visible_rect().size.x * .42:
                drag_touch = event.index;last_drag = event.position
            elif touches.size() >= 2:
                drag_touch = -1;pinch_distance = _touch_distance()
        else:
            touches.erase(event.index)
            if event.index == drag_touch:drag_touch = -1
            if touches.size() < 2:pinch_distance = 0.0
    elif event is InputEventScreenDrag:
        touches[event.index] = event.position
        if touches.size() >= 2:
            var now := _touch_distance()
            if pinch_distance > 0.0:distance -= (now - pinch_distance) * .018
            pinch_distance = now
        elif event.index == drag_touch:
            var delta_drag := event.position - last_drag
            last_drag = event.position
            _orbit(delta_drag)

func _orbit(delta_drag:Vector2):
    yaw -= delta_drag.x * .006
    pitch += delta_drag.y * .0045

func _touch_distance()->float:
    if touches.size() < 2:return 0.0
    var keys := touches.keys()
    return (touches[keys[0]] as Vector2).distance_to(touches[keys[1]] as Vector2)

func _find_game_nodes():
    player = _find_type(get_tree().current_scene, "CharacterBody3D") as CharacterBody3D
    camera = _find_type(get_tree().current_scene, "Camera3D") as Camera3D

func _find_type(node:Node,type_name:String)->Node:
    if node == null:return null
    if node.is_class(type_name):return node
    for child in node.get_children():
        var found := _find_type(child,type_name)
        if found != null:return found
    return null
