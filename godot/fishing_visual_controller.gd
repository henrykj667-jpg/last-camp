extends Node

var fish_root: Node3D
var bobber: Node3D
var line_root: Node3D
var held_ref: Node3D
var was_busy:=false
var line_cast:=false

func _process(_delta):
    var scene:=get_tree().current_scene
    if scene==null:return
    _ensure_fish(scene)
    var selected:=str(scene.get("selected_tool"))
    if selected!="FISHING ROD":
        _clear_rod_visuals();was_busy=bool(scene.get("action_busy"));return
    var held=scene.get("held_tool") as Node3D
    if held==null:return
    if held_ref!=held or bobber==null or not is_instance_valid(bobber):_make_rod_visuals(scene,held)
    var busy:=bool(scene.get("action_busy"))
    if busy and not was_busy:
        if line_cast:_reel_in()
        else:_cast(scene)
    was_busy=busy
    _draw_line()

func _clear_rod_visuals():
    if bobber!=null and is_instance_valid(bobber):bobber.queue_free()
    if line_root!=null and is_instance_valid(line_root):line_root.queue_free()
    bobber=null;line_root=null;held_ref=null;line_cast=false

func _make_rod_visuals(scene:Node,held:Node3D):
    _clear_rod_visuals();held_ref=held
    bobber=Node3D.new();bobber.name="DEBUG_VISIBLE_BOBBER";scene.add_child(bobber)
    bobber.global_position=held.global_position+Vector3(0,.35,0)
    _make_bobber(bobber)
    line_root=Node3D.new();line_root.name="FishingLineWorld";scene.add_child(line_root)

func _rod_end()->Vector3:
    if held_ref==null:return Vector3.ZERO
    var best:=held_ref.global_position
    var best_dist:=0.0
    for child in held_ref.get_children():
        if not (child is Node3D):continue
        var n:=child as Node3D
        for part in n.get_children():
            if part is MeshInstance3D and (part as MeshInstance3D).mesh is CylinderMesh:
                var cyl: CylinderMesh=(part as MeshInstance3D).mesh
                if cyl.height<1.5:continue
                var mesh:=part as MeshInstance3D
                var a:=mesh.to_global(Vector3(0,-cyl.height*.5,0));var b:=mesh.to_global(Vector3(0,cyl.height*.5,0))
                var hand:=held_ref.global_position
                var tip:=a if a.distance_to(hand)>b.distance_to(hand) else b
                if tip.distance_to(hand)>best_dist:best=tip;best_dist=tip.distance_to(hand)
    return best

func _cast(scene:Node):
    if bobber==null:return
    var water=scene.get("water_zone") as Node3D
    if water==null:return
    var center:=water.global_position
    var player_pos:=held_ref.global_position
    var d:=Vector2(player_pos.x-center.x,player_pos.z-center.z)
    if d.length()<.1:d=Vector2(0,1)
    d=d.normalized()
    var target:=Vector3(center.x+d.x*3.2,center.y+.16,center.z+d.y*3.2)
    var start:=_rod_end();bobber.global_position=start
    var peak:=(start+target)*.5+Vector3(0,1.5,0)
    var tw:=create_tween();tw.tween_property(bobber,"global_position",peak,.25);tw.tween_property(bobber,"global_position",target,.35)
    tw.finished.connect(func():line_cast=true)

func _reel_in():
    if bobber==null:return
    var tw:=create_tween();tw.tween_property(bobber,"global_position",_rod_end(),.4)
    tw.finished.connect(func():line_cast=false)

func _draw_line():
    if line_root==null or bobber==null or held_ref==null:return
    for c in line_root.get_children():c.queue_free()
    var a:=_rod_end();var b:=bobber.global_position;var d:=b-a
    if d.length()<.02:return
    var mesh:=MeshInstance3D.new();var cyl:=CylinderMesh.new();cyl.top_radius=.018;cyl.bottom_radius=.018;cyl.height=d.length();mesh.mesh=cyl
    var mat:=StandardMaterial3D.new();mat.albedo_color=Color(1,1,1);mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mesh.material_override=mat
    line_root.add_child(mesh);mesh.global_position=(a+b)*.5;mesh.quaternion=Quaternion(Vector3.UP,d.normalized())

func _ensure_fish(scene:Node):
    if fish_root!=null and is_instance_valid(fish_root):return
    var water=scene.get("water_zone") as Node3D
    if water==null:return
    fish_root=Node3D.new();fish_root.name="VISIBLE_FISH_TEST";scene.add_child(fish_root)
    var center:=water.global_position
    var offsets=[Vector3(-2.0,.20,-1.0),Vector3(1.5,.20,-1.3),Vector3(-.6,.20,1.8),Vector3(2.0,.20,.8),Vector3(.3,.20,.1)]
    for i in range(offsets.size()):_make_fish(fish_root,center+offsets[i],float(i)*38.0)

func _make_fish(parent:Node3D,pos:Vector3,yaw:float):
    var f:=Node3D.new();parent.add_child(f);f.global_position=pos;f.rotation_degrees.y=yaw
    var body:=MeshInstance3D.new();var s:=SphereMesh.new();s.radius=.30;s.height=.50;body.mesh=s;body.scale=Vector3(1.8,.45,.75);body.material_override=_fish_material();f.add_child(body)
    var tail:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=Vector3(.28,.30,.10);tail.mesh=box;tail.position=Vector3(-.52,0,0);tail.rotation_degrees.z=45;tail.material_override=_fish_material();f.add_child(tail)

func _fish_material()->StandardMaterial3D:
    var m:=StandardMaterial3D.new();m.albedo_color=Color(.95,.42,.08);m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;return m

func _make_bobber(parent:Node3D):
    var ball:=MeshInstance3D.new();var s:=SphereMesh.new();s.radius=.18;s.height=.36;ball.mesh=s
    var red:=StandardMaterial3D.new();red.albedo_color=Color(1,.05,.05);red.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;ball.material_override=red;parent.add_child(ball)
    var stem:=MeshInstance3D.new();var c:=CylinderMesh.new();c.top_radius=.035;c.bottom_radius=.035;c.height=.45;stem.mesh=c;stem.position.y=.20;stem.material_override=red;parent.add_child(stem)
