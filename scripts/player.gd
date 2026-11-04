extends CharacterBody3D
const Audio = preload("res://scripts/audio_api.gd")
const Health = preload("res://scripts/health_component.gd")
const CaptainVisual = preload("res://scripts/captain_visual.gd")
const Weapon = preload("res://scripts/weapon_system.gd")
@export var move_speed: float = 6.0
@export var acceleration: float = 20.0
var mobile_direction := Vector2.ZERO
var controls: Control
var health: Node
var weapon: Node
var active := true
var reported_movement := false
const GRAVITY := 22.0
const JUMP_SPEED := 8.0
var jump_buffer := 0.0
var jump_lock := 0.0
var step_timer := 0.0
var safe_position := preload("res://scripts/neighborhood_layout.gd").PLAYER_START
var visual: Node3D
var body_material: StandardMaterial3D
var actor: Node3D
var damage_push := Vector3.ZERO
var boost_aura: MeshInstance3D

func _ready() -> void:
    add_to_group("player")
    collision_layer = 4
    collision_mask = 1 | 2
    health = Health.new()
    add_child(health)
    weapon = Weapon.new()
    add_child(weapon)
    weapon.power_activated.connect(_power_activated)
    visual = $Visual
    $Visual/MeshInstance3D.hide()
    actor = CaptainVisual.new()
    visual.add_child(actor)
    body_material = actor.chest.material_override
    boost_aura = MeshInstance3D.new()
    var ring := TorusMesh.new()
    ring.inner_radius = 0.65
    ring.outer_radius = 0.73
    ring.rings = 24
    ring.ring_segments = 6
    boost_aura.mesh = ring
    boost_aura.material_override = preload("res://scripts/visual_kit.gd").material(Color(0.1, 0.85, 1), true)
    boost_aura.position.y = 0.08
    add_child(boost_aura)
    boost_aura.hide()

func _physics_process(delta: float) -> void:
    if not active:
        boost_aura.hide()
        velocity = Vector3.ZERO
        weapon.active = false
        return
    get_node("/root/GameAudio").listener_position = global_position
    boost_aura.visible = weapon.overdrive_time > 0 or weapon.frenzy_time > 0
    boost_aura.material_override = preload("res://scripts/visual_kit.gd").material(Color(1, 0.64, 0.07) if weapon.frenzy_time > 0 else Color(0.1, 0.85, 1), true)
    actor.weapon_models[weapon.selected].scale = Vector3.ONE * (1.3 if weapon.frenzy_time > 0 else 1.0)
    actor.weapon_models[1 - weapon.selected].scale = Vector3.ONE
    boost_aura.scale = Vector3.ONE * (1 + sin(weapon.overdrive_time * 12) * 0.1)
    var direction := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    if is_instance_valid(controls):
        mobile_direction = controls.movement
    if mobile_direction.length() > 0.05:
        direction = mobile_direction.limit_length()
    var world_move := screen_to_world(direction)
    var target := world_move * move_speed * (1.5 if weapon.frenzy_time > 0 else 1.0)
    velocity.x = move_toward(velocity.x, target.x, acceleration * delta)
    velocity.z = move_toward(velocity.z, target.z, acceleration * delta)
    jump_lock = maxf(0.0, jump_lock - delta)
    if Input.is_action_just_pressed("jump"):
        request_jump()
    jump_buffer = maxf(0.0, jump_buffer - delta)
    if is_on_floor():
        velocity.y = -0.5
        if position.y < 0.2 and preload("res://scripts/neighborhood_layout.gd").in_bounds(position):
            safe_position = position
        if jump_buffer > 0.0 and jump_lock <= 0.0:
            velocity.y = JUMP_SPEED
            jump_buffer = 0.0
            jump_lock = 0.3
            print("DEADLIGHT_JUMP")
            Audio.play(self, "jump")
    else:
        velocity.y -= GRAVITY * delta
    velocity.x = clampf(velocity.x + damage_push.x * delta * 8, -9, 9)
    velocity.z = clampf(velocity.z + damage_push.z * delta * 8, -9, 9)
    damage_push = damage_push.move_toward(Vector3.ZERO, 18 * delta)
    move_and_slide()
    step_timer -= delta
    if is_on_floor() and Vector2(velocity.x, velocity.z).length() > 1 and step_timer <= 0:
        step_timer = 0.28
        Audio.play(self, "step")
    actor.animate(delta, Vector2(velocity.x, velocity.z).length(), not is_on_floor(), weapon.active)
    if position.y < -6.0 or not preload("res://scripts/neighborhood_layout.gd").in_bounds(position):
        position = safe_position + Vector3.UP * 0.2
        velocity = Vector3.ZERO
        receive_damage(15.0)
    if Vector2(velocity.x, velocity.z).length_squared() > 1 and not reported_movement:
        reported_movement = true
        print("DEADLIGHT_MOVE")
    var aim := Vector3.ZERO
    if is_instance_valid(controls) and controls.aiming:
        aim = screen_to_world(controls.aim)
        aim = _assist_aim(aim)
    elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and get_viewport().gui_get_hovered_control() == null:
        var camera := get_viewport().get_camera_3d()
        var mouse := get_viewport().get_mouse_position()
        var plane := Plane(Vector3.UP, global_position.y + 1.05)
        var intersection: Variant = plane.intersects_ray(camera.project_ray_origin(mouse), camera.project_ray_normal(mouse))
        if intersection != null:
            aim = intersection - global_position
            aim.y = 0.0
    weapon.direction = aim.normalized()
    weapon.active = aim.length_squared() > 0.05
    if weapon.active:
        visual.rotation.y = atan2(-aim.x, -aim.z)
    elif direction.length() > 0.1:
        visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-world_move.x, -world_move.z), delta * 12)
    body_material.emission_enabled = health.invulnerability > 0.0
    body_material.emission = Color(0.5, 0.12, 0.02)

