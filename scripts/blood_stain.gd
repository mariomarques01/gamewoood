extends MeshInstance3D
# A whole splatter is one draw call; retained separately from short-lived debris.
const MAX_STAINS := 32
const LIFETIME := 30.0
var age := 0.0

static func spread(parent: Node3D, point: Vector3, ranged: bool) -> void:
    var stains := parent.get_tree().get_nodes_in_group("blood_stains")
    if stains.size() >= MAX_STAINS:
        stains[0].free()
    var stain = load("res://scripts/blood_stain.gd").new()
    parent.add_child(stain)
    stain.global_position = Vector3(point.x, 0, point.z)
    stain.build(ranged)

func build(ranged: bool) -> void:
    add_to_group("blood_stains")
    cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    var random := RandomNumberGenerator.new()
    random.seed = get_instance_id()
    var tool := SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    var district_map = get_parent().get("district_map")
    var direction := random.randf_range(0, TAU)
    for patch in range(12):
        var angle := direction + random.randf_range(-1.2, 1.2)
        var distance := random.randf_range(0.3, 1.8) if patch > 0 else 0.0
        var center := Vector3(cos(angle) * distance, 0, sin(angle) * distance)
        var query := PhysicsRayQueryParameters3D.create(global_position + center + Vector3.UP * 0.8, global_position + center + Vector3.DOWN, 1)
        var ground := get_world_3d().direct_space_state.intersect_ray(query)
        if ground.is_empty() or ground.normal.y < 0.8:
            continue
        var height: float = ground.position.y
        if is_instance_valid(district_map):
            height = district_map.blood_surface_height(global_position + center, height)
        center.y = maxf(0.06, height + 0.02) + patch * 0.0002
        var radius := random.randf_range(0.035, 0.14) if patch > 0 else random.randf_range(0.35, 0.65)
        var points: Array[Vector3] = []
        for index in range(12):
            var theta := TAU * index / 12
            var length := radius * random.randf_range(0.65, 1.35)
            points.append(center + Vector3(cos(theta) * length, 0, sin(theta) * length * 0.7))
        var color := Color(0.32, 0.035, 0.12) if ranged else Color(0.52, 0.035, 0.055)
        color = color.lightened(random.randf_range(0, 0.09))
        for index in range(12):
            for vertex in [center, points[(index + 1) % 12], points[index]]:
                tool.set_color(color)
                tool.set_normal(Vector3.UP)
                tool.add_vertex(vertex)
    mesh = tool.commit()
    var material := StandardMaterial3D.new()
    material.vertex_color_use_as_albedo = true
    material.roughness = 0.65
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    material_override = material

func _physics_process(delta: float) -> void:
    age += delta
    if age > LIFETIME - 5:
        scale = Vector3.ONE * maxf(0.01, (LIFETIME - age) / 5)
    if age >= LIFETIME:
        queue_free()
