extends Control
var health_ratio := 1.0
var mission_rect := Rect2()
var health_rect := Rect2()
var ammo_rect := Rect2()

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func panel(rect: Rect2, accent: Color) -> void:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.035, 0.065, 0.1, 0.93)
    style.border_color = Color(0.2, 0.31, 0.4)
    style.set_border_width_all(2)
    style.set_corner_radius_all(12)
    style.shadow_color = Color(0, 0, 0, 0.3)
    style.shadow_size = 5
    draw_style_box(style, rect)
    draw_rect(Rect2(rect.position + Vector2(12, 0), Vector2(rect.size.x - 24, 3)), accent)

func _draw() -> void:
    panel(health_rect, Color(0.16, 0.85, 0.64))
    panel(ammo_rect, Color(1, 0.65, 0.1))
    panel(mission_rect, Color(1, 0.65, 0.1))
    # Original captain portrait, drawn as UI geometry rather than borrowed artwork.
    var origin := health_rect.position + Vector2(13, 15)
    draw_rect(Rect2(origin, Vector2(62, 64)), Color(0.1, 0.24, 0.34))
    draw_circle(origin + Vector2(31, 26), 20, Color(0.91, 0.62, 0.39))
    draw_rect(Rect2(origin + Vector2(9, 11), Vector2(44, 12)), Color(0.08, 0.17, 0.25))
    draw_rect(Rect2(origin + Vector2(12, 23), Vector2(38, 9)), Color(0.04, 0.85, 1))
    draw_colored_polygon(PackedVector2Array([origin + Vector2(3, 64), origin + Vector2(12, 43), origin + Vector2(50, 43), origin + Vector2(60, 64)]), Color(1, 0.38, 0.08))
    # Health is split into readable chunks; missing life stays dark.
    var width := health_rect.size.x - 102
    for index in range(10):
        var color := Color(0.2, 0.86, 0.53) if float(index) / 10 < health_ratio else Color(0.1, 0.18, 0.22)
        if health_ratio < 0.3 and float(index) / 10 < health_ratio:
            color = Color(1, 0.27, 0.15)
        draw_rect(Rect2(health_rect.position + Vector2(89 + index * width / 10, 47), Vector2(width / 10 - 3, 15)), color)
    # Stylized blaster silhouette on the ammunition card.
    var gun := ammo_rect.position + Vector2(12, 15)
    draw_rect(Rect2(gun, Vector2(40, 10)), Color(0.64, 0.76, 0.82))
    draw_rect(Rect2(gun + Vector2(7, 10), Vector2(10, 14)), Color(0.38, 0.47, 0.52))
    draw_rect(Rect2(gun + Vector2(34, 1), Vector2(11, 7)), Color(0.05, 0.9, 1))
