extends Control
signal jump_requested
var jump_button: Button
var weapon_buttons: Array[Button] = []
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
            for button in weapon_buttons:
                if button.is_visible_in_tree() and button.get_global_rect().has_point(event.position):
                    return
            if is_instance_valid(jump_button) and jump_button.visible and jump_button.get_global_rect().has_point(event.position):
                jump_requested.emit()
                get_viewport().set_input_as_handled()
                return
            # Keep the HUD / pause button region clear.
            if event.position.y < 116:
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
    var left := move_start if move_id >= 0 else Vector2(96, size.y - 100)
    var right := aim_start if aim_id >= 0 else Vector2(size.x - 96, size.y - 100)
    _stick(left, movement, move_id >= 0)
    _stick(right, aim if aiming else Vector2.ZERO, aiming)

func _stick(center: Vector2, direction: Vector2, active: bool) -> void:
    draw_circle(center + Vector2(0, 5), RADIUS + 5, Color(0.02, 0.025, 0.03, 0.25))
    draw_circle(center, RADIUS + 3, Color(0.75, 0.81, 0.85, 0.4))
    draw_circle(center, RADIUS, Color(0.33, 0.39, 0.43, 0.38))
    draw_circle(center, RADIUS - 8, Color(0.61, 0.68, 0.72, 0.15))
    draw_arc(center, RADIUS - 3, PI, TAU, 32, Color(0.95, 0.98, 1, 0.45), 2, true)
    if active:
        draw_arc(center, RADIUS, 0, TAU, 48, Color(0.5, 0.9, 1, 0.55), 2, true)
    var knob := center + direction * RADIUS * 0.62
    draw_circle(knob + Vector2(2, 5), 27, Color(0, 0, 0, 0.4))
    for index in range(8):
        var radius := 26.0 - index * 2.7
        var shade := 0.62 - index * 0.06
        draw_circle(knob + Vector2(0, -index * 0.15), radius, Color(shade, shade + 0.025, shade + 0.045, 0.95))
    draw_arc(knob + Vector2(0, -2), 20, PI, TAU, 24, Color(0.82, 0.88, 0.92, 0.7), 2, true)
