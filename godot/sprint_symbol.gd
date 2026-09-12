extends Control

func _ready():
    mouse_filter=Control.MOUSE_FILTER_IGNORE
    queue_redraw()

func _draw():
    var c:=Color(.96,.98,.96,1)
    # Clean boost/sprint symbol: two bold forward chevrons.
    # No text or tiny character details, so it stays readable on mobile.
    var thickness:=8.0
    draw_line(Vector2(27,10),Vector2(47,22),c,thickness,true)
    draw_line(Vector2(47,22),Vector2(27,34),c,thickness,true)
    draw_line(Vector2(56,10),Vector2(76,22),c,thickness,true)
    draw_line(Vector2(76,22),Vector2(56,34),c,thickness,true)
