extends SceneTree
func _initialize() -> void:
    call_deferred("_run")
func touch(point: Vector2) -> void:
    for pressed in [true, false]:
        var event := InputEventScreenTouch.new()
        event.position = root.get_final_transform() * point
        event.index = 7
        event.pressed = pressed
        Input.parse_input_event(event)
        Input.flush_buffered_events()
func _run() -> void:
    root.size = Vector2i(1280,720)
    var mixer = root.get_node("GameAudio")
    var original := [mixer.music_volume, mixer.effects_volume, mixer.muted]
    var menu = load("res://scenes/start_menu.tscn").instantiate()
    root.add_child(menu)
    current_scene = menu
    await process_frame
    await process_frame
    assert(ProjectSettings.get_setting("display/window/handheld/orientation") == DisplayServer.SCREEN_SENSOR_LANDSCAPE)
    assert(get_nodes_in_group("player").is_empty() and get_nodes_in_group("enemies").is_empty(), "Combat started behind the menu")
    assert(absf(menu.art.texture.get_size().aspect() - 16.0/9.0) < 0.01)
    assert(menu.play_button.get_global_rect().has_point(Vector2(640,525)))
    assert(menu.settings_button.get_global_rect().has_point(Vector2(960,650)))
    touch(Vector2(320,650))
    assert(not menu.starting and not menu.settings.visible, "Reserved button started an action")
    touch(menu.settings_button.get_global_rect().get_center())
    assert(menu.settings.visible)
    await process_frame
    await process_frame
    assert(menu.panel.get_rect().end.y <= root.get_visible_rect().size.y, "Settings panel overflows")
    touch(menu.music_slider.get_global_rect().position + menu.music_slider.size * Vector2(0.31,0.5))
    touch(menu.effects_slider.get_global_rect().position + menu.effects_slider.size * Vector2(0.59,0.5))
    assert(absf(mixer.music_volume - 0.31) < 0.02 and absf(mixer.effects_volume - 0.59) < 0.02, "Touch volume sliders failed")
    touch(menu.mute_button.get_global_rect().get_center())
    assert(mixer.muted != original[2])
    touch(menu.mute_button.get_global_rect().get_center())
    touch(menu.back_button.get_global_rect().get_center())
    assert(not menu.settings.visible and not menu.starting)
    var config := ConfigFile.new()
    assert(config.load(mixer.SETTINGS) == OK)
    assert(absf(float(config.get_value("audio", "music")) - 0.31) < 0.02)
    root.size = Vector2i(390,844)
    await process_frame
    await process_frame
    assert(root.get_visible_rect().size.x > root.get_visible_rect().size.y, "Startup is not landscape in portrait window")
    await RenderingServer.frame_post_draw
    assert(absf(root.get_visible_rect().size.aspect() - Vector2(root.size).aspect()) < 0.01, "Native view still has borders")
    assert(menu.art.size.is_equal_approx(root.get_visible_rect().size), "Menu does not fill the viewport")
    root.get_texture().get_image().save_png("res://build/logs/start-menu-portrait.png")
    touch(menu.play_button.get_global_rect().get_center())
    for frame in range(30):
        await process_frame
        if is_instance_valid(current_scene) and current_scene.name == "Main":
            break
    var district = current_scene
    assert(district.name == "Main", "Jogar did not enter the actual game")
    district.spawner.active = false
    assert(district.player != null and not district.orientation_blocked, "Game blocked landscape startup")
    assert(absf(mixer.music_volume - 0.31) < 0.02, "Play reset audio preferences")
    mixer.set_levels(original[0], original[1])
    mixer.set_muted(original[2])
    mixer.save_settings()
    district.queue_free()
    await process_frame
    mixer.shutdown()
    await create_timer(0.4).timeout
    print("DEADLIGHT_START_MENU_OK artwork, reserved buttons, touch settings, persistence and landscape play")
    quit()
