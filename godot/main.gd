extends Node3D

var player: CharacterBody3D
var camera: Camera3D
var move_input := Vector2.ZERO
var speed := 4.6
var acceleration := 18.0
var deceleration := 22.0
var turn_speed := 14.0
var camera_offset := Vector3(0,5.5,7.2)
var action_button: Button
var left_leg: MeshInstance3D
var right_leg: MeshInstance3D
var left_arm: Node3D
var right_arm: Node3D
var body_mesh: MeshInstance3D
var held_tool: Node3D
var axe_pivot: Node3D
var walk_time := 0.0
var selected_tool := "HANDS"
var tool_buttons: Array[Button]=[]
var tools := ["HANDS","AXE","BASKET","FISHING ROD","LOCKED","LOCKED"]
var berry_bushes: Array[Node3D]=[]
var trees: Array[StaticBody3D]=[]
var water_zone: Node3D
var berries:=0
var fish:=0
var wood:=0
var action_busy:=false

func _ready():
    _make_environment();_make_ground();_make_forest();_make_water();_make_berries();_make_camp();_make_player();_make_ui()

func _physics_process(delta):
    if player==null:return
    var keyboard:=Input.get_vector("ui_left","ui_right","ui_up","ui_down")
    var input_vec:=keyboard if keyboard.length()>.05 else move_input
    if input_vec.length()<.10:input_vec=Vector2.ZERO
    if input_vec.length()>1.0:input_vec=input_vec.normalized()
    var desired:=Vector3(input_vec.x,0,input_vec.y)*speed
    var rate:=acceleration if input_vec!=Vector2.ZERO else deceleration
    player.velocity.x=move_toward(player.velocity.x,desired.x,rate*delta);player.velocity.z=move_toward(player.velocity.z,desired.z,rate*delta)
    var horizontal:=Vector3(player.velocity.x,0,player.velocity.z)
    if horizontal.length()>.15:player.rotation.y=lerp_angle(player.rotation.y,atan2(horizontal.x,horizontal.z)+PI,clamp(turn_speed*delta,0,1))
    player.velocity.y=-1;player.move_and_slide();_animate_walk(delta,horizontal.length())

func _animate_walk(delta:float,movement_speed:float):
    if movement_speed>.18:
        walk_time+=delta*(7.0+movement_speed*.35);var swing:=sin(walk_time)*.62
        left_leg.rotation.x=swing;right_leg.rotation.x=-swing;body_mesh.position.y=.27+abs(sin(walk_time*2))*.045
        if not action_busy:left_arm.rotation.x=-swing*.75;right_arm.rotation.x=swing*.75
    else:
        left_leg.rotation.x=lerp(left_leg.rotation.x,0.0,clamp(delta*10,0,1));right_leg.rotation.x=lerp(right_leg.rotation.x,0.0,clamp(delta*10,0,1));body_mesh.position.y=lerp(body_mesh.position.y,.27,clamp(delta*10,0,1))
        if not action_busy:left_arm.rotation.x=lerp(left_arm.rotation.x,0.0,clamp(delta*10,0,1));right_arm.rotation.x=lerp(right_arm.rotation.x,0.0,clamp(delta*10,0,1))

func _mat(color:Color)->StandardMaterial3D:
    var m:=StandardMaterial3D.new();m.albedo_color=color;m.roughness=.9;return m
func _box(parent:Node3D,pos:Vector3,size:Vector3,color:Color)->MeshInstance3D:
    var n:=MeshInstance3D.new();var b:=BoxMesh.new();b.size=size;n.mesh=b;n.position=pos;n.material_override=_mat(color);parent.add_child(n);return n
func _cylinder(parent:Node3D,pos:Vector3,radius:float,height:float,color:Color)->MeshInstance3D:
    var n:=MeshInstance3D.new();var c:=CylinderMesh.new();c.top_radius=radius;c.bottom_radius=radius;c.height=height;n.mesh=c;n.position=pos;n.material_override=_mat(color);parent.add_child(n);return n
