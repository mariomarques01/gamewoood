extends Control
var health_ratio := 1.0
var mission_rect := Rect2()
var health_rect := Rect2()
var ammo_rect := Rect2()
var credit_rect := Rect2()

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func panel(rect: Rect2, accent: Color) -> void:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.035, 0.065, 0.1, 0.78)
    style.border_color = Color(0.2, 0.31, 0.4)
    style.set_border_width_all(2)
    style.set_corner_radius_all(9)
    style.shadow_color = Color(0, 0, 0, 0.3)
    style.shadow_size = 2
    draw_style_box(style, rect)
    draw_rect(Rect2(rect.position + Vector2(12, 0), Vector2(rect.size.x - 24, 3)), accent)

func _draw() -> void:
    panel(health_rect, Color(0.16, 0.85, 0.64))
    panel(ammo_rect, Color(1, 0.65, 0.1))
    panel(mission_rect, Color(1, 0.65, 0.1))
    panel(credit_rect, Color(1, 0.7, 0.15))
    var origin := health_rect.position
    var red := Color(0.96, 0.18, 0.23)
    var center := origin + Vector2(19, 18)
    draw_circle(center + Vector2(-5, -3), 7, red)
    draw_circle(center + Vector2(5, -3), 7, red)
    draw_colored_polygon(PackedVector2Array([center + Vector2(-12, -1), center + Vector2(12, -1), center + Vector2(0, 13)]), red)
    draw_style_box(_bar(Color(0.19, 0.05, 0.08)), Rect2(origin + Vector2(39, 8), Vector2(141, 23)))
    if health_ratio > 0:
        draw_style_box(_bar(red), Rect2(origin + Vector2(39, 8), Vector2(maxf(4, 141 * health_ratio), 23)))
    draw_line(origin + Vector2(43, 10), origin + Vector2(43 + maxf(0, 133 * health_ratio), 10), Color(1, 0.55, 0.5), 2)
    var coin := credit_rect.position + Vector2(18, 17)
    draw_circle(coin, 11, Color(0.6, 0.34, 0.02))
    draw_circle(coin + Vector2(0, -1), 9, Color(1, 0.76, 0.12))
    draw_line(coin + Vector2(0, -6), coin + Vector2(0, 5), Color(1, 0.95, 0.5), 3)

func _bar(color: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.set_corner_radius_all(9)
    return style
