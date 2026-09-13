extends Node3D

var game: Node
var bobber: Node3D
var fish_nodes: Array[Node3D]=[]
var fish_origins: Array[Vector3]=[]
var fish_tails: Array[Node3D]=[]
var line_mesh: MeshInstance3D
var cast_out:=false
var casting:=false
var last_fish_count:=0
var t:=0.0

func _ready():
    game=get_parent()
    last_fish_count=int(game.get("fish"))
    for i in range(1,5):
        var f=get_node_or_null("Fish"+str(i)) as Node3D
        if f!=null:
            fish_nodes.append(f)
            fish_origins.append(f.position)
            var tail=f.get_node_or_null("Tail") as Node3D
            fish_tails.append(tail)
    line_mesh=MeshInstance3D.new();line_mesh.name="FishingLine";add_child(line_mesh);line_mesh.visible=false
    call_deferred("_soften_water")

func _soften_water():
    var water=game.get("water_zone") as Node3D
    if water==null:return
    for child in water.get_children():
        if child is MeshInstance3D:
            var mesh:=child as MeshInstance3D
            var mat:=StandardMaterial3D.new()
            mat.albedo_color=Color(0.24,0.67,0.79,.46)
            mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
            mat.roughness=.25
            mat.cull_mode=BaseMaterial3D.CULL_DISABLED
            mesh.material_override=mat

func _process(delta):
    t+=delta
    _animate_fish(delta)
    var selected:=str(game.get("selected_tool"))
    var current_fish:=int(game.get("fish"))
    if selected!="FISHING ROD":
        _remove_bobber();cast_out=false;casting=false;last_fish_count=current_fish;return
    _polish_rod()
    # main.gd already changes the fish counter inside its real USE -> _cast_rod path.
    # Watching that change ties the visual cast to the exact same mobile USE action.
    if current_fish!=last_fish_count and not casting:
        if cast_out:_reel()
        else:_cast()
    last_fish_count=current_fish
    if bobber!=null and is_instance_valid(bobber):
        if cast_out:bobber.global_position.y=.105+sin(t*2.1)*.012
        _update_line()

func _animate_fish(delta:float):
    for i in range(fish_nodes.size()):
        var f:=fish_nodes[i];var base:=fish_origins[i]
        var phase:=t*(.58+float(i)*.035)+float(i)*1.7
        var x:=base.x+sin(phase)*.90
        var z:=base.z+cos(phase*.82)*.68
        f.position=Vector3(x,base.y+sin(t*.8+float(i))*.006,z)
        var vx:=cos(phase)*.90
        var vz:=-sin(phase*.82)*.68*.82
        if abs(vx)+abs(vz)>.001:f.rotation.y=lerp_angle(f.rotation.y,atan2(-vz,vx),clamp(delta*4.0,0.0,1.0))
        if i<fish_tails.size() and fish_tails[i]!=null:
            fish_tails[i].rotation_degrees.y=sin(t*7.0+float(i)*1.4)*28.0

func _make_bobber()->Node3D:
    var root:=Node3D.new();root.name="CastBobber";add_child(root)
    var red:=StandardMaterial3D.new();red.albedo_color=Color(.95,.03,.02);red.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
    var white:=StandardMaterial3D.new();white.albedo_color=Color(1,1,1);white.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
    var top:=MeshInstance3D.new();var s1:=SphereMesh.new();s1.radius=.15;s1.height=.30;top.mesh=s1;top.scale=Vector3(1,.55,1);top.position.y=.075;top.material_override=red;root.add_child(top)
    var bottom:=MeshInstance3D.new();var s2:=SphereMesh.new();s2.radius=.15;s2.height=.30;bottom.mesh=s2;bottom.scale=Vector3(1,.55,1);bottom.position.y=-.065;bottom.material_override=white;root.add_child(bottom)
    var stem:=MeshInstance3D.new();var c:=CylinderMesh.new();c.top_radius=.022;c.bottom_radius=.022;c.height=.32;stem.mesh=c;stem.position.y=.20;stem.material_override=red;root.add_child(stem)
    return root

func _remove_bobber():
    if bobber!=null and is_instance_valid(bobber):bobber.queue_free()
    bobber=null
    if line_mesh!=null:line_mesh.visible=false

func _polish_rod():
    var held=game.get("held_tool") as Node3D
    if held==null:return
    for child in held.get_children():
        if not (child is Node3D):continue
        for part in child.get_children():
            if part is MeshInstance3D and (part as MeshInstance3D).mesh is CylinderMesh:
                var mi:=part as MeshInstance3D;var cyl:=mi.mesh as CylinderMesh
                if cyl.height>1.5:
                    cyl.top_radius=.010;cyl.bottom_radius=.025;cyl.height=2.05
                    var mat:=StandardMaterial3D.new();mat.albedo_color=Color(.08,.075,.065);mat.roughness=.55;mi.material_override=mat

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
    var water=game.get("water_zone") as Node3D
    if water==null:return
    _remove_bobber();bobber=_make_bobber();bobber.global_position=_rod_tip();line_mesh.visible=true;casting=true
    var center:=water.global_position;var player=game.get("player") as Node3D
    var d:=Vector2(player.global_position.x-center.x,player.global_position.z-center.z)
    if d.length()<.1:d=Vector2(0,1)
    d=d.normalized();var target:=Vector3(center.x+d.x*3.0,.105,center.z+d.y*3.0)
    var peak:=(bobber.global_position+target)*.5+Vector3(0,1.25,0)
    var tw:=create_tween();tw.set_trans(Tween.TRANS_SINE);tw.set_ease(Tween.EASE_OUT);tw.tween_property(bobber,"global_position",peak,.24);tw.set_ease(Tween.EASE_IN);tw.tween_property(bobber,"global_position",target,.34)
    tw.finished.connect(func():cast_out=true;casting=false)

func _reel():
    if bobber==null:return
    casting=true
    var tw:=create_tween();tw.tween_property(bobber,"global_position",_rod_tip(),.38)
    tw.finished.connect(func():cast_out=false;casting=false;_remove_bobber())

func _update_line():
    if bobber==null or not is_instance_valid(bobber):return
    var a:=_rod_tip();var b:=bobber.global_position;var d:=b-a
    if d.length()<.02:return
    var cyl:=CylinderMesh.new();cyl.top_radius=.009;cyl.bottom_radius=.009;cyl.height=d.length();line_mesh.mesh=cyl
    var mat:=StandardMaterial3D.new();mat.albedo_color=Color(.96,.97,.92);mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;line_mesh.material_override=mat
    line_mesh.global_position=(a+b)*.5;line_mesh.quaternion=Quaternion(Vector3.UP,d.normalized())
