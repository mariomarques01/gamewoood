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
            district.hud.controls.movement = Vector2.ZERO
            return
        district.hud.controls.movement = Vector2(offset.x, offset.z).normalized()
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
    await _walk(Vector3(-10, 0, 7))
    await _walk(Vector3(-17, 0, 3))
    await _walk(Vector3(-17, 0, -7))
    district.missions._physics_process(3.1)
    assert(district.missions.current == 1, "Arsenal inaccessible")
    await _walk(Vector3(-15, 0, -7))
    await _walk(Vector3(-15, 0, -10))
    await _walk(Vector3(0, 0, -10))
    await _walk(Vector3(17, 0, -9))
    district.missions._physics_process(3.1)
    assert(district.missions.current == 2, "Helipad inaccessible")
    await _walk(Vector3(7, 0, -10))
    await _walk(Vector3(0, 0, -13))
    await _walk(Vector3(0, 0, -18))
    district.missions._physics_process(3.1)
    assert(district.missions.current == 3 and district.ended, "Communications inaccessible")
    print("DEADLIGHT_NAVIGATION_OK collision-respecting route to all three objectives")
    district.queue_free()
    await process_frame
    quit(0)
