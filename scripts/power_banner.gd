extends Control
const TitleFont = preload("res://assets/fonts/LilitaOne-Regular.ttf")
var remaining := 0.0
var major := true
var title: Label
var player: CharacterBody3D

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    title = Label.new()
    title.add_theme_font_override("font", TitleFont)
    title.add_theme_color_override("font_color", Color(1, 0.9, 0.48))
    title.add_theme_color_override("font_outline_color", Color(0.12, 0.055, 0.02))
    title.add_theme_constant_override("outline_size", 2)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(title)
    hide()

func trigger(is_major: bool) -> void:
    major = is_major
    remaining = 1.2
    title.text = "FÚRIA TRANCO • 10s" if major else "TRANCO TOTAL • 4s"
    _process(0)

func _process(delta: float) -> void:
    if get_tree().paused or (is_instance_valid(player) and not player.active):
        hide()
        return
    remaining = maxf(0, remaining - delta)
    visible = remaining > 0
    if not visible:
        return
    modulate.a = minf(minf((1.2 - remaining) / 0.12 + 0.05, 1), remaining / 0.35)
    var width := minf(size.x - 40, 288)
    var center := Vector2(size.x * 0.5, 136.0)
    title.position = center + Vector2(-width * 0.5, -16)
    title.size = Vector2(width, 32)
    title.add_theme_font_size_override("font_size", 20)
    queue_redraw()

func _draw() -> void:
    var center := Vector2(size.x * 0.5, 136.0)
    var width := minf(size.x - 40, 288)
    var gold := Color(1, 0.68, 0.1) if major else Color(0.15, 0.85, 1)
    var points := PackedVector2Array([center + Vector2(-width * 0.5, -20), center + Vector2(width * 0.5 - 15, -20), center + Vector2(width * 0.5, -12), center + Vector2(width * 0.5, 20), center + Vector2(-width * 0.5 + 15, 20), center + Vector2(-width * 0.5, 12)])
    draw_colored_polygon(points, Color(0.035, 0.065, 0.09, 0.94))
    points.append(points[0])
    draw_polyline(points, gold, 3, true)
