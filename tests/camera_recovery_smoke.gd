extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var target := Node3D.new()
    root.add_child(target)
    var camera := Camera3D.new()
    camera.set_script(preload("res://scripts/camera_controller.gd"))
    target.add_child(camera)
    await process_frame
    # A bad view basis must be repaired even after the target is valid again.
    camera.rotation = Vector3(NAN, NAN, NAN)
    camera._process(1.0 / 60.0)
    assert(camera.global_transform.is_finite(), "Camera retained an invalid view basis")
    assert(camera.global_basis.get_scale().is_equal_approx(Vector3.ONE))
    camera.impact(Vector3(INF, 0, 0))
    camera._process(1.0 / 60.0)
    assert(camera.global_transform.is_finite(), "Invalid impact poisoned camera shake")
    var last_view := camera.global_transform
    target.position.x = NAN
    camera._process(1.0 / 60.0)
    assert(camera.global_transform.is_finite(), "Non-finite target poisoned the camera")
    assert(camera.global_transform.is_equal_approx(last_view), "Invalid target changed the last safe view")
    assert(not preload("res://scripts/neighborhood_layout.gd").in_bounds(Vector3(0, NAN, 0)), "Invalid height bypassed map recovery")
    target.position = Vector3(42, 0, -10)
    camera._process(1.0 / 60.0)
    assert(camera.global_transform.is_finite() and camera.global_basis.get_scale().is_equal_approx(Vector3.ONE))
    assert(not camera.is_position_behind(target.position + Vector3.UP * 0.8))
    camera.finale = true
    for frame in range(60):
        camera._process(1.0 / 60.0)
        assert(camera.global_transform.is_finite() and camera.global_basis.get_scale().is_equal_approx(Vector3.ONE))
    target.queue_free()
    await process_frame
    root.get_node("GameAudio").shutdown()
    await create_timer(0.4).timeout
    print("DEADLIGHT_CAMERA_RECOVERY_OK basis, invalid target, teleport and finale")
    quit()
