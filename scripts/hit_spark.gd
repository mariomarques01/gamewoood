extends Node3D
const MeshParticles = preload("res://scripts/mesh_particles.gd")
const Kit = preload("res://scripts/visual_kit.gd")
const MAX_EFFECTS := 12
var age := 0.0
var color := Color(0.15, 0.85, 1)
var normal := Vector3.UP
var batch: MeshParticles
var velocities: Array[Vector3] = []

static func spawn(parent: Node3D, point: Vector3, surface_normal: Vector3, alien: bool, purple: bool = false) -> void:
    var effects := parent.get_tree().get_nodes_in_group("hit_sparks")
    if effects.size() >= MAX_EFFECTS:
        effects[0].free()
    var effect = load("res://scripts/hit_spark.gd").new()
    effect.normal = surface_normal
    if alien:
        effect.color = Color(0.7, 0.2, 0.9) if purple else Color(0.5, 1, 0.15)
    parent.add_child(effect)
    effect.global_position = point

func _ready() -> void:
    add_to_group("hit_sparks")
    batch = MeshParticles.new()
    add_child(batch)
    batch.configure(Kit.bevel(Vector3(0.045, 0.045, 0.16)), 6, Kit.material(color, true))
    for index in range(6):
        var angle := index * TAU / 6
        velocities.append(normal * 1.3 + Vector3(cos(angle), 0.9, sin(angle)) * 2)

func _physics_process(delta: float) -> void:
    age += delta
    for index in range(6):
        var point := velocities[index] * age + Vector3.DOWN * age * age * 3
        var basis := Basis.from_euler(Vector3(index, age * 8, index * 2)).scaled(Vector3.ONE * maxf(0.01, 1 - age / 0.28))
        batch.set_instance_transform(index, Transform3D(basis, point))
    if age >= 0.28:
        queue_free()
