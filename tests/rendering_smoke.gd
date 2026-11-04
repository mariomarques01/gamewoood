extends SceneTree
func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    root.size = Vector2i(1280,590)
    var district = load("res://scenes/main.tscn").instantiate()
    root.add_child(district)
    current_scene = district
    district.spawner.active = false
    district.missions.active = false
    district.player.set_physics_process(false)
    await process_frame
    var camera = district.player.get_node("Camera3D")
    var stray := Camera3D.new()
    district.add_child(stray)
    stray.make_current()
    for node in district.get_children():
        if node.get_script() == preload("res://scripts/neighborhood_overview.gd"):
            node._process(0)
    assert(camera.is_current(), "Gameplay resumed with a different active camera")
    stray.queue_free()
    for z in [-48,0,48]:
        for x in [-63,-42,-21,0,21,42,63]:
            district.player.position = Vector3(x,0,z)
            camera.global_rotation = Vector3.ZERO
            camera._process(1.0/60.0)
            var focus: Vector3 = district.player.position+Vector3.UP*0.8
            assert(not camera.is_position_behind(focus), "Camera lost the player after crossing regions")
            assert(camera.unproject_position(focus).distance_to(root.get_visible_rect().size*0.5) < 1)
            await RenderingServer.frame_post_draw
            var picture := root.get_texture().get_image()
            var background := 0
            for iy in range(12):
                for ix in range(12):
                    var pixel := picture.get_pixel(int(picture.get_width()*(0.25+ix*0.04)),int(picture.get_height()*(0.3+iy*0.025)))
                    if absf(pixel.r-0.035)+absf(pixel.g-0.11)+absf(pixel.b-0.18) < 0.04:
                        background += 1
            assert(background < 100, "3D scene disappeared behind the HUD")
    for batch in get_nodes_in_group("static_regions"):
        var bounds: AABB = batch.mesh.get_aabb()
        assert(bounds.size.x > 0 and bounds.size.z > 0, "Static batch has no visibility bounds")
        assert(bounds.size.x < 40 and bounds.size.z < 40, "Static batch spans distant city regions")
        if bounds.size.y < 0.06 and bounds.position.y <= 0.2:
            assert(batch.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "Ground batches regained expensive self shadows")
    var alien = district.spawner.spawn()
    assert(alien != null)
    alien.receive_damage(999)
    preload("res://scripts/hit_spark.gd").spawn(district,district.player.position,Vector3.UP,true)
    district.player.weapon.activate_frenzy(10)
    var celebration = preload("res://scripts/stage_finale.gd").new()
    celebration.player = district.player
    district.add_child(celebration)
    await process_frame
    assert(district.find_children("*","MultiMeshInstance3D",true,false).is_empty(), "Actors or effects still use GPU instancing")
    var safe: Vector3 = district.player.safe_position
    district.player.position = Vector3(100,0,100)
    district.player._physics_process(0)
    assert(district.player.position.distance_to(safe) < 0.3, "Player escaped the supported map")
    camera._process(1.0/60.0)
    assert(camera.global_position.distance_to(district.player.position*Vector3(1,0,1)+camera.offset) < 0.01)
    print("DEADLIGHT_RENDERING_OK 21 regions, camera recovery, ground shadows and local visibility bounds")
    district.queue_free()
    await process_frame
    root.get_node("GameAudio").shutdown()
    await create_timer(0.4).timeout
    quit()
