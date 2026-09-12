extends Node

var rig: Node3D
var line_root: Node3D
var bobber: Node3D
var was_busy := false
var cast_running := false

func _ready():
    process_mode=Node.PROCESS_MODE_ALWAYS

func _process(_delta):
    var scene:=get_tree().current_scene
    if scene==null:return
    var selected:=str(scene.get("selected_tool"))
    if selected!="FISHING ROD":
        _clear_visuals()
        was_busy=bool(scene.get("action_busy"))
        return
    var held=scene.get("held_tool") as Node3D
    if held==null:return
    if rig==null or not is_instance_valid(rig) or rig.get_parent()!=held:
        _build_idle_rig(held)
    var busy:=bool(scene.get("action_busy"))
    if busy and not was_busy and not cast_running:
        _animate_cast(scene,held)
    was_busy=busy

func _clear_visuals():
    cast_running=false
    if rig!=null and is_instance_valid(rig):rig.queue_free()
    rig=null;line_root=null;bobber=null

func _build_idle_rig(held:Node3D):
    _clear_visuals()
    rig=Node3D.new();rig.name="FishingLineVisual";held.add_child(rig)
    # Rod currently points along this local path. The line lies close to it in idle.
    line_root=Node3D.new();rig.add_child(line_root)
    _segment(line_root,Vector3(.02,.05,.03),Vector3(.02,.67,1.53),.012,Color(.92,.94,.90))
    _segment(line_root,Vector3(.02,.67,1.53),Vector3(.02,.35,1.55),.012,Color(.92,.94,.90))
    bobber=Node3D.new();bobber.position=Vector3(.02,.27,1.55);rig.add_child(bobber)
    _bobber_mesh(bobber)

func _animate_cast(scene:Node,held:Node3D):
    if bobber==null:return
    cast_running=true
    # Visual cast only: the existing USE/fishing logic remains untouched.
    var start:=bobber.position
    var forward:=Vector3(0,.20,4.4)
    var peak:=Vector3(0,1.75,2.4)
    var target:=forward
    if bool(scene.call("_near_water")):
        target=Vector3(0,.05,4.8)
    var tw:=create_tween()
    tw.set_trans(Tween.TRANS_SINE);tw.set_ease(Tween.EASE_OUT)
    tw.tween_property(bobber,"position",peak,.28)
    tw.set_ease(Tween.EASE_IN)
    tw.tween_property(bobber,"position",target,.36)
    tw.finished.connect(func():cast_running=false)

func _physics_process(_delta):
    if rig==null or bobber==null or line_root==null or not is_instance_valid(rig):return
    # Rebuild the thin line each frame so it follows the moving float during a cast.
    for child in line_root.get_children():child.queue_free()
    var tip:=Vector3(.02,.67,1.53)
    _segment(line_root,Vector3(.02,.05,.03),tip,.012,Color(.92,.94,.90))
    _segment(line_root,tip,bobber.position,.012,Color(.92,.94,.90))

func _segment(parent:Node3D,a:Vector3,b:Vector3,radius:float,color:Color):
    var d:=b-a
    if d.length()<.001:return
    var mesh:=MeshInstance3D.new();var cyl:=CylinderMesh.new();cyl.top_radius=radius;cyl.bottom_radius=radius;cyl.height=d.length();mesh.mesh=cyl
    var mat:=StandardMaterial3D.new();mat.albedo_color=color;mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mesh.material_override=mat
    mesh.position=(a+b)*.5
    mesh.quaternion=Quaternion(Vector3.UP,d.normalized())
    parent.add_child(mesh)

func _bobber_mesh(parent:Node3D):
    var top:=MeshInstance3D.new();var s1:=SphereMesh.new();s1.radius=.085;s1.height=.17;top.mesh=s1;top.position.y=.055
    var red:=StandardMaterial3D.new();red.albedo_color=Color("e94b3c");top.material_override=red;parent.add_child(top)
    var bottom:=MeshInstance3D.new();var s2:=SphereMesh.new();s2.radius=.085;s2.height=.17;bottom.mesh=s2;bottom.position.y=-.055
    var white:=StandardMaterial3D.new();white.albedo_color=Color("f2f0df");bottom.material_override=white;parent.add_child(bottom)
    var stem:=MeshInstance3D.new();var c:=CylinderMesh.new();c.top_radius=.018;c.bottom_radius=.018;c.height=.24;stem.mesh=c;stem.position.y=-.13;stem.material_override=red;parent.add_child(stem)
