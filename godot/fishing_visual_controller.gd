extends Node

var rig: Node3D
var line_root: Node3D
var bobber: Node3D
var rod_node: Node3D
var pole_mesh: MeshInstance3D
var fish_root: Node3D
var was_busy := false
var cast_running := false
var line_cast := false
var bite_running := false
var bite_timer := 0.0
var rng:=RandomNumberGenerator.new()

func _ready():
    process_mode=Node.PROCESS_MODE_ALWAYS
    rng.randomize()

func _process(delta):
    var scene:=get_tree().current_scene
    if scene==null:return
    _ensure_fish(scene)
    var selected:=str(scene.get("selected_tool"))
    if selected!="FISHING ROD":
        _clear_visuals()
        was_busy=bool(scene.get("action_busy"))
        return
    var held=scene.get("held_tool") as Node3D
    if held==null:return
    if rig==null or not is_instance_valid(rig) or rig.get_parent()!=held:_build_idle_rig(held)
    var busy:=bool(scene.get("action_busy"))
    if busy and not was_busy and not cast_running:
        if line_cast:_animate_reel()
        else:_animate_cast(scene)
    was_busy=busy
    if line_cast and not cast_running and not bite_running:
        bite_timer-=delta
        if bite_timer<=0.0:_animate_bite()

func _clear_visuals():
    cast_running=false;line_cast=false;bite_running=false;bite_timer=0.0
    if rig!=null and is_instance_valid(rig):rig.queue_free()
    rig=null;line_root=null;bobber=null;rod_node=null;pole_mesh=null

func _find_actual_rod(held:Node3D):
    rod_node=null;pole_mesh=null
    for child in held.get_children():
        if child==rig or not (child is Node3D):continue
        var candidate:=child as Node3D
        for part in candidate.get_children():
            if part is MeshInstance3D and (part as MeshInstance3D).mesh is CylinderMesh:
                var cyl: CylinderMesh=(part as MeshInstance3D).mesh
                if cyl.height>1.5:rod_node=candidate;pole_mesh=part as MeshInstance3D;return

func _rod_points()->Array[Vector3]:
    if rod_node==null or pole_mesh==null or not is_instance_valid(rod_node) or not is_instance_valid(pole_mesh):return [Vector3.ZERO,Vector3(0,0,1.8)]
    var cyl:=pole_mesh.mesh as CylinderMesh;var half:=cyl.height*.5
    var a:Vector3=rod_node.transform*(pole_mesh.transform*Vector3(0,-half,0));var b:Vector3=rod_node.transform*(pole_mesh.transform*Vector3(0,half,0))
    if a.length()>b.length():return [b,a]
    return [a,b]

func _idle_bobber_position()->Vector3:return _rod_points()[1]+Vector3(0,-.42,0)

func _build_idle_rig(held:Node3D):
    _clear_visuals();rig=Node3D.new();rig.name="FishingLineVisual";held.add_child(rig);_find_actual_rod(held)
    line_root=Node3D.new();rig.add_child(line_root);bobber=Node3D.new();bobber.position=_idle_bobber_position();rig.add_child(bobber);_bobber_mesh(bobber)

func _water_target(scene:Node,tip:Vector3,flat:Vector3)->Vector3:
    var target:=tip+flat*4.4+Vector3(0,-.45,0)
    if bool(scene.call("_near_water")):
        # Convert the lake surface (world y=.08) into held-tool local space so the float actually sits on the water.
        var world_guess:=rig.to_global(tip+flat*4.8)
        world_guess.y=.10
        target=rig.to_local(world_guess)
    return target

func _animate_cast(scene:Node):
    if bobber==null:return
    cast_running=true;bite_running=false
    var points:=_rod_points();var tip:=points[1];var outward:=(tip-points[0]).normalized();var flat:=Vector3(outward.x,0,outward.z)
    if flat.length()<.1:flat=Vector3(0,0,-1)
    flat=flat.normalized();var peak:=tip+flat*2.4+Vector3(0,1.15,0);var target:=_water_target(scene,tip,flat)
    var tw:=create_tween();tw.set_trans(Tween.TRANS_SINE);tw.set_ease(Tween.EASE_OUT);tw.tween_property(bobber,"position",peak,.28);tw.set_ease(Tween.EASE_IN);tw.tween_property(bobber,"position",target,.36)
    tw.finished.connect(func():line_cast=true;cast_running=false;bite_timer=rng.randf_range(2.5,6.0))

