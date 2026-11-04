extends Node3D
const MeshParticles = preload("res://scripts/mesh_particles.gd")
# A short burst follows the Captain; no lights or expensive screen post-processing.
var major := true
var age := 0.0
var ring: MeshInstance3D
var sparks: MeshParticles
var material: StandardMaterial3D

func _ready() -> void:
    add_to_group("power_surges")
    material = StandardMaterial3D.new()
    material.albedo_color = Color(1, 0.7, 0.12) if major else Color(0.1, 0.85, 1)
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    ring = MeshInstance3D.new()
    var mesh := TorusMesh.new()
    mesh.inner_radius = 0.86
    mesh.outer_radius = 1.0
    mesh.rings = 32
    mesh.ring_segments = 6
    ring.mesh = mesh
    ring.material_override = material
    ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    ring.position.y = 0.14
    add_child(ring)
    sparks = MeshParticles.new()
    var spark := SphereMesh.new()
    spark.radial_segments = 8
    spark.rings = 4
    spark.radius = 0.09
    spark.height = 0.5
    add_child(sparks)
    sparks.configure(spark, 16, material)
    _process(0)

func _process(delta: float) -> void:
    age += delta
    var phase := clampf(age / 1.15, 0, 1)
    ring.scale = Vector3.ONE * (0.4 + phase * (3.2 if major else 2.2))
    material.albedo_color.a = 1.0 - phase
    for index in range(16):
        var angle := index * TAU / 16 + age * 2
        var radius := 0.65 + phase * 1.5
        var point := Vector3(cos(angle) * radius, 0.25 + phase * (1.5 + (index % 3) * 0.5), sin(angle) * radius)
        sparks.set_instance_transform(index, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * (1 - phase * 0.75)), point))
    if age >= 1.15:
        queue_free()
