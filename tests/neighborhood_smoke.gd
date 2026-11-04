extends SceneTree
func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    root.size = Vector2i(1280,720)
    var district = load("res://scenes/main.tscn").instantiate()
    root.add_child(district)
    current_scene = district
    district.spawner.active = false
    await process_frame
    assert(district.district_map.get_meta("expanded_blocks") == 6)
    assert(district.district_map.blood_surface_height(Vector3(42,0,-14),0) >= 0.16)
    var overview
    for node in district.get_children():
        if node.get_script() == preload("res://scripts/neighborhood_overview.gd"):
            overview = node
    assert(overview != null)
    overview.toggle()
    assert(paused and overview.camera.current and overview.panel.visible)
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://build/logs/neighborhood-overview.png")
    var touch := InputEventScreenTouch.new()
    touch.index = 6
    touch.pressed = true
    touch.position = root.get_final_transform() * overview.close_button.get_global_rect().get_center()
    Input.parse_input_event(touch)
    await process_frame
    assert(not paused and district.player.get_node("Camera3D").current)
    touch.position = root.get_final_transform() * overview.map_button.get_global_rect().get_center()
    Input.parse_input_event(touch)
    await process_frame
    assert(paused and overview.open, "Map touch button failed")
    var escape := InputEventKey.new()
    escape.keycode = KEY_ESCAPE
    escape.pressed = true
    Input.parse_input_event(escape)
    await process_frame
    assert(not paused and not overview.open and not district.manually_paused)
    print("DEADLIGHT_NEIGHBORHOOD_OK six blocks, raised surfaces, overview and resume")
    root.get_node("GameAudio").shutdown()
    await create_timer(0.4).timeout
    quit()
