extends Node

var rig: Node3D
var line_root: Node3D
var bobber: Node3D
var rod_node: Node3D
var pole_mesh: MeshInstance3D
var fish_root: Node3D
var held_ref: Node3D
var was_busy := false
var cast_running := false
var line_cast := false
var bite_running := false
var bite_timer := 0.0
var rng:=RandomNumberGenerator.new()

const LAKE_RADIUS:=5.0
const WATER_Y:=0.10

func _ready():
    process_mode=Node.PROCESS_MODE_ALWAYS
    rng.randomize()

func _process(delta):
    var scene:=get_tree().current_scene
    if scene==null:return
    _ensure_fish(scene)
    var selected:=str(scene.get("selected_tool"))
    if selected!="FISHING ROD":
        _clear_visuals();was_busy=bool(scene.get("action_busy"));return
    var held=scene.get("held_tool") as Node3D
    if held==null:return
    if held_ref!=held or rig==null or not is_instance_valid(rig):_build_rig(scene,held)
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
    rig=null;line_root=null;bobber=null;rod_node=null;pole_mesh=null;held_ref=null

func _find_actual_rod(held:Node3D):
    rod_node=null;pole_mesh=null
    for child in held.get_children():
        if not (child is Node3D):continue
        var candidate:=child as Node3D
        for part in candidate.get_children():
            if part is MeshInstance3D and (part as MeshInstance3D).mesh is CylinderMesh:
                var cyl: CylinderMesh=(part as MeshInstance3D).mesh
                if cyl.height>1.5:rod_node=candidate;pole_mesh=part as MeshInstance3D;return

func _rod_tip_world()->Vector3:
    if rod_node==null or pole_mesh==null or not is_instance_valid(rod_node) or not is_instance_valid(pole_mesh):
        return held_ref.global_position if held_ref!=null else Vector3.ZERO
    var cyl:=pole_mesh.mesh as CylinderMesh
    var half:=cyl.height*.5
    var a:=pole_mesh.to_global(Vector3(0,-half,0))
    var b:=pole_mesh.to_global(Vector3(0,half,0))
    var hand:=held_ref.global_position
    return a if a.distance_to(hand)>b.distance_to(hand) else b

func _build_rig(scene:Node,held:Node3D):
    _clear_visuals();held_ref=held;_find_actual_rod(held)
    rig=Node3D.new();rig.name="FishingWorldVisuals";scene.add_child(rig)
    line_root=Node3D.new();line_root.name="FishingLine";rig.add_child(line_root)
    bobber=Node3D.new();bobber.name="Bobber";bobber.global_position=_rod_tip_world()+Vector3(0,-.35,0);rig.add_child(bobber);_bobber_mesh(bobber)

func _lake_target(scene:Node)->Vector3:
    var water=scene.get("water_zone") as Node3D
    if water==null:return _rod_tip_world()+Vector3(0,-1.0,-3.5)
    var center:=water.global_position
    var from_center:=Vector2(_rod_tip_world().x-center.x,_rod_tip_world().z-center.z)
    if from_center.length()<.1:from_center=Vector2(0,1)
    var shore_dir:=from_center.normalized()
    var target2:=Vector2(center.x,center.z)+shore_dir*(LAKE_RADIUS-1.5)
    return Vector3(target2.x,center.y+WATER_Y,target2.y)

func _animate_cast(scene:Node):
    if bobber==null:return
    cast_running=true;bite_running=false
    var start:=_rod_tip_world()+Vector3(0,-.25,0);bobber.global_position=start
    var target:=_lake_target(scene)
    var peak:=(start+target)*.5+Vector3(0,1.7,0)
    var tw:=create_tween();tw.set_trans(Tween.TRANS_SINE);tw.set_ease(Tween.EASE_OUT);tw.tween_property(bobber,"global_position",peak,.28);tw.set_ease(Tween.EASE_IN);tw.tween_property(bobber,"global_position",target,.38)
    tw.finished.connect(func():line_cast=true;cast_running=false;bite_timer=rng.randf_range(2.5,6.0))