func _sphere(parent:Node3D,pos:Vector3,radius:float,color:Color)->MeshInstance3D:
    var n:=MeshInstance3D.new();var s:=SphereMesh.new();s.radius=radius;s.height=radius*2.0;n.mesh=s;n.position=pos;n.material_override=_mat(color);parent.add_child(n);return n
func _box_collision(parent:Node3D,pos:Vector3,size:Vector3):
    var shape:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=size;shape.shape=box;shape.position=pos;parent.add_child(shape)
func _cylinder_collision(parent:Node3D,pos:Vector3,radius:float,height:float):
    var shape:=CollisionShape3D.new();var cyl:=CylinderShape3D.new();cyl.radius=radius;cyl.height=height;shape.shape=cyl;shape.position=pos;parent.add_child(shape)

func _make_environment():
    var world:=WorldEnvironment.new();var env:=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color("8db6c9");env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("d7e4dc");env.ambient_light_energy=.75;world.environment=env;add_child(world)
    var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-55,-35,0);sun.shadow_enabled=true;sun.light_energy=1.15;add_child(sun)
func _make_ground():
    var body:=StaticBody3D.new();add_child(body);_box(body,Vector3(0,-.3,0),Vector3(60,.6,60),Color("526f3f"));_box_collision(body,Vector3(0,-.3,0),Vector3(60,.6,60))
func _make_forest():
    var spots=[Vector3(-8,0,-6),Vector3(-12,0,2),Vector3(-7,0,9),Vector3(9,0,-8),Vector3(13,0,-2),Vector3(11,0,8),Vector3(-16,0,-10),Vector3(17,0,12),Vector3(-2,0,-14),Vector3(4,0,14)]
    for p in spots:
        var tree:=StaticBody3D.new();tree.position=p;tree.set_meta("hits",0);add_child(tree);trees.append(tree);_cylinder(tree,Vector3(0,1.7,0),.34,3.4,Color("76513a"));_cylinder_collision(tree,Vector3(0,1.7,0),.38,3.4)
        for y in [3.1,4.0,4.8]:
            var crown:=MeshInstance3D.new();var cone:=CylinderMesh.new();cone.top_radius=0;cone.bottom_radius=1.55-(y-3.1)*.22;cone.height=2.1;crown.mesh=cone;crown.position.y=y;crown.material_override=_mat(Color("2f5837"));tree.add_child(crown)
func _make_water():
    water_zone=Node3D.new();water_zone.position=Vector3(-10,0,-12);add_child(water_zone);var lake:=MeshInstance3D.new();var m:=CylinderMesh.new();m.top_radius=5;m.bottom_radius=5;m.height=.12;lake.mesh=m;lake.position.y=.02;lake.material_override=_mat(Color("4b89a4"));water_zone.add_child(lake)
func _make_berries():
    for p in [Vector3(-5,0,1),Vector3(7,0,6),Vector3(-3,0,-8)]:
        var bush:=Node3D.new();bush.position=p;bush.set_meta("picked",false);add_child(bush);berry_bushes.append(bush);_sphere(bush,Vector3(0,.55,0),.7,Color("315d38"))
        for off in [Vector3(-.25,.7,.35),Vector3(.2,.55,.4),Vector3(.35,.8,.1)]:_sphere(bush,off,.09,Color("8d2845"))
func _make_camp():
    var camp:=StaticBody3D.new();camp.position=Vector3(3,0,2);add_child(camp);_box(camp,Vector3(0,.65,0),Vector3(2.7,1.3,2.2),Color("80664a"));_box(camp,Vector3(0,1.45,0),Vector3(3,.22,2.5),Color("39452f"));_box_collision(camp,Vector3(0,.65,0),Vector3(2.7,1.3,2.2));var fire:=OmniLight3D.new();fire.position=Vector3(-2,.7,1);fire.light_color=Color("ff9d52");fire.light_energy=3;fire.omni_range=5;camp.add_child(fire)

