extends Node

var game: Node
var layer: CanvasLayer
var toggle: Button
var panel: Panel
var contents: VBoxContainer
var open:=false
var last_counts:=Vector3i(-1,-1,-1)

func _ready():
    process_mode=Node.PROCESS_MODE_ALWAYS

func _process(_delta):
    game=get_tree().current_scene
    if game==null:return
    if layer==null or not is_instance_valid(layer):_build_ui()
    var counts:=Vector3i(int(game.get("fish")),int(game.get("berries")),int(game.get("wood")))
    if counts!=last_counts:
        last_counts=counts;_refresh()

func _build_ui():
    layer=CanvasLayer.new();layer.name="BackpackInventoryUI";add_child(layer)
    toggle=Button.new();toggle.text="🎒";toggle.position=Vector2(1190,285);toggle.size=Vector2(70,70);toggle.add_theme_font_size_override("font_size",30);toggle.pressed.connect(_toggle_inventory);layer.add_child(toggle)
    panel=Panel.new();panel.position=Vector2(920,170);panel.size=Vector2(250,350);panel.visible=false;layer.add_child(panel)
    var box:=VBoxContainer.new();box.position=Vector2(20,18);box.size=Vector2(210,315);panel.add_child(box)
    var title:=Label.new();title.text="BACKPACK";title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;title.add_theme_font_size_override("font_size",24);box.add_child(title)
    var line:=HSeparator.new();box.add_child(line)
    contents=VBoxContainer.new();contents.add_theme_constant_override("separation",12);box.add_child(contents)
    _refresh()

func _toggle_inventory():
    open=not open
    if panel!=null:panel.visible=open

func _refresh():
    if contents==null or game==null:return
    for child in contents.get_children():child.queue_free()
    _add_row("FISH",int(game.get("fish")))
    _add_row("BERRIES",int(game.get("berries")))
    _add_row("WOOD",int(game.get("wood")))

func _add_row(name:String,count:int):
    var row:=Label.new();row.text=name+"  ×"+str(count);row.add_theme_font_size_override("font_size",22);contents.add_child(row)
