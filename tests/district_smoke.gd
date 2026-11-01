extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    Input.emulate_mouse_from_touch = false
    root.size = Vector2i(1280, 720)
    var scene := load("res://scenes/main.tscn") as PackedScene
    if scene == null:
        _fail("Main scene could not load")
        return
    var district = scene.instantiate()
    root.add_child(district)
    await process_frame
    if district.get_script() == null or district.get_child_count() < 40:
        _fail("District script did not construct the base")
        return
    if district.objective_markers.size() != 3 or not district.hud.text.contains("v0.2.2"):
        _fail("Mission markers or version HUD missing")
        return
    var player = district.get_node("Player")
    if not player.get_node("Camera3D").is_current():
        _fail("Player camera is not current")
        return
    # _process must run, rather than merely loading a valid script.
    await process_frame
    if district.enemies.is_empty():
        _fail("Process callback did not spawn an alien")
        return
    # Two independent touch indices must survive a drag and release.
    var touch := InputEventScreenTouch.new()
    touch.index = 0
    touch.position = Vector2(100, 400)
    touch.pressed = true
    Input.parse_input_event(touch)
    Input.flush_buffered_events()
    touch = InputEventScreenTouch.new()
    touch.index = 1
    touch.position = Vector2(1100, 400)
    touch.pressed = true
    Input.parse_input_event(touch)
    Input.flush_buffered_events()
    var drag := InputEventScreenDrag.new()
    drag.index = 0
    drag.position = Vector2(170, 400)
    Input.parse_input_event(drag)
    Input.flush_buffered_events()
    await process_frame
    if district.move_id != 0 or district.aim_id != 1 or player.mobile_direction.x < 0.9:
        _fail("Simultaneous touch input failed")
        return
    var start: Vector3 = player.position
    for frame in range(20):
        await physics_frame
    if player.position.x <= start.x:
        _fail("Player did not move")
        return
    touch = InputEventScreenTouch.new()
    touch.index = 0
    touch.pressed = false
    Input.parse_input_event(touch)
    Input.flush_buffered_events()
    await process_frame
    if player.mobile_direction != Vector2.ZERO or district.aim_id != 1:
        _fail("Releasing movement interrupted aim")
        return
    print("DEADLIGHT_SMOKE_OK ready process input movement camera missions")
    district.queue_free()
    await process_frame
    quit(0)

func _fail(reason: String) -> void:
    push_error(reason)
    quit(1)
