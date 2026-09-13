extends Node

var game: Node
var idle_root: Node3D
var idle_line: MeshInstance3D
var idle_bobber: Node3D

func _ready():
    process_mode=Node.PROCESS_MODE_ALWAYS

func _process(_delta):
    game=get_tree().current_scene
    if game==null:return
    var selected:=str(game.get("selected_tool"))
    var cast=game.get("cast_bobber") as Node3D
    if selected!="FISHING ROD" or cast!=null:
        _clear_idle()
        return
    if idle_root==null or not is_instance_valid(idle_root):_build_idle()
    _place_idle()

func _build_idle():
    idle_root=Node3D.new();idle_root.name="IdleFishingRig";game.add_child(idle_root)
    idle_bobber=Node3D.new();idle_bobber.name="IdleBobber";idle_root.add_child(idle_bobber)
    var red:=StandardMaterial3D.new();red.albedo_color=Color(.95,.04,.03);red.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
    var white:=StandardMaterial3D.new();white.albedo_color=Color(1,1,1);white.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
    var top:=MeshInstance3D.new();var s1:=SphereMesh.new();s1.radius=.12;s1.height=.24;top.mesh=s1;top.scale.y=.55;top.position.y=.055;top.material_override=red;idle_bobber.add_child(top)
    var bottom:=MeshInstance3D.new();var s2:=SphereMesh.new();s2.radius=.12;s2.height=.24;bottom.mesh=s2;bottom.scale.y=.55;bottom.position.y=-.05;bottom.material_override=white;idle_bobber.add_child(bottom)
    var stem:=MeshInstance3D.new();var c:=CylinderMesh.new();c.top_radius=.016;c.bottom_radius=.016;c.height=.22;stem.mesh=c;stem.position.y=.15;stem.material_override=red;idle_bobber.add_child(stem)
    idle_line=MeshInstance3D.new();idle_line.name="IdleFishingLine";idle_root.add_child(idle_line)

func _rod_tip()->Vector3:
    var held=game.get("held_tool") as Node3D
    if held==null:return Vector3.ZERO
    var best:=held.global_position;var best_d:=0.0
    for child in held.get_children():
        if not (child is Node3D):continue
        for part in child.get_children():
            if part is MeshInstance3D and (part as MeshInstance3D).mesh is CylinderMesh:
                var mi:=part as MeshInstance3D;var cyl:=mi.mesh as CylinderMesh
                if cyl.height<1.5:continue
                var a:=mi.to_global(Vector3(0,-cyl.height*.5,0));var b:=mi.to_global(Vector3(0,cyl.height*.5,0));var hand:=held.global_position
                var tip:=a if a.distance_to(hand)>b.distance_to(hand) else b
                if tip.distance_to(hand)>best_d:best=tip;best_d=tip.distance_to(hand)
    return best

func _place_idle():
    if idle_bobber==null or idle_line==null:return
    var tip:=_rod_tip()
    idle_bobber.global_position=tip+Vector3(0,-.55,0)
    var d:=idle_bobber.global_position-tip
    var cyl:=CylinderMesh.new();cyl.top_radius=.007;cyl.bottom_radius=.007;cyl.height=d.length();idle_line.mesh=cyl
    var mat:=StandardMaterial3D.new();mat.albedo_color=Color(.94,.95,.91);mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;idle_line.material_override=mat
    idle_line.global_position=(tip+idle_bobber.global_position)*.5;idle_line.quaternion=Quaternion(Vector3.UP,d.normalized())

func _clear_idle():
    if idle_root!=null and is_instance_valid(idle_root):idle_root.queue_free()
    idle_root=null;idle_line=null;idle_bobber=null
