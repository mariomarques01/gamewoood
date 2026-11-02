extends Node3D
const Kit = preload("res://scripts/visual_kit.gd")

const SIZE := 58.0
const BLUE := Color(0.12, 0.35, 0.62)
const ASPHALT := Color(0.17, 0.20, 0.25)
const CONCRETE := Color(0.47, 0.51, 0.56)
const GOLD := Color(1.0, 0.68, 0.12)
const GREEN := Color(0.18, 0.86, 0.36)
const objectives := [Vector3(-17, 0, -7), Vector3(17, 0, -9), Vector3(0, 0, -18)]
var materials: Dictionary = {}
var rock_mesh: SphereMesh
var objective_markers: Array[Node3D] = []

func _material(color: Color, glow: bool = false) -> StandardMaterial3D:
    if materials.has(color):
        return materials[color]
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.75
    if color == ASPHALT:
        var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
        var random := RandomNumberGenerator.new()
        random.seed = 412
        for y in range(32):
            for x in range(32):
                var grain := random.randf_range(0.9, 1.1)
                image.set_pixel(x, y, Color(grain, grain, grain, 1))
        mat.albedo_texture = ImageTexture.create_from_image(image)
        mat.uv1_scale = Vector3(16, 16, 1)
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
    var mesh: Mesh = Kit.bevel(size) if minf(minf(size.x, size.y), size.z) > 0.18 else _plain_box(size)
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
    # Caixas de suprimentos e vegetacao.
    for p in [Vector3(-19, 0.65, 5), Vector3(-16, 0.65, 8), Vector3(19, 0.65, 10), Vector3(22, 0.65, 8)]:
        _box(self, p, Vector3(1.4, 1.3, 1.4), Color(0.22, 0.47, 0.25), true)
    for p in [Vector3(-22, 0, 10), Vector3(22, 0, 1), Vector3(-21, 0, -10)]:
        _box(self, p + Vector3(0, 1, 0), Vector3(0.6, 2, 0.6), Color(0.42, 0.25, 0.12))
        _sphere(p + Vector3(0, 2.3, 0), Vector3(2.3, 1.9, 2.3), Color(0.14, 0.42, 0.23))
        _sphere(p + Vector3(0, 3.3, 0), Vector3(1.6, 1.4, 1.8), Color(0.19, 0.5, 0.25))
    for i in range(3):
        var marker := Node3D.new()
        add_child(marker)
        marker.position = objectives[i]
        var ring := MeshInstance3D.new()
        var ring_mesh := TorusMesh.new()
        ring_mesh.inner_radius = 1.45
        ring_mesh.outer_radius = 1.58
        ring_mesh.rings = 24
        ring_mesh.ring_segments = 6
        ring.mesh = ring_mesh
        ring.material_override = Kit.material(GREEN, true)
        ring.position.y = 0.1
        marker.add_child(ring)
        var beacon := Kit.box(marker, Vector3(0, 1.75, 0), Vector3(0.4, 0.4, 0.18), Kit.material(GREEN, true))
        beacon.rotation.z = PI / 4
        objective_markers.append(marker)

    _details()
    _reference_pass()
    _architecture_pass()
    preload("res://scripts/base_set_dressing.gd").build(self)
    _batch_static_meshes()

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
    settings.ambient_light_energy = 0.42
    environment.environment = settings
    add_child(environment)

func _sphere(pos: Vector3, dimensions: Vector3, color: Color) -> void:
    var visual := MeshInstance3D.new()
    if rock_mesh == null:
        rock_mesh = SphereMesh.new()
        rock_mesh.radial_segments = 8
        rock_mesh.rings = 3
    visual.mesh = rock_mesh
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

