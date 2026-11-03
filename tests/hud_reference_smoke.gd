extends SceneTree
func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    root.size = Vector2i(1280, 590)
    var district = load("res://scenes/main.tscn").instantiate()
    root.add_child(district)
    current_scene = district
    district.spawner.active = false
    district.player.set_physics_process(false)
    district.player.weapon.set_physics_process(false)
    district.arcade.set_physics_process(false)
    await physics_frame
    await process_frame
    district.arcade.xp = 108
    district.arcade.frenzy_level = 6
    district.player.weapon.ammo = 18
    district.hud.show_credits(1005)
    district._update_hud()
    district.hud._process(0)
    district.hud.toast_time = 0
    district.hud.toast.hide()
    district.hud.navigation.hide()
    assert(district.hud.life.text == "100/100")
    assert(district.hud.weapon_buttons.size() == 1, "Reference has a single weapon swap button")
    assert(district.hud.pause_button.get_global_rect().position.x > root.get_visible_rect().size.x * 0.9)
    assert(district.hud.jump_button.get_global_rect().get_center().y < district.hud.controls.aim_center().y)
    assert(district.hud.weapon_buttons[0].get_global_rect().get_center().x > root.get_visible_rect().size.x * 0.75)
    assert(absf(district.hud.art.fury_ratio - 0.6) < 0.01)
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://build/logs/hud-reference-1280x590.png")
    district.hud._swap_weapon()
    assert(district.player.weapon.selected == 0)
    district.hud._swap_weapon()
    assert(district.player.weapon.selected == 1)
    district.hud.pause_requested.emit()
    assert(paused and district.hud.overlay.visible)
    district.hud.pause_requested.emit()
    assert(not paused and not district.hud.overlay.visible)
    root.size = Vector2i(844, 390)
    await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://build/logs/hud-reference-844x390.png")
    for button in [district.hud.pause_button, district.hud.jump_button, district.hud.weapon_buttons[0]]:
        assert(button.get_global_rect().end.x <= root.get_visible_rect().size.x)
        assert(button.get_global_rect().end.y <= root.get_visible_rect().size.y)
    print("DEADLIGHT_HUD_REFERENCE_OK reference layout segmented fury swap settings responsive")
    district.queue_free()
    await process_frame
    root.get_node("GameAudio").shutdown()
    await create_timer(0.4).timeout
    quit(0)
