extends Node

var game: Node
var layer: CanvasLayer
var toggle: Button
var panel: Panel
var contents: VBoxContainer
var open:=false
var last_counts:=Vector3i(-1,-1,-1)
var touch_down_id:=-1

func _ready():
    process_mode=Node.PROCESS_MODE_ALWAYS

func _process(_delta):
    game=get_tree().current_scene
    if game==null:return
    if layer==null or not is_instance_valid(layer):_build_ui()
    var counts:=Vector3i(int(game.get("fish")),int(game.get("berries")),int(game.get("wood")))
    if counts!=last_counts:
        last_counts=counts;_refresh()

func _input(event):
    if toggle==null or not is_instance_valid(toggle):return
    if event is InputEventScreenTouch:
        var touch:=event as InputEventScreenTouch
        if touch.pressed and toggle.get_global_rect().has_point(touch.position):
            touch_down_id=touch.index;_toggle_inventory();get_viewport().set_input_as_handled()
        elif not touch.pressed and touch.index==touch_down_id:
            touch_down_id=-1;get_viewport().set_input_as_handled()

func _build_ui():
    layer=CanvasLayer.new();layer.name="BackpackInventoryUI";layer.layer=30;add_child(layer)
    toggle=Button.new();toggle.text="BACKPACK";toggle.position=Vector2(1145,250);toggle.size=Vector2(115,72);toggle.add_theme_font_size_override("font_size",16);toggle.focus_mode=Control.FOCUS_NONE;toggle.mouse_filter=Control.MOUSE_FILTER_STOP;toggle.pressed.connect(_toggle_inventory);layer.add_child(toggle)
    panel=Panel.new();panel.position=Vector2(875,120);panel.size=Vector2(275,330);panel.visible=false;panel.mouse_filter=Control.MOUSE_FILTER_STOP;layer.add_child(panel)
    var box:=VBoxContainer.new();box.position=Vector2(22,20);box.size=Vector2(231,285);box.add_theme_constant_override("separation",14);panel.add_child(box)
    var title:=Label.new();title.text="BACKPACK";title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;title.add_theme_font_size_override("font_size",28);box.add_child(title)
    var hint:=Label.new();hint.text="CARRIED ITEMS";hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;hint.add_theme_font_size_override("font_size",14);box.add_child(hint)
    box.add_child(HSeparator.new())
    contents=VBoxContainer.new();contents.add_theme_constant_override("separation",16);box.add_child(contents)
    _refresh()

func _toggle_inventory():
    open=not open
    if panel!=null:panel.visible=open
    if toggle!=null:toggle.text="CLOSE" if open else "BACKPACK"

func _refresh():
    if contents==null or game==null:return
    for child in contents.get_children():child.queue_free()
    var fish_count:=int(game.get("fish"));var berry_count:=int(game.get("berries"));var wood_count:=int(game.get("wood"))
    if fish_count>0:_add_row("FISH",fish_count)
    if berry_count>0:_add_row("BERRIES",berry_count)
    if wood_count>0:_add_row("WOOD",wood_count)
    if fish_count<=0 and berry_count<=0 and wood_count<=0:
        var empty:=Label.new();empty.text="Empty";empty.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;empty.add_theme_font_size_override("font_size",20);contents.add_child(empty)

func _add_row(name:String,count:int):
    var row:=Label.new();row.text=name+"   x "+str(count);row.add_theme_font_size_override("font_size",24);contents.add_child(row)
