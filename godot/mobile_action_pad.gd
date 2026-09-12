extends Node

const JumpSymbol=preload("res://jump_symbol.gd")
const SprintSymbol=preload("res://sprint_symbol.gd")

# Raw mobile touch router. Action buttons and hotbar work without
# touch-to-mouse emulation, while movement remains isolated to the joystick.
var use_touch := -1
var sprint_touch := -1
var jump_touch := -1
var use_pad: Control
var sprint_pad: Control
var jump_pad: Control
var last_selected := ""

func _ready():
    process_mode=Node.PROCESS_MODE_ALWAYS
    call_deferred("_install")

func _process(_delta):
    var scene=_scene()
    if scene==null:return
    var movement=scene.get("move_input")
    if movement is Vector2 and movement.length()>.10:
        scene.set("move_input",movement.normalized())
    var selected=str(scene.get("selected_tool"))
    if selected!=last_selected:
        last_selected=selected
        _style_hotbar()

func _install():
    var scene:=get_tree().current_scene
    if scene==null:return
    scene.set("sprint_speed",9.0)
    var layer:=CanvasLayer.new();layer.layer=20;scene.add_child(layer)
    use_pad=_make_pad(layer,Vector2(-164,-146),Vector2(112,78),"USE")
    jump_pad=_make_pad(layer,Vector2(-164,-242),Vector2(112,78),"")
    _add_jump_symbol(jump_pad)
    sprint_pad=_make_pad(layer,Vector2(-296,-146),Vector2(112,78),"")
    _add_sprint_symbol(sprint_pad)
    call_deferred("_style_hotbar")

func _add_jump_symbol(pad:Control):
    if pad==null:return
    var mark:=JumpSymbol.new();mark.position=Vector2(0,17);mark.size=Vector2(112,44);mark.mouse_filter=Control.MOUSE_FILTER_IGNORE;pad.add_child(mark)

func _add_sprint_symbol(pad:Control):
    if pad==null:return
    var mark:=SprintSymbol.new();mark.position=Vector2(0,17);mark.size=Vector2(112,44);mark.mouse_filter=Control.MOUSE_FILTER_IGNORE;pad.add_child(mark)

func _make_style(fill:Color,border:Color,radius:int,shadow:int=3)->StyleBoxFlat:
    var style:=StyleBoxFlat.new();style.bg_color=fill
    style.border_width_left=2;style.border_width_top=2;style.border_width_right=2;style.border_width_bottom=2;style.border_color=border
    style.corner_radius_top_left=radius;style.corner_radius_top_right=radius;style.corner_radius_bottom_left=radius;style.corner_radius_bottom_right=radius
    style.shadow_color=Color(0,0,0,.24);style.shadow_size=shadow;return style

func _make_pad(layer:CanvasLayer,pos:Vector2,size:Vector2,text:String)->Control:
    var pad:=Control.new();pad.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT);pad.position=pos;pad.size=size;pad.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(pad)
    var panel:=Panel.new();panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;pad.add_child(panel)
    var normal:=_make_style(Color(.07,.09,.08,.84),Color(.72,.78,.73,.55),14,4)
    panel.add_theme_stylebox_override("panel",normal);pad.set_meta("panel",panel);pad.set_meta("normal_style",normal)
    var label:=Label.new();label.text=text;label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
    label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);label.mouse_filter=Control.MOUSE_FILTER_IGNORE;label.add_theme_font_size_override("font_size",15);label.add_theme_color_override("font_color",Color(.94,.97,.95,1));pad.add_child(label);return pad

