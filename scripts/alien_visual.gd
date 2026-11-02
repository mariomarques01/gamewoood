extends Node3D
const Kit = preload("res://scripts/visual_kit.gd")
var ranged := false
var skin: StandardMaterial3D
var feet: Array[MeshInstance3D] = []
var phase := 0.0

func _ready() -> void:
    skin = StandardMaterial3D.new()
    skin.albedo_color = Color(0.55, 0.19, 0.7) if ranged else Color(0.27, 0.73, 0.17)
    skin.roughness = 0.65
    var dark := Kit.material(Color(0.055, 0.07, 0.11))
    var eye := Kit.material(Color(0.9, 1, 0.47), true)
    var armor := Kit.material(Color(0.2, 0.15, 0.3))
    Kit.sphere(self, Vector3(0, 0.65, 0), Vector3(0.8, 0.82, 0.65), skin)
    Kit.sphere(self, Vector3(0, 1.15, -0.06), Vector3(0.91, 0.8, 0.79), skin)
    for x in [-0.23, 0.23]:
        Kit.sphere(self, Vector3(x, 1.19, -0.4), Vector3(0.3, 0.35, 0.13), dark)
        Kit.sphere(self, Vector3(x, 1.2, -0.47), Vector3(0.12, 0.19, 0.05), eye)
        var foot := Kit.box(self, Vector3(x, 0.14, -0.11), Vector3(0.34, 0.28, 0.5), armor if ranged else skin)
        feet.append(foot)
        Kit.sphere(self, Vector3(signf(x) * 0.49, 0.66, 0), Vector3(0.25, 0.63, 0.27), skin)
    Kit.box(self, Vector3(0, 0.96, -0.42), Vector3(0.24, 0.06, 0.07), dark)
    if ranged:
        Kit.box(self, Vector3(0, 0.77, -0.29), Vector3(0.65, 0.48, 0.21), armor)
        Kit.box(self, Vector3(0.48, 0.8, -0.4), Vector3(0.25, 0.25, 0.8), armor)
        Kit.box(self, Vector3(0.48, 0.8, -0.83), Vector3(0.18, 0.18, 0.09), Kit.material(Color(1, 0.15, 0.6), true))
    else:
        for x in [-0.3, 0.3]:
            Kit.box(self, Vector3(x, 1.6, 0.02), Vector3(0.08, 0.38, 0.08), skin)
            Kit.sphere(self, Vector3(x, 1.81, 0.02), Vector3(0.19, 0.19, 0.19), eye)

func animate(delta: float, moving: bool) -> void:
    phase += delta * 11
    for index in range(2):
        feet[index].position.z = -0.11 + (sin(phase + index * PI) * 0.13 if moving else 0.0)
    position.y = absf(sin(phase)) * 0.035 if moving else 0.0
