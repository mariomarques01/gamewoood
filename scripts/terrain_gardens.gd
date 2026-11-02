extends RefCounted
const Kit = preload("res://scripts/visual_kit.gd")
const TREES := [Vector3(-22, 0, 10), Vector3(22, 0, 1), Vector3(-21, 0, -10), Vector3(-23, 0, -4), Vector3(23, 0, 13), Vector3(-23, 0, 13)]
const HALF_SIZE := 1.25
const FENCE_OFFSET := 1.34

static func build(root: Node3D) -> void:
    var grass := Kit.material(Color(0.24, 0.39, 0.12))
    var fence := Kit.material(Color(0.79, 0.83, 0.76))
    var curb := Kit.material(Color(0.33, 0.37, 0.34))
    var random := RandomNumberGenerator.new()
    random.seed = 981
    var blades := MultiMesh.new()
    blades.transform_format = MultiMesh.TRANSFORM_3D
    blades.mesh = Kit.bevel(Vector3(0.05, 0.16, 0.08))
    blades.instance_count = TREES.size() * 24
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
        var plane := PlaneMesh.new()
        plane.size = Vector2.ONE * HALF_SIZE * 2
        lawn.mesh = plane
        lawn.material_override = grass
        lawn.position = tree + Vector3.UP * 0.035
        lawn.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        root.add_child(lawn)
        var bed := StaticBody3D.new()
        bed.name = "TreeFence"
        bed.add_to_group("tree_fences")
        bed.position = tree
        root.add_child(bed)
        # Four low fences leave the lawn confined to the tree's immediate surround.
        for axis in [0, 2]:
            for side in [-1.0, 1.0]:
                var center := Vector3(0, 0.25, 0)
                center[axis] = side * FENCE_OFFSET
                var dimensions := Vector3(2.82, 0.5, 0.1) if axis == 2 else Vector3(0.1, 0.5, 2.82)
                var collision := CollisionShape3D.new()
                var shape := BoxShape3D.new()
                shape.size = dimensions
                collision.shape = shape
                collision.position = center
                bed.add_child(collision)
                for y in [0.06, 0.19, 0.39]:
                    var rail := Vector3(2.82, 0.07, 0.08) if axis == 2 else Vector3(0.08, 0.07, 2.82)
                    Kit.box(bed, Vector3(center.x, y, center.z), rail, curb if y == 0.06 else fence)
                for index in range(5):
                    var post := center
                    post[2 if axis == 0 else 0] = -1.24 + index * 0.62
                    post.y = 0.27
                    Kit.box(bed, post, Vector3(0.08, 0.54, 0.08), fence)
        for index in range(24):
            var point: Vector3 = tree + Vector3(random.randf_range(-1.12, 1.12), 0.11, random.randf_range(-1.12, 1.12))
            var basis := Basis(Vector3.UP, random.randf() * TAU).scaled(Vector3.ONE * random.randf_range(0.7, 1.3))
            blades.set_instance_transform(slot, Transform3D(basis, point))
            slot += 1
