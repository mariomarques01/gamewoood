extends SceneTree
func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    root.size = Vector2i(1280, 720)
    var district = load("res://scenes/main.tscn").instantiate()
    root.add_child(district)
    current_scene = district
    district.spawner.active = false
    var player = district.player
    await physics_frame
    player.receive_damage(50)
    assert(player.health.current == 50, "Test damage setup failed")
    var health = district.arcade.spawn_supply(player.position, "health")
    await physics_frame
    await physics_frame
    assert(player.health.current == 70, "Health pickup did not collect automatically")
    assert(district.hud.toast.text == "+20 VIDA", "Pickup feedback missing")
    player.weapon.ammo = 2
    player.weapon.reload_time = 1
    var ammo = district.arcade.spawn_supply(player.position + Vector3.RIGHT * 4, "ammo")
    ammo.collect()
    assert(player.weapon.ammo == 24 and player.weapon.reload_time == 0, "Ammo did not cancel reload/refill")
    player.weapon.ammo = 3
    ammo.collect()
    assert(player.weapon.ammo == 3, "Pickup applied twice")
    for index in range(5):
        district.arcade.register_kill(player.position + Vector3.RIGHT * 8)
    assert(player.weapon.overdrive_time == 4, "Five-kill sequence did not activate boost")
    assert(district.hud.toast.text.contains("TRANCO TOTAL"), "Boost feedback missing")
    assert(get_nodes_in_group("supplies").size() >= 1, "Kills did not drop supplies")
    player.weapon.direction = Vector3.RIGHT
    player.weapon.active = true
    player.weapon.cooldown = 0
    player.weapon._physics_process(0.01)
    assert(player.weapon.cooldown < 0.16, "Boost did not improve fire rate")
    var boosted := false
    for shot in get_nodes_in_group("projectiles"):
        if shot.damage > 25:
            boosted = true
    assert(boosted, "Boost did not improve projectile damage")
    player.weapon.active = false
    player.weapon._physics_process(4.1)
    district.arcade._physics_process(5)
    assert(player.weapon.overdrive_time == 0 and district.arcade.chain == 0, "Combo/boost did not expire")
    player.health.current = 90
    district.arcade.mission_completed(1)
    assert(player.health.current == 100 and player.weapon.ammo == 24, "Mission checkpoint reward failed")
    player.health.current = 70
    district.arcade.mission_completed(1)
    assert(player.health.current == 70, "Mission reward duplicated")
    player.health.invulnerability = 0
    player.receive_damage(100)
    var late_supply = district.arcade.spawn_supply(player.position, "health")
    late_supply.collect()
    assert(player.health.current == 0 and not player.active, "Supply resurrected a defeated player")
    print("DEADLIGHT_ARCADE_OK health ammo sequence boost expiry checkpoint")
    district.queue_free()
    await process_frame
    quit(0)
