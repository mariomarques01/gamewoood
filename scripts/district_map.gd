extends Node3D
const Kit = preload("res://scripts/visual_kit.gd")

const Layout = preload("res://scripts/neighborhood_layout.gd")
const SIZE := 148.0
const BLUE := Color(0.12, 0.35, 0.62)
const PAVEMENT := Color(0.48, 0.5, 0.49)
const ASPHALT := Color(0.17, 0.20, 0.25)
const CONCRETE := Color(0.47, 0.51, 0.56)
const GOLD := Color(1.0, 0.68, 0.12)
const GREEN := Color(0.18, 0.86, 0.36)
const objectives = Layout.OBJECTIVES
var materials: Dictionary = {}
var rock_mesh: SphereMesh
var objective_markers: Array[Node3D] = []
var ground_surfaces: Array[Dictionary] = []

func _material(color: Color, glow: bool = false) -> StandardMaterial3D:
    var key := str(color) + str(glow)
    if materials.has(key):
        return materials[key]
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.75
    if color == PAVEMENT:
        var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
        for y in range(64):
            for x in range(64):
                var grout := x < 2 or y < 2
                var shade := 0.65 if grout else 0.96
                image.set_pixel(x, y, Color(shade, shade, shade))
        image.generate_mipmaps()
        mat.albedo_texture = ImageTexture.create_from_image(image)
        mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
        mat.uv1_triplanar = true
        mat.uv1_world_triplanar = true
        mat.uv1_scale = Vector3.ONE * 0.65
    if glow:
        mat.emission_enabled = true
        mat.emission = color
        mat.emission_energy_multiplier = 1.4
    materials[key] = mat
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
    if pos.y <= 0.2 and size.y <= 1.0:
        visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    root.add_child(visual)
    if size.y <= 0.25 and pos.y >= -0.1 and pos.y <= 0.2:
        var center := root.global_position
        ground_surfaces.append({"rect": Rect2(Vector2(center.x - size.x * 0.5, center.z - size.z * 0.5), Vector2(size.x, size.z)), "height": center.y + size.y * 0.5})
    if solid:
        var shape := CollisionShape3D.new()
        var box := BoxShape3D.new()
        box.size = size
        shape.shape = box
        root.add_child(shape)
    return root

func build() -> void:
    preload("res://scripts/expanded_neighborhood.gd").build(self)
    _batch_static_meshes()
    for point in Layout.CANISTERS:
        var canister = preload("res://scripts/energy_canister.gd").new()
        add_child(canister)
        canister.position = point

func _plain_box(dimensions: Vector3) -> BoxMesh:
    var box := BoxMesh.new()
    box.size = dimensions
    return box

func _sphere(pos: Vector3, dimensions: Vector3, color: Color) -> void:
    var visual := MeshInstance3D.new()
    if rock_mesh == null:
        rock_mesh = SphereMesh.new()
        rock_mesh.radial_segments = 10
        rock_mesh.rings = 4
    visual.mesh = rock_mesh
    visual.material_override = _material(color)
    visual.scale = dimensions
    visual.position = pos
    add_child(visual)

func _sign(text: String, pos: Vector3, pixel_size: float) -> Label3D:
    var sign := Label3D.new()
    sign.text = text
    sign.font = preload("res://assets/fonts/LilitaOne-Regular.ttf")
    sign.font_size = 48
    sign.pixel_size = pixel_size
    sign.position = pos
    sign.outline_size = 10
    sign.modulate = Color(0.92, 0.96, 1)
    sign.no_depth_test = false
    add_child(sign)
    return sign

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
        # Keep batches local: a single district-wide AABB defeats frustum/light culling.
        var cell := Vector2i(floori(mesh.global_position.x / 16.0), floori(mesh.global_position.z / 16.0))
        var key := str(mesh.material_override.get_rid()) + ":" + str(cell) + ":" + str(mesh.cast_shadow)
        if not groups.has(key):
            groups[key] = []
        groups[key].append(mesh)
    for group in groups.values():
        if group.size() < 3:
            continue
        # Bake static vertices instead of issuing instanced draws on WebKit/Apple GPUs.
        # Unlike a district-wide MultiMesh, each mesh also has local visibility bounds.
        var tool := SurfaceTool.new()
        tool.begin(Mesh.PRIMITIVE_TRIANGLES)
        for source in group:
            var transform: Transform3D = global_transform.affine_inverse() * source.global_transform
            tool.append_from(source.mesh, 0, transform)
        var batch := MeshInstance3D.new()
        batch.name = "StaticRegion"
        batch.mesh = tool.commit()
        batch.material_override = group[0].material_override
        batch.cast_shadow = group[0].cast_shadow
        batch.add_to_group("static_regions")
        add_child(batch)
        for source in group:
            source.hide()
            source.queue_free()

func blood_surface_height(point: Vector3, fallback: float) -> float:
    var height := fallback
    for surface in ground_surfaces:
        if surface.rect.has_point(Vector2(point.x, point.z)):
            height = maxf(height, surface.height)
    return height
