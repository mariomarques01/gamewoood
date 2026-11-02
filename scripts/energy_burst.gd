extends Node3D
const Kit = preload("res://scripts/visual_kit.gd")
const MAX_EFFECTS := 6
var age := 0.0
var flash: MeshInstance3D
var wave: MeshInstance3D
var smoke: Array[MeshInstance3D] = []

static func spawn(parent: Node3D, point: Vector3) -> void:
    var effects := parent.get_tree().get_nodes_in_group("energy_fx")
    if effects.size() >= MAX_EFFECTS:
        effects[0].free()
    var effect = load("res://scripts/energy_burst.gd").new()
    parent.add_child(effect)
    effect.global_position = point

func _ready() -> void:
    add_to_group("energy_fx")
    flash = Kit.sphere(self, Vector3.UP * 0.7, Vector3.ONE, Kit.material(Color(1, 0.65, 0.13), true))
    wave = MeshInstance3D.new()
    var mesh := TorusMesh.new()
    mesh.inner_radius = 0.9
    mesh.outer_radius = 1.0
    mesh.rings = 24
    mesh.ring_segments = 6
    wave.mesh = mesh
    wave.material_override = Kit.material(Color(0.2, 0.9, 1), true)
    wave.position.y = 0.08
    add_child(wave)
    for index in range(4):
        var angle := index * TAU / 4
        smoke.append(Kit.sphere(self, Vector3(cos(angle), 0.6, sin(angle)) * 0.7, Vector3.ONE * 0.7, Kit.material(Color(0.19, 0.23, 0.27))))

func _physics_process(delta: float) -> void:
    age += delta
    flash.visible = age < 0.22
    flash.scale = Vector3.ONE * maxf(0.01, sin(minf(1, age / 0.22) * PI) * 2.5)
    wave.visible = age < 0.45
    wave.scale = Vector3.ONE * (0.4 + minf(1, age / 0.45) * 4.1)
    for index in range(smoke.size()):
        smoke[index].position.y += delta * (0.7 + index * 0.15)
        smoke[index].scale = Vector3.ONE * maxf(0.01, (1.2 - age) * (0.8 + age))
    if age >= 1.2:
        queue_free()