# First art pass toward the supplied coastal-base concept, using reusable geometry.
func _reference_pass() -> void:
    var dark_blue := Color(0.07, 0.18, 0.3)
    var warm := Color(1, 0.72, 0.27)
    for x in [-5.9, -1.5, 1.5, 5.9]:
        _box(self, Vector3(x, 3.0, 0.65), Vector3(0.3, 6, 0.3), dark_blue)
    _box(self, Vector3(0, 3.15, 0.7), Vector3(12.2, 0.28, 0.4), BLUE)
    _box(self, Vector3(0, 0.12, 1.0), Vector3(4.5, 0.22, 1.0), CONCRETE)
    for x in [-1.25, 1.25]:
        _box(self, Vector3(x, 1.5, 0.7), Vector3(0.15, 2.6, 0.15), Color(0.08, 0.8, 1))
    # Rooftop helipad and parapet from the reference; the playable objective stays on the ground.
    var ring := MeshInstance3D.new()
    var torus := TorusMesh.new()
    torus.inner_radius = 2.65
    torus.outer_radius = 2.88
    torus.rings = 24
    torus.ring_segments = 8
    ring.mesh = torus
    ring.material_override = _material(GOLD)
    ring.position = Vector3(0, 6.59, -4)
    add_child(ring)
    for x in [-1.1, 1.1]:
        _box(self, Vector3(x, 6.6, -4), Vector3(0.35, 0.06, 2.7), Color(0.9, 0.92, 0.85))
    _box(self, Vector3(0, 6.6, -4), Vector3(2.3, 0.06, 0.35), Color(0.9, 0.92, 0.85))
    for x in [-6.1, 6.1]:
        _box(self, Vector3(x, 6.7, -4), Vector3(0.2, 0.5, 9.8), CONCRETE)
        for z in [-8.2, 0.2]:
            _box(self, Vector3(x, 7.1, z), Vector3(0.3, 0.35, 0.3), Color(1, 0.2, 0.08))
    for x in [-4.6, 4.6]:
        _box(self, Vector3(x, 6.95, -6.8), Vector3(1.3, 0.8, 1.3), CONCRETE)
        for z in [-7.1, -6.8, -6.5]:
            _box(self, Vector3(x, 7.37, z), Vector3(0.9, 0.04, 0.09), dark_blue)
    # Arsenal roller door and original military crate hardware.
    for y in [0.6, 1.1, 1.6, 2.1]:
        _box(self, Vector3(-18, y, -10.96), Vector3(3, 0.35, 0.08), dark_blue)
    for p in [Vector3(-19, 0.65, 5), Vector3(-16, 0.65, 8), Vector3(19, 0.65, 10), Vector3(22, 0.65, 8)]:
        for x in [-0.5, 0.5]:
            _box(self, p + Vector3(x, 0, 0.72), Vector3(0.12, 1.25, 0.08), GOLD)
    # Lightweight lamps: emissive surfaces, without per-lamp real-time shadows.
    for x in [-8.2, 8.2]:
        for z in [4.0, 15.0]:
            _box(self, Vector3(x, 2.2, z), Vector3(0.15, 4.4, 0.15), dark_blue)
            var lamp := _box(self, Vector3(x, 4.4, z), Vector3(0.65, 0.25, 0.45), warm)
            var mesh := lamp.get_child(0) as MeshInstance3D
            var emission := StandardMaterial3D.new()
            emission.albedo_color = warm
            emission.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
            mesh.material_override = emission
    for p in [Vector3(-23, 0, -4), Vector3(23, 0, 13), Vector3(-23, 0, 13)]:
        _box(self, p + Vector3.UP, Vector3(0.35, 2, 0.35), Color(0.32, 0.2, 0.1))
        for y in [2.0, 2.8, 3.5]:
            _sphere(p + Vector3(0, y, 0), Vector3(2.8 - y * 0.4, 1.3, 2.8 - y * 0.4), Color(0.16, 0.38 + y * 0.035, 0.22))

func _plain_box(dimensions: Vector3) -> BoxMesh:
    var box := BoxMesh.new()
    box.size = dimensions
    return box

