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
var pooled := false
var in_use := true
var visual: MeshInstance3D
var trail: MeshInstance3D
static var tracer_mesh: BoxMesh
static var point_mesh: SphereMesh

func _ready() -> void:
    visual = MeshInstance3D.new()
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
    trail = MeshInstance3D.new()
    trail.mesh = tracer_mesh
    trail.material_override = material
    trail.rotation.y = atan2(-direction.x, -direction.z)
    trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(trail)
    if empowered:
        visual.scale = Vector3.ONE * 1.8
        trail.scale = Vector3(2.5, 2.5, 1.8)
    if pooled:
        release()
    else:
        add_to_group("projectiles")

static func fire(world: Node3D, point: Vector3, heading: Vector3, source: CollisionObject3D, shot_material: Material, amount: float, enemy: bool = false, power: bool = false) -> Node3D:
    var shot = preload("res://scripts/combat_pool.gd").ensure(world).acquire("projectile")
    if shot == null:
        return null
    shot.direction = heading.normalized()
    shot.speed = 10.0 if enemy else 24.0
    shot.damage = amount
    shot.hostile = enemy
    shot.empowered = power
    shot.shooter = source
    shot.material = shot_material
    shot.life = 1.8
    shot.global_position = point
    shot.visual.material_override = shot_material
    shot.trail.material_override = shot_material
    shot.visual.scale = Vector3.ONE * (1.8 if power else 1.0)
    shot.trail.scale = Vector3(2.5, 2.5, 1.8) if power else Vector3.ONE
    shot.trail.rotation.y = atan2(-shot.direction.x, -shot.direction.z)
    shot.in_use = true
    shot.show()
    shot.set_physics_process(true)
    shot.add_to_group("projectiles")
    return shot

func release() -> void:
    if not pooled:
        queue_free()
        return
    in_use = false
    hide()
    set_physics_process(false)
    remove_from_group("projectiles")
    shooter = null
    material = null
    visual.material_override = null
    trail.material_override = null

func _physics_process(delta: float) -> void:
    if not in_use:
        return
    life -= delta
    if life <= 0.0:
        release()
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
        release()
    else:
        global_position = destination
