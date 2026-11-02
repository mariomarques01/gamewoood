extends SceneTree
var district: Node3D
var player: CharacterBody3D

func _initialize() -> void:
    call_deferred("_run")

func key(code: int) -> void:
    for pressed in [true, false]:
        var event := InputEventKey.new()
        event.keycode = code
        event.physical_keycode = code
        event.pressed = pressed
        Input.parse_input_event(event)
        Input.flush_buffered_events()

func touch(index: int, point: Vector2, pressed: bool) -> void:
    var event := InputEventScreenTouch.new()
    event.index = index
    event.position = root.get_final_transform() * point
    event.pressed = pressed
    Input.parse_input_event(event)
    Input.flush_buffered_events()

func _run() -> void:
    Input.emulate_mouse_from_touch = false
    root.size = Vector2i(1280, 720)
    district = load("res://scenes/main.tscn").instantiate()
    root.add_child(district)
    current_scene = district
    district.spawner.active = false
    player = district.player
    await physics_frame
    await process_frame
    var weapon = player.weapon
    assert(weapon.selected == 1 and weapon.ammo == 24, "Default machine gun missing")
    assert(player.actor.weapon_models[1].visible and not player.actor.weapon_models[0].visible, "Gun model not selected")
    weapon.ammo = 7
    key(KEY_1)
    assert(weapon.selected == 0 and weapon.ammo == 12 and weapon.capacity == 12, "Keyboard pistol selection failed")
    assert(district.hud.ammo_text.text == "12/12" and player.actor.weapon_models[0].visible, "Pistol visual/HUD mismatch")
    weapon.ammo = 3
    key(KEY_2)
    assert(weapon.ammo == 7, "Switching refilled the machine gun")
    key(KEY_Q)
    assert(weapon.selected == 0 and weapon.ammo == 3, "Cycle key lost pistol ammunition")
    weapon.reload()
    var remaining: float = weapon.reload_time
    assert(remaining > 0 and weapon.ammo == 3, "Reload did not start")
    weapon.select_weapon(1)
    weapon.active = false
    weapon._physics_process(0.2)
    assert(weapon.reloads[0] > 0 and weapon.magazines[0] == 3, "Holstering bypassed pistol reload")
    weapon.select_weapon(0)
    assert(weapon.reload_time > 0 and weapon.reload_time < remaining and weapon.cooldown >= 0.18, "Reload/cooldown not preserved")
    weapon._physics_process(1)
    assert(weapon.ammo == 12 and weapon.reload_time == 0, "Pistol reload did not complete")
    weapon.ammo = 2
    weapon.select_weapon(1)
    weapon.ammo = 4
    weapon.resupply()
    weapon.select_weapon(0)
    assert(weapon.ammo == 2, "Selected-weapon supply refilled the holstered gun")
    weapon.resupply(true)
    assert(weapon.magazines == [12, 24], "Checkpoint did not refill both guns")
    # A third pointer can choose a gun without stealing either stick.
    touch(0, Vector2(100, 430), true)
    var right_stick := Vector2(root.get_visible_rect().size.x - 100, 430)
    touch(1, right_stick, true)
    for entry in [[0, Vector2(132, 430)], [1, right_stick + Vector2(0, -35)]]:
        var drag := InputEventScreenDrag.new()
        drag.index = entry[0]
        drag.position = root.get_final_transform() * entry[1]
        Input.parse_input_event(drag)
        Input.flush_buffered_events()
    var center: Vector2 = district.hud.weapon_buttons[1].get_global_rect().get_center()
    touch(2, center, true)
    assert(weapon.selected == 1, "Combat selector waited for finger release")
    touch(2, center, false)
    assert(weapon.selected == 1 and district.hud.controls.move_id == 0 and district.hud.controls.aim_id == 1 and district.hud.controls.aiming and district.hud.controls.movement.length() > 0, "Weapon touch stole a stick")
    touch(0, Vector2(100, 430), false)
    touch(1, right_stick, false)
    district._pause()
    assert(not weapon.select_weapon(0), "Paused weapon switch was accepted")
    district._pause()
    # Measure actual emitted shots/damage, rather than only reading definitions.
    player.set_physics_process(false)
    weapon.set_physics_process(false)
    weapon.direction = Vector3.FORWARD
    weapon.active = true
    weapon.resupply(true)
    weapon.cooldown = 0
    weapon.select_weapon(0)
    weapon.cooldown = 0
    weapon._physics_process(0.001)
    var pistol_damage := 0.0
    for shot in get_nodes_in_group("projectiles"):
        pistol_damage = maxf(pistol_damage, shot.damage)
        shot.queue_free()
    assert(pistol_damage == 45 and weapon.ammo == 11, "Pistol shot damage/ammo wrong")
    var pistol_ammo: int = weapon.ammo
    weapon._physics_process(0.13)
    assert(weapon.ammo == pistol_ammo, "Pistol fired at machine-gun cadence")
    weapon.select_weapon(1)
    weapon.cooldown = 0
    weapon._physics_process(0.001)
    var machine_ammo: int = weapon.ammo
    weapon._physics_process(0.13)
    assert(weapon.ammo == machine_ammo - 1, "Machine gun did not sustain automatic fire")
    weapon.active = false
    for shot in get_nodes_in_group("projectiles"):
        shot.queue_free()
    await process_frame
    var sparks = preload("res://scripts/hit_spark.gd")
    for index in range(20):
        sparks.spawn(district, player.position, Vector3.UP, index % 2 == 0)
    assert(get_nodes_in_group("hit_sparks").size() <= 12, "Impact particles exceeded budget")
    for frame in range(20):
        await physics_frame
    assert(get_nodes_in_group("hit_sparks").is_empty(), "Impact particles leaked")
    # Complete the real ordered mission triggers, then inspect the presented result.
    var credits_before: int = district.save.credits
    district.score = 12
    district.arcade.credits = 35
    district.run_seconds = 95
    player.health.current = 75
    for index in range(3):
        player.position = district.missions.POSITIONS[index]
        district.missions._physics_process(3.1)
    assert(district.ended and district.hud.results.visible and not district.hud.overlay.visible, "Dedicated phase result was not displayed")
    assert(district.last_result.stars == 3 and district.last_result.bonus == 150 and district.last_result.earned == 185, "Completion reward calculation wrong")
    assert(district.save.credits == credits_before + 185 and district.save.best_stars == 3, "Completion reward/medals not saved")
    assert(not player.active and not weapon.enabled and not district.spawner.active, "Finale left combat active")
    assert(player.get_node("Camera3D").finale, "Victory camera was not activated")
    district._finish(true)
    assert(district.save.credits == credits_before + 185, "Victory reward was granted twice")
    assert(not weapon.select_weapon(0), "Result screen allowed firing equipment changes")
    await create_timer(1.1).timeout
    await RenderingServer.frame_post_draw
    var result = district.hud.results
    assert(result.card.get_global_rect().end.y < root.get_visible_rect().size.y, "Results extend below screen")
    assert(result.rewards.text.contains("185"), "Reward count-up did not finish")
    root.get_texture().get_image().save_png("res://build/logs/stage-complete.png")
    root.size = Vector2i(844, 390)
    await process_frame
    await RenderingServer.frame_post_draw
    assert(result.card.get_global_rect().end.x < root.get_visible_rect().size.x, "Mobile results overflow horizontally")
    root.get_texture().get_image().save_png("res://build/logs/stage-complete-mobile.png")
    var replay_center: Vector2 = result.replay_button.get_global_rect().get_center()
    touch(5, replay_center, true)
    touch(5, replay_center, false)
    await process_frame
    await process_frame
    district = current_scene
    player = district.player
    assert(not district.ended and player.weapon.enabled and player.weapon.ammo == 24, "Result replay did not restore a playable run")
    district.spawner.active = false
    var wallet: int = district.save.credits
    player.receive_damage(100)
    assert(district.hud.results.visible and not district.last_result.won and district.last_result.bonus == 0, "Defeat incorrectly granted a completion bonus")
    assert(district.save.credits == wallet, "Defeat granted credits not earned in the run")
    print("DEADLIGHT_ARSENAL_FINALE_OK keys multitouch models magazines reload cadence particles missions rewards medals replay defeat")
    district.queue_free()
    await process_frame
    root.get_node("GameAudio").shutdown()
    await create_timer(0.4).timeout
    quit(0)
