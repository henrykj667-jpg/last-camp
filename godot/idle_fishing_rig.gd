extends Node

var game: Node
var idle_root: Node3D
var idle_line: MeshInstance3D
var idle_bobber: Node3D
var idle_reel: Node3D
var watched_cast: Node3D
var bite_wait:=0.0
var bite_time:=0.0
var biting:=false
var bite_base_y:=0.11
var rng:=RandomNumberGenerator.new()

func _ready():
    process_mode=Node.PROCESS_MODE_ALWAYS
    rng.randomize()

func _process(delta):
    game=get_tree().current_scene
    if game==null:return
    var selected:=str(game.get("selected_tool"))
    var cast=game.get("cast_bobber") as Node3D
    if selected!="FISHING ROD":
        _clear_idle();_reset_bite();return
    if cast!=null and is_instance_valid(cast):
        _clear_idle();_update_bite(cast,delta);return
    _reset_bite()
    if idle_root==null or not is_instance_valid(idle_root):_build_idle()
    _place_idle()

func _update_bite(cast:Node3D,delta:float):
    if watched_cast!=cast:
        watched_cast=cast;biting=false;bite_time=0.0;bite_wait=rng.randf_range(2.2,5.5);bite_base_y=.11
        game.set_meta("fish_biting",false)
    if not bool(game.get("bobber_cast")):return
    if not biting:
        bite_wait-=delta
        if bite_wait<=0.0:
            biting=true;bite_time=1.65;bite_base_y=cast.global_position.y;game.set_meta("fish_biting",true)
    else:
        bite_time-=delta
        var pulse:=sin(bite_time*18.0)*.025
        cast.global_position.y=bite_base_y-.085+pulse
        if bite_time<=0.0:
            biting=false;game.set_meta("fish_biting",false);bite_wait=rng.randf_range(2.8,6.0)

func _reset_bite():
    if game!=null:game.set_meta("fish_biting",false)
    watched_cast=null;biting=false;bite_time=0.0;bite_wait=0.0

func _build_idle():
    idle_root=Node3D.new();idle_root.name="IdleFishingRig";game.add_child(idle_root)
    idle_bobber=Node3D.new();idle_bobber.name="IdleBobber";idle_root.add_child(idle_bobber)
    var red:=StandardMaterial3D.new();red.albedo_color=Color(.98,.03,.02);red.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
    var white:=StandardMaterial3D.new();white.albedo_color=Color(1,1,1);white.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
    var top:=MeshInstance3D.new();var s1:=SphereMesh.new();s1.radius=.17;s1.height=.34;top.mesh=s1;top.scale.y=.60;top.position.y=.075;top.material_override=red;idle_bobber.add_child(top)
    var bottom:=MeshInstance3D.new();var s2:=SphereMesh.new();s2.radius=.17;s2.height=.34;bottom.mesh=s2;bottom.scale.y=.60;bottom.position.y=-.065;bottom.material_override=white;idle_bobber.add_child(bottom)
    var stem:=MeshInstance3D.new();var c:=CylinderMesh.new();c.top_radius=.022;c.bottom_radius=.022;c.height=.30;stem.mesh=c;stem.position.y=.22;stem.material_override=red;idle_bobber.add_child(stem)
    idle_line=MeshInstance3D.new();idle_line.name="IdleFishingLine";idle_root.add_child(idle_line)
    idle_reel=Node3D.new();idle_reel.name="IdleReel";idle_root.add_child(idle_reel)
    var reel_mat:=StandardMaterial3D.new();reel_mat.albedo_color=Color(.08,.10,.11);reel_mat.metallic=.65;reel_mat.roughness=.3
    var reel:=MeshInstance3D.new();var rc:=CylinderMesh.new();rc.top_radius=.14;rc.bottom_radius=.14;rc.height=.12;reel.mesh=rc;reel.rotation_degrees.z=90;reel.material_override=reel_mat;idle_reel.add_child(reel)
    var handle:=MeshInstance3D.new();var hc:=CylinderMesh.new();hc.top_radius=.025;hc.bottom_radius=.025;hc.height=.20;handle.mesh=hc;handle.rotation_degrees.z=90;handle.position=Vector3(.13,0,0);handle.material_override=reel_mat;idle_reel.add_child(handle)
    var knob:=MeshInstance3D.new();var ks:=SphereMesh.new();ks.radius=.055;ks.height=.11;knob.mesh=ks;knob.position=Vector3(.24,0,0);knob.material_override=reel_mat;idle_reel.add_child(knob)

func _held()->Node3D:
    return game.get("held_tool") as Node3D

func _rod_pole()->MeshInstance3D:
    var held:=_held()
    if held==null:return null
    for child in held.get_children():
        if not (child is Node3D):continue
        for part in child.get_children():
            if part is MeshInstance3D and (part as MeshInstance3D).mesh is CylinderMesh:
                var mi:=part as MeshInstance3D;var cyl:=mi.mesh as CylinderMesh
                if cyl.height>1.5:return mi
    return null

func _rod_tip()->Vector3:
    var held:=_held();var pole:=_rod_pole()
    if held==null or pole==null:return Vector3.ZERO
    var cyl:=pole.mesh as CylinderMesh
    var a:=pole.to_global(Vector3(0,-cyl.height*.5,0));var b:=pole.to_global(Vector3(0,cyl.height*.5,0));var hand:=held.global_position
    return a if a.distance_to(hand)>b.distance_to(hand) else b

func _place_idle():
    if idle_bobber==null or idle_line==null:return
    var held:=_held();var pole:=_rod_pole()
    if held==null or pole==null:return
    var tip:=_rod_tip();idle_bobber.global_position=tip+Vector3(0,-.72,0)
    var d:=idle_bobber.global_position-tip
    var cyl:=CylinderMesh.new();cyl.top_radius=.012;cyl.bottom_radius=.012;cyl.height=d.length();idle_line.mesh=cyl
    var mat:=StandardMaterial3D.new();mat.albedo_color=Color(1,1,1);mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;idle_line.material_override=mat
    idle_line.global_position=(tip+idle_bobber.global_position)*.5;idle_line.quaternion=Quaternion(Vector3.UP,d.normalized())
    var pc:=pole.mesh as CylinderMesh
    var pa:=pole.to_global(Vector3(0,-pc.height*.5,0));var pb:=pole.to_global(Vector3(0,pc.height*.5,0));var hand:=held.global_position
    var butt:=pa if pa.distance_to(hand)<pb.distance_to(hand) else pb;var toward_tip:=(tip-butt).normalized()
    idle_reel.global_position=butt+toward_tip*.42+Vector3(0,-.06,0);idle_reel.global_rotation=held.global_rotation

func _clear_idle():
    if idle_root!=null and is_instance_valid(idle_root):idle_root.queue_free()
    idle_root=null;idle_line=null;idle_bobber=null;idle_reel=null
