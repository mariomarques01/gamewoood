extends Control
var weapon_index := 1
func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
    draw_set_transform(Vector2.ZERO, 0, size / Vector2(60, 32))
    var steel := Color(0.72, 0.83, 0.9)
    var accent := Color(1, 0.76, 0.2) if weapon_index == 0 else Color(0.12, 0.85, 1)
    if weapon_index == 0:
        draw_rect(Rect2(9, 5, 37, 9), steel)
        draw_colored_polygon(PackedVector2Array([Vector2(15, 14), Vector2(27, 14), Vector2(23, 29), Vector2(11, 29)]), Color(0.35, 0.45, 0.53))
        draw_rect(Rect2(39, 6, 9, 6), accent)
        draw_line(Vector2(28, 15), Vector2(33, 22), steel, 2)
    else:
        draw_rect(Rect2(10, 8, 32, 10), steel)
        draw_rect(Rect2(42, 10, 15, 6), accent)
        draw_rect(Rect2(2, 11, 10, 6), Color(0.38, 0.48, 0.56))
        draw_rect(Rect2(18, 18, 7, 10), steel)
        draw_colored_polygon(PackedVector2Array([Vector2(30, 18), Vector2(40, 18), Vector2(36, 30), Vector2(26, 30)]), accent)
        draw_rect(Rect2(20, 4, 13, 3), accent)
