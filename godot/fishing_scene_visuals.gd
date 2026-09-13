extends Node3D

var game: Node
var bobber: Node3D
var fish_nodes: Array[Node3D]=[]
var fish_origins: Array[Vector3]=[]
var line_mesh: MeshInstance3D
var cast_out:=false
var was_busy:=false
var t:=0.0

func _ready():
    game=get_parent()
    bobber=get_node_or_null("BobberProof") as Node3D
    if bobber!=null:bobber.visible=false
    for i in range(1,5):
        var f=get_node_or_null("Fish"+str(i)) as Node3D
        if f!=null:
            f.position.y=.055
            f.rotation_degrees.z=0
            fish_nodes.append(f);fish_origins.append(f.position)
    line_mesh=MeshInstance3D.new();line_mesh.name="FishingLine";add_child(line_mesh);line_mesh.visible=false
    call_deferred("_soften_water")

func _soften_water():
    var water=game.get("water_zone") as Node3D
    if water==null:return
    for child in water.get_children():
        if child is MeshInstance3D:
            var mesh:=child as MeshInstance3D
            var mat:=StandardMaterial3D.new();mat.albedo_color=Color(0.29,0.63,0.76,.78);mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mat.roughness=.35;mesh.material_override=mat

func _process(delta):
    t+=delta
    for i in range(fish_nodes.size()):
        var f:=fish_nodes[i]
        var base:=fish_origins[i]
        f.position.x=base.x+sin(t*.55+i*1.7)*.55
        f.position.z=base.z+cos(t*.48+i*1.3)*.42
        f.position.y=.045+sin(t*1.1+i)*.018
        f.rotation.y+=delta*(.18 if i%2==0 else -.15)
    var selected:=str(game.get("selected_tool"))
    if selected!="FISHING ROD":
        cast_out=false
        if bobber!=null:bobber.visible=false
        line_mesh.visible=false
        was_busy=bool(game.get("action_busy"));return
    _polish_rod()
    var busy:=bool(game.get("action_busy"))
    if busy and not was_busy:
        if cast_out:_reel()
        else:_cast()
    was_busy=busy
    if cast_out and bobber!=null and bobber.visible:
        bobber.position.y=.105+sin(t*2.1)*.018
        _update_line()

func _polish_rod():
    var held=game.get("held_tool") as Node3D
    if held==null:return
    for child in held.get_children():
        if not (child is Node3D):continue
        for part in child.get_children():
            if part is MeshInstance3D and (part as MeshInstance3D).mesh is CylinderMesh:
                var mi:=part as MeshInstance3D;var cyl:=mi.mesh as CylinderMesh
                if cyl.height>1.5:
                    cyl.top_radius=.018;cyl.bottom_radius=.035;cyl.height=2.15
                    var mat:=StandardMaterial3D.new();mat.albedo_color=Color(.12,.10,.08);mat.roughness=.55;mi.material_override=mat

func _rod_tip()->Vector3:
    var held=game.get("held_tool") as Node3D
    if held==null:return Vector3.ZERO
    var best:=held.global_position;var dist:=0.0
    for child in held.get_children():
        if not (child is Node3D):continue
        for part in child.get_children():
            if part is MeshInstance3D and (part as MeshInstance3D).mesh is CylinderMesh:
                var mi:=part as MeshInstance3D;var cyl:=mi.mesh as CylinderMesh
                if cyl.height<1.5:continue
                var a:=mi.to_global(Vector3(0,-cyl.height*.5,0));var b:=mi.to_global(Vector3(0,cyl.height*.5,0));var hand:=held.global_position
                var tip:=a if a.distance_to(hand)>b.distance_to(hand) else b
                if tip.distance_to(hand)>dist:best=tip;dist=tip.distance_to(hand)
    return best

func _cast():
    if bobber==null:return
    var water=game.get("water_zone") as Node3D
    if water==null:return
    bobber.visible=true;line_mesh.visible=true
    bobber.global_position=_rod_tip()
    var center:=water.global_position;var player=game.get("player") as Node3D
    var d:=Vector2(player.global_position.x-center.x,player.global_position.z-center.z)
    if d.length()<.1:d=Vector2(0,1)
    d=d.normalized();var target:=Vector3(center.x+d.x*3.0,.105,center.z+d.y*3.0)
    var peak:=(bobber.global_position+target)*.5+Vector3(0,1.35,0)
    var tw:=create_tween();tw.set_trans(Tween.TRANS_SINE);tw.set_ease(Tween.EASE_OUT);tw.tween_property(bobber,"global_position",peak,.24);tw.set_ease(Tween.EASE_IN);tw.tween_property(bobber,"global_position",target,.34)
    tw.finished.connect(func():cast_out=true)

func _reel():
    if bobber==null:return
    var tw:=create_tween();tw.tween_property(bobber,"global_position",_rod_tip(),.38)
    tw.finished.connect(func():cast_out=false;bobber.visible=false;line_mesh.visible=false)

func _update_line():
    var a:=_rod_tip();var b:=bobber.global_position;var d:=b-a
    if d.length()<.02:return
    var cyl:=CylinderMesh.new();cyl.top_radius=.009;cyl.bottom_radius=.009;cyl.height=d.length();line_mesh.mesh=cyl
    var mat:=StandardMaterial3D.new();mat.albedo_color=Color(.92,.94,.90);mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;line_mesh.material_override=mat
    line_mesh.global_position=(a+b)*.5;line_mesh.quaternion=Quaternion(Vector3.UP,d.normalized())
