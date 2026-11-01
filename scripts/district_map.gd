extends Node3D

const SIZE := 58.0
const BLUE := Color(0.12, 0.35, 0.62)
const ASPHALT := Color(0.17, 0.20, 0.25)
const CONCRETE := Color(0.47, 0.51, 0.56)
const GOLD := Color(1.0, 0.68, 0.12)
const GREEN := Color(0.18, 0.86, 0.36)
const objectives := [Vector3(-17, 0, -7), Vector3(17, 0, -9), Vector3(0, 0, -18)]
var materials: Dictionary = {}
var objective_markers: Array[Node3D] = []

func _material(color: Color, glow: bool = false) -> StandardMaterial3D:
    if materials.has(color):
        return materials[color]
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.75
    if glow:
        mat.emission_enabled = true
        mat.emission = color
        mat.emission_energy_multiplier = 1.4
    materials[color] = mat
    return mat

func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, solid: bool = false) -> Node3D:
    var root: Node3D
    if solid:
        root = StaticBody3D.new()
    else:
        root = Node3D.new()
    parent.add_child(root)
    root.position = pos
    var visual := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    visual.mesh = mesh
    visual.material_override = _material(color)
    root.add_child(visual)
    if solid:
        var shape := CollisionShape3D.new()
        var box := BoxShape3D.new()
        box.size = size
        shape.shape = box
        root.add_child(shape)
    return root

func build() -> void:
    # Area principal e acesso ao portao sul.
    _box(self, Vector3(0, -0.55, 0), Vector3(SIZE, 1, SIZE), Color(0.24, 0.32, 0.30), true)
    _box(self, Vector3(0, -0.04, 14), Vector3(12, 0.08, 27), ASPHALT)
    _box(self, Vector3(0, -0.03, -7), Vector3(42, 0.08, 16), ASPHALT)
    _box(self, Vector3(0, -0.03, 1), Vector3(12, 0.08, 26), ASPHALT)
    # Muros com passagem no portao sul.
    for z in [-26.0]:
        _box(self, Vector3(0, 1.2, z), Vector3(52, 2.4, 1.3), CONCRETE, true)
    for x in [-26.0, 26.0]:
        _box(self, Vector3(x, 1.2, 0), Vector3(1.3, 2.4, 52), CONCRETE, true)
    _box(self, Vector3(-17, 1.2, 20), Vector3(18, 2.4, 1.3), CONCRETE, true)
    _box(self, Vector3(17, 1.2, 20), Vector3(18, 2.4, 1.3), CONCRETE, true)
    for x in [-17.0, 17.0]:
        _box(self, Vector3(x, 1.2, 26), Vector3(18, 2.4, 1.3), CONCRETE, true)
    _box(self, Vector3(0, 0.45, 27.5), Vector3(15, 0.9, 0.6), GOLD, true)
    # Quartel central, duas alas e telhado azul.
    _box(self, Vector3(0, 3.1, -4), Vector3(12, 6.2, 9), CONCRETE, true)
    _box(self, Vector3(0, 6.3, -4), Vector3(13, 0.5, 10), BLUE)
    _box(self, Vector3(-11, 1.8, -17), Vector3(9, 3.6, 6), Color(0.38, 0.44, 0.50), true)
    _box(self, Vector3(-11, 3.8, -17), Vector3(10, 0.4, 7), BLUE)
    _box(self, Vector3(13, 2.2, -17), Vector3(9, 4.4, 7), Color(0.40, 0.46, 0.52), true)
    _box(self, Vector3(13, 4.6, -17), Vector3(10, 0.4, 8), BLUE)
    # Torres e luzes.
    for x in [-22.0, 22.0]:
        for z in [-22.0, 16.0]:
            _box(self, Vector3(x, 3, z), Vector3(2.2, 6, 2.2), Color(0.32, 0.38, 0.45), true)
            _box(self, Vector3(x, 6.2, z), Vector3(3.2, 0.6, 3.2), BLUE)
            _box(self, Vector3(x, 6.65, z), Vector3(0.6, 0.3, 0.6), GOLD)
    # Heliponto com marcas e heliponto de acesso.
    _box(self, Vector3(17, 0.05, -9), Vector3(10, 0.12, 10), ASPHALT)
    _box(self, Vector3(17, 0.13, -9), Vector3(7, 0.04, 0.6), GOLD)
    _box(self, Vector3(17, 0.14, -9), Vector3(0.6, 0.04, 6), GOLD)
    # Caixas de suprimentos e vegetacao.
    for p in [Vector3(-19, 0.65, 5), Vector3(-16, 0.65, 8), Vector3(19, 0.65, 10), Vector3(22, 0.65, 8)]:
        _box(self, p, Vector3(1.4, 1.3, 1.4), Color(0.22, 0.47, 0.25), true)
    for p in [Vector3(-22, 0, 10), Vector3(22, 0, 1), Vector3(-21, 0, -10)]:
        _box(self, p + Vector3(0, 1, 0), Vector3(0.6, 2, 0.6), Color(0.42, 0.25, 0.12))
        _box(self, p + Vector3(0, 2.5, 0), Vector3(2.7, 2.1, 2.7), Color(0.14, 0.48, 0.24))
    for i in range(3):
        var marker := Node3D.new()
        add_child(marker)
        marker.position = objectives[i]
        _box(marker, Vector3(0, 0.08, 0), Vector3(3.2, 0.15, 3.2), GREEN, false)
        _box(marker, Vector3(0, 2.0, 0), Vector3(0.28, 3.8, 0.28), GREEN, false)
        objective_markers.append(marker)

    _details()

