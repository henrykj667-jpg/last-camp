extends Node

var game: Node
var score_game: Node
var confirmed_fish:=0
var idle_root: Node3D
var idle_line: MeshInstance3D
var idle_bobber: Node3D
var idle_reel: Node3D
var watched_cast: Node3D
var bite_wait:=0.0
var nibble_time:=0.0
var hook_time:=0.0
var stage:=0
var bite_base_y:=0.11
var rng:=RandomNumberGenerator.new()
var reel_started:=false
var reel_was_hooked:=false
var previous_tip_distance:=999.0
var catch_notice: Label
var notice_time:=0.0
var caught_visual: Node3D

func _ready():
    process_mode=Node.PROCESS_MODE_ALWAYS
    rng.randomize()

func _process(delta):
    game=get_tree().current_scene
    if game==null:return
    if score_game!=game:
        score_game=game
        confirmed_fish=int(game.get("fish"))
    elif int(game.get("fish"))!=confirmed_fish:
        game.set("fish",confirmed_fish)
    _update_notice(delta)
    var selected:=str(game.get("selected_tool"))
    var cast=game.get("cast_bobber") as Node3D
    if selected!="FISHING ROD":
        _clear_idle();_reset_bite();return
    if cast==null:
        if watched_cast!=null:_finish_reel_result()
        _reset_bite()
        if idle_root==null or not is_instance_valid(idle_root):_build_idle()
        _place_idle();return
    _clear_idle();_update_bite(cast,delta);_detect_reel(cast)

func _update_bite(cast:Node3D,delta:float):
    if watched_cast!=cast:
        watched_cast=cast;stage=0;bite_wait=rng.randf_range(2.0,4.5);nibble_time=0.0;hook_time=0.0;bite_base_y=.11;reel_started=false;reel_was_hooked=false;previous_tip_distance=999.0
        game.set_meta("fish_biting",false);game.set_meta("fish_hooked",false)
    if not bool(game.get("bobber_cast")):return
    if stage==0:
        bite_wait-=delta
        if bite_wait<=0.0:
            stage=1;nibble_time=rng.randf_range(1.1,1.7);bite_base_y=cast.global_position.y
    elif stage==1:
        nibble_time-=delta
        cast.global_position.y=bite_base_y-.025-abs(sin(nibble_time*15.0))*.035
        game.set_meta("fish_biting",true);game.set_meta("fish_hooked",false)
        if nibble_time<=0.0:
            stage=2;hook_time=1.45;game.set_meta("fish_hooked",true)
    elif stage==2:
        hook_time-=delta
        cast.global_position.y=bite_base_y-.18+sin(hook_time*22.0)*.03
        game.set_meta("fish_biting",true);game.set_meta("fish_hooked",true)
        if hook_time<=0.0:
            stage=0;bite_wait=rng.randf_range(2.5,5.5);game.set_meta("fish_biting",false);game.set_meta("fish_hooked",false)

func _detect_reel(cast:Node3D):
    if not bool(game.get("bobber_cast")):return
    var tip:=game.call("_rod_tip_world") as Vector3
    var dist:=cast.global_position.distance_to(tip)
    if previous_tip_distance<998.0 and dist<previous_tip_distance-.025 and bool(game.get("action_busy")):
        if not reel_started:
            reel_started=true;reel_was_hooked=(stage==2)
            if reel_was_hooked:_spawn_caught_visual(cast.global_position)
    previous_tip_distance=dist

