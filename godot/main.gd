extends Node3D

var player: CharacterBody3D
var camera: Camera3D
var move_input := Vector2.ZERO
var speed := 5.2

func _ready():
    _make_environment()
    _make_ground()
    _make_forest()
    _make_camp()
    _make_player()
    _make_ui()

func _physics_process(_delta):
    if player == null: return
    var keyboard := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    var input_vec := keyboard if keyboard.length() > 0.05 else move_input
    var direction := Vector3(input_vec.x, 0.0, input_vec.y)
    if direction.length() > 0.08:
        direction = direction.normalized()
        player.velocity.x = direction.x * speed
        player.velocity.z = direction.z * speed
        var target := atan2(direction.x, direction.z)
        player.rotation.y = lerp_angle(player.rotation.y, target, 0.18)
    else:
        player.velocity.x = move_toward(player.velocity.x, 0.0, 0.8)
        player.velocity.z = move_toward(player.velocity.z, 0.0, 0.8)
    player.velocity.y = -1.0
    player.move_and_slide()

func _mat(color: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = 0.9
    return m

func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color):
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new(); box.size = size
    mesh.mesh = box; mesh.position = pos; mesh.material_override = _mat(color)
    parent.add_child(mesh)

func _make_environment():
    var world := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("8db6c9")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("d7e4dc")
    env.ambient_light_energy = 0.75
    world.environment = env; add_child(world)
    var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-55,-35,0); sun.shadow_enabled = true; sun.light_energy = 1.15; add_child(sun)

func _make_ground():
    var body := StaticBody3D.new(); add_child(body)
    _box(body, Vector3(0,-0.3,0), Vector3(60,0.6,60), Color("526f3f"))
    var shape := CollisionShape3D.new(); var box := BoxShape3D.new(); box.size = Vector3(60,0.6,60); shape.shape = box; shape.position.y = -0.3; body.add_child(shape)

func _make_forest():
    var spots = [Vector3(-8,0,-6),Vector3(-12,0,2),Vector3(-7,0,9),Vector3(9,0,-8),Vector3(13,0,-2),Vector3(11,0,8),Vector3(-16,0,-10),Vector3(17,0,12),Vector3(-2,0,-14),Vector3(4,0,14)]
    for p in spots:
        var tree := Node3D.new(); tree.position = p; add_child(tree)
        var trunk := MeshInstance3D.new(); var cyl := CylinderMesh.new(); cyl.top_radius=.28; cyl.bottom_radius=.38; cyl.height=3.4; trunk.mesh=cyl; trunk.position.y=1.7; trunk.material_override=_mat(Color("76513a")); tree.add_child(trunk)
        for y in [3.1,4.0,4.8]:
            var crown := MeshInstance3D.new(); var cone := CylinderMesh.new(); cone.top_radius=0.0; cone.bottom_radius=1.55-(y-3.1)*.22; cone.height=2.1; crown.mesh=cone; crown.position.y=y; crown.material_override=_mat(Color("2f5837")); tree.add_child(crown)

func _make_camp():
    var camp := Node3D.new(); camp.position = Vector3(3,0,2); add_child(camp)
    _box(camp, Vector3(0,.65,0), Vector3(2.7,1.3,2.2), Color("80664a"))
    _box(camp, Vector3(0,1.45,0), Vector3(3.0,.22,2.5), Color("39452f"))
    var fire := OmniLight3D.new(); fire.position=Vector3(-2,.7,1); fire.light_color=Color("ff9d52"); fire.light_energy=3.0; fire.omni_range=5.0; camp.add_child(fire)
    var flame := MeshInstance3D.new(); var sphere:=SphereMesh.new(); sphere.radius=.25; sphere.height=.65; flame.mesh=sphere; flame.position=Vector3(-2,.35,1); flame.material_override=_mat(Color("ff7b31")); camp.add_child(flame)

func _make_player():
    player = CharacterBody3D.new(); player.position=Vector3(0,.9,5); add_child(player)
    var collider:=CollisionShape3D.new(); var cap:=CapsuleShape3D.new(); cap.radius=.38; cap.height=1.75; collider.shape=cap; player.add_child(collider)
    _box(player, Vector3(0,.25,0), Vector3(.8,1.05,.45), Color("536b49"))
    var head:=MeshInstance3D.new(); var sphere:=SphereMesh.new(); sphere.radius=.34; sphere.height=.68; head.mesh=sphere; head.position=Vector3(0,1.05,0); head.material_override=_mat(Color("d49a6a")); player.add_child(head)
    _box(player, Vector3(-.22,-.55,0), Vector3(.25,.75,.3), Color("343b43")); _box(player, Vector3(.22,-.55,0), Vector3(.25,.75,.3), Color("343b43"))
    camera=Camera3D.new(); camera.position=Vector3(0,7.5,9.5); camera.rotation_degrees=Vector3(-34,0,0); camera.current=true; player.add_child(camera)

func _make_ui():
    var layer:=CanvasLayer.new(); add_child(layer)
    var title:=Label.new(); title.text="BLACKOUT: SWEDEN  •  3D PROTOTYPE"; title.position=Vector2(22,18); title.add_theme_font_size_override("font_size",22); layer.add_child(title)
    var hint:=Label.new(); hint.text="Move: joystick / arrow keys"; hint.position=Vector2(22,50); layer.add_child(hint)
    var joy:=VirtualJoystick.new(); joy.position=Vector2(40,500); joy.size=Vector2(170,170); joy.changed.connect(func(v): move_input=v); layer.add_child(joy)

class VirtualJoystick extends Control:
    signal changed(value: Vector2)
    var active := false
    var center := Vector2(85,85)
    var knob := center
    func _ready(): mouse_filter=Control.MOUSE_FILTER_STOP; queue_redraw()
    func _gui_input(event):
        if event is InputEventScreenTouch or event is InputEventMouseButton:
            active=event.pressed
            if active: _set_pos(event.position)
            else: knob=center; changed.emit(Vector2.ZERO); queue_redraw()
        elif active and (event is InputEventScreenDrag or event is InputEventMouseMotion): _set_pos(event.position)
    func _set_pos(p:Vector2):
        var d:=p-center
        if d.length()>65: d=d.normalized()*65
        knob=center+d; changed.emit(Vector2(d.x/65.0,d.y/65.0)); queue_redraw()
    func _draw():
        draw_circle(center,72,Color(0.05,0.08,0.08,.42)); draw_circle(center,68,Color(1,1,1,.10)); draw_circle(knob,29,Color(1,1,1,.55))
