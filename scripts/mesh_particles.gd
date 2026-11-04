extends Node3D
# Small, bounded effects use ordinary meshes to avoid WebGL instancing state.
var instance_count: int:
    get:
        return items.size()
var items: Array[MeshInstance3D] = []
var source_material: StandardMaterial3D
var color_materials: Dictionary = {}

func configure(mesh: Mesh, count: int, material: StandardMaterial3D) -> void:
    source_material = material
    for index in range(count):
        var item := MeshInstance3D.new()
        item.mesh = mesh
        item.material_override = material
        item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        add_child(item)
        items.append(item)

func set_instance_transform(index: int, value: Transform3D) -> void:
    if not value.origin.is_finite() or not value.basis.x.is_finite() or not value.basis.y.is_finite() or not value.basis.z.is_finite():
        return
    items[index].transform = value

func set_instance_color(index: int, color: Color) -> void:
    if not color_materials.has(color):
        var material: StandardMaterial3D = source_material.duplicate()
        material.vertex_color_use_as_albedo = false
        material.albedo_color = color
        color_materials[color] = material
    items[index].material_override = color_materials[color]
