extends SceneTree
var district: Node3D
var overview: CanvasLayer

func _initialize() -> void:
    call_deferred("_run")

func refresh() -> void:
    district._update_hud()
    district.hud._process(0.2)

func _run() -> void:
    root.size = Vector2i(844, 390)
    district = load("res://scenes/main.tscn").instantiate()
    root.add_child(district)
    current_scene = district
    district.save.storage_path = "user://mission_guidance_smoke.cfg"
    district.spawner.active = false
    district.player.set_physics_process(false)
    district.missions.set_physics_process(false)
    for child in district.get_children():
        if child.get_script() == preload("res://scripts/neighborhood_overview.gd"):
            overview = child
    await physics_frame
    refresh()
    var guide = district.hud.mission_guide
    assert(guide.visible and not guide.instruction.visible, "Guide should remain compact during active waves away from objectives")
    district.spawner.waves_completed = 3
    refresh()
    await process_frame
    assert(guide.is_visible_in_tree() and guide.instruction.visible and guide.heading.text.contains("LIBERE O ARSENAL"))
    assert(guide.status_label.text.contains("ÁREA VERDE") and guide.instruction.text.contains("3s"))
    assert(district.hud.wave_status.text.contains("FALTAM 3 MISSÕES"))
    var camera: Camera3D = district.player.get_node("Camera3D")
    var desired: Vector2 = camera.unproject_position(district.missions.POSITIONS[0] + Vector3.UP) - camera.unproject_position(district.player.position + Vector3.UP)
    assert(guide.compass.direction.normalized().dot(desired.normalized()) > 0.99, "Compass points away from the active objective")
    var bounds: Rect2 = guide.get_global_rect()
    assert(root.get_visible_rect().encloses(bounds), "Mission guide overflows mobile viewport")
    assert(not bounds.intersects(district.hud.jump_button.get_global_rect()) and not bounds.intersects(district.hud.kill_popup.get_global_rect()), "Guide overlaps combat controls or combo")
    for label in [guide.heading, guide.status_label, guide.instruction]:
        var font: Font = label.get_theme_font("font")
        assert(font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x <= label.size.x, "Mission text is clipped")
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://build/logs/mission-guide-after-waves.png")
    overview.toggle()
    await process_frame
    await process_frame
    assert(paused and not guide.is_visible_in_tree())
    assert(overview.current_task.text.contains("FALTAM 3 MISSÕES"))
    assert(overview.task_labels[0].text.contains("ATUAL") and overview.task_labels[2].text.contains("COMUNICAÇÃO"))
    assert(root.get_visible_rect().encloses(overview.legend.get_global_rect()), "Map checklist overflows mobile viewport")
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://build/logs/mission-guide-map.png")
    overview.toggle()
    district.player.position = district.missions.POSITIONS[0]
    district.missions._physics_process(0.3)
    refresh()
    assert(guide.compass.arrived and guide.status_label.text.contains("CAPTURANDO") and guide.meter.value > 0)
    var before: float = district.missions.progress
    var enemy = preload("res://scripts/enemy_controller.gd").new()
    enemy.player = district.player
    district.add_child(enemy)
    enemy.position = district.player.position + Vector3(1.4, 0, 0)
    enemy.set_physics_process(false)
    district.missions._physics_process(1)
    refresh()
    assert(district.missions.progress == before and guide.status_label.text.contains("BLOQUEADA"))
    assert(guide.instruction.text.contains("Elimine os inimigos"))
    camera._process(1)
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://build/logs/mission-guide-contested.png")
    enemy.receive_damage(1000)
    await physics_frame
    district.missions._physics_process(3.1)
    refresh()
    assert(district.missions.current == 1 and guide.heading.text.contains("ATIVE O HELIPONTO"))
    assert(guide.checklist[0].text.begins_with("OK") and district.hud.wave_status.text.contains("FALTAM 2 MISSÕES"))
    for index in range(3):
        assert(district.district_map.objective_markers[index].visible == (index == 1))
    district._pause()
    district.hud._process(0.2)
    assert(not guide.visible, "Paused guide remains above settings")
    district._pause()
    refresh()
    assert(guide.visible)
    for index in range(1, 3):
        district.player.position = district.missions.POSITIONS[index]
        district.missions._physics_process(3.1)
        refresh()
        if not district.ended:
            await process_frame
            var title_font: Font = guide.heading.get_theme_font("font")
            assert(title_font.get_string_size(guide.heading.text, HORIZONTAL_ALIGNMENT_LEFT, -1, guide.heading.get_theme_font_size("font_size")).x <= guide.heading.size.x, "Communication task title is clipped")
            assert(district.hud.wave_status.text.contains("FALTA 1 MISSÃO"))
    assert(district.ended and district.last_result.won and not guide.visible, "Completed missions left a stale objective or prevented victory")
    print("DEADLIGHT_MISSION_GUIDANCE_OK after-waves direction checklist map capture contested next pause victory mobile-bounds")
    district.queue_free()
    await process_frame
    root.get_node("GameAudio").shutdown()
    await create_timer(0.4).timeout
    DirAccess.remove_absolute("user://mission_guidance_smoke.cfg")
    quit()
