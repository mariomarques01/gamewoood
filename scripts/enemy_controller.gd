extends CharacterBody3D
const Audio = preload("res://scripts/audio_api.gd")
signal eliminated
const CombatEffect = preload("res://scripts/combat_effect.gd")
const AlienVisual = preload("res://scripts/alien_visual.gd")
const Health = preload("res://scripts/health_component.gd")
const Projectile = preload("res://scripts/projectile.gd")
var player: CharacterBody3D
var ranged := false
var archetype := "grunt"
var health: Node
var attack_timer := 0.0
var hurt_timer := 0.0
var visual: Node3D
var body_material: StandardMaterial3D
var plasma_material: StandardMaterial3D
var dead := false
var speed := 2.5
var winding_up := false
var windup := 0.0
var warning_ring: MeshInstance3D
var knockback := Vector3.ZERO
var hit_bar: Node3D
var hit_fill: MeshInstance3D
var hit_time := 0.0

func _ready() -> void:
    add_to_group("enemies")
    collision_layer = 2
    collision_mask = 1 | 4
    health = Health.new()
    health.maximum = 50.0 if ranged else (100.0 if archetype == "brute" else (25.0 if archetype == "runner" else 35.0))
    speed = 1.7 if archetype == "brute" else (3.6 if archetype == "runner" else 2.5)
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
    visual = AlienVisual.new()
    visual.ranged = ranged
    visual.archetype = archetype
    add_child(visual)
    body_material = visual.skin
    warning_ring = MeshInstance3D.new()
    var ring := TorusMesh.new()
    ring.inner_radius = 0.65
    ring.outer_radius = 0.75
    ring.rings = 16
    ring.ring_segments = 6
    warning_ring.mesh = ring
    var warning := StandardMaterial3D.new()
    warning.albedo_color = Color(1, 0.24, 0.17)
    warning.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    warning_ring.material_override = warning
    warning_ring.position.y = 0.06
    add_child(warning_ring)
    warning_ring.hide()
    hit_bar = Node3D.new()
    hit_bar.position.y = 2.05
    add_child(hit_bar)
    var kit = preload("res://scripts/visual_kit.gd")
    kit.box(hit_bar, Vector3.ZERO, Vector3(0.94, 0.1, 0.12), kit.material(Color(0.04, 0.08, 0.1)))
    hit_fill = kit.box(hit_bar, Vector3(0, 0, 0.025), Vector3(0.86, 0.06, 0.13), kit.material(Color(1, 0.72, 0.16), true))
    hit_bar.hide()
    plasma_material = StandardMaterial3D.new()
    plasma_material.albedo_color = Color(1, 0.15, 0.85)
    plasma_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

func _physics_process(delta: float) -> void:
    if dead or not is_instance_valid(player) or not player.active:
        return
    attack_timer -= delta
    hurt_timer = maxf(0.0, hurt_timer - delta)
    hit_time = maxf(0, hit_time - delta)
    hit_bar.visible = hit_time > 0
    var camera := get_viewport().get_camera_3d()
    if camera != null and hit_bar.visible:
        hit_bar.global_rotation.y = camera.global_rotation.y
    body_material.emission_enabled = hurt_timer > 0.0
    body_material.emission = Color(0.8, 0.2, 0.15)
    var toward: Vector3 = player.global_position - global_position
    toward.y = 0.0
    var distance := toward.length()
    if distance > 38.0:
        return
    if knockback.length_squared() > 0.04:
        velocity = knockback
        move_and_slide()
        knockback = knockback.move_toward(Vector3.ZERO, delta * 24)
        visual.animate(delta, false)
        return
    visual.animate(delta, velocity.length_squared() > 0.1 and not winding_up)
    if winding_up:
        velocity = Vector3.ZERO
        windup -= delta
        warning_ring.scale = Vector3.ONE * (1 + maxf(0, windup) * 0.6)
        if windup <= 0:
            winding_up = false
            warning_ring.hide()
            attack_timer = 1.8 if ranged else 1.1
            if ranged and distance < 14:
                _shoot(toward.normalized())
            elif not ranged and distance < 1.7 and absf(player.global_position.y - global_position.y) < 1:
                player.receive_damage(14.0 if archetype == "brute" else 8.0)
        return
    var desired := toward.normalized()
    var separation := Vector3.ZERO
    for other in get_tree().get_nodes_in_group("enemies"):
        if other == self:
            continue
        var offset: Vector3 = global_position - other.global_position
        offset.y = 0
        if offset.length_squared() > 0.01 and offset.length_squared() < 1.3:
            separation += offset.normalized() * (1.15 - offset.length())
    desired = (desired + separation * 1.2).normalized()
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
    if attack_timer <= 0.0 and ((ranged and distance < 13.0) or (not ranged and distance < 1.6)):
        winding_up = true
        windup = 0.55 if ranged else 0.42
        warning_ring.show()

func _shoot(direction: Vector3) -> void:
    Audio.play(self, "plasma", global_position)
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
    if dead or amount <= 0:
        return
    hurt_timer = 0.12
    if amount > 0:
        winding_up = false
        warning_ring.hide()
        attack_timer = maxf(attack_timer, 0.3)
        if is_instance_valid(player):
            var away := global_position - player.global_position
            away.y = 0
            knockback = away.normalized() * 3.5
    health.damage(amount)
    if not dead:
        hit_time = 1.5
        hit_bar.show()
        hit_fill.scale.x = health.current / health.maximum
        hit_fill.position.x = -(1 - hit_fill.scale.x) * 0.43

func _die() -> void:
    dead = true
    warning_ring.hide()
    remove_from_group("enemies")
    collision_layer = 0
    collision_mask = 0
    eliminated.emit()
    Audio.play(self, "explosion", global_position)
    Audio.play(self, "splatter", global_position)
    CombatEffect.burst(get_parent(), global_position, ranged)
    visual.hide()
    queue_free()