func receive_damage(amount: float) -> void:
    if active:
        var before: float = health.current
        health.damage(amount, 0.8)
        if health.current < before:
            var nearest: Node3D
            var distance := 2.6
            for enemy in get_tree().get_nodes_in_group("enemies"):
                var candidate: float = enemy.global_position.distance_to(global_position)
                if candidate < distance:
                    distance = candidate
                    nearest = enemy
            if is_instance_valid(nearest):
                damage_push = (global_position - nearest.global_position).normalized() * 3.5

func set_mobile_direction(direction: Vector2) -> void:
    mobile_direction = direction

func request_jump() -> void:
    if active and jump_lock <= 0.0:
        jump_buffer = 0.12

func _assist_aim(direction: Vector3) -> Vector3:
    var best := 0.94
    var result := direction
    for enemy in get_tree().get_nodes_in_group("enemies"):
        var offset: Vector3 = enemy.global_position - global_position
        offset.y = 0
        if offset.length_squared() > 196 or offset.length_squared() < 0.1:
            continue
        var candidate := offset.normalized()
        var alignment := direction.dot(candidate)
        if alignment > best:
            var ray := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP, enemy.global_position + Vector3.UP, 1)
            if get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
                best = alignment
                result = candidate
    return direction.lerp(result, 0.65).normalized()

func screen_to_world(direction: Vector2) -> Vector3:
    var basis := get_viewport().get_camera_3d().global_basis
    var right := Vector3(basis.x.x, 0, basis.x.z).normalized()
    var back := Vector3(basis.z.x, 0, basis.z.z).normalized()
    return right * direction.x + back * direction.y

func _power_activated(_duration: float, major: bool) -> void:
    for child in get_children():
        if child.is_in_group("power_surges"):
            child.queue_free()
    var effect = preload("res://scripts/power_surge.gd").new()
    effect.major = major
    add_child(effect)
    Audio.play(self, "mission")