func _animate_reel():
    if bobber==null:return
    cast_running=true;bite_running=false
    var target:=_idle_bobber_position();var duration:=clamp(bobber.position.distance_to(target)/8.0,.28,.65)
    var tw:=create_tween();tw.set_trans(Tween.TRANS_SINE);tw.set_ease(Tween.EASE_IN_OUT);tw.tween_property(bobber,"position",target,duration)
    tw.finished.connect(func():line_cast=false;cast_running=false;bite_timer=0.0)

func _animate_bite():
    if bobber==null or not line_cast:return
    bite_running=true
    var surface:=bobber.position;var under:=surface+Vector3(0,-.28,0)
    var tw:=create_tween();tw.set_trans(Tween.TRANS_SINE);tw.set_ease(Tween.EASE_IN_OUT)
    tw.tween_property(bobber,"position",under,.16);tw.tween_interval(.38);tw.tween_property(bobber,"position",surface,.24)
    tw.finished.connect(func():bite_running=false;bite_timer=rng.randf_range(3.0,7.0))

func _ensure_fish(scene:Node):
    if fish_root!=null and is_instance_valid(fish_root):return
    var water=scene.get("water_zone") as Node3D
    if water==null:return
    fish_root=Node3D.new();fish_root.name="LakeFish";water.add_child(fish_root)
    var positions=[Vector3(-2.6,-.16,-1.2),Vector3(1.8,-.18,-1.7),Vector3(-.8,-.20,2.1),Vector3(2.7,-.17,1.1),Vector3(.5,-.22,.2)]
    for i in range(positions.size()):_make_fish(fish_root,positions[i],-25.0+i*31.0)

func _make_fish(parent:Node3D,pos:Vector3,yaw:float):
    var f:=Node3D.new();f.position=pos;f.rotation_degrees.y=yaw;parent.add_child(f)
    var body:=MeshInstance3D.new();var s:=SphereMesh.new();s.radius=.18;s.height=.32;body.mesh=s;body.scale=Vector3(1.8,.55,.72);body.material_override=_fish_mat();f.add_child(body)
    var tail:=MeshInstance3D.new();var p:=PrismMesh.new();p.size=Vector3(.20,.24,.28);tail.mesh=p;tail.position=Vector3(-.34,0,0);tail.rotation_degrees.z=90;tail.material_override=_fish_mat();f.add_child(tail)

func _fish_mat()->StandardMaterial3D:
    var m:=StandardMaterial3D.new();m.albedo_color=Color(.12,.30,.34,.82);m.roughness=.75;return m

func _physics_process(_delta):
    if rig==null or bobber==null or line_root==null or not is_instance_valid(rig):return
    for child in line_root.get_children():child.queue_free()
    var points:=_rod_points();var base:=points[0];var tip:=points[1]
    _segment(line_root,base,tip,.012,Color(.92,.94,.90));_segment(line_root,tip,bobber.position,.012,Color(.92,.94,.90))

func _segment(parent:Node3D,a:Vector3,b:Vector3,radius:float,color:Color):
    var d:=b-a
    if d.length()<.001:return
    var mesh:=MeshInstance3D.new();var cyl:=CylinderMesh.new();cyl.top_radius=radius;cyl.bottom_radius=radius;cyl.height=d.length();mesh.mesh=cyl
    var mat:=StandardMaterial3D.new();mat.albedo_color=color;mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mesh.material_override=mat;mesh.position=(a+b)*.5;mesh.quaternion=Quaternion(Vector3.UP,d.normalized());parent.add_child(mesh)

func _bobber_mesh(parent:Node3D):
    var top:=MeshInstance3D.new();var s1:=SphereMesh.new();s1.radius=.085;s1.height=.17;top.mesh=s1;top.position.y=.055;var red:=StandardMaterial3D.new();red.albedo_color=Color("e94b3c");top.material_override=red;parent.add_child(top)
    var bottom:=MeshInstance3D.new();var s2:=SphereMesh.new();s2.radius=.085;s2.height=.17;bottom.mesh=s2;bottom.position.y=-.055;var white:=StandardMaterial3D.new();white.albedo_color=Color("f2f0df");bottom.material_override=white;parent.add_child(bottom)
    var stem:=MeshInstance3D.new();var c:=CylinderMesh.new();c.top_radius=.018;c.bottom_radius=.018;c.height=.24;stem.mesh=c;stem.position.y=-.13;stem.material_override=red;parent.add_child(stem)
