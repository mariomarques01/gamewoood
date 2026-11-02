extends Node3D
const Audio = preload("res://scripts/audio_api.gd")
var direction := Vector3.FORWARD
var speed := 24.0
var damage := 25.0
var hostile := false
var empowered := false
var life := 1.8
var shooter: CollisionObject3D
var material: Material
static var tracer_mesh: BoxMesh
static var point_mesh: SphereMesh

func _ready() -> void:
    var visual := MeshInstance3D.new()
    if point_mesh == null:
        point_mesh = SphereMesh.new()
        point_mesh.radius = 0.1
        point_mesh.height = 0.2
        point_mesh.radial_segments = 8
        point_mesh.rings = 4
        tracer_mesh = BoxMesh.new()
        tracer_mesh.size = Vector3(0.055, 0.055, 0.65)
    visual.mesh = point_mesh
    visual.material_override = material
    visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(visual)
    var trail := MeshInstance3D.new()
    trail.mesh = tracer_mesh
    trail.material_override = material
    trail.rotation.y = atan2(-direction.x, -direction.z)
    trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(trail)
    if empowered:
        visual.scale = Vector3.ONE * 1.8
        trail.scale = Vector3(2.5, 2.5, 1.8)
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
        Audio.play(self, "impact", hit.position)
        var target: Object = hit.collider
        var alien: bool = target.is_in_group("enemies")
        preload("res://scripts/hit_spark.gd").spawn(get_parent(), hit.position, hit.normal, alien, target.ranged if alien else false)
        if target.has_method("receive_damage"):
            target.receive_damage(damage)
        queue_free()
    else:
        global_position = destination