func _make_player():
    player=CharacterBody3D.new();player.position=Vector3(0,.9,5);add_child(player)
    var collider:=CollisionShape3D.new();var cap:=CapsuleShape3D.new();cap.radius=.38;cap.height=1.85;collider.shape=cap;player.add_child(collider)
    body_mesh=_box(player,Vector3(0,.27,0),Vector3(.76,1.02,.42),Color("405747"));_box(player,Vector3(0,.30,-.225),Vector3(.60,.72,.05),Color("4d6855"));_box(player,Vector3(0,.30,-.255),Vector3(.035,.72,.025),Color("c6b37d"))
    _sphere(player,Vector3(0,1.08,0),.34,Color("d49a6a"));_sphere(player,Vector3(-.34,1.08,0),.075,Color("c98d62"));_sphere(player,Vector3(.34,1.08,0),.075,Color("c98d62"))
    _sphere(player,Vector3(0,1.30,.02),.31,Color("49372d"));_sphere(player,Vector3(-.22,1.24,-.08),.16,Color("49372d"));_sphere(player,Vector3(.22,1.24,-.08),.16,Color("49372d"));_box(player,Vector3(0,1.10,-.335),Vector3(.11,.09,.08),Color("c98d62"))
    left_leg=_box(player,Vector3(-.20,-.55,0),Vector3(.27,.78,.32),Color("2f3940"));right_leg=_box(player,Vector3(.20,-.55,0),Vector3(.27,.78,.32),Color("2f3940"));_box(left_leg,Vector3(0,-.40,-.07),Vector3(.30,.16,.45),Color("292c2c"));_box(right_leg,Vector3(0,-.40,-.07),Vector3(.30,.16,.45),Color("292c2c"))
    left_arm=Node3D.new();left_arm.position=Vector3(-.51,.66,0);player.add_child(left_arm);_box(left_arm,Vector3(0,-.41,0),Vector3(.20,.82,.24),Color("405747"));_sphere(left_arm,Vector3(0,-.87,0),.12,Color("d49a6a"))
    right_arm=Node3D.new();right_arm.position=Vector3(.51,.66,0);player.add_child(right_arm);_box(right_arm,Vector3(0,-.41,0),Vector3(.20,.82,.24),Color("405747"));_sphere(right_arm,Vector3(0,-.87,0),.12,Color("d49a6a"))
    _box(player,Vector3(0,.35,.30),Vector3(.58,.72,.28),Color("4b493c"));_box(player,Vector3(-.30,.38,.17),Vector3(.07,.65,.08),Color("2f332d"));_box(player,Vector3(.30,.38,.17),Vector3(.07,.65,.08),Color("2f332d"))
    held_tool=Node3D.new();held_tool.position=Vector3(.03,-.89,-.13);right_arm.add_child(held_tool);_show_selected_tool()
    camera=Camera3D.new();camera.global_position=player.global_position+camera_offset;camera.current=true;add_child(camera);camera.look_at(player.global_position+Vector3(0,.55,0),Vector3.UP)

func _show_selected_tool():
    if held_tool==null:return
    for child in held_tool.get_children():child.queue_free()
    held_tool.rotation=Vector3.ZERO;held_tool.position=Vector3(.03,-.89,-.13);axe_pivot=null
    if selected_tool=="AXE":
        axe_pivot=Node3D.new();axe_pivot.position=Vector3.ZERO;held_tool.add_child(axe_pivot)
        # Compact low-poly axe: angled down beside the character instead of sticking sideways.
        axe_pivot.rotation_degrees=Vector3(-12,8,-28)
        var handle:=_cylinder(axe_pivot,Vector3(0,.31,0),.065,.92,Color("704529"));handle.scale=Vector3(1.0,1.0,.82)
        _sphere(axe_pivot,Vector3(0,-.14,0),.075,Color("5d351f"))
        _box(axe_pivot,Vector3(-.01,.77,0),Vector3(.24,.18,.20),Color("505d64"))
        _box(axe_pivot,Vector3(-.23,.77,0),Vector3(.30,.31,.12),Color("89969b"))
        _box(axe_pivot,Vector3(-.39,.77,0),Vector3(.08,.25,.08),Color("aab4b8"))
    elif selected_tool=="BASKET":
        var basket:=Node3D.new();held_tool.add_child(basket);_cylinder(basket,Vector3(0,-.28,-.08),.30,.34,Color("9b6a3b"));_box(basket,Vector3(-.27,.02,-.08),Vector3(.06,.42,.06),Color("6e4528"));_box(basket,Vector3(.27,.02,-.08),Vector3(.06,.42,.06),Color("6e4528"));_box(basket,Vector3(0,.22,-.08),Vector3(.58,.06,.06),Color("6e4528"))
    elif selected_tool=="FISHING ROD":
        var rod:=Node3D.new();held_tool.add_child(rod);var pole:=_cylinder(rod,Vector3(0,.55,-.2),.035,1.8,Color("6f4b2d"));pole.rotation_degrees.x=68;var reel:=_cylinder(rod,Vector3(.08,-.05,-.05),.10,.08,Color("3b4449"));reel.rotation_degrees.z=90

