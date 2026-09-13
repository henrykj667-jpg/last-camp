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
            touch_down_id=touch.index
            _toggle_inventory()
            get_viewport().set_input_as_handled()
        elif not touch.pressed and touch.index==touch_down_id:
            touch_down_id=-1
            get_viewport().set_input_as_handled()

func _build_ui():
    layer=CanvasLayer.new();layer.name="BackpackInventoryUI";layer.layer=30;add_child(layer)

    toggle=Button.new()
    toggle.text="BAG"
    toggle.position=Vector2(1168,250)
    toggle.size=Vector2(92,72)
    toggle.add_theme_font_size_override("font_size",20)
    toggle.focus_mode=Control.FOCUS_NONE
    toggle.mouse_filter=Control.MOUSE_FILTER_STOP
    toggle.pressed.connect(_toggle_inventory)
    layer.add_child(toggle)

    panel=Panel.new()
    panel.position=Vector2(875,120)
    panel.size=Vector2(275,390)
    panel.visible=false
    panel.mouse_filter=Control.MOUSE_FILTER_STOP
    layer.add_child(panel)

    var box:=VBoxContainer.new();box.position=Vector2(22,20);box.size=Vector2(231,345);box.add_theme_constant_override("separation",14);panel.add_child(box)
    var title:=Label.new();title.text="BACKPACK";title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;title.add_theme_font_size_override("font_size",28);box.add_child(title)
    var hint:=Label.new();hint.text="CARRIED ITEMS";hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;hint.add_theme_font_size_override("font_size",14);box.add_child(hint)
    var line:=HSeparator.new();box.add_child(line)
    contents=VBoxContainer.new();contents.add_theme_constant_override("separation",16);box.add_child(contents)
    var close:=Button.new();close.text="CLOSE";close.custom_minimum_size=Vector2(0,55);close.add_theme_font_size_override("font_size",18);close.focus_mode=Control.FOCUS_NONE;close.pressed.connect(_close_inventory);box.add_child(close)
    _refresh()

func _toggle_inventory():
    open=not open
    if panel!=null:panel.visible=open
    if toggle!=null:toggle.text="CLOSE" if open else "BAG"

func _close_inventory():
    open=false
    if panel!=null:panel.visible=false
    if toggle!=null:toggle.text="BAG"

func _refresh():
    if contents==null or game==null:return
    for child in contents.get_children():child.queue_free()
    _add_row("FISH",int(game.get("fish")))
    _add_row("BERRIES",int(game.get("berries")))
    _add_row("WOOD",int(game.get("wood")))

func _add_row(name:String,count:int):
    var row:=Label.new();row.text=name+"   x "+str(count);row.add_theme_font_size_override("font_size",24);contents.add_child(row)
