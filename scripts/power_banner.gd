extends Control
const TitleFont = preload("res://assets/fonts/LilitaOne-Regular.ttf")
const BodyFont = preload("res://assets/fonts/Nunito-ExtraBold.ttf")
var remaining := 0.0
var major := true
var title: Label
var subtitle: Label
var player: CharacterBody3D

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    title = Label.new()
    title.add_theme_font_override("font", TitleFont)
    title.add_theme_color_override("font_color", Color(1, 0.9, 0.48))
    title.add_theme_color_override("font_outline_color", Color(0.12, 0.055, 0.02))
    title.add_theme_constant_override("outline_size", 4)
    subtitle = Label.new()
    subtitle.add_theme_font_override("font", BodyFont)
    subtitle.add_theme_font_size_override("font_size", 14)
    for label in [title, subtitle]:
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        label.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(label)
    hide()

func trigger(is_major: bool) -> void:
    major = is_major
    remaining = 2.1
    title.text = "FÚRIA TRANCO!" if major else "TRANCO TOTAL!"
    subtitle.text = "PODER MÁXIMO  •  10 SEGUNDOS" if major else "PODER DE FOGO AUMENTADO  •  4 SEGUNDOS"
    _process(0)

func _process(delta: float) -> void:
    if get_tree().paused or (is_instance_valid(player) and not player.active):
        hide()
        return
    remaining = maxf(0, remaining - delta)
    visible = remaining > 0
    if not visible:
        return
    modulate.a = minf(minf((2.1 - remaining) / 0.12 + 0.05, 1), remaining / 0.35)
    var width := minf(size.x - 40, 470)
    var center := Vector2(size.x * 0.5, size.y * 0.34)
    title.position = center + Vector2(-width * 0.5, -40)
    title.size = Vector2(width, 57)
    title.add_theme_font_size_override("font_size", 40 if size.x >= 800 else 32)
    subtitle.position = center + Vector2(-width * 0.5, 18)
    subtitle.size = Vector2(width, 28)
    queue_redraw()

func _draw() -> void:
    var center := Vector2(size.x * 0.5, size.y * 0.34)
    var width := minf(size.x - 40, 470)
    var gold := Color(1, 0.68, 0.1) if major else Color(0.15, 0.85, 1)
    var points := PackedVector2Array([center + Vector2(-width * 0.5, -47), center + Vector2(width * 0.5 - 15, -47), center + Vector2(width * 0.5, -32), center + Vector2(width * 0.5, 46), center + Vector2(-width * 0.5 + 15, 46), center + Vector2(-width * 0.5, 31)])
    draw_colored_polygon(points, Color(0.035, 0.065, 0.09, 0.94))
    points.append(points[0])
    draw_polyline(points, gold, 3, true)
    for side in [-1.0, 1.0]:
        for ray in range(3):
            var start := center + Vector2(side * (width * 0.5 + 8), -20 + ray * 20)
            draw_line(start, start + Vector2(side * 20, (ray - 1) * 9), gold, 4, true)
