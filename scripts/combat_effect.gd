extends Node3D
const Kit = preload("res://scripts/visual_kit.gd")
const MAX_EFFECTS := 10
var alien_color := Color(0.2, 0.65, 0.08)
var age := 0.0
var fragments: MultiMeshInstance3D
var ring: MeshInstance3D
var stain: MeshInstance3D
var positions: Array[Vector3] = []
var velocities: Array[Vector3] = []

static func burst(parent: Node3D, point: Vector3, ranged: bool) -> Node3D:
    preload("res://scripts/blood_stain.gd").spread(parent, point, ranged)
    var active := parent.get_tree().get_nodes_in_group("combat_fx")
    if active.size() >= MAX_EFFECTS:
        active[0].free()
    var effect = load("res://scripts/combat_effect.gd").new()
    effect.alien_color = Color(0.43, 0.08, 0.53) if ranged else Color(0.15, 0.47, 0.035)
    parent.add_child(effect)
    effect.global_position = point
    return effect

func _ready() -> void:
    add_to_group("combat_fx")
    var random := RandomNumberGenerator.new()
    random.seed = get_instance_id()
    fragments = MultiMeshInstance3D.new()
    var batch := MultiMesh.new()
    batch.transform_format = MultiMesh.TRANSFORM_3D
    batch.mesh = Kit.bevel(Vector3(0.17, 0.16, 0.24))
    batch.use_colors = true
    batch.instance_count = 18
    fragments.multimesh = batch
    var spray_material := StandardMaterial3D.new()
    spray_material.vertex_color_use_as_albedo = true
    spray_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    fragments.material_override = spray_material
    add_child(fragments)
    for index in range(18):
        batch.set_instance_color(index, Color(0.6, 0.025, 0.055) if index < 12 else alien_color.lightened(0.18))
        positions.append(Vector3(0, 0.8, 0))
        var angle := random.randf() * TAU
        velocities.append(Vector3(cos(angle) * random.randf_range(2, 5), random.randf_range(2, 5), sin(angle) * random.randf_range(2, 5)))
    ring = MeshInstance3D.new()
    var torus := TorusMesh.new()
    torus.inner_radius = 0.85
    torus.outer_radius = 1.0
    torus.rings = 20
    torus.ring_segments = 6
    ring.mesh = torus
    ring.material_override = Kit.material(Color(1, 0.62, 0.12), true)
    ring.position.y = 0.06
    add_child(ring)
    # Irregular flat splat: stylized alien blood, without opaque rectangles or decals.
    stain = MeshInstance3D.new()
    var tool := SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    var points: Array[Vector3] = []
    for index in range(18):
        var angle := TAU * index / 18
        var radius := random.randf_range(0.15, 0.4)
        points.append(Vector3(cos(angle) * radius, 0.035, sin(angle) * radius))
    for index in range(18):
        for point in [Vector3(0, 0.035, 0), points[index], points[(index + 1) % 18]]:
            tool.set_normal(Vector3.UP)
            tool.add_vertex(point)
    stain.mesh = tool.commit()
    var blood := StandardMaterial3D.new()
    blood.albedo_color = Color(0.3, 0.025, 0.045)
    blood.roughness = 1
    blood.cull_mode = BaseMaterial3D.CULL_DISABLED
    stain.material_override = blood
    add_child(stain)

func _physics_process(delta: float) -> void:
    age += delta
    ring.visible = age < 0.35
    ring.scale = Vector3.ONE * (0.3 + age * 6)
    if age < 0.8:
        for index in range(positions.size()):
            velocities[index].y -= 13 * delta
            positions[index] += velocities[index] * delta
            if positions[index].y < 0.08:
                positions[index].y = 0.08
                velocities[index] *= 0.35
                velocities[index].y = absf(velocities[index].y)
            var basis := Basis.from_euler(Vector3(age * (index + 1), age * 4, 0)).scaled(Vector3.ONE * maxf(0.01, 1 - age))
            fragments.multimesh.set_instance_transform(index, Transform3D(basis, positions[index]))
    else:
        fragments.hide()
    if age > 6:
        stain.scale = Vector3.ONE * maxf(0.01, (8 - age) / 2)
    if age >= 8:
        queue_free()
