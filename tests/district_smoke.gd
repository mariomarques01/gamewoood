extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func touch(index: int, position: Vector2, pressed: bool) -> void:
    var event := InputEventScreenTouch.new()
    event.index = index
    event.position = root.get_final_transform() * position
    event.pressed = pressed
    Input.parse_input_event(event)
    Input.flush_buffered_events()

func drag(index: int, position: Vector2) -> void:
    var event := InputEventScreenDrag.new()
    event.index = index
    event.position = root.get_final_transform() * position
    Input.parse_input_event(event)
    Input.flush_buffered_events()

func pause_key() -> void:
    var key := InputEventKey.new()
    key.keycode = KEY_ESCAPE
    key.physical_keycode = KEY_ESCAPE
    key.pressed = true
    Input.parse_input_event(key)
    Input.flush_buffered_events()
    key = InputEventKey.new()
    key.keycode = KEY_ESCAPE
    key.physical_keycode = KEY_ESCAPE
    key.pressed = false
    Input.parse_input_event(key)
    Input.flush_buffered_events()

func _run() -> void:
    Input.emulate_mouse_from_touch = false
    root.size = Vector2i(1280, 720)
    var scene := load("res://scenes/main.tscn") as PackedScene
    assert(scene != null, "Main scene could not load")
    var district = scene.instantiate()
    root.add_child(district)
    current_scene = district
    await process_frame
    assert(district.get_script() != null and district.district_map.get_child_count() >= 100, "Base geometry missing")
    assert(district.district_map.objective_markers.size() == 3, "Mission markers missing")
    assert(district.hud.status.text.contains("v0.10.0"), "Version missing")
    assert(district.hud.jump_button.text.is_empty(), "Jump action should use an icon")
    assert(district.hud.art.mission_rect.end.y <= 110, "HUD still occupies too much of the upper screen")
    assert(district.hud.art.health_rect.size.y <= 48, "Health HUD is oversized")
    assert(not district.hud.art.mission_rect.intersects(district.hud.pause_button.get_global_rect()), "HUD overlaps pause")
    var player = district.player
    assert(player.actor.legs.size() == 2, "Animated captain model missing")
    var camera: Camera3D = player.get_node("Camera3D")
    assert(camera.is_current(), "Camera not active")
    district.spawner.timer = 0.0
    await physics_frame
    await physics_frame
    assert(get_nodes_in_group("enemies").size() == 2, "Spawner did not execute opening wave")
    district.spawner.active = false
    for enemy in get_nodes_in_group("enemies"):
        enemy.queue_free()
    await process_frame
    touch(0, Vector2(100, 400), true)
    touch(1, Vector2(1100, 400), true)
    drag(0, Vector2(170, 400))
    drag(1, Vector2(1100, 330))
    var start: Vector3 = player.position
    var camera_start := camera.global_position
    for frame in range(25):
        await physics_frame
    assert(district.hud.controls.move_id == 0 and district.hud.controls.aim_id == 1, "Touch ownership failed")
    assert(player.position.x > start.x + 0.5, "Player did not move")
    assert(camera.global_position.x > camera_start.x, "Camera did not follow")
    assert(player.weapon.direction.dot(player.screen_to_world(Vector2.UP)) > 0.99 and player.velocity.x > 0.9, "Aim depends on movement")
    assert(player.weapon.ammo < 24, "Aim did not fire")
    # A third touch jumps while both existing pointers keep movement and aim.
    var jump_center: Vector2 = district.hud.jump_button.get_global_rect().get_center()
    var floor_y: float = player.position.y
    touch(2, jump_center, true)
    for frame in range(8):
        await physics_frame
    assert(player.position.y > floor_y + 0.4, "Third-touch jump did not leave ground")
    assert(district.hud.controls.move_id == 0 and district.hud.controls.aim_id == 1, "Jump stole a joystick pointer")
    var rising_speed: float = player.velocity.y
    touch(2, jump_center, false)
    player.request_jump()
    await physics_frame
    assert(player.velocity.y <= rising_speed, "Airborne request caused double jump")
    for frame in range(55):
        await physics_frame
    assert(player.is_on_floor(), "Jump did not land")
    touch(0, Vector2(170, 400), false)
    assert(district.hud.controls.movement == Vector2.ZERO and district.hud.controls.aim_id == 1, "Release interrupted aim")
    touch(1, Vector2(1170, 400), false)
    for shot in get_nodes_in_group("projectiles"):
        shot.queue_free()
    # A visible projectile must actually hit an alien and award exactly one kill.
    var enemy = preload("res://scripts/enemy_controller.gd").new()
    enemy.player = player
    enemy.eliminated.connect(func(): district.spawner.eliminated.emit())
    district.add_child(enemy)
    enemy.global_position = player.global_position + Vector3(3, 0, 0)
    enemy.set_physics_process(false)
    var free_aim := Vector3(1, 0, 0.15).normalized()
    assert(player._assist_aim(free_aim).dot(Vector3.RIGHT) > free_aim.dot(Vector3.RIGHT), "Touch aim assistance failed")
    var projectile = preload("res://scripts/projectile.gd").new()
    projectile.direction = Vector3.RIGHT
    projectile.damage = 100
    projectile.shooter = player
    projectile.material = player.weapon.shot_material
    district.add_child(projectile)
    projectile.global_position = player.global_position + Vector3(0.8, 1.05, 0)
    for frame in range(20):
        await physics_frame
    assert(district.score == 1, "Projectile damage / elimination failed")
    # Fire into headquarters; wall must consume the shot before it passes through.
    var wall_shot = preload("res://scripts/projectile.gd").new()
    wall_shot.direction = Vector3.FORWARD
    wall_shot.shooter = player
    wall_shot.material = player.weapon.shot_material
    district.add_child(wall_shot)
    wall_shot.global_position = Vector3(0, 1, 2)
    for frame in range(12):
        await physics_frame
    assert(not is_instance_valid(wall_shot), "Projectile passed through headquarters")
    player.receive_damage(10)
    assert(player.health.current == 90, "Player damage failed")
    player.receive_damage(10)
    assert(player.health.current == 90, "Damage cooldown failed")
    var melee = preload("res://scripts/enemy_controller.gd").new()
    melee.player = player
    district.add_child(melee)
    melee.position = player.position + Vector3.RIGHT * 1.3
    melee.set_physics_process(false)
    player.health.invulnerability = 0
    var before_attack: float = player.health.current
    melee._physics_process(0.1)
    assert(melee.winding_up and melee.warning_ring.visible, "Melee warning missing")
    assert(player.health.current == before_attack, "Melee damage arrived before warning")
    var original_position: Vector3 = player.position
    player.position += Vector3.BACK * 4
    melee._physics_process(0.5)
    assert(player.health.current == before_attack, "Escaping the attack did not prevent damage")
    player.position = original_position
    melee.queue_free()
    await process_frame
    player.weapon.ammo = 1
    player.weapon.cooldown = 0.0
    player.weapon.direction = Vector3.RIGHT
    player.weapon.active = true
    player.weapon._physics_process(0.2)
    assert(player.weapon.ammo == 0 and player.weapon.reload_time > 0, "Magazine did not reload")
    player.weapon.active = false
    player.weapon._physics_process(1.3)
    assert(player.weapon.ammo == 24, "Reload did not finish")
    var ranged = preload("res://scripts/enemy_controller.gd").new()
    ranged.ranged = true
    ranged.player = player
    district.add_child(ranged)
    ranged.global_position = player.global_position + Vector3(4, 0, 0)
    ranged._physics_process(0.1)
    assert(ranged.winding_up, "Plasma attack has no warning")
    ranged._physics_process(0.6)
    assert(not get_nodes_in_group("projectiles").is_empty(), "Plasma attack missing")
    ranged.queue_free()
    await process_frame
    for shot in get_nodes_in_group("projectiles"):
        shot.queue_free()
    # Exercise mixed AI under the configured simultaneous-enemy ceiling.
    player.health.invulnerability = 10.0
    for index in range(district.spawner.MAX_ENEMIES):
        var stress_enemy = preload("res://scripts/enemy_controller.gd").new()
        stress_enemy.player = player
        stress_enemy.ranged = index % 3 == 0
        district.add_child(stress_enemy)
        stress_enemy.position = Vector3(-20 + (index % 8) * 5, 0, 10 + (index / 8) * 2)
    district.spawner.active = true
    district.spawner.timer = 0.0
    for frame in range(120):
        await physics_frame
        assert(get_nodes_in_group("enemies").size() <= district.spawner.MAX_ENEMIES, "Spawner exceeded enemy limit")
    assert(get_nodes_in_group("enemies").size() == district.spawner.MAX_ENEMIES, "Mixed-AI stress population changed unexpectedly")
    district.spawner.active = false
    for stress_enemy in get_nodes_in_group("enemies"):
        stress_enemy.queue_free()
    for shot in get_nodes_in_group("projectiles"):
        shot.queue_free()
    await process_frame
    print("DEADLIGHT_STRESS_OK 24 mixed enemies for 120 physics frames")
    pause_key()
    assert(paused and district.hud.overlay.visible, "Pause failed")
    pause_key()
    assert(not paused, "Resume failed")
    root.size = Vector2i(390, 844)
    await process_frame
    await process_frame
    assert(paused and district.hud.rotation_panel.visible, "Portrait orientation did not pause/show rotate prompt")
    assert(district.hud.details.text.contains("ARSENAL"), "Pause objective details missing")
    root.size = Vector2i(1280, 720)
    await process_frame
    await process_frame
    assert(not paused and not district.hud.rotation_panel.visible, "Landscape did not resume after rotation")
    pause_key()
    root.size = Vector2i(390, 844)
    await process_frame
    await process_frame
    root.size = Vector2i(1280, 720)
    await process_frame
    await process_frame
    assert(paused and district.manually_paused, "Rotation cleared a manual pause")
    pause_key()
    # Physical trigger range, contested objective and sequential completion.
    player.position = Vector3.ZERO
    district.missions._physics_process(3.1)
    assert(district.missions.current == 0, "Objective completed outside trigger")
    var blocker = preload("res://scripts/enemy_controller.gd").new()
    blocker.player = player
    district.add_child(blocker)
    player.position = district.missions.POSITIONS[0]
    blocker.position = player.position + Vector3.RIGHT * 2
    district.missions._physics_process(3.1)
    assert(district.missions.current == 0 and district.missions.contested, "Contested objective advanced")
    blocker.queue_free()
    await process_frame
    for index in range(3):
        player.position = district.missions.POSITIONS[index]
        district.missions._physics_process(1.5)
        assert(district.missions.progress > 0.0, "Progress feedback missing")
        district.missions._physics_process(1.6)
        assert(district.missions.current == index + 1, "Mission did not complete")
    assert(district.ended and district.hud.outcome.text.contains("BASE PROTEGIDA"), "Victory failed")
    district._restart()
    await process_frame
    await process_frame
    district = current_scene
    assert(not district.ended and district.score == 0, "Restart failed")
    district.player.receive_damage(100)
    assert(district.ended and district.hud.outcome.text.contains("BASE INVADIDA"), "Defeat failed")
    print("DEADLIGHT_SMOKE_OK map input movement camera weapon collision damage missions victory defeat restart pause")
    district.queue_free()
    await process_frame
    root.get_node("GameAudio").shutdown()
    await create_timer(0.4).timeout
    quit(0)
