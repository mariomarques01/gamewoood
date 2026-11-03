extends Control
const Assets = preload("res://scripts/hud_assets.gd")
var health_ratio := 1.0
var fury_ratio := 0.0
var fury_active := false
var captain_rect := Rect2()
var fury_rect := Rect2()
var mission_rect := Rect2()
var health_rect := Rect2()
var ammo_rect := Rect2()
var credit_rect := Rect2()
var level := 1

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func panel(rect: Rect2) -> void:
    _frame("panel", rect, 14)

func _draw() -> void:
    draw_texture_rect(Assets.texture("portrait"), captain_rect, false)
    var badge := Rect2(captain_rect.position + Vector2(0, captain_rect.size.y * 0.62), Vector2(captain_rect.size.x * 0.38, captain_rect.size.y * 0.38))
    draw_texture_rect(Assets.texture("badge"), badge, false)
    var font = preload("res://assets/fonts/LilitaOne-Regular.ttf")
    var number := str(level)
    var number_size := 20
    var number_width := font.get_string_size(number, HORIZONTAL_ALIGNMENT_LEFT, -1, number_size).x
    draw_string(font, badge.position + Vector2((badge.size.x - number_width) * 0.5, badge.size.y * 0.72), number, HORIZONTAL_ALIGNMENT_LEFT, -1, number_size, Color(0.1, 0.12, 0.14))
    panel(health_rect)
    var fill := Rect2(health_rect.position + Vector2(29, 5), Vector2(health_rect.size.x - 36, health_rect.size.y - 10))
    if health_ratio > 0:
        fill.size.x *= health_ratio
        _frame("health", fill, 7)
    draw_texture_rect(Assets.texture("heart"), Rect2(health_rect.position + Vector2(-3, -1), Vector2(36, health_rect.size.y + 3)), false)
    panel(fury_rect)
    draw_texture_rect(Assets.texture("bolt"), Rect2(fury_rect.position + Vector2(0, -2), Vector2(27, fury_rect.size.y + 4)), false)
    var start := fury_rect.position + Vector2(fury_rect.size.x * 0.4, 5)
    var slot_width := (fury_rect.size.x * 0.58 - 12) / 5
    var segment := Assets.texture("segment")
    for index in range(5):
        var rect := Rect2(start + Vector2(index * (slot_width + 2), 0), Vector2(slot_width, fury_rect.size.y - 10))
        draw_texture_rect(segment, rect, false, Color(0.16, 0.22, 0.3, 0.9))
        var amount := clampf(fury_ratio * 5 - index, 0, 1)
        if amount > 0:
            var crop := Rect2(0, 0, segment.get_width() * amount, segment.get_height())
            rect.size.x *= amount
            draw_texture_rect_region(segment, rect, crop, Color(1, 0.78, 0.16) if fury_active else Color.WHITE)
    for rect in [ammo_rect, mission_rect, credit_rect]:
        panel(rect)
    draw_texture_rect(Assets.texture("crate"), Rect2(mission_rect.position + Vector2(5, -3), Vector2(55, mission_rect.size.y + 8)), false)
    draw_texture_rect(Assets.texture("coin"), Rect2(credit_rect.position + Vector2(-2, -3), Vector2(40, credit_rect.size.y + 6)), false)

func _frame(key: String, rect: Rect2, margin: float) -> void:
    # Render nine-slice rims at UI scale rather than keeping the large atlas border.
    draw_set_transform(rect.position, 0, Vector2.ONE * 0.4)
    draw_style_box(Assets.style(key, margin), Rect2(Vector2.ZERO, rect.size / 0.4))
    draw_set_transform(Vector2.ZERO)
