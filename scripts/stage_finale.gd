extends Node3D
const MeshParticles = preload("res://scripts/mesh_particles.gd")
const Kit = preload("res://scripts/visual_kit.gd")
var player: CharacterBody3D
var age := 0.0
var confetti: MeshParticles
var velocities: Array[Vector3] = []

func _ready() -> void:
    confetti = MeshParticles.new()
    var material := StandardMaterial3D.new()
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    add_child(confetti)
    confetti.configure(Kit.bevel(Vector3(0.1, 0.035, 0.18)), 40, material)
    var colors := [Color(1, 0.7, 0.12), Color(0.1, 0.85, 1), Color(0.3, 1, 0.55)]
    for index in range(40):
        var angle := index * TAU / 40
        velocities.append(Vector3(cos(angle) * (1.3 + index % 3 * 0.4), 3.5 + index % 4 * 0.3, sin(angle) * 2))
        confetti.set_instance_color(index, colors[index % 3])
    global_position = player.global_position

func _process(delta: float) -> void:
    if not is_instance_valid(player):
        queue_free()
        return
    age += delta
    player.actor.celebrate(age)
    var camera := get_viewport().get_camera_3d()
    var toward := camera.global_position - player.global_position
    player.visual.rotation.y = lerp_angle(player.visual.rotation.y, atan2(-toward.x, -toward.z), minf(1, delta * 3))
    if is_instance_valid(confetti):
        for index in range(40):
            var point := Vector3.UP + velocities[index] * age + Vector3.DOWN * age * age * 1.8
            var basis := Basis.from_euler(Vector3(age * (index % 3 + 1), age * 4, index)).scaled(Vector3.ONE * clampf((4 - age) / 0.7, 0.01, 1))
            confetti.set_instance_transform(index, Transform3D(basis, point))
        if age >= 4:
            confetti.queue_free()
