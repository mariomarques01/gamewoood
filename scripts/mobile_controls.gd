extends Control
var move_id := -1
var aim_id := -1
var move_start := Vector2.ZERO
var aim_start := Vector2.ZERO
var movement := Vector2.ZERO
var aim := Vector2.RIGHT
var aiming := false
var enabled := true
var reported_simultaneous := false
const RADIUS := 62.0

func _ready() -> void:
    resized.connect(queue_redraw)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func reset() -> void:
    move_id = -1
    aim_id = -1
    movement = Vector2.ZERO
    aiming = false
    queue_redraw()

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
        reset()

func _input(event: InputEvent) -> void:
    if not enabled:
        return
    if event is InputEventScreenTouch:
        if event.pressed:
            # Keep the HUD / pause button region clear.
            if event.position.y < 100:
                return
            if event.position.x < size.x * 0.5 and move_id == -1:
                move_id = event.index
                move_start = event.position
            elif event.position.x >= size.x * 0.5 and aim_id == -1:
                aim_id = event.index
                aim_start = event.position
                aiming = false
        else:
            if event.index == move_id:
                move_id = -1
                movement = Vector2.ZERO
            if event.index == aim_id:
                aim_id = -1
                aiming = false
        queue_redraw()
    elif event is InputEventScreenDrag:
        if event.index == move_id:
            movement = ((event.position - move_start) / RADIUS).limit_length()
        elif event.index == aim_id:
            var offset: Vector2 = event.position - aim_start
            aiming = offset.length() > 10.0
            if aiming:
                aim = offset.normalized()
        if move_id >= 0 and aim_id >= 0 and aiming and not reported_simultaneous:
            reported_simultaneous = true
            print("DEADLIGHT_CONTROLS simultaneous")
        queue_redraw()

func _draw() -> void:
    var left := move_start if move_id >= 0 else Vector2(105, size.y - 105)
    var right := aim_start if aim_id >= 0 else Vector2(size.x - 105, size.y - 105)
    for center in [left, right]:
        draw_circle(center, RADIUS, Color(0.03, 0.1, 0.18, 0.42))
        draw_arc(center, RADIUS, 0, TAU, 48, Color(0.55, 0.85, 1, 0.5), 2, true)
    draw_circle(left + movement * RADIUS * 0.65, 23, Color(0.4, 0.8, 1, 0.55))
    draw_circle(right + (aim * RADIUS * 0.65 if aiming else Vector2.ZERO), 23, Color(1, 0.65, 0.15, 0.65))

    draw_string(ThemeDB.fallback_font, left + Vector2(-33, 90), "MOVER", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.75, 0.9, 1, 0.8))
    draw_string(ThemeDB.fallback_font, right + Vector2(-55, 90), "MIRAR / TIRO", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 0.8, 0.3, 0.8))
