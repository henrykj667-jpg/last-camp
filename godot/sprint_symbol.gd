extends Control

func _ready():
    mouse_filter=Control.MOUSE_FILTER_IGNORE
    queue_redraw()

func _draw():
    var c:=Color(.96,.98,.96,1)
    # Simple running-person icon, drawn entirely with Godot primitives.
    draw_circle(Vector2(64,13),6.0,c)
    draw_line(Vector2(60,21),Vector2(52,36),c,6.0,true)
    draw_line(Vector2(53,27),Vector2(39,24),c,5.0,true)
    draw_line(Vector2(55,29),Vector2(70,34),c,5.0,true)
    draw_line(Vector2(52,36),Vector2(38,43),c,6.0,true)
    draw_line(Vector2(52,36),Vector2(66,43),c,6.0,true)
    # Motion streaks make the action read as sprint at small mobile size.
    draw_line(Vector2(18,20),Vector2(37,20),c,4.0,true)
    draw_line(Vector2(13,30),Vector2(34,30),c,4.0,true)
    draw_line(Vector2(20,40),Vector2(34,40),c,4.0,true)
