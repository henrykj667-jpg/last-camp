extends Node

var touch_id := -1
var pad: Control
var label: Label

func _ready():
    call_deferred("_install")

func _install():
    var scene := get_tree().current_scene
    if scene == null:
        return
    var layer := CanvasLayer.new()
    layer.layer = 20
    scene.add_child(layer)
    pad = Control.new()
    pad.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    pad.position = Vector2(-190, -150)
    pad.size = Vector2(150, 90)
    pad.mouse_filter = Control.MOUSE_FILTER_STOP
    pad.gui_input.connect(_on_pad_input)
    layer.add_child(pad)
    label = Label.new()
    label.text = "USE"
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.add_theme_font_size_override("font_size", 18)
    pad.add_child(label)
    pad.draw.connect(_draw_pad)
    pad.queue_redraw()

func _on_pad_input(event):
    if event is InputEventScreenTouch:
        if event.pressed and touch_id == -1:
            touch_id = event.index
            _trigger_action()
            pad.queue_redraw()
        elif not event.pressed and event.index == touch_id:
            touch_id = -1
            pad.queue_redraw()
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        _trigger_action()

func _trigger_action():
    var scene := get_tree().current_scene
    if scene != null and scene.has_method("_context_action"):
        scene.call("_context_action")

func _draw_pad():
    if pad == null:
        return
    var fill := Color(0.22, 0.26, 0.24, 0.92) if touch_id == -1 else Color(0.34, 0.40, 0.36, 0.96)
    pad.draw_rect(Rect2(Vector2.ZERO, pad.size), fill, true)
    pad.draw_rect(Rect2(Vector2.ZERO, pad.size), Color(1, 1, 1, 0.35), false, 2.0)