func _make_ui():
    var layer:=CanvasLayer.new();add_child(layer);var title:=Label.new();title.text="BLACKOUT: SWEDEN";title.position=Vector2(22,18);title.add_theme_font_size_override("font_size",22);layer.add_child(title)
    var joy:=VirtualJoystick.new();joy.set_anchors_preset(Control.PRESET_BOTTOM_LEFT);joy.position=Vector2(28,-228);joy.size=Vector2(220,220);joy.changed.connect(func(v):move_input=v);layer.add_child(joy)
    var hotbar:=HBoxContainer.new();hotbar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM);hotbar.position=Vector2(-330,-94);hotbar.size=Vector2(660,72);hotbar.add_theme_constant_override("separation",6);layer.add_child(hotbar)
    for i in range(tools.size()):
        var b:=Button.new();b.text=str(i+1)+"\n"+tools[i];b.custom_minimum_size=Vector2(104,68);b.add_theme_font_size_override("font_size",13);b.focus_mode=Control.FOCUS_NONE
        if tools[i]=="LOCKED":b.disabled=true
        else:b.pressed.connect(_select_tool.bind(i))
        hotbar.add_child(b);tool_buttons.append(b)
    _refresh_hotbar();action_button=Button.new();action_button.text="USE";action_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT);action_button.position=Vector2(-190,-150);action_button.size=Vector2(150,90);action_button.add_theme_font_size_override("font_size",18);action_button.focus_mode=Control.FOCUS_NONE;action_button.action_mode=BaseButton.ACTION_MODE_BUTTON_PRESS;action_button.pressed.connect(_context_action);layer.add_child(action_button)
func _select_tool(index:int):
    if index<0 or index>=tools.size() or tools[index]=="LOCKED":return
    selected_tool=tools[index];_refresh_hotbar();_show_selected_tool()
func _refresh_hotbar():
    for i in range(tool_buttons.size()):tool_buttons[i].text=str(i+1)+"\n"+("[SELECTED] " if tools[i]==selected_tool else "")+tools[i]
func _nearest_berry()->Node3D:
    var best:Node3D=null;var best_d:=999.0
    for bush in berry_bushes:
        if bush.get_meta("picked",false):continue
        var d:=player.global_position.distance_to(bush.global_position)
        if d<best_d:best_d=d;best=bush
    return best if best_d<2.3 else null
func _nearest_tree()->StaticBody3D:
    var best:StaticBody3D=null;var best_d:=999.0
    for tree in trees:
        if not is_instance_valid(tree):continue
        var d:=player.global_position.distance_to(tree.global_position)
        if d<best_d:best_d=d;best=tree
    return best if best_d<2.0 else null
func _near_water()->bool:return water_zone!=null and player.global_position.distance_to(water_zone.global_position)<6.2
func _context_action():
    if action_busy:return
    match selected_tool:
        "AXE":_axe_swing()
        "FISHING ROD":_cast_rod()
        "BASKET":
            var bush:=_nearest_berry()
            if bush!=null:bush.set_meta("picked",true);berries+=3;for child in bush.get_children():child.visible=false
        _:
            pass
