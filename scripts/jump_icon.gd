extends Control
var airborne := false
func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _draw() -> void:
    var center := size * 0.5
    var color := Color(0.4, 0.95, 1, 0.5 if airborne else 1.0)
    var points := PackedVector2Array([center + Vector2(-23, -1), center + Vector2(0, -23), center + Vector2(23, -1), center + Vector2(14, 8), center + Vector2(6, 0), center + Vector2(6, 23), center + Vector2(-6, 23), center + Vector2(-6, 0), center + Vector2(-14, 8)])
    draw_colored_polygon(points, color)
    draw_line(center + Vector2(-22, 29), center + Vector2(22, 29), Color(0.45, 0.8, 0.9, 0.5), 3, true)
