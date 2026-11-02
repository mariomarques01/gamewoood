extends RefCounted
const Kit = preload("res://scripts/visual_kit.gd")
const TREES := [Vector3(-22, 0, 10), Vector3(22, 0, 1), Vector3(-21, 0, -10), Vector3(-23, 0, -4), Vector3(23, 0, 13), Vector3(-23, 0, 13)]

static func build(root: Node3D) -> void:
    var grass := StandardMaterial3D.new()
    grass.albedo_color = Color(0.24, 0.39, 0.12)
    grass.roughness = 1.0
    grass.cull_mode = BaseMaterial3D.CULL_DISABLED
    var random := RandomNumberGenerator.new()
    random.seed = 981
    var blades := MultiMesh.new()
    blades.transform_format = MultiMesh.TRANSFORM_3D
    blades.mesh = Kit.bevel(Vector3(0.05, 0.16, 0.08))
    blades.instance_count = TREES.size() * 48
    var tufts := MultiMeshInstance3D.new()
    tufts.multimesh = blades
    tufts.material_override = Kit.material(Color(0.34, 0.5, 0.16))
    tufts.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    root.add_child(tufts)
    var slot := 0
    for tree in TREES:
        var lawn := MeshInstance3D.new()
        lawn.name = "TreeGrass"
        lawn.add_to_group("tree_grass")
        var surface := SurfaceTool.new()
        surface.begin(Mesh.PRIMITIVE_TRIANGLES)
        var ring: Array[Vector3] = []
        for index in range(32):
            var angle := index * TAU / 32
            var radius := 3.2 + sin(index * 1.7) * 0.22
            ring.append(Vector3(cos(angle) * radius, 0, sin(angle) * radius))
        for index in range(32):
            for point in [Vector3.ZERO, ring[index], ring[(index + 1) % 32]]:
                surface.set_normal(Vector3.UP)
                surface.add_vertex(point)
        lawn.mesh = surface.commit()
        lawn.material_override = grass
        lawn.position = tree + Vector3.UP * 0.035
        lawn.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        root.add_child(lawn)
        for index in range(48):
            var angle := random.randf() * TAU
            var radius := random.randf_range(0.4, 3.0)
            var point: Vector3 = tree + Vector3(cos(angle) * radius, 0.11, sin(angle) * radius)
            var basis := Basis(Vector3.UP, angle).scaled(Vector3.ONE * random.randf_range(0.7, 1.3))
            blades.set_instance_transform(slot, Transform3D(basis, point))
            slot += 1
