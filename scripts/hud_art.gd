extends Control
var health_ratio := 1.0
var mission_rect := Rect2()
var health_rect := Rect2()
var ammo_rect := Rect2()

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
    var origin := health_rect.position
    # One health symbol and a short bar replace the portrait/name/numeric stack.
    var green := Color(0.2, 0.86, 0.53) if health_ratio > 0.3 else Color(1, 0.27, 0.15)
    draw_rect(Rect2(origin + Vector2(12, 18), Vector2(20, 7)), green)
    draw_rect(Rect2(origin + Vector2(19, 11), Vector2(7, 21)), green)
    for index in range(10):
        draw_rect(Rect2(origin + Vector2(44 + index * 9, 18), Vector2(7, 10)), green if float(index) / 10 < health_ratio else Color(0.13, 0.2, 0.23))
    var gun := ammo_rect.position + Vector2(10, 10)
    draw_rect(Rect2(gun, Vector2(25, 7)), Color(0.64, 0.76, 0.82))
    draw_rect(Rect2(gun + Vector2(4, 7), Vector2(7, 9)), Color(0.38, 0.47, 0.52))
    draw_rect(Rect2(gun + Vector2(23, 1), Vector2(7, 5)), Color(0.05, 0.9, 1))
