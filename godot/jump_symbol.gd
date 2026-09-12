extends Control

func _ready():
    mouse_filter=Control.MOUSE_FILTER_IGNORE
    queue_redraw()

func _draw():
    var c:=Color(.96,.98,.96,1)
    # Large, bold visual-only jump arrow.
    draw_line(Vector2(56,39),Vector2(56,7),c,7.0,true)
    draw_line(Vector2(56,7),Vector2(38,25),c,7.0,true)
    draw_line(Vector2(56,7),Vector2(74,25),c,7.0,true)