func _animate_reel():
    if bobber==null:return
    cast_running=true;bite_running=false
    var target:=_rod_tip_world()+Vector3(0,-.30,0)
    var tw:=create_tween();tw.set_trans(Tween.TRANS_SINE);tw.set_ease(Tween.EASE_IN_OUT);tw.tween_property(bobber,"global_position",target,.45)
    tw.finished.connect(func():line_cast=false;cast_running=false;bite_timer=0.0)

func _animate_bite():
    if bobber==null or not line_cast:return
    bite_running=true
    var surface:=bobber.global_position;var under:=surface;under.y-=.30
    var tw:=create_tween();tw.set_trans(Tween.TRANS_SINE);tw.set_ease(Tween.EASE_IN_OUT);tw.tween_property(bobber,"global_position",under,.16);tw.tween_interval(.38);tw.tween_property(bobber,"global_position",surface,.24)
    tw.finished.connect(func():bite_running=false;bite_timer=rng.randf_range(3.0,7.0))

func _ensure_fish(scene:Node):
    if fish_root!=null and is_instance_valid(fish_root):return
    var water=scene.get("water_zone") as Node3D
    if water==null:return
    fish_root=Node3D.new();fish_root.name="LakeFishWorld";scene.add_child(fish_root)
    var c:=water.global_position
    var offsets=[Vector3(-2.3,0,-1.0),Vector3(1.7,0,-1.5),Vector3(-.8,0,2.0),Vector3(2.4,0,1.0),Vector3(.4,0,.2)]
    for i in range(offsets.size()):
        var p:Vector3=c+offsets[i];p.y=c.y+.16;_make_fish(fish_root,p,-25.0+i*31.0)

func _make_fish(parent:Node3D,pos:Vector3,yaw:float):
    var f:=Node3D.new();f.global_position=pos;f.rotation_degrees.y=yaw;parent.add_child(f)
    var body:=MeshInstance3D.new();var s:=SphereMesh.new();s.radius=.24;s.height=.42;body.mesh=s;body.scale=Vector3(1.9,.48,.72);body.material_override=_fish_mat();f.add_child(body)
    var tail:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=Vector3(.20,.24,.08);tail.mesh=box;tail.position=Vector3(-.45,0,0);tail.rotation_degrees.z=45;tail.material_override=_fish_mat();f.add_child(tail)

func _fish_mat()->StandardMaterial3D:
    var m:=StandardMaterial3D.new();m.albedo_color=Color(.08,.22,.26,1.0);m.roughness=.65;return m

func _physics_process(_delta):
    if rig==null or bobber==null or line_root==null or held_ref==null or not is_instance_valid(rig):return
    for child in line_root.get_children():child.queue_free()
    _segment(line_root,_rod_tip_world(),bobber.global_position,.012,Color(.92,.94,.90))

func _segment(parent:Node3D,a:Vector3,b:Vector3,radius:float,color:Color):
    var d:=b-a
    if d.length()<.001:return
    var mesh:=MeshInstance3D.new();var cyl:=CylinderMesh.new();cyl.top_radius=radius;cyl.bottom_radius=radius;cyl.height=d.length();mesh.mesh=cyl
    var mat:=StandardMaterial3D.new();mat.albedo_color=color;mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mesh.material_override=mat;mesh.global_position=(a+b)*.5;mesh.quaternion=Quaternion(Vector3.UP,d.normalized());parent.add_child(mesh)

func _bobber_mesh(parent:Node3D):
    var top:=MeshInstance3D.new();var s1:=SphereMesh.new();s1.radius=.12;s1.height=.24;top.mesh=s1;top.position.y=.07;var red:=StandardMaterial3D.new();red.albedo_color=Color("e94b3c");top.material_override=red;parent.add_child(top)
    var bottom:=MeshInstance3D.new();var s2:=SphereMesh.new();s2.radius=.12;s2.height=.24;bottom.mesh=s2;bottom.position.y=-.07;var white:=StandardMaterial3D.new();white.albedo_color=Color("f2f0df");bottom.material_override=white;parent.add_child(bottom)
    var stem:=MeshInstance3D.new();var c:=CylinderMesh.new();c.top_radius=.022;c.bottom_radius=.022;c.height=.30;stem.mesh=c;stem.position.y=-.17;stem.material_override=red;parent.add_child(stem)
