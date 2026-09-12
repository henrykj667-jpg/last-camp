extends Node

# Right-side controls use raw viewport touch input instead of GUI input.
# This keeps their fingers completely separate from the left joystick.
var use_touch := -1
var sprint_touch := -1
var jump_touch := -1
var use_pad: Control
var sprint_pad: Control
var jump_pad: Control

func _ready():
    process_mode=Node.PROCESS_MODE_ALWAYS
    call_deferred("_install")

func _install():
    var scene:=get_tree().current_scene
    if scene==null:return
    scene.set("sprint_speed",9.0)
    var layer:=CanvasLayer.new();layer.layer=20;scene.add_child(layer)
    use_pad=_make_pad(layer,Vector2(-170,-145),Vector2(130,78),"USE")
    jump_pad=_make_pad(layer,Vector2(-165,-245),Vector2(120,82),"JUMP")
    sprint_pad=_make_pad(layer,Vector2(-315,-145),Vector2(125,72),"SPRINT")

func _make_pad(layer:CanvasLayer,pos:Vector2,size:Vector2,text:String)->Control:
    var pad:=Control.new()
    pad.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    pad.position=pos;pad.size=size
    # Visual only. Raw touch routing below owns these buttons.
    pad.mouse_filter=Control.MOUSE_FILTER_IGNORE
    layer.add_child(pad)
    var label:=Label.new();label.text=text
    label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
    label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);label.mouse_filter=Control.MOUSE_FILTER_IGNORE
    label.add_theme_font_size_override("font_size",16);pad.add_child(label)
    pad.draw.connect(_draw_pad.bind(pad));pad.queue_redraw()
    return pad

func _input(event):
    if event is InputEventScreenTouch:
        if event.pressed:_route_touch_down(event.index,event.position)
        else:_route_touch_up(event.index)
    elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
        if event.pressed:_route_mouse_down(event.position)
        else:_set_sprint(false)

func _route_touch_down(id:int,pos:Vector2):
    # Only touches that START inside a right-side action rectangle are claimed.
    # A joystick finger can never become an action finger, and action fingers
    # never write to movement direction.
    if use_touch==-1 and _contains(use_pad,pos):
        use_touch=id;_trigger_use();use_pad.queue_redraw();get_viewport().set_input_as_handled();return
    if jump_touch==-1 and _contains(jump_pad,pos):
        jump_touch=id;_trigger_jump();jump_pad.queue_redraw();get_viewport().set_input_as_handled();return
    if sprint_touch==-1 and _contains(sprint_pad,pos):
        sprint_touch=id;_set_sprint(true);sprint_pad.queue_redraw();get_viewport().set_input_as_handled();return

func _route_touch_up(id:int):
    if id==use_touch:
        use_touch=-1;use_pad.queue_redraw();get_viewport().set_input_as_handled();return
    if id==jump_touch:
        jump_touch=-1;jump_pad.queue_redraw();get_viewport().set_input_as_handled();return
    if id==sprint_touch:
        sprint_touch=-1;_set_sprint(false);sprint_pad.queue_redraw();get_viewport().set_input_as_handled();return

func _route_mouse_down(pos:Vector2):
    if _contains(use_pad,pos):_trigger_use()
    elif _contains(jump_pad,pos):_trigger_jump()
    elif _contains(sprint_pad,pos):_set_sprint(true)

func _contains(pad:Control,pos:Vector2)->bool:
    return pad!=null and pad.get_global_rect().has_point(pos)

func _scene():return get_tree().current_scene
func _trigger_use():
    var scene=_scene()
    if scene!=null and scene.has_method("_context_action"):scene.call("_context_action")
func _trigger_jump():
    var scene=_scene()
    if scene!=null and scene.has_method("jump"):scene.call("jump")
func _set_sprint(value:bool):
    var scene=_scene()
    if scene!=null and scene.has_method("set_sprinting"):scene.call("set_sprinting",value)

func _draw_pad(pad:Control):
    var active:bool=(pad==use_pad and use_touch!=-1) or (pad==jump_pad and jump_touch!=-1) or (pad==sprint_pad and sprint_touch!=-1)
    var fill:=Color(0.34,0.40,0.36,.96) if active else Color(0.22,0.26,0.24,.92)
    pad.draw_rect(Rect2(Vector2.ZERO,pad.size),fill,true)
    pad.draw_rect(Rect2(Vector2.ZERO,pad.size),Color(1,1,1,.35),false,2.0)
