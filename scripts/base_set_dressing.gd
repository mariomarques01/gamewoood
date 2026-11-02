extends RefCounted
const Kit = preload("res://scripts/visual_kit.gd")

static func build(root: Node3D) -> void:
    var steel := Kit.material(Color(0.075, 0.13, 0.18))
    var blue := Kit.material(Color(0.1, 0.25, 0.37))
    var concrete := Kit.material(Color(0.48, 0.51, 0.51))
    var yellow := Kit.material(Color(0.95, 0.64, 0.1))
    var cyan := Kit.material(Color(0.05, 0.65, 0.9), true)
    var warm := Kit.material(Color(0.9, 0.58, 0.16), true)
    # Security gate at the existing southern boundary, outside mission routes.
    root._box(root, Vector3(0, 1.2, 26.8), Vector3(15, 2.4, 0.25), Color(0.1, 0.17, 0.22), true)
    for x in [-8.0, 8.0]:
        Kit.box(root, Vector3(x, 1.9, 26.0), Vector3(1.2, 3.8, 1.5), concrete)
        Kit.box(root, Vector3(x, 3.9, 26.0), Vector3(1.6, 0.28, 1.8), blue)
        Kit.box(root, Vector3(x, 2.0, 25.22), Vector3(0.18, 2.8, 0.06), cyan)
    for x in range(-7, 8):
        Kit.box(root, Vector3(x, 1.5, 26.59), Vector3(0.12, 2.5, 0.15), concrete)
    for y in [0.35, 2.7]:
        Kit.box(root, Vector3(0, y, 26.5), Vector3(15, 0.18, 0.2), steel)
    for x in [-5.5, 5.5]:
        Kit.box(root, Vector3(x, 0.55, 24.8), Vector3(3.3, 0.8, 0.65), concrete)
        for offset in [-0.9, 0.0, 0.9]:
            var stripe := Kit.box(root, Vector3(x + offset, 0.55, 24.44), Vector3(0.23, 0.72, 0.04), yellow)
            stripe.rotation.z = -0.4
    # Parked supply rover, with its own solid body and independent art pieces.
    var rover := Node3D.new()
    root.add_child(rover)
    rover.position = Vector3(18, 0, 15)
    root._box(rover, Vector3(0, 0.9, 0), Vector3(1.9, 1.5, 3.5), Color(0.14, 0.28, 0.24), true)
    Kit.box(rover, Vector3(0, 0.9, 0), Vector3(2.15, 0.5, 3.8), blue)
    Kit.box(rover, Vector3(0, 1.65, -0.25), Vector3(1.85, 1.2, 1.9), blue)
    Kit.box(rover, Vector3(0, 1.72, -1.22), Vector3(1.55, 0.66, 0.08), cyan)
    Kit.box(rover, Vector3(0, 2.27, -0.25), Vector3(2, 0.16, 2.15), steel)
    Kit.box(rover, Vector3(0, 1.22, -1.5), Vector3(1.9, 0.3, 0.8), blue)
    Kit.box(rover, Vector3(0, 0.67, -1.99), Vector3(2.3, 0.18, 0.23), steel)
    for x in [-0.72, 0.72]:
        Kit.box(rover, Vector3(x, 0.98, -1.98), Vector3(0.3, 0.26, 0.06), warm)
    for x in [-1.1, 1.1]:
        for z in [-1.15, 1.15]:
            var wheel := MeshInstance3D.new()
            var mesh := CylinderMesh.new()
            mesh.top_radius = 0.46
            mesh.bottom_radius = 0.46
            mesh.height = 0.3
            mesh.radial_segments = 12
            wheel.mesh = mesh
            wheel.material_override = steel
            wheel.position = Vector3(x, 0.46, z)
            wheel.rotation.z = PI * 0.5
            rover.add_child(wheel)
    for z in [0.6, 1.35]:
        Kit.box(rover, Vector3(0, 1.4, z), Vector3(1.4, 0.6, 0.55), Kit.material(Color(0.22, 0.42, 0.24)))
    # Side facade windows and service vents, visible under the diagonal camera.
    for z in [-6.5, -3.9, -1.3]:
        for y in [2.0, 4.5]:
            Kit.box(root, Vector3(6.14, y, z), Vector3(0.25, 1.5, 1.6), steel)
            Kit.box(root, Vector3(6.3, y, z), Vector3(0.06, 1.18, 1.32), warm)
            Kit.box(root, Vector3(6.36, y, z), Vector3(0.08, 1.22, 0.06), steel)
    for x in [-4.6, 4.6]:
        Kit.box(root, Vector3(x, 6.85, -0.9), Vector3(1.3, 0.6, 1.1), concrete)
        for offset in [-0.3, 0.0, 0.3]:
            Kit.box(root, Vector3(x + offset, 7.17, -0.9), Vector3(0.12, 0.04, 0.8), steel)
