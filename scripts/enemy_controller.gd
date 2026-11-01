extends CharacterBody3D
signal eliminated
const Health = preload("res://scripts/health_component.gd")
const Projectile = preload("res://scripts/projectile.gd")
var player: CharacterBody3D
var ranged := false
var health: Node
var attack_timer := 0.0
var hurt_timer := 0.0
var visual: Node3D
var body_material: StandardMaterial3D
var plasma_material: StandardMaterial3D
var dead := false
var speed := 2.8

func _ready() -> void:
    add_to_group("enemies")
    collision_layer = 2
    collision_mask = 1 | 4
    health = Health.new()
    health.maximum = 50.0 if ranged else 35.0
    health.current = health.maximum
    add_child(health)
    health.died.connect(_die)
    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.48
    capsule.height = 1.5
    collision.shape = capsule
    collision.position.y = 0.75
    add_child(collision)
    visual = Node3D.new()
    add_child(visual)
    body_material = StandardMaterial3D.new()
    body_material.albedo_color = Color(0.65, 0.24, 0.85) if ranged else Color(0.25, 0.9, 0.3)
    var body := MeshInstance3D.new()
    var mesh := CapsuleMesh.new()
    mesh.radius = 0.48
    mesh.height = 1.5
    mesh.radial_segments = 8
    mesh.rings = 2
    body.mesh = mesh
    body.material_override = body_material
    body.position.y = 0.75
    visual.add_child(body)
    var eye_material := StandardMaterial3D.new()
    eye_material.albedo_color = Color(0.025, 0.04, 0.07)
    for x in [-0.2, 0.2]:
        var eye := MeshInstance3D.new()
        var eye_mesh := SphereMesh.new()
        eye_mesh.radius = 0.14
        eye_mesh.height = 0.32
        eye.mesh = eye_mesh
        eye.material_override = eye_material
        eye.position = Vector3(x, 1.05, -0.4)
        visual.add_child(eye)
    plasma_material = StandardMaterial3D.new()
    plasma_material.albedo_color = Color(1, 0.15, 0.85)
    plasma_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

func _physics_process(delta: float) -> void:
    if dead or not is_instance_valid(player) or not player.active:
        return
    attack_timer -= delta
    hurt_timer = maxf(0.0, hurt_timer - delta)
    body_material.emission_enabled = hurt_timer > 0.0
    body_material.emission = Color(0.8, 0.2, 0.15)
    var toward: Vector3 = player.global_position - global_position
    toward.y = 0.0
    var distance := toward.length()
    if distance > 38.0:
        return
    var desired := toward.normalized()
    if distance > (8.0 if ranged else 1.15):
        # Local obstacle avoidance: evaluate both sides of a blocked heading.
        # At prototype scale this avoids baking and runtime navigation overhead.
        if test_move(global_transform, desired * 1.3):
            var found := false
            for angle in [PI / 4, -PI / 4, PI / 2, -PI / 2, PI * 0.75, -PI * 0.75]:
                var alternate := desired.rotated(Vector3.UP, angle)
                if not test_move(global_transform, alternate * 1.3):
                    desired = alternate
                    found = true
                    break
            if not found:
                desired = Vector3.ZERO
        velocity = desired * (2.0 if ranged else speed)
        move_and_slide()
    if distance > 0.1:
        visual.rotation.y = atan2(-toward.x, -toward.z)
    if attack_timer <= 0.0:
        if ranged and distance < 13.0:
            attack_timer = 1.8
            _shoot(toward.normalized())
        elif not ranged and distance < 1.5:
            attack_timer = 0.8
            player.receive_damage(10.0)

func _shoot(direction: Vector3) -> void:
    var shot = Projectile.new()
    shot.direction = direction
    shot.speed = 10.0
    shot.damage = 12.0
    shot.hostile = true
    shot.shooter = self
    shot.material = plasma_material
    get_parent().add_child(shot)
    shot.global_position = global_position + Vector3.UP * 1.05 + direction * 0.8

func receive_damage(amount: float) -> void:
    if dead:
        return
    hurt_timer = 0.12
    health.damage(amount)

func _die() -> void:
    dead = true
    remove_from_group("enemies")
    collision_layer = 0
    collision_mask = 0
    eliminated.emit()
    var tween := create_tween()
    tween.tween_property(visual, "scale", Vector3(1.4, 0.05, 1.4), 0.18)
    tween.tween_callback(queue_free)
