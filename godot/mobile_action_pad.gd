extends Node

var use_touch := -1
var sprint_touch := -1
var jump_touch := -1
var use_pad: Control
var sprint_pad: Control
var jump_pad: Control

func _ready():call_deferred("_install")

func _install():
    var scene:=get_tree().current_scene
    if scene==null:return
    # Sprint should feel clearly faster than normal running.
    scene.set("sprint_speed",9.0)
    var layer:=CanvasLayer.new();layer.layer=20;scene.add_child(layer)
    use_pad=_make_pad(layer,Vector2(-170,-145),Vector2(130,78),"USE",0)
    jump_pad=_make_pad(layer,Vector2(-165,-245),Vector2(120,82),"JUMP",1)
    sprint_pad=_make_pad(layer,Vector2(-315,-145),Vector2(125,72),"SPRINT",2)

func _make_pad(layer:CanvasLayer,pos:Vector2,size:Vector2,text:String,kind:int)->Control:
    var pad:=Control.new();pad.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT);pad.position=pos;pad.size=size;pad.mouse_filter=Control.MOUSE_FILTER_STOP;layer.add_child(pad)
    var label:=Label.new();label.text=text;label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);label.mouse_filter=Control.MOUSE_FILTER_IGNORE;label.add_theme_font_size_override("font_size",16);pad.add_child(label)
    pad.gui_input.connect(_pad_input.bind(kind));pad.draw.connect(_draw_pad.bind(pad,kind));pad.queue_redraw();return pad

func _pad_input(event,kind:int):
    if event is InputEventScreenTouch:
        if event.pressed:_touch_down(event.index,kind)
        else:_touch_up(event.index,kind)
    elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
        if kind==0 and event.pressed:_trigger_use()
        elif kind==1 and event.pressed:_trigger_jump()
        elif kind==2:_set_sprint(event.pressed)

func _touch_down(id:int,kind:int):
    if kind==0 and use_touch==-1:use_touch=id;_trigger_use();use_pad.queue_redraw()
    elif kind==1 and jump_touch==-1:jump_touch=id;_trigger_jump();jump_pad.queue_redraw()
    elif kind==2 and sprint_touch==-1:sprint_touch=id;_set_sprint(true);sprint_pad.queue_redraw()

func _touch_up(id:int,kind:int):
    if kind==0 and id==use_touch:use_touch=-1;use_pad.queue_redraw()
    elif kind==1 and id==jump_touch:jump_touch=-1;jump_pad.queue_redraw()
    elif kind==2 and id==sprint_touch:sprint_touch=-1;_set_sprint(false);sprint_pad.queue_redraw()

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

func _draw_pad(pad:Control,kind:int):
    var active:=use_touch!=-1 if kind==0 else (jump_touch!=-1 if kind==1 else sprint_touch!=-1)
    var fill:=Color(0.34,0.40,0.36,.96) if active else Color(0.22,0.26,0.24,.92)
    pad.draw_rect(Rect2(Vector2.ZERO,pad.size),fill,true);pad.draw_rect(Rect2(Vector2.ZERO,pad.size),Color(1,1,1,.35),false,2.0)