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
    player.set_physics_process(false)
    player.weapon.set_physics_process(false)
    district.arcade.set_physics_process(false)
    await physics_frame
    await physics_frame
    # Only actual deaths award XP, exactly once, including explosion deaths.
    var enemy = district.spawner.spawn()
    assert(enemy != null)
    enemy.receive_damage(1000)
    enemy.receive_damage(1000)
    assert(district.arcade.xp == 10 and district.score == 1)
    for index in range(16):
        district.arcade.register_kill(Vector3(3, 0, 10))
    assert(district.arcade.xp == 170 and player.weapon.frenzy_time == 0)
    player.weapon.reload_time = 1.0
    district.arcade.register_kill(Vector3(3, 0, 10))
    assert(player.weapon.frenzy_time == 10 and player.weapon.reload_time == 0)
    assert(district.arcade.xp == 0 and district.arcade.xp_required == 260)
    assert(district.hud.power_banner.major and district.hud.power_banner.remaining > 0, "Frenzy activation banner missing")
    assert(get_nodes_in_group("power_surges").size() > 0, "World energy burst missing")
    district.arcade.award_xp(100)
    assert(district.arcade.xp == 0, "Frenzy kills must not charge the next ability")
    player.weapon.direction = Vector3.RIGHT
    player.weapon.active = true
    player.weapon.cooldown = 0
    var before: int = player.weapon.ammo
    player.weapon._physics_process(0.01)
    assert(player.weapon.ammo == before, "Frenzy consumed ammunition")
    assert(player.weapon.cooldown < 0.1)
    var empowered := false
    for shot in get_nodes_in_group("projectiles"):
        if shot.empowered:
            empowered = shot.damage == player.weapon.WEAPONS[player.weapon.selected].damage * 3
    assert(empowered, "Golden shots did not deal triple damage")
    player.controls.movement = Vector2.RIGHT
    player._physics_process(0.5)
    assert(Vector2(player.velocity.x, player.velocity.z).length() > 8.5)
    player.controls.movement = Vector2.ZERO
    player.weapon.active = false
    player.weapon.set_physics_process(true)
    paused = true
    var remaining: float = player.weapon.frenzy_time
    await create_timer(0.1).timeout
    assert(player.weapon.frenzy_time == remaining, "Pause consumed ability duration")
    paused = false
    player.weapon.set_physics_process(false)
    player.weapon._physics_process(11)
    assert(player.weapon.frenzy_time == 0)
    player.weapon.active = true
    player.weapon.direction = Vector3.RIGHT
    player.weapon.cooldown = 0
    player.weapon._physics_process(0.01)
    assert(player.weapon.ammo == before - 1, "Normal ammunition did not resume")
    player.weapon.active = false
    # Distinct horde variants are spawned by the production sequence.
    var variants: Dictionary = {}
    for index in range(16):
        var alien = district.spawner.spawn()
        if alien != null:
            variants["ranged" if alien.ranged else alien.archetype] = true
            alien.position = Vector3(-15 + index % 4 * 2, 0, 12 + index / 4 * 2)
            alien.set_physics_process(false)
        await physics_frame
    assert(variants.has("runner") and variants.has("brute") and variants.has("ranged"), str(variants))
    # Persistent ground blood survives debris and stays under a fixed budget.
    var stain = get_nodes_in_group("blood_stains")[0]
    stain._physics_process(9)
    assert(not stain.is_queued_for_deletion() and stain.mesh.get_faces().size() > 100)
    for index in range(52):
        preload("res://scripts/blood_stain.gd").spread(district, Vector3(2 + index % 4, 0, 7 + index % 5), false)
    assert(get_nodes_in_group("blood_stains").size() <= 32)
    preload("res://scripts/blood_stain.gd").spread(district, Vector3(17, 0, -9), false)
    var raised = get_nodes_in_group("blood_stains")[-1]
    assert(raised.mesh.get_faces()[0].y > 0.11, "Blood is hidden below the raised helipad")
    for existing in get_nodes_in_group("blood_stains"):
        existing.free()
    for point in [Vector3(1, 0, 7), Vector3(-2, 0, 10), Vector3(4, 0, 9), Vector3(-3, 0, 5)]:
        preload("res://scripts/blood_stain.gd").spread(district, point, false)
    player.weapon.activate_frenzy(10)
    district.hud.notify("FÚRIA TRANCO! 10s • PODER MÁXIMO")
    player._physics_process(0.01)
    district.hud._process(0)
    assert(district.hud.xp_text.text.contains("FÚRIA ATIVA"))
    district.hud.power_banner._process(0.2)
    for surge in get_nodes_in_group("power_surges"):
        surge._process(0.2)
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://build/logs/evolution-frenzy.png")
    assert(district.hud.power_banner.title.size.x <= 288 and district.hud.power_banner.title.size.y <= 32, "Activation badge is oversized")
    assert(not district.hud.kill_popup.visible and not district.hud.frenzy_text.visible, "Redundant ability text obscures combat")
    assert(get_nodes_in_group("tree_grass").size() == 6, "Tree lawns missing")
    district.hud.power_banner.remaining = 0
    district.hud.power_banner.hide()
    player.position = Vector3(18, 0, 6)
    var camera = player.get_node("Camera3D")
    camera.follow_position = player.global_position + camera.offset
    camera.global_position = camera.follow_position
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://build/logs/terrain-east.png")
    var old_xp: int = district.arcade.xp
    player.active = false
    district.arcade.register_kill(Vector3.ZERO)
    assert(district.arcade.xp == old_xp)
    player.weapon.stop()
    assert(player.weapon.frenzy_time == 0)
    print("DEADLIGHT_EVOLUTION_OK xp threshold damage ammo speed pause expiry variants blood budget")
    district.queue_free()
    await process_frame
    root.get_node("GameAudio").shutdown()
    await create_timer(0.4).timeout
    quit(0)
