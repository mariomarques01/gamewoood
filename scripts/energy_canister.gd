extends StaticBody3D
# Shoot twice; the visible fuse gives the player time to leave the blast radius.
signal detonated
const Kit = preload("res://scripts/visual_kit.gd")
const Burst = preload("res://scripts/energy_burst.gd")
const Audio = preload("res://scripts/audio_api.gd")
const RADIUS := 4.5
var health := 40.0
var armed := false
var spent := false
var fuse := 0.65
var warning: MeshInstance3D
var shell: MeshInstance3D

func _ready() -> void:
    add_to_group("explosives")
    collision_layer = 1 | 16
    collision_mask = 0
    var collision := CollisionShape3D.new()
    var shape := CylinderShape3D.new()
    shape.radius = 0.48
    shape.height = 1.45
    collision.shape = shape
    collision.position.y = 0.73
    add_child(collision)
    for part in [[0.73, 1.25, 0.44], [0.15, 0.16, 0.5], [1.35, 0.16, 0.5]]:
        var visual := MeshInstance3D.new()
        var mesh := CylinderMesh.new()
        mesh.top_radius = part[2]
        mesh.bottom_radius = part[2]
        mesh.height = part[1]
        mesh.radial_segments = 12
        visual.mesh = mesh
        visual.material_override = Kit.material(Color(0.94, 0.28, 0.055) if shell == null else Color(0.07, 0.12, 0.18))
        visual.position.y = part[0]
        add_child(visual)
        if shell == null:
            shell = visual
    for angle in [0.0, PI * 0.5, PI, PI * 1.5]:
        var cell := Kit.box(self, Vector3(sin(angle) * 0.44, 0.73, cos(angle) * 0.44), Vector3(0.17, 0.65, 0.07), Kit.material(Color(0.1, 0.8, 1), true))
        cell.rotation.y = angle
    var hazard := Kit.box(self, Vector3(0, 1.55, 0), Vector3(0.36, 0.36, 0.12), Kit.material(Color(1, 0.8, 0.1), true))
    hazard.rotation.z = PI / 4
    warning = MeshInstance3D.new()
    var ring := TorusMesh.new()
    ring.inner_radius = RADIUS - 0.1
    ring.outer_radius = RADIUS
    ring.rings = 32
    ring.ring_segments = 6
    warning.mesh = ring
    warning.material_override = Kit.material(Color(1, 0.23, 0.08), true)
    warning.position.y = 0.07
    add_child(warning)
    warning.hide()

func receive_damage(amount: float) -> void:
    if spent or armed or amount <= 0:
        return
    health -= amount
    if health <= 0:
        armed = true
        warning.show()
        print("DEADLIGHT_CANISTER_ARMED")

func _physics_process(delta: float) -> void:
    if not armed or spent:
        return
    fuse -= delta
    shell.scale.x = 1 + sin(fuse * 40) * 0.06
    warning.visible = sin(fuse * 35) > -0.5
    if fuse <= 0:
        _detonate()

func _detonate() -> void:
    if spent:
        return
    spent = true
    remove_from_group("explosives")
    # Resolve line of sight before removing physics; never damage through walls.
    var targets := get_tree().get_nodes_in_group("enemies") + get_tree().get_nodes_in_group("explosives") + get_tree().get_nodes_in_group("player")
    var origin := global_position + Vector3.UP * 0.8
    for target in targets:
        if not is_instance_valid(target):
            continue
        var point: Vector3 = target.global_position + Vector3.UP * 0.8
        var distance := origin.distance_to(point)
        if distance > RADIUS:
            continue
        var query := PhysicsRayQueryParameters3D.create(origin, point, 1)
        query.exclude = [get_rid(), target.get_rid()]
        if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():
            continue
        target.receive_damage(20.0 if target.is_in_group("player") else 75.0 * (1 - 0.45 * distance / RADIUS))
    collision_layer = 0
    Burst.spawn(get_parent(), global_position)
    Audio.play(self, "explosion", global_position)
    var camera := get_viewport().get_camera_3d()
    if camera != null and camera.has_method("impact"):
        camera.impact(global_position)
    detonated.emit()
    print("DEADLIGHT_CANISTER_EXPLODED")
    queue_free()
