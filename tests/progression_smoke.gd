extends SceneTree
const Progress = preload("res://scripts/save_manager.gd")
const Projectile = preload("res://scripts/projectile.gd")
const Spark = preload("res://scripts/hit_spark.gd")
const TEST_PATH := "user://progression_smoke.cfg"

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    root.size = Vector2i(844, 390)
    DirAccess.remove_absolute(TEST_PATH)
    var progress = Progress.new()
    progress.storage_path = TEST_PATH
    root.add_child(progress)
    assert(progress.credits == 0 and progress.equipped == 1)
    assert(not progress.buy_upgrade(0, "damage"), "Empty wallet accepted a purchase")
    progress.credits = 1000
    assert(not progress.buy_upgrade(9, "damage") and not progress.buy_upgrade(0, "invalid"))
    for index in range(3):
        assert(progress.buy_upgrade(0, "damage"))
    assert(progress.credits == 550 and not progress.buy_upgrade(0, "damage"), "Upgrade cap/cumulative price wrong")
    assert(progress.buy_upgrade(0, "reload") and progress.equip(0))
    progress.best_wave = 2
    progress.mark_tutorial_seen()
    var restored = Progress.new()
    restored.storage_path = TEST_PATH
    root.add_child(restored)
    assert(restored.credits == 475 and restored.equipped == 0 and restored.upgrade_level(0, "damage") == 3 and restored.upgrade_level(0, "reload") == 1)
    assert(restored.best_wave == 2 and restored.tutorial_seen, "Reload lost progress")
    # A failed disk write must never charge or equip anything.
    var good_path: String = restored.storage_path
    restored.storage_path = "user://missing_progression_directory/save.cfg"
    assert(not restored.buy_upgrade(1, "damage") and restored.credits == 475 and restored.upgrade_level(1, "damage") == 0)
    assert(not restored.equip(1) and restored.equipped == 0)
    restored.storage_path = good_path
    var menu = load("res://scenes/start_menu.tscn").instantiate()
    root.add_child(menu)
    current_scene = menu
    menu.progression.progress = restored
    menu._open_progression("upgrades")
    await process_frame
    await process_frame
    assert(menu.progression.visible and menu.progression.damage_button.disabled, "Max-level purchase stays enabled")
    assert(menu.progression.panel.get_global_rect().end.y < root.get_visible_rect().size.y, "Upgrade panel overflows mobile")
    menu.progression.selectors[1].pressed.emit()
    menu.progression.damage_button.pressed.emit()
    assert(restored.upgrade_level(1, "damage") == 1 and restored.credits == 400)
    menu.progression.open("achievements")
    assert(menu.progression.description.text.contains("2/3"))
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://build/logs/progression-achievements.png")
    menu.progression.open("arsenal")
    await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://build/logs/progression-arsenal.png")
    menu.queue_free()
    await process_frame
    var district = load("res://scenes/main.tscn").instantiate()
    root.add_child(district)
    current_scene = district
    district.spawner.set_physics_process(false)
    district.missions.set_physics_process(false)
    district.player.set_physics_process(false)
    district.player.weapon.set_physics_process(false)
    var player = district.player
    var weapon = player.weapon
    weapon.apply_loadout(progress)
    assert(weapon.selected == 0)
    weapon.direction = Vector3.RIGHT
    weapon.active = true
    weapon.cooldown = 0
    weapon._physics_process(0.001)
    var upgraded_shot = get_nodes_in_group("projectiles")[0]
    assert(is_equal_approx(upgraded_shot.damage, 58.5), "Saved damage upgrade was not applied")
    weapon.reload()
    assert(is_equal_approx(weapon.reload_time, 0.81), "Saved reload upgrade was not applied")
    weapon.active = false
    var pool = district.get_node("CombatPool")
    pool.clear()
    var created_before: Dictionary = pool.created.duplicate()
    var first_id := 0
    # 2,500 shots, equivalent in count to five minutes at 0.12s cadence.
    # Lifetime is stepped explicitly; this is an allocation test, not a real-time soak.
    for index in range(2500):
        var powered: bool = index % 2 == 0
        var shot = Projectile.fire(district, Vector3(0, 20, 0), Vector3.RIGHT, player, weapon.shot_material, 25, powered, powered)
        assert(shot != null and shot.life == 1.8 and shot.hostile == powered and shot.empowered == powered)
        assert(shot.speed == (10 if powered else 24) and is_equal_approx(shot.visual.scale.x, 1.8 if powered else 1.0))
        if index == 0:
            first_id = shot.get_instance_id()
        assert(shot.get_instance_id() == first_id, "Projectile was recreated instead of reused")
        shot._physics_process(2.0)
        assert(not shot.in_use and shot.shooter == null)
        Spark.spawn(district, Vector3.ZERO, Vector3.UP, powered, powered)
        get_nodes_in_group("hit_sparks")[0]._physics_process(0.3)
    assert(pool.created == created_before, "Continuous firing allocated additional scene objects")
    assert(get_nodes_in_group("projectiles").is_empty() and get_nodes_in_group("hit_sparks").is_empty())
    # Recycle that same entry through real friendly and hostile ray collisions.
    var target = preload("res://scripts/enemy_controller.gd").new()
    target.player = player
    district.add_child(target)
    target.position = Vector3(0, 100, 0)
    target.set_physics_process(false)
    player.position = Vector3(0, 100, 4)
    await physics_frame
    await physics_frame
    var friendly = Projectile.fire(district, Vector3(0, 101.05, 2), Vector3.FORWARD, player, weapon.shot_material, 25)
    friendly._physics_process(0.1)
    assert(target.health.current == 10 and not friendly.in_use, "Reused friendly projectile missed its collision layer")
    var hostile = Projectile.fire(district, Vector3(0, 101.05, 2), Vector3.BACK, target, weapon.shot_material, 12, true)
    assert(hostile.get_instance_id() == first_id)
    hostile._physics_process(0.2)
    assert(player.health.current == 88 and not hostile.in_use, "Reused hostile projectile retained friendly collision/shooter state")
    target.queue_free()
    player.position = Vector3(0, 0, 1)
    player.health.current = 100
    pool.clear()
    await physics_frame
    # Hard ceiling: player fire cannot grow an unbounded pool.
    for index in range(64):
        assert(Projectile.fire(district, Vector3(0, 20, 0), Vector3.RIGHT, player, weapon.shot_material, 25) != null)
    assert(Projectile.fire(district, Vector3.ZERO, Vector3.RIGHT, player, weapon.shot_material, 25) == null)
    pool.clear()
    # Exercise actual scheduling/death signals, rewards, intermission and final stop.
    var spawner = district.spawner
    var wallet: int = district.arcade.credits
    for wave in range(1, 4):
        var attempts := 0
        while spawner.waves_completed < wave:
            spawner._physics_process(4)
            assert(get_nodes_in_group("enemies").size() <= 20)
            for alien in get_nodes_in_group("enemies"):
                alien.receive_damage(1000)
            await physics_frame
            attempts += 1
            assert(attempts < 40, "Wave never completed")
        assert(spawner.wave == wave and spawner.waves_completed == wave)
        if wave < 3:
            assert(spawner.resting)
            spawner._physics_process(8.1)
    # Kill 12 challenge adds 25 on top of the 150 from completed waves.
    assert(district.arcade.credits == wallet + 175, "Wave rewards were lost or duplicated")
    assert(spawner.wave_kills == 16 and spawner.waves_completed == 3)
    for index in range(10):
        spawner._physics_process(10)
    assert(get_nodes_in_group("enemies").is_empty(), "Final wave restarted continuous spawning")
    district.save.storage_path = TEST_PATH
    district._finish(false)
    assert(district.last_result.waves == 3 and district.save.best_wave == 3)
    assert(get_nodes_in_group("projectiles").is_empty())
    print("DEADLIGHT_PROGRESSION_OK persistence purchases caps rollback loadout 2500-reused-shots bounds 3-waves rewards")
    district.queue_free()
    progress.queue_free()
    restored.queue_free()
    await process_frame
    root.get_node("GameAudio").shutdown()
    await create_timer(0.4).timeout
    DirAccess.remove_absolute(TEST_PATH)
    quit()
