extends Node3D

var player: CharacterBody3D
var camera: Camera3D
var move_input := Vector2.ZERO
var speed := 4.4
var acceleration := 18.0
var deceleration := 22.0
var turn_speed := 14.0

func _ready():
    _make_environment()
    _make_ground()
    _make_forest()
    _make_camp()
    _make_player()
    _make_ui()

func _physics_process(delta):
    if player == null: return
    var keyboard := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    var input_vec := keyboard if keyboard.length() > 0.05 else move_input
    if input_vec.length() < 0.10: input_vec = Vector2.ZERO
    if input_vec.length() > 1.0: input_vec = input_vec.normalized()
    var desired := Vector3(input_vec.x, 0.0, input_vec.y) * speed
    var rate := acceleration if input_vec != Vector2.ZERO else deceleration
    player.velocity.x = move_toward(player.velocity.x, desired.x, rate * delta)
    player.velocity.z = move_toward(player.velocity.z, desired.z, rate * delta)
    var horizontal := Vector3(player.velocity.x,0.0,player.velocity.z)
    if horizontal.length() > 0.15:
        player.rotation.y = lerp_angle(player.rotation.y, atan2(horizontal.x,horizontal.z), clamp(turn_speed*delta,0.0,1.0))
    player.velocity.y=-1.0
    player.move_and_slide()

func _mat(color:Color)->StandardMaterial3D:
    var m:=StandardMaterial3D.new(); m.albedo_color=color; m.roughness=.9; return m

func _box(parent:Node3D,pos:Vector3,size:Vector3,color:Color):
    var mesh:=MeshInstance3D.new(); var box:=BoxMesh.new(); box.size=size; mesh.mesh=box; mesh.position=pos; mesh.material_override=_mat(color); parent.add_child(mesh)

func _make_environment():
    var world:=WorldEnvironment.new(); var env:=Environment.new(); env.background_mode=Environment.BG_COLOR; env.background_color=Color("8db6c9"); env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color=Color("d7e4dc"); env.ambient_light_energy=.75; world.environment=env; add_child(world)
    var sun:=DirectionalLight3D.new(); sun.rotation_degrees=Vector3(-55,-35,0); sun.shadow_enabled=true; sun.light_energy=1.15; add_child(sun)

func _make_ground():
    var body:=StaticBody3D.new(); add_child(body); _box(body,Vector3(0,-.3,0),Vector3(60,.6,60),Color("526f3f")); var shape:=CollisionShape3D.new(); var box:=BoxShape3D.new(); box.size=Vector3(60,.6,60); shape.shape=box; shape.position.y=-.3; body.add_child(shape)

func _make_forest():
    var spots=[Vector3(-8,0,-6),Vector3(-12,0,2),Vector3(-7,0,9),Vector3(9,0,-8),Vector3(13,0,-2),Vector3(11,0,8),Vector3(-16,0,-10),Vector3(17,0,12),Vector3(-2,0,-14),Vector3(4,0,14)]
    for p in spots:
        var tree:=Node3D.new(); tree.position=p; add_child(tree); var trunk:=MeshInstance3D.new(); var cyl:=CylinderMesh.new(); cyl.top_radius=.28; cyl.bottom_radius=.38; cyl.height=3.4; trunk.mesh=cyl; trunk.position.y=1.7; trunk.material_override=_mat(Color("76513a")); tree.add_child(trunk)
        for y in [3.1,4.0,4.8]:
            var crown:=MeshInstance3D.new(); var cone:=CylinderMesh.new(); cone.top_radius=0; cone.bottom_radius=1.55-(y-3.1)*.22; cone.height=2.1; crown.mesh=cone; crown.position.y=y; crown.material_override=_mat(Color("2f5837")); tree.add_child(crown)

