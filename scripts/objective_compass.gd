extends Control
var direction := Vector2.UP
var arrived := false
var contested := false

func _ready() -> void:
    custom_minimum_size = Vector2(34, 34)
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
    var center := size * 0.5
    var tint := Color(1, 0.4, 0.25) if contested else Color(0.35, 1, 0.7)
    draw_circle(center, 15, Color(0.025, 0.12, 0.16))
    draw_arc(center, 15, 0, TAU, 32, tint, 2, true)
    if arrived:
        draw_polyline(PackedVector2Array([center + Vector2(-7, 0), center + Vector2(-2, 5), center + Vector2(8, -6)]), tint, 3, true)
    else:
        var forward := direction.normalized() if direction.is_finite() and direction.length_squared() > 0.01 else Vector2.UP
        var side := forward.orthogonal()
        draw_colored_polygon(PackedVector2Array([center + forward * 11, center - forward * 7 + side * 7, center - forward * 3, center - forward * 7 - side * 7]), tint)
