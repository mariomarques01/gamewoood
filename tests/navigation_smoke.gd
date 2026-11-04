extends SceneTree
var district: Node3D

func _initialize() -> void:
    call_deferred("_run")

func _walk(destination: Vector3) -> void:
    var player: CharacterBody3D = district.player
    for frame in range(360):
        var offset := destination - player.position
        offset.y = 0
        if offset.length() < 0.6:
            print("DEADLIGHT_WAYPOINT %s" % destination)
            district.hud.controls.movement = Vector2.ZERO
            return
        district.hud.controls.movement = Vector2(offset.dot(player.screen_to_world(Vector2.RIGHT)), offset.dot(player.screen_to_world(Vector2.DOWN))).normalized()
        await physics_frame
    push_error("Unreachable waypoint %s from %s" % [destination, player.position])
    quit(1)

func _run() -> void:
    root.size = Vector2i(1280, 720)
    district = load("res://scenes/main.tscn").instantiate()
    root.add_child(district)
    current_scene = district
    district.spawner.active = false
    await physics_frame
    for point in [Vector3(-21,0,1),Vector3(-42,0,1),Vector3(-42,0,-14)]:
        await _walk(point)
    district.missions._physics_process(3.1)
    assert(district.missions.current == 1, "Arsenal inaccessible")
    for point in [Vector3(-42,0,1),Vector3(-21,0,1),Vector3(0,0,1),Vector3(21,0,1),Vector3(42,0,1),Vector3(42,0,-10)]:
        await _walk(point)
    district.missions._physics_process(3.1)
    assert(district.missions.current == 2, "Helipad inaccessible")
    for point in [Vector3(42,0,1),Vector3(21,0,1),Vector3(0,0,1),Vector3(0,0,-7),Vector3(-16,0,-7),Vector3(-16,0,-31),Vector3(-12,0,-34)]:
        await _walk(point)
    district.missions._physics_process(3.1)
    assert(district.missions.current == 3 and district.ended, "Communications inaccessible")
    print("DEADLIGHT_NAVIGATION_OK collision-respecting route to all three objectives")
    district.queue_free()
    await process_frame
    root.get_node("GameAudio").shutdown()
    await create_timer(0.4).timeout
    quit(0)