func _make_camp():
    var camp:=Node3D.new(); camp.position=Vector3(3,0,2); add_child(camp); _box(camp,Vector3(0,.65,0),Vector3(2.7,1.3,2.2),Color("80664a")); _box(camp,Vector3(0,1.45,0),Vector3(3,.22,2.5),Color("39452f")); var fire:=OmniLight3D.new(); fire.position=Vector3(-2,.7,1); fire.light_color=Color("ff9d52"); fire.light_energy=3; fire.omni_range=5; camp.add_child(fire); var flame:=MeshInstance3D.new(); var sphere:=SphereMesh.new(); sphere.radius=.25; sphere.height=.65; flame.mesh=sphere; flame.position=Vector3(-2,.35,1); flame.material_override=_mat(Color("ff7b31")); camp.add_child(flame)

func _make_player():
    player=CharacterBody3D.new(); player.position=Vector3(0,.9,5); add_child(player); var collider:=CollisionShape3D.new(); var cap:=CapsuleShape3D.new(); cap.radius=.38; cap.height=1.75; collider.shape=cap; player.add_child(collider); _box(player,Vector3(0,.25,0),Vector3(.8,1.05,.45),Color("536b49")); var head:=MeshInstance3D.new(); var sphere:=SphereMesh.new(); sphere.radius=.34; sphere.height=.68; head.mesh=sphere; head.position=Vector3(0,1.05,0); head.material_override=_mat(Color("d49a6a")); player.add_child(head); _box(player,Vector3(-.22,-.55,0),Vector3(.25,.75,.3),Color("343b43")); _box(player,Vector3(.22,-.55,0),Vector3(.25,.75,.3),Color("343b43")); camera=Camera3D.new(); camera.position=Vector3(0,7.5,9.5); camera.rotation_degrees=Vector3(-34,0,0); camera.current=true; player.add_child(camera)

func _make_ui():
    var layer:=CanvasLayer.new(); add_child(layer); var title:=Label.new(); title.text="BLACKOUT: SWEDEN  •  3D PROTOTYPE"; title.position=Vector2(22,18); title.add_theme_font_size_override("font_size",22); layer.add_child(title); var hint:=Label.new(); hint.text="Move: joystick / arrow keys"; hint.position=Vector2(22,50); layer.add_child(hint)
    var joy:=VirtualJoystick.new(); joy.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT); joy.position=Vector2(-238,-228); joy.size=Vector2(220,220); joy.changed.connect(func(v):move_input=v); layer.add_child(joy)

class VirtualJoystick extends Control:
    signal changed(value:Vector2)
    var active:=false
    var center:=Vector2(110,110)
    var knob:=center
    var touch_id:=-1
    const RADIUS:=88.0
    const DEAD_ZONE:=9.0
    func _ready(): mouse_filter=Control.MOUSE_FILTER_STOP; queue_redraw()
    func _gui_input(event):
        if event is InputEventScreenTouch:
            if event.pressed and not active: active=true; touch_id=event.index; _set_pos(event.position)
            elif not event.pressed and event.index==touch_id: _release()
        elif event is InputEventScreenDrag and active and event.index==touch_id: _set_pos(event.position)
        elif event is InputEventMouseButton:
            active=event.pressed
            if active:_set_pos(event.position)
            else:_release()
        elif event is InputEventMouseMotion and active:_set_pos(event.position)
    func _release(): active=false; touch_id=-1; knob=center; changed.emit(Vector2.ZERO); queue_redraw()
    func _set_pos(p:Vector2):
        var d:=p-center
        if d.length()>RADIUS:d=d.normalized()*RADIUS
        knob=center+d
        if d.length()<=DEAD_ZONE: changed.emit(Vector2.ZERO)
        else: changed.emit(d.normalized()*max(.35,d.length()/RADIUS))
        queue_redraw()
    func _draw(): draw_circle(center,100,Color(.05,.08,.08,.46)); draw_circle(center,94,Color(1,1,1,.11)); draw_circle(knob,38,Color(1,1,1,.68))
