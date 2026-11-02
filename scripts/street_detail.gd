extends RefCounted
const Kit = preload("res://scripts/visual_kit.gd")
const CROSSING_Z := 12.0

static func build(root: Node3D) -> void:
    var red := Kit.material(Color(0.62, 0.17, 0.12))
    var cream := Kit.material(Color(0.79, 0.73, 0.59))
    var iron := Kit.material(Color(0.11, 0.15, 0.17))
    var yellow := Kit.material(Color(0.98, 0.68, 0.15))
    # Warm tiled sidewalks and painted curbs frame the central combat lane.
    for side in [-1.0, 1.0]:
        for row in range(14):
            var z := 5.5 + row * 1.0
            for column in range(3):
                var tint := Color(0.48, 0.43, 0.36).lightened(((row + column) % 3) * 0.035)
                Kit.box(root, Vector3(side * (7.1 + column * 0.95), 0.005, z), Vector3(0.91, 0.07, 0.96), Kit.material(tint))
            # The only crossing aligns with both sidewalks; its curb is lowered.
            var crossing_access := absf(z - CROSSING_Z) < 1.0
            Kit.box(root, Vector3(side * 6.53, 0.015 if crossing_access else 0.055, z), Vector3(0.22, 0.04 if crossing_access else 0.12, 0.98), cream if crossing_access else (red if row % 4 != 3 else cream))
        Kit.box(root, Vector3(side * 6.3, 0.015, CROSSING_Z), Vector3(0.5, 0.06, 1.95), cream)
        # Drain covers: narrow metal slots, flush with the asphalt.
        for z in [8.5, 15.5]:
            Kit.box(root, Vector3(side * 5.7, 0.022, z), Vector3(0.6, 0.025, 0.9), iron)
            for slot in range(5):
                Kit.box(root, Vector3(side * 5.7, 0.04, z - 0.3 + slot * 0.15), Vector3(0.48, 0.02, 0.045), cream)
        # Boundary bollards stay off the playable street and mission approaches.
        for z in [6.0, 11.0, 17.0]:
            var x: float = side * 10.2
            Kit.box(root, Vector3(x, 0.45, z), Vector3(0.16, 0.9, 0.16), red)
            Kit.box(root, Vector3(x, 0.7, z), Vector3(0.19, 0.16, 0.19), yellow)
    # One crossing at z=12 connects paved sidewalks across the north-south road.
    # Leave the centerline clear of the crossing instead of stacking road paint.
    for z in [8.0, 15.0, 18.5]:
        Kit.box(root, Vector3(0, 0.028, z), Vector3(0.12, 0.02, 1.5), yellow)
    for index in range(9):
        Kit.box(root, Vector3(-5.6 + index * 1.4, 0.03, CROSSING_Z), Vector3(0.75, 0.025, 1.9), cream)
    # Manhole rings with radial grooves, no texture downloads or dynamic lights.
    for point in [Vector3(-3, 0.04, 9), Vector3(3, 0.04, 6)]:
        var cover := MeshInstance3D.new()
        var cylinder := CylinderMesh.new()
        cylinder.top_radius = 0.55
        cylinder.bottom_radius = 0.55
        cylinder.height = 0.035
        cylinder.radial_segments = 20
        cover.mesh = cylinder
        cover.material_override = iron
        cover.position = point
        root.add_child(cover)
        for offset in [-0.25, 0.0, 0.25]:
            Kit.box(root, point + Vector3(offset, 0.025, 0), Vector3(0.045, 0.02, 0.7), cream)
