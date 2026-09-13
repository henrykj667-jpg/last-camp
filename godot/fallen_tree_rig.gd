extends Node

var game: Node
var tracked: Dictionary={}
var fallen: Array[Node3D]=[]
var stored_wood:=0

func _ready():
    process_priority=-100

func _process(_delta):
    var scene:=get_tree().current_scene
    if scene==null:return
    if game!=scene:
        game=scene
        tracked.clear()
        fallen.clear()
        stored_wood=int(game.get("wood"))

    # Wood must only enter the backpack through a future pickup action.
    # main.gd still contains the old +3 reward, so suppress it unconditionally.
    if int(game.get("wood"))!=stored_wood:
        game.set("wood",stored_wood)

    var current: Dictionary={}
    var trees_value=game.get("trees")
    if trees_value==null:return
    for tree in trees_value:
        if tree==null or not is_instance_valid(tree):continue
        var id:=tree.get_instance_id()
        current[id]={"pos":tree.global_position,"hits":int(tree.get_meta("hits",0))}

    for id in tracked.keys():
        if current.has(id):continue
        var old:Dictionary=tracked[id]
        if int(old.get("hits",0))>=4:
            _spawn_fallen_tree(old.get("pos",Vector3.ZERO))
    tracked=current

func _spawn_fallen_tree(pos:Vector3):
    var root:=Node3D.new()
    root.name="FallenTree"
    game.add_child(root)
    root.global_position=pos
    fallen.append(root)
    _cylinder(root,Vector3(0,1.7,0),.34,3.4,Color("76513a"))
    for y in [3.1,4.0,4.8]:
        var crown:=MeshInstance3D.new()
        var cone:=CylinderMesh.new()
        cone.top_radius=0
        cone.bottom_radius=1.55-(y-3.1)*.22
        cone.height=2.1
        crown.mesh=cone
        crown.position.y=y
        crown.material_override=_mat(Color("2f5837"))
        root.add_child(crown)
    var direction:=1.0 if (fallen.size()%2)==0 else -1.0
    var tw:=game.create_tween()
    tw.set_trans(Tween.TRANS_QUAD)
    tw.set_ease(Tween.EASE_IN)
    tw.tween_property(root,"rotation:z",direction*deg_to_rad(88.0),.85)
    tw.set_trans(Tween.TRANS_BOUNCE)
    tw.set_ease(Tween.EASE_OUT)
    tw.tween_property(root,"rotation:z",direction*deg_to_rad(90.0),.18)

func _mat(color:Color)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=color
    m.roughness=.9
    return m

func _cylinder(parent:Node3D,pos:Vector3,radius:float,height:float,color:Color)->MeshInstance3D:
    var n:=MeshInstance3D.new()
    var c:=CylinderMesh.new()
    c.top_radius=radius
    c.bottom_radius=radius
    c.height=height
    n.mesh=c
    n.position=pos
    n.material_override=_mat(color)
    parent.add_child(n)
    return n