func _axe_swing():
    if axe_pivot==null:return
    action_busy=true
    var pivot_start:=axe_pivot.rotation;var rarm:=right_arm.rotation;var larm:=left_arm.rotation;var torso:=body_mesh.rotation
    var raise:=create_tween();raise.set_parallel(true);raise.set_trans(Tween.TRANS_SINE);raise.set_ease(Tween.EASE_OUT)
    raise.tween_property(right_arm,"rotation",Vector3(2.18,-.10,.18),.24)
    raise.tween_property(left_arm,"rotation",Vector3(.20,.06,-.06),.24)
    raise.tween_property(axe_pivot,"rotation",pivot_start+Vector3(-.18,.12,.22),.24)
    raise.tween_property(body_mesh,"rotation",Vector3(-.04,.04,0),.24)
    await raise.finished
    await get_tree().create_timer(.055).timeout
    var strike:=create_tween();strike.set_parallel(true);strike.set_trans(Tween.TRANS_CUBIC);strike.set_ease(Tween.EASE_IN)
    strike.tween_property(right_arm,"rotation",Vector3(.38,0,.03),.16)
    strike.tween_property(left_arm,"rotation",Vector3(.08,0,0),.16)
    strike.tween_property(axe_pivot,"rotation",pivot_start+Vector3(-.10,-.04,-.08),.16)
    strike.tween_property(body_mesh,"rotation",Vector3(.05,-.04,0),.16)
    var tree:=_nearest_tree()
    if tree!=null:
        _tree_hit_feedback(tree);var hits:int=tree.get_meta("hits",0)+1;tree.set_meta("hits",hits)
        if hits>=5:wood+=3;trees.erase(tree);tree.queue_free()
    await strike.finished
    var recover:=create_tween();recover.set_parallel(true);recover.set_trans(Tween.TRANS_SINE);recover.set_ease(Tween.EASE_OUT)
    recover.tween_property(right_arm,"rotation",rarm,.22);recover.tween_property(left_arm,"rotation",larm,.22);recover.tween_property(axe_pivot,"rotation",pivot_start,.22);recover.tween_property(body_mesh,"rotation",torso,.22)
    await recover.finished;action_busy=false
func _tree_hit_feedback(tree:StaticBody3D):
    var start:=tree.position
    var tw:=create_tween();tw.tween_property(tree,"position",start+Vector3(.10,0,0),.045);tw.tween_property(tree,"position",start-Vector3(.08,0,0),.045);tw.tween_property(tree,"position",start,.055)
func _cast_rod():
    action_busy=true
    var start:=held_tool.rotation
    var tw:=create_tween();tw.tween_property(held_tool,"rotation",Vector3(-.85,0,0),.18);tw.tween_property(held_tool,"rotation",Vector3(.45,0,0),.22);tw.tween_property(held_tool,"rotation",start,.18);tw.finished.connect(func():action_busy=false)
    if _near_water():fish+=1

class VirtualJoystick extends Control:
    signal changed(value:Vector2)
    var active:=false;var center:=Vector2(110,110);var knob:=center;var touch_id:=-1;var mouse_active:=false
    const RADIUS:=88.0;const DEAD_ZONE:=9.0
    func _ready():mouse_filter=Control.MOUSE_FILTER_STOP;queue_redraw()
    func _gui_input(event):
        if event is InputEventScreenTouch:
            if event.pressed and not active:active=true;touch_id=event.index;mouse_active=false;_set_pos(event.position)
            elif not event.pressed and event.index==touch_id:_release()
        elif event is InputEventScreenDrag and active and event.index==touch_id:_set_pos(event.position)
        elif event is InputEventMouseButton and touch_id==-1:
            mouse_active=event.pressed;active=mouse_active
            if active:_set_pos(event.position)
            else:_release()
        elif event is InputEventMouseMotion and mouse_active and touch_id==-1:_set_pos(event.position)
    func _release():active=false;mouse_active=false;touch_id=-1;knob=center;changed.emit(Vector2.ZERO);queue_redraw()
    func _set_pos(p:Vector2):
        var d:=p-center
        if d.length()>RADIUS:d=d.normalized()*RADIUS
        knob=center+d
        if d.length()<=DEAD_ZONE:changed.emit(Vector2.ZERO)
        else:changed.emit(d.normalized()*max(.35,d.length()/RADIUS))
        queue_redraw()
    func _draw():draw_circle(center,100,Color(.05,.08,.08,.46));draw_circle(center,94,Color(1,1,1,.11));draw_circle(knob,38,Color(1,1,1,.68))