func _architecture_pass() -> void:
    var frame := Kit.material(Color(0.075, 0.17, 0.27))
    var stone := Kit.material(Color(0.37, 0.42, 0.46))
    var glass := Kit.material(Color(0.65, 0.38, 0.12), true)
    var neon := Kit.material(Color(0.08, 0.75, 1), true)
    # Recessed window surrounds and mullions cast real shadows across the facade.
    for x in [-4.4, -2.8, 2.8, 4.4]:
        for y in [2.0, 4.5]:
            Kit.box(self, Vector3(x, y, 0.63), Vector3(1.36, 1.55, 0.18), frame)
            Kit.box(self, Vector3(x, y, 0.74), Vector3(1.07, 1.26, 0.05), glass)
            Kit.box(self, Vector3(x, y, 0.8), Vector3(0.06, 1.3, 0.06), frame)
            Kit.box(self, Vector3(x, y - 0.8, 0.72), Vector3(1.5, 0.12, 0.4), stone)
    # Modular wall panels / cornices make the headquarters read as a building.
    for x in [-5.8, 5.8]:
        for z in [-7.4, -5.1, -2.8, -0.5]:
            Kit.box(self, Vector3(x * 1.045, 2.8, z), Vector3(0.35, 5.6, 0.2), stone)
    for y in [0.45, 3.1, 6.1]:
        Kit.box(self, Vector3(0, y, 0.7), Vector3(12.4, 0.18, 0.4), frame)
    Kit.box(self, Vector3(0, 3.62, 0.76), Vector3(5.8, 0.8, 0.3), frame)
    # Original winged shield emblem, aligned to the front of the headquarters.
    emblem(self, Vector3(0, 5.05, 0.84), neon)
    for x in [-1.75, 1.75]:
        Kit.box(self, Vector3(x, 1.5, 1.0), Vector3(0.32, 2.9, 0.6), frame)
        Kit.box(self, Vector3(x, 1.55, 1.32), Vector3(0.1, 2.15, 0.04), neon)
    # Perimeter columns and inset rails; all stay behind existing colliders.
    for x in [-25.9, 25.9]:
        for z in [-23.0, -17.0, -11.0, -5.0, 1.0, 7.0, 13.0, 19.0]:
            Kit.box(self, Vector3(x, 1.6, z), Vector3(1.6, 3.2, 0.5), stone)
            Kit.box(self, Vector3(x, 2.7, z + 2.7), Vector3(0.14, 0.14, 4.7), frame)
    # Watchtower cabins, tinted glazing and diagonal supports.
    for x in [-22.0, 22.0]:
        for z in [-22.0, 16.0]:
            Kit.box(self, Vector3(x, 5.55, z), Vector3(3, 1.0, 3), frame)
            Kit.box(self, Vector3(x, 5.6, z + 1.52), Vector3(2.5, 0.65, 0.06), glass)
            for side in [-1.0, 1.0]:
                Kit.beam(self, Vector3(x - 1.1, 0.5, z + side * 1.18), Vector3(x + 1.1, 4.6, z + side * 1.18), 0.16, stone)
    # Workshop canopy, service bay, vented walls and two fuel cylinders.
    Kit.box(self, Vector3(13, 2.8, -13.25), Vector3(7, 0.4, 2), frame)
    Kit.box(self, Vector3(13, 1.3, -13.43), Vector3(4, 2.3, 0.08), Kit.material(Color(0.09, 0.14, 0.19)))
    for x in [10.3, 15.7]:
        Kit.box(self, Vector3(x, 1.3, -13.3), Vector3(0.16, 2.3, 0.12), glass)
    for x in [17.8, 19.0]:
        var mesh := CylinderMesh.new()
        mesh.top_radius = 0.42
        mesh.bottom_radius = 0.42
        mesh.height = 1.5
        mesh.radial_segments = 12
        var barrel := MeshInstance3D.new()
        barrel.mesh = mesh
        barrel.material_override = frame
        barrel.position = Vector3(x, 0.75, -21.8)
        add_child(barrel)
    # Road-side safety markings and small stones at the edge of the island.
    for x in [-6.3, 6.3]:
        for z in range(7, 19, 2):
            Kit.box(self, Vector3(x, 0.035, z), Vector3(0.17, 0.03, 0.8), Kit.material(GOLD))
    for index in range(14):
        var angle := index * TAU / 14
        _sphere(Vector3(cos(angle) * 30, -1.5, sin(angle) * 30), Vector3(4, 3, 3), Color(0.29 + (index % 3) * 0.025, 0.27, 0.26))

func emblem(parent: Node3D, pos: Vector3, mat: Material) -> void:
    var badge := Kit.box(parent, pos, Vector3(1.0, 0.9, 0.16), mat)
    badge.rotation.z = PI / 4
    for sign_value in [-1.0, 1.0]:
        for row in range(3):
            Kit.box(parent, pos + Vector3(sign_value * 1.05, 0.27 - row * 0.23, 0), Vector3(1.2 - row * 0.2, 0.14, 0.13), mat)

func _batch_static_meshes() -> void:
    # Batch repeated static art; keep physics bodies and independently visible objectives.
    var groups: Dictionary = {}
    for node in find_children("*", "MeshInstance3D", true, false):
        var mesh := node as MeshInstance3D
        var is_marker := false
        for marker in objective_markers:
            if marker.is_ancestor_of(mesh):
                is_marker = true
                break
        if is_marker or mesh.material_override == null:
            continue
        var key := str(mesh.mesh.get_rid()) + str(mesh.material_override.get_rid())
        if not groups.has(key):
            groups[key] = []
        groups[key].append(mesh)
    for group in groups.values():
        if group.size() < 3:
            continue
        var instances := MultiMesh.new()
        instances.transform_format = MultiMesh.TRANSFORM_3D
        instances.mesh = group[0].mesh
        instances.instance_count = group.size()
        var batch := MultiMeshInstance3D.new()
        batch.multimesh = instances
        batch.material_override = group[0].material_override
        add_child(batch)
        for index in range(group.size()):
            instances.set_instance_transform(index, global_transform.affine_inverse() * group[index].global_transform)
            group[index].hide()
            group[index].queue_free()
