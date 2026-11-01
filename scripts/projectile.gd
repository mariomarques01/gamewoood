extends Node3D
var direction := Vector3.FORWARD
var speed := 24.0
var damage := 25.0
var hostile := false
var life := 1.8
var shooter: CollisionObject3D
var material: Material

func _ready() -> void:
    var visual := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 0.16
    mesh.height = 0.32
    visual.mesh = mesh
    visual.material_override = material
    add_child(visual)
    add_to_group("projectiles")

func _physics_process(delta: float) -> void:
    life -= delta
    if life <= 0.0:
        queue_free()
        return
    var destination := global_position + direction * speed * delta
    var query := PhysicsRayQueryParameters3D.create(global_position, destination, 1 | (4 if hostile else 2))
    if is_instance_valid(shooter):
        query.exclude = [shooter.get_rid()]
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if not hit.is_empty():
        var target: Object = hit.collider
        if target.has_method("receive_damage"):
            target.receive_damage(damage)
        queue_free()
    else:
        global_position = destination
