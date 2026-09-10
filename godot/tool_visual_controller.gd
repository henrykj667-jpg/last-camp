extends Node

var scene: Node
var player: CharacterBody3D
var right_arm: MeshInstance3D
var left_arm: MeshInstance3D
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

    # The equipped prop lives in the right hand at all times, including while
    # main.gd is running its action tween. This intentionally overrides the old
    # player-space tool positions that made the axe float behind the arm.
    if held_tool.get_parent() != right_arm:
        held_tool.reparent(right_arm, false)
    held_tool.position=Vector3(0,-.47,-.08)

    var busy:=bool(scene.get("action_busy"))
    var selected:=str(scene.get("selected_tool"))
    if not busy:
        held_tool.rotation=Vector3.ZERO
    _orient_current_tool(selected)

    # main.gd continues CharacterBody movement during an action, but its old
    # walk animator returns early. Drive the lower body here so walking remains
    # visibly active while the upper body performs the action.
    if busy:
        var horizontal:=Vector2(player.velocity.x,player.velocity.z).length()
        if horizontal>.12:
            walk_time+=delta*(7.2+horizontal*.35)
            var swing:=sin(walk_time)*.64
            left_leg.rotation.x=swing
            right_leg.rotation.x=-swing
        else:
            left_leg.rotation.x=lerp(left_leg.rotation.x,0.0,clamp(delta*11.0,0.0,1.0))
            right_leg.rotation.x=lerp(right_leg.rotation.x,0.0,clamp(delta*11.0,0.0,1.0))

func _orient_current_tool(selected:String):
    if selected!="AXE" or held_tool.get_child_count()==0:return
    var axe:=held_tool.get_child(0) as Node3D
    if axe==null:return
    # Grip begins at the hand; yaw gives the head real visible depth instead of
    # presenting it as a flat slab to the third-person camera.
    axe.position=Vector3(.01,-.10,-.08)
    axe.rotation_degrees=Vector3(-12,52,174)

func _bind_game():
    scene=get_tree().current_scene
    if scene==null:return
    var p=scene.get("player")
    var arm=scene.get("right_arm")
    var larm=scene.get("left_arm")
    var ll=scene.get("left_leg")
    var rl=scene.get("right_leg")
    var tool=scene.get("held_tool")
    if p is CharacterBody3D and arm is MeshInstance3D and larm is MeshInstance3D and ll is MeshInstance3D and rl is MeshInstance3D and tool is Node3D:
        player=p;right_arm=arm;left_arm=larm;left_leg=ll;right_leg=rl;held_tool=tool;bound=true
