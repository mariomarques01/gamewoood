extends RefCounted
# Shared lightweight geometry; all bevels are real mesh surfaces, without CSG at runtime.
static var boxes: Dictionary = {}
static var sphere_mesh: SphereMesh
static var materials: Dictionary = {}

static func material(color: Color, emissive: bool = false) -> StandardMaterial3D:
    var key := str(color) + str(emissive)
    if materials.has(key):
        return materials[key]
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.72
    if emissive:
        mat.emission_enabled = true
        mat.emission = color
        mat.emission_energy_multiplier = 0.7
    materials[key] = mat
    return mat

static func _face(tool: SurfaceTool, points: Array[Vector3]) -> void:
    var normal := (points[1] - points[0]).cross(points[2] - points[0]).normalized()
    var center := Vector3.ZERO
    for point in points:
        center += point
    if normal.dot(center) < 0:
        points.reverse()
        normal = -normal
    # Godot front faces use clockwise winding.
    for index in range(1, points.size() - 1):
        for vertex in [points[0], points[index + 1], points[index]]:
            tool.set_normal(normal)
            tool.set_uv(Vector2(vertex.x + vertex.z, vertex.y + vertex.z))
            tool.add_vertex(vertex)

static func bevel(dimensions: Vector3) -> ArrayMesh:
    if boxes.has(dimensions):
        return boxes[dimensions]
    var h := dimensions * 0.5
    var b := minf(minf(h.x, h.y), h.z) * 0.22
    b = minf(b, 0.14)
    var inner := h - Vector3.ONE * b
    var tool := SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    for axis in range(3):
        var u := (axis + 1) % 3
        var v := (axis + 2) % 3
        for sign_value in [-1.0, 1.0]:
            var points: Array[Vector3] = []
            for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
                var point := Vector3.ZERO
                point[axis] = h[axis] * sign_value
                point[u] = inner[u] * corner.x
                point[v] = inner[v] * corner.y
                points.append(point)
            _face(tool, points)
    for axis in range(3):
        var u := (axis + 1) % 3
        var v := (axis + 2) % 3
        for su in [-1.0, 1.0]:
            for sv in [-1.0, 1.0]:
                var points: Array[Vector3] = []
                for index in range(4):
                    var point := Vector3.ZERO
                    point[axis] = inner[axis] * (-1 if index < 2 else 1)
                    point[u] = (h[u] if index == 0 or index == 3 else inner[u]) * su
                    point[v] = (inner[v] if index == 0 or index == 3 else h[v]) * sv
                    points.append(point)
                _face(tool, points)
    for sx in [-1.0, 1.0]:
        for sy in [-1.0, 1.0]:
            for sz in [-1.0, 1.0]:
                var points: Array[Vector3] = []
                for axis in range(3):
                    var point := inner
                    point[axis] = h[axis]
                    points.append(point * Vector3(sx, sy, sz))
                _face(tool, points)
    var mesh := tool.commit()
    boxes[dimensions] = mesh
    return mesh

static func box(parent: Node3D, pos: Vector3, dimensions: Vector3, mat: Material) -> MeshInstance3D:
    var visual := MeshInstance3D.new()
    visual.mesh = bevel(dimensions)
    visual.material_override = mat
    visual.position = pos
    parent.add_child(visual)
    return visual

static func sphere(parent: Node3D, pos: Vector3, dimensions: Vector3, mat: Material) -> MeshInstance3D:
    if sphere_mesh == null:
        sphere_mesh = SphereMesh.new()
        sphere_mesh.radial_segments = 16
        sphere_mesh.rings = 8
    var visual := MeshInstance3D.new()
    visual.mesh = sphere_mesh
    visual.scale = dimensions
    visual.position = pos
    visual.material_override = mat
    parent.add_child(visual)
    return visual

static func beam(parent: Node3D, start: Vector3, finish: Vector3, width: float, mat: Material) -> void:
    var part := box(parent, (start + finish) * 0.5, Vector3(width, width, start.distance_to(finish)), mat)
    part.look_at_from_position(part.global_position, parent.to_global(finish), Vector3.UP)