func _style_hotbar():
    var scene=_scene();if scene==null:return
    var buttons=scene.get("tool_buttons");if buttons==null:return
    var selected=str(scene.get("selected_tool"));var tools=scene.get("tools");if tools==null:return
    for i in range(buttons.size()):
        var b:Button=buttons[i];if b==null:continue
        var locked:bool=str(tools[i])=="LOCKED";var chosen:bool=str(tools[i])==selected
        b.text=str(i+1)+"\n"+str(tools[i]);b.add_theme_font_size_override("font_size",12)
        b.add_theme_color_override("font_color",Color(.97,.98,.95,1) if not locked else Color(.72,.75,.72,.42));b.add_theme_color_override("font_disabled_color",Color(.72,.75,.72,.42))
        var fill:=Color(.18,.24,.20,.95) if chosen else Color(.055,.07,.06,.84);var border:=Color(.90,.92,.80,.92) if chosen else Color(.58,.64,.59,.42)
        if locked:fill=Color(.08,.09,.08,.38);border=Color(.45,.48,.45,.20)
        var normal:=_make_style(fill,border,10,3);var hover:=_make_style(fill.lightened(.06),border.lightened(.08),10,3);var pressed:=_make_style(fill.lightened(.10),Color(.95,.96,.88,.95),10,2)
        b.add_theme_stylebox_override("normal",normal);b.add_theme_stylebox_override("hover",hover);b.add_theme_stylebox_override("pressed",pressed);b.add_theme_stylebox_override("focus",normal);b.add_theme_stylebox_override("disabled",normal)

func _set_pad_active(pad:Control,active:bool):
    if pad==null:return
    var panel:Panel=pad.get_meta("panel");if panel==null:return
    var style:=_make_style(Color(.20,.28,.23,.96),Color(.92,.95,.90,.90),14,3) if active else pad.get_meta("normal_style");panel.add_theme_stylebox_override("panel",style)

func _input(event):
    if event is InputEventScreenTouch:
        if event.pressed:_route_touch_down(event.index,event.position)
        else:_route_touch_up(event.index)
    elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
        if event.pressed:_route_mouse_down(event.position)
        else:_set_sprint(false)

func _route_touch_down(id:int,pos:Vector2):
    var tool_index:=_hotbar_index_at(pos)
    if tool_index>=0:_select_tool(tool_index);get_viewport().set_input_as_handled();return
    if use_touch==-1 and _contains(use_pad,pos):use_touch=id;_set_pad_active(use_pad,true);_trigger_use();get_viewport().set_input_as_handled();return
    if jump_touch==-1 and _contains(jump_pad,pos):jump_touch=id;_set_pad_active(jump_pad,true);_trigger_jump();get_viewport().set_input_as_handled();return
    if sprint_touch==-1 and _contains(sprint_pad,pos):sprint_touch=id;_set_pad_active(sprint_pad,true);_set_sprint(true);get_viewport().set_input_as_handled();return

func _route_touch_up(id:int):
    if id==use_touch:use_touch=-1;_set_pad_active(use_pad,false);get_viewport().set_input_as_handled();return
    if id==jump_touch:jump_touch=-1;_set_pad_active(jump_pad,false);get_viewport().set_input_as_handled();return
    if id==sprint_touch:sprint_touch=-1;_set_pad_active(sprint_pad,false);_set_sprint(false);get_viewport().set_input_as_handled();return

func _route_mouse_down(pos:Vector2):
    if _contains(use_pad,pos):_trigger_use()
    elif _contains(jump_pad,pos):_trigger_jump()
    elif _contains(sprint_pad,pos):_set_sprint(true)

func _hotbar_index_at(pos:Vector2)->int:
    var scene=_scene();if scene==null:return -1
    var buttons=scene.get("tool_buttons");if buttons==null:return -1
    for i in range(buttons.size()):
        var button=buttons[i]
        if button!=null and not button.disabled and button.get_global_rect().has_point(pos):return i
    return -1

func _select_tool(index:int):
    var scene=_scene()
    if scene!=null and scene.has_method("_select_tool"):scene.call("_select_tool",index);call_deferred("_style_hotbar")

func _contains(pad:Control,pos:Vector2)->bool:return pad!=null and pad.get_global_rect().has_point(pos)
func _scene():return get_tree().current_scene
func _trigger_use():
    var scene=_scene();if scene!=null and scene.has_method("_context_action"):scene.call("_context_action")
func _trigger_jump():
    var scene=_scene();if scene!=null and scene.has_method("jump"):scene.call("jump")
func _set_sprint(value:bool):
    var scene=_scene();if scene!=null and scene.has_method("set_sprinting"):scene.call("set_sprinting",value)
