extends Control
const Assets = preload("res://scripts/hud_assets.gd")
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
const RADIUS := 78.0

func _ready() -> void:
    resized.connect(queue_redraw)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func move_center() -> Vector2:
    return Vector2(128 * size.x / 1172.0, size.y - 114)

func aim_center() -> Vector2:
    return Vector2(size.x - 133 * size.x / 1172.0, size.y - 97)

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
            if event.position.y < 105:
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
    var left := move_center()
    var right := aim_center()
    draw_texture_rect(Assets.texture("move_base"), Rect2(left - Vector2.ONE * 78, Vector2.ONE * 156), false)
    var knob := left + movement * 39
    draw_texture_rect(Assets.texture("move_knob"), Rect2(knob - Vector2.ONE * 33, Vector2.ONE * 66), false)
    var aim_offset := aim * 8 if aiming else Vector2.ZERO
    draw_texture_rect(Assets.texture("aim_base"), Rect2(right - Vector2.ONE * 72 + aim_offset, Vector2.ONE * 144), false, Color(1, 1, 1, 1 if aiming else 0.96))
