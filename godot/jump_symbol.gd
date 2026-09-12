extends Control

func _ready():
    mouse_filter=Control.MOUSE_FILTER_IGNORE
    queue_redraw()

func _draw():
    var c:=Color(.96,.98,.96,1)
    # Shaft
    draw_line(Vector2(56,34),Vector2(56,10),c,5.0,true)
    # Arrow head
    draw_line(Vector2(56,10),Vector2(43,23),c,5.0,true)
    draw_line(Vector2(56,10),Vector2(69,23),c,5.0,true)
