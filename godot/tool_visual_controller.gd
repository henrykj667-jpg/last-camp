extends Node

var scene: Node
var player: CharacterBody3D
var right_arm: MeshInstance3D
var left_leg: MeshInstance3D
var right_leg: MeshInstance3D
var held_tool: Node3D
var walk_time := 0.0
var bound := false

func _process(delta):
    if not bound:
        _bind_game()
        return
    if not is_instance_valid(player) or not is_instance_valid(held_tool) or not is_instance_valid(right_arm):
        bound=false
        return

    # Keep the equipped item attached to the character's right hand.
    if held_tool.get_parent() != right_arm:
        held_tool.reparent(right_arm, false)
        held_tool.position=Vector3(0,-.48,-.03)
        held_tool.rotation=Vector3.ZERO

    # main.gd rebuilds/reset tools when a hotbar slot changes, so restore the hand anchor.
    if not bool(scene.get("action_busy")):
        held_tool.position=Vector3(0,-.48,-.03)
        held_tool.rotation=Vector3.ZERO
        _orient_current_tool()

    # During a tool action main.gd deliberately pauses its walk animation.
    # Keep only the lower-body walk cycle alive so movement and the action can overlap.
    if bool(scene.get("action_busy")):
        var horizontal:=Vector2(player.velocity.x,player.velocity.z).length()
        if horizontal>.18:
            walk_time+=delta*(7.0+horizontal*.35)
            var swing:=sin(walk_time)*.62
            left_leg.rotation.x=swing
            right_leg.rotation.x=-swing
        else:
            left_leg.rotation.x=lerp(left_leg.rotation.x,0.0,clamp(delta*10.0,0.0,1.0))
            right_leg.rotation.x=lerp(right_leg.rotation.x,0.0,clamp(delta*10.0,0.0,1.0))

func _orient_current_tool():
    var selected:=str(scene.get("selected_tool"))
    if selected!="AXE" or held_tool.get_child_count()==0:return
    var axe:=held_tool.get_child(0) as Node3D
    if axe==null:return
    # Present the model edge-on in depth rather than as a flat billboard.
    axe.rotation_degrees=Vector3(8,-22,-12)
    axe.position=Vector3(0,-.05,-.03)

func _bind_game():
    scene=get_tree().current_scene
    if scene==null:return
    var p=scene.get("player")
    var arm=scene.get("right_arm")
    var ll=scene.get("left_leg")
    var rl=scene.get("right_leg")
    var tool=scene.get("held_tool")
    if p is CharacterBody3D and arm is MeshInstance3D and ll is MeshInstance3D and rl is MeshInstance3D and tool is Node3D:
        player=p;right_arm=arm;left_leg=ll;right_leg=rl;held_tool=tool;bound=true
