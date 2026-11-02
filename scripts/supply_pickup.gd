extends Node3D
const Audio = preload("res://scripts/audio_api.gd")
signal collected(kind: String)
const Kit = preload("res://scripts/visual_kit.gd")
var player: CharacterBody3D
var kind := "ammo"
var lifetime := 14.0
var age := 0.0
var visual: Node3D
var taken := false

func _ready() -> void:
    add_to_group("supplies")
    visual = Node3D.new()
    add_child(visual)
    if kind == "credit":
        var coin := MeshInstance3D.new()
        var mesh := CylinderMesh.new()
        mesh.top_radius = 0.32
        mesh.bottom_radius = 0.32
        mesh.height = 0.1
        mesh.radial_segments = 16
        coin.mesh = mesh
        coin.material_override = Kit.material(Color(1, 0.65, 0.1), true)
        coin.rotation.x = PI / 2
        visual.add_child(coin)
        Kit.box(visual, Vector3(0, 0, -0.065), Vector3(0.09, 0.37, 0.04), Kit.material(Color(1, 0.94, 0.5)))
        return
    var color := Color(0.18, 0.9, 0.5) if kind == "health" else Color(1, 0.7, 0.1)
    Kit.box(visual, Vector3.ZERO, Vector3(0.65, 0.5, 0.5), Kit.material(Color(0.06, 0.18, 0.22)))
    if kind == "boost":
        var bolt := Kit.box(visual, Vector3(0, 0, -0.29), Vector3(0.14, 0.4, 0.05), Kit.material(Color(0.1, 0.8, 1), true))
        bolt.rotation.z = -0.35
    elif kind == "health":
        Kit.box(visual, Vector3(0, 0, -0.27), Vector3(0.4, 0.13, 0.04), Kit.material(color, true))
        Kit.box(visual, Vector3(0, 0, -0.28), Vector3(0.13, 0.38, 0.04), Kit.material(color, true))
    else:
        for x in [-0.18, 0.0, 0.18]:
            Kit.box(visual, Vector3(x, 0, -0.27), Vector3(0.09, 0.35, 0.05), Kit.material(color, true))

func _physics_process(delta: float) -> void:
    if taken or not is_instance_valid(player) or not player.active:
        return
    age += delta
    lifetime -= delta
    visual.position.y = 0.55 + sin(age * 4) * 0.08
    visual.rotation.y += delta
    var offset: Vector3 = player.global_position - global_position
    var distance := Vector2(offset.x, offset.z).length()
    if distance < 1.35 and absf(offset.y) < 1.5:
        collect()
    elif distance < 2.8 and _path_clear():
        global_position += Vector3(offset.x, 0, offset.z).normalized() * delta * 3
    if lifetime <= 0:
        queue_free()

func collect() -> void:
    if taken or not player.active:
        return
    if not _path_clear():
        return
    if kind == "health" and player.health.current >= player.health.maximum:
        return
    taken = true
    Audio.play(self, "pickup")
    if kind == "health":
        player.health.heal(20)
    elif kind == "boost":
        player.weapon.overdrive_time = 4.0
    elif kind == "ammo":
        player.weapon.resupply()
    collected.emit(kind)
    queue_free()

func _path_clear() -> bool:
    var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.5, player.global_position + Vector3.UP * 0.5, 1)
    return get_world_3d().direct_space_state.intersect_ray(query).is_empty()