func _spawn_caught_visual(start:Vector3):
    if caught_visual!=null and is_instance_valid(caught_visual):caught_visual.queue_free()
    caught_visual=Node3D.new();caught_visual.name="CaughtFish";game.add_child(caught_visual);caught_visual.global_position=start+Vector3(0,-.12,0)
    var mat:=StandardMaterial3D.new();mat.albedo_color=Color("294b40");mat.roughness=.7
    var body:=MeshInstance3D.new();var s:=SphereMesh.new();s.radius=.20;s.height=.36;body.mesh=s;body.scale=Vector3(1.7,.45,.72);body.material_override=mat;caught_visual.add_child(body)
    var tail:=MeshInstance3D.new();var b:=BoxMesh.new();b.size=Vector3(.20,.20,.07);tail.mesh=b;tail.position=Vector3(-.36,0,0);tail.rotation_degrees.z=45;tail.material_override=mat;caught_visual.add_child(tail)
    var tip:=game.call("_rod_tip_world") as Vector3;var arc:=(caught_visual.global_position+tip)*.5+Vector3(0,1.25,0)
    var tw:=game.create_tween();tw.set_trans(Tween.TRANS_SINE);tw.tween_property(caught_visual,"global_position",arc,.28);tw.tween_property(caught_visual,"global_position",tip+Vector3(0,-.30,0),.34);tw.tween_interval(.35)
    tw.finished.connect(func():
        if caught_visual!=null and is_instance_valid(caught_visual):caught_visual.queue_free()
        caught_visual=null)

func _finish_reel_result():
    if reel_started and reel_was_hooked:
        confirmed_fish+=1
        game.set("fish",confirmed_fish)
        _show_notice("FISH +1  ->  BACKPACK")
    else:
        game.set("fish",confirmed_fish)
        if reel_started:_show_notice("MISSED!")
    reel_started=false;reel_was_hooked=false

func _show_notice(text:String):
    if catch_notice==null or not is_instance_valid(catch_notice):
        var layer:=CanvasLayer.new();layer.name="FishingCatchUI";game.add_child(layer)
        catch_notice=Label.new();catch_notice.position=Vector2(470,120);catch_notice.size=Vector2(340,55);catch_notice.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;catch_notice.add_theme_font_size_override("font_size",28);layer.add_child(catch_notice)
    catch_notice.text=text;catch_notice.visible=true;notice_time=1.4

func _update_notice(delta:float):
    if notice_time<=0.0:return
    notice_time-=delta
    if notice_time<=0.0 and catch_notice!=null and is_instance_valid(catch_notice):catch_notice.visible=false

func _reset_bite():
    if game!=null:
        game.set_meta("fish_biting",false);game.set_meta("fish_hooked",false)
    watched_cast=null;stage=0;bite_wait=0.0;nibble_time=0.0;hook_time=0.0;previous_tip_distance=999.0

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

func _held()->Node3D:return game.get("held_tool") as Node3D
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
    var cyl:=pole.mesh as CylinderMesh;var a:=pole.to_global(Vector3(0,-cyl.height*.5,0));var b:=pole.to_global(Vector3(0,cyl.height*.5,0));var hand:=held.global_position
    return a if a.distance_to(hand)>b.distance_to(hand) else b
func _place_idle():
    if idle_bobber==null or idle_line==null:return
    var held:=_held();var pole:=_rod_pole()
    if held==null or pole==null:return
    var tip:=_rod_tip();idle_bobber.global_position=tip+Vector3(0,-.72,0);var d:=idle_bobber.global_position-tip
    var cyl:=CylinderMesh.new();cyl.top_radius=.012;cyl.bottom_radius=.012;cyl.height=d.length();idle_line.mesh=cyl
    var mat:=StandardMaterial3D.new();mat.albedo_color=Color(1,1,1);mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;idle_line.material_override=mat
    idle_line.global_position=(tip+idle_bobber.global_position)*.5;idle_line.quaternion=Quaternion(Vector3.UP,d.normalized())
    var pc:=pole.mesh as CylinderMesh;var pa:=pole.to_global(Vector3(0,-pc.height*.5,0));var pb:=pole.to_global(Vector3(0,pc.height*.5,0));var hand:=held.global_position
    var butt:=pa if pa.distance_to(hand)<pb.distance_to(hand) else pb;var toward_tip:=(tip-butt).normalized();idle_reel.global_position=butt+toward_tip*.42+Vector3(0,-.06,0);idle_reel.global_rotation=held.global_rotation
func _clear_idle():
    if idle_root!=null and is_instance_valid(idle_root):idle_root.queue_free()
    idle_root=null;idle_line=null;idle_bobber=null;idle_reel=null
