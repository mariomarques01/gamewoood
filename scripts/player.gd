extends CharacterBody3D
const Health = preload("res://scripts/health_component.gd")
const Weapon = preload("res://scripts/weapon_system.gd")
@export var move_speed: float = 6.0
@export var acceleration: float = 20.0
var mobile_direction := Vector2.ZERO
var controls: Control
var health: Node
var weapon: Node
var active := true
var reported_movement := false
var visual: Node3D
var body_material: StandardMaterial3D

func _ready() -> void:
    collision_layer = 4
    collision_mask = 1 | 2
    health = Health.new()
    add_child(health)
    weapon = Weapon.new()
    add_child(weapon)
    visual = $Visual
    $Visual/MeshInstance3D.hide()
    body_material = _material(Color(1, 0.36, 0.08))
    _part(Vector3(0, 1.0, 0), Vector3(0.75, 0.72, 0.45), body_material)
    var blue := _material(Color(0.08, 0.24, 0.55))
    _part(Vector3(0, 0.6, 0), Vector3(0.5, 0.35, 0.4), blue)
    for x in [-0.24, 0.24]:
        _part(Vector3(x, 0.22, -0.05), Vector3(0.35, 0.4, 0.6), _material(Color(0.07, 0.1, 0.16)))
        _part(Vector3(x * 2, 1.0, 0), Vector3(0.23, 0.55, 0.28), blue)
    _part(Vector3(0, 1.57, 0), Vector3(0.48, 0.45, 0.46), _material(Color(0.9, 0.65, 0.42)))
    _part(Vector3(0, 1.64, -0.25), Vector3(0.5, 0.14, 0.06), _material(Color(0.05, 0.85, 1)))
    _part(Vector3(0.35, 1.05, -0.6), Vector3(0.25, 0.28, 1.0), _material(Color(0.16, 0.2, 0.28)))
    _part(Vector3(0.35, 1.05, -1.1), Vector3(0.21, 0.18, 0.16), _material(Color(0.05, 0.9, 1)))

func _material(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    return material

func _part(pos: Vector3, dimensions: Vector3, material: Material) -> void:
    var mesh := BoxMesh.new()
    mesh.size = dimensions
    var part := MeshInstance3D.new()
    part.mesh = mesh
    part.material_override = material
    part.position = pos
    visual.add_child(part)

func _physics_process(delta: float) -> void:
    if not active:
        velocity = Vector3.ZERO
        weapon.active = false
        return
    var direction := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    if is_instance_valid(controls):
        mobile_direction = controls.movement
    if mobile_direction.length() > 0.05:
        direction = mobile_direction.limit_length()
    var target := Vector3(direction.x, 0.0, direction.y) * move_speed
    velocity.x = move_toward(velocity.x, target.x, acceleration * delta)
    velocity.z = move_toward(velocity.z, target.z, acceleration * delta)
    velocity.y = -1.0
    move_and_slide()
    if velocity.length_squared() > 1 and not reported_movement:
        reported_movement = true
        print("DEADLIGHT_MOVE")
    var aim := Vector3.ZERO
    if is_instance_valid(controls) and controls.aiming:
        aim = Vector3(controls.aim.x, 0, controls.aim.y)
    elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
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
        visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-direction.x, -direction.y), delta * 12)
    body_material.emission_enabled = health.invulnerability > 0.0
    body_material.emission = Color(0.5, 0.12, 0.02)

func receive_damage(amount: float) -> void:
    if active:
        health.damage(amount, 0.5)

func set_mobile_direction(direction: Vector2) -> void:
    mobile_direction = direction