func _details() -> void:
    var sea := Color(0.04, 0.27, 0.38)
    _box(self, Vector3(0, -4.5, 0), Vector3(180, 0.5, 180), sea)
    _box(self, Vector3(0, -2.1, 0), Vector3(61, 3.2, 61), Color(0.27, 0.25, 0.29))
    # Road paint and walkable pavement, with no overlapping physics floors.
    for z in range(9, 26, 4):
        _box(self, Vector3(0, 0.03, z), Vector3(0.18, 0.04, 1.7), GOLD)
    for x in [-7.0, 7.0]:
        _box(self, Vector3(x, 0.06, 11), Vector3(1.4, 0.15, 17), CONCRETE)
    for x in range(-4, 5):
        _box(self, Vector3(x, 0.04, 18), Vector3(0.55, 0.04, 2.3), Color(0.88, 0.87, 0.77))
    # Headquarters facade: orange windows, blue entrance and cyan strip lights.
    for x in [-4.4, -2.8, 2.8, 4.4]:
        for y in [2.0, 4.5]:
            _box(self, Vector3(x, y, 0.53), Vector3(1.1, 1.3, 0.08), Color(1, 0.68, 0.23))
    _box(self, Vector3(0, 1.3, 0.55), Vector3(2.1, 2.6, 0.1), BLUE)
    _box(self, Vector3(0, 2.9, 0.65), Vector3(5, 0.25, 0.3), Color(0.05, 0.85, 1))
    _sign("BASE DO CAPITAO", Vector3(0, 3.65, 0.65), 0.012)
    _sign("ARSENAL", Vector3(-17, 2.4, -9.5), 0.012)
    _sign("OFICINA", Vector3(13, 3.3, -13.4), 0.012)
    # An arsenal shelter behind its accessible interaction pad.
    _box(self, Vector3(-18, 1.6, -12.5), Vector3(7, 3.2, 3), CONCRETE, true)
    _box(self, Vector3(-18, 3.4, -12.5), Vector3(7.5, 0.35, 3.5), BLUE)
    for x in [-19.0, -17.0]:
        _box(self, Vector3(x, 0.6, -9.8), Vector3(1.3, 1.2, 1), Color(0.25, 0.43, 0.2), true)
    # Communications mast and radar, independent 3D geometry.
    _box(self, Vector3(0, 3.5, -23), Vector3(0.6, 7, 0.6), Color(0.7, 0.4, 0.15), true)
    for y in [2.0, 4.0, 6.0]:
        _box(self, Vector3(0, y, -23), Vector3(3, 0.15, 0.2), GOLD)
    _sphere(Vector3(0, 7.4, -23), Vector3(2.2, 2.2, 0.6), Color(0.75, 0.82, 0.87))
    _box(self, Vector3(0, 9, -23), Vector3(0.25, 0.25, 0.25), Color(1, 0.15, 0.08))
    # Helicopter parked beside the active helipad, leaving a walkable marker.
    var helicopter := Node3D.new()
    add_child(helicopter)
    helicopter.position = Vector3(20, 0, -10)
    _box(helicopter, Vector3(0, 1.3, 0), Vector3(1.5, 1.3, 3), Color(0.17, 0.28, 0.33), true)
    _box(helicopter, Vector3(0, 1.6, -1.2), Vector3(1.3, 0.7, 0.8), Color(0.1, 0.6, 0.85))
    _box(helicopter, Vector3(0, 1.3, 2.4), Vector3(0.35, 0.4, 2.7), Color(0.2, 0.3, 0.34))
    _box(helicopter, Vector3(0, 2.25, 0), Vector3(5, 0.12, 0.23), Color(0.08, 0.12, 0.17))
    _box(helicopter, Vector3(0, 2.25, 0), Vector3(0.23, 0.12, 5), Color(0.08, 0.12, 0.17))
    for x in [-0.85, 0.85]:
        _box(helicopter, Vector3(x, 0.35, 0), Vector3(0.15, 0.15, 3.5), Color(0.1, 0.13, 0.18))
    # H rather than a cross.
    for x in [14.5, 18.0]:
        _box(self, Vector3(x, 0.18, -8), Vector3(0.4, 0.04, 4), GOLD)
    for x in [-28.0, 28.0]:
        for z in [-24.0, -15.0, -4.0, 8.0, 20.0]:
            _sphere(Vector3(x, -0.5, z), Vector3(5, 5, 6), Color(0.31, 0.29, 0.32))
    var environment := WorldEnvironment.new()
    var settings := Environment.new()
    settings.background_mode = Environment.BG_COLOR
    settings.background_color = Color(0.12, 0.22, 0.33)
    settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    settings.ambient_light_color = Color(0.6, 0.72, 0.9)
    settings.ambient_light_energy = 0.6
    environment.environment = settings
    add_child(environment)

func _sphere(pos: Vector3, dimensions: Vector3, color: Color) -> void:
    var visual := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radial_segments = 8
    sphere.rings = 3
    visual.mesh = sphere
    visual.material_override = _material(color)
    visual.scale = dimensions
    visual.position = pos
    add_child(visual)

func _sign(text: String, pos: Vector3, pixel_size: float) -> void:
    var sign := Label3D.new()
    sign.text = text
    sign.font_size = 32
    sign.pixel_size = pixel_size
    sign.position = pos
    sign.no_depth_test = false
    add_child(sign)
