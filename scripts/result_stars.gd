extends Control
var stars := 0
func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
    for index in range(3):
        var center := Vector2(size.x * (index + 0.5) / 3, size.y * 0.5)
        var points := PackedVector2Array()
        for vertex in range(10):
            var angle := -PI * 0.5 + vertex * PI / 5
            var radius := 25.0 if vertex % 2 == 0 else 11.5
            points.append(center + Vector2(cos(angle), sin(angle)) * radius)
        draw_colored_polygon(points, Color(1, 0.75, 0.15) if index < stars else Color(0.19, 0.27, 0.34))
        points.append(points[0])
        draw_polyline(points, Color(1, 0.9, 0.45) if index < stars else Color(0.35, 0.44, 0.5), 2, true)
