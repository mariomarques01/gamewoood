extends Node3D
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
    var color := Color(0.18, 0.9, 0.5) if kind == "health" else Color(1, 0.7, 0.1)
    Kit.box(visual, Vector3.ZERO, Vector3(0.65, 0.5, 0.5), Kit.material(Color(0.06, 0.18, 0.22)))
    if kind == "health":
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
    elif distance < 2.8:
        global_position += Vector3(offset.x, 0, offset.z).normalized() * delta * 3
    if lifetime <= 0:
        queue_free()

func collect() -> void:
    if taken or not player.active:
        return
    if kind == "health" and player.health.current >= player.health.maximum:
        return
    taken = true
    if kind == "health":
        player.health.heal(20)
    else:
        player.weapon.resupply()
    collected.emit(kind)
    queue_free()
