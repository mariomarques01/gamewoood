extends SceneTree
const Canister = preload("res://scripts/energy_canister.gd")
const Enemy = preload("res://scripts/enemy_controller.gd")
const Projectile = preload("res://scripts/projectile.gd")
var district: Node3D
var player: CharacterBody3D

func _initialize() -> void:
    call_deferred("_run")

func _shot(point: Vector3, direction: Vector3) -> void:
    var shot = Projectile.new()
    shot.direction = direction
    shot.shooter = player
    shot.material = player.weapon.shot_material
    district.add_child(shot)
    shot.global_position = point

func _run() -> void:
    root.size = Vector2i(1280, 720)
    district = load("res://scenes/main.tscn").instantiate()
    root.add_child(district)
    current_scene = district
    player = district.player
    district.spawner.active = false
    player.set_physics_process(false)
    await physics_frame
    await physics_frame
    assert(get_nodes_in_group("explosives").size() == 6, "Six functional energy props missing")
    for canister in get_nodes_in_group("explosives"):
        var shape := SphereShape3D.new()
        shape.radius = 0.46
        var query := PhysicsShapeQueryParameters3D.new()
        query.shape = shape
        query.transform.origin = canister.global_position + Vector3.UP * 0.8
        query.exclude = [canister.get_rid()]
        query.collision_mask = 1
        assert(player.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty(), "Canister embedded in base geometry: %s" % canister.position)
    player.position = Vector3(0, 0, 14)
    var hurt = Enemy.new()
    hurt.player = player
    district.add_child(hurt)
    hurt.position = Vector3(3, 0, 14)
    await physics_frame
    hurt.receive_damage(25)
    assert(hurt.health.current == 10 and hurt.hit_bar.visible, "Hit health feedback missing")
    var before: Vector3 = hurt.position
    for frame in range(6):
        await physics_frame
    assert(hurt.position.x > before.x + 0.15, "Knockback was overwritten by pursuit")
    hurt.set_physics_process(false)
    hurt.hit_time = 0
    hurt._physics_process(0.01)
    assert(not hurt.hit_bar.visible, "Hit bar remained permanently visible")
    hurt.queue_free()
    await process_frame
    var primary = get_nodes_in_group("explosives")[0]
    var center: Vector3 = primary.global_position
    player.position = center + Vector3(0, 0, 3)
    var secondary = Canister.new()
    district.add_child(secondary)
    secondary.position = center + Vector3(2.5, 0, 0)
    for offset in [Vector3(1.3, 0, 0), Vector3(0, 0, -1.8)]:
        var alien = district.spawner.spawn()
        assert(alien != null)
        alien.position = center + offset
        alien.set_physics_process(false)
    await physics_frame
    await physics_frame
    _shot(center + Vector3(0, 1, 2.5), Vector3.FORWARD)
    for frame in range(12):
        await physics_frame
    assert(primary.health == 15 and not primary.armed, "First projectile did not damage canister")
    _shot(center + Vector3(0, 1, 2.5), Vector3.FORWARD)
    for frame in range(12):
        await physics_frame
    assert(primary.armed and primary.warning.visible and district.score == 0, "Fuse was not telegraphed before damage")
    for frame in range(39):
        await physics_frame
    assert(district.score == 2 and district.arcade.total_kills == 2, "Blast kills bypassed normal kill/drop accounting")
    assert(secondary.armed, "Explosion did not arm nearby canister")
    assert(player.health.current == 80, "Nearby player did not take bounded blast damage")
    await process_frame
    await RenderingServer.frame_post_draw
    assert(district.hud.combo_meter.visible and district.hud.combo_meter.value > 0, "Combo duration feedback missing")
    assert(district.hud.kill_popup.get_global_rect().end.x <= root.get_visible_rect().size.x, "Combo text extends off screen")
    var camera := root.get_camera_3d()
    assert(camera.impact_time > 0 and camera.impact_strength <= 0.13, "Nearby blast camera impulse missing or excessive")
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://build/logs/energy-combat.png")
    for frame in range(45):
        await physics_frame
    assert(not is_instance_valid(secondary), "Chain reaction did not finish")
    assert(player.health.current == 80, "Chain reaction bypassed player invulnerability")
    assert(camera.global_position.distance_to(camera.follow_position) < 0.001, "Camera shake accumulated drift")
    var protected = Enemy.new()
    protected.player = player
    district.add_child(protected)
    protected.position = Vector3(1, 0, 17)
    protected.set_physics_process(false)
    var blocker := StaticBody3D.new()
    district.add_child(blocker)
    blocker.position = Vector3(2.5, 1.5, 17)
    var collider := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(0.3, 3, 4)
    collider.shape = box
    blocker.add_child(collider)
    var blocked = Canister.new()
    district.add_child(blocked)
    blocked.position = Vector3(4, 0, 17)
    player.position = Vector3(0, 0, 7)
    await physics_frame
    await physics_frame
    blocked.receive_damage(100)
    for frame in range(45):
        await physics_frame
    assert(protected.health.current == protected.health.maximum, "Blast penetrated a wall")
    player.position = Vector3(1, 0, 17)
    var credit = district.arcade.spawn_supply(Vector3(3, 0, 17), "credit")
    var supply_start: Vector3 = credit.position
    var credits_before: int = district.arcade.credits
    for frame in range(8):
        await physics_frame
    credit.collect()
    assert(not credit.taken and credit.position.is_equal_approx(supply_start), "Supply magnet crossed a wall")
    assert(district.arcade.credits == credits_before, "Supply collected through wall")
    blocker.queue_free()
    protected.queue_free()
    for frame in range(60):
        await physics_frame
    assert(district.arcade.credits > credits_before, "Clear-path magnet did not collect")
    player.position = Vector3(0, 0, 7)
    player.weapon.overdrive_time = 4
    player.set_physics_process(true)
    await physics_frame
    await process_frame
    assert(player.boost_aura.visible and district.hud.combo_meter.visible, "Boost aura/countdown missing")
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://build/logs/boost-feedback.png")
    player.weapon.overdrive_time = 0
    district.arcade.chain_time = 0
    for frame in range(100):
        await physics_frame
    assert(not player.boost_aura.visible and not district.hud.combo_meter.visible, "Boost feedback did not expire")
    for index in range(10):
        preload("res://scripts/energy_burst.gd").spawn(district, player.position)
    assert(get_nodes_in_group("energy_fx").size() <= 6, "Energy FX exceeded draw budget")
    for frame in range(80):
        await physics_frame
    assert(get_nodes_in_group("energy_fx").is_empty(), "Expired blast visuals leaked")
    print("DEADLIGHT_IMPACT_OK projectile fuse chain damage cover drops knockback combo aura cleanup")
    district.queue_free()
    await process_frame
    root.get_node("GameAudio").shutdown()
    await create_timer(0.4).timeout
    quit(0)
