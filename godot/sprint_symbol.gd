extends Control

func _ready():
    mouse_filter=Control.MOUSE_FILTER_IGNORE
    queue_redraw()

func _draw():
    var c:=Color(.96,.98,.96,1)
    # Larger, cleaner runner silhouette for a small mobile action button.
    # Head
    draw_circle(Vector2(67,9),6.5,c)
    # Forward-leaning torso
    draw_line(Vector2(62,18),Vector2(53,34),c,7.0,true)
    # Arms: one forward, one back
    draw_line(Vector2(59,22),Vector2(75,25),c,5.5,true)
    draw_line(Vector2(59,23),Vector2(45,18),c,5.5,true)
    # Legs: clearly separated running stride
    draw_line(Vector2(53,34),Vector2(72,39),c,6.5,true)
    draw_line(Vector2(72,39),Vector2(82,35),c,6.5,true)
    draw_line(Vector2(53,34),Vector2(42,43),c,6.5,true)
    draw_line(Vector2(42,43),Vector2(31,43),c,6.5,true)
    # Two short speed marks only, kept behind the runner.
    draw_line(Vector2(19,21),Vector2(38,21),c,4.5,true)
    draw_line(Vector2(13,31),Vector2(34,31),c,4.5,true)
