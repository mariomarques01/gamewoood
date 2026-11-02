extends CharacterBody3D
const Audio = preload("res://scripts/audio_api.gd")
signal eliminated
const CombatEffect = preload("res://scripts/combat_effect.gd")
const AlienVisual = preload("res://scripts/alien_visual.gd")
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
var speed := 2.5
var winding_up := false
var windup := 0.0
var warning_ring: MeshInstance3D

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
    visual = AlienVisual.new()
    visual.ranged = ranged
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
                player.receive_damage(8.0)
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
    if dead:
        return
    hurt_timer = 0.12
    if amount > 0:
        winding_up = false
        warning_ring.hide()
        attack_timer = maxf(attack_timer, 0.3)
        var away := global_position - player.global_position
        away.y = 0
        velocity = away.normalized() * 2.0
    health.damage(amount)

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
