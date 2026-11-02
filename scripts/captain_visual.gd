extends Node3D
const Kit = preload("res://scripts/visual_kit.gd")
var legs: Array[Node3D] = []
var arms: Array[Node3D] = []
var chest: MeshInstance3D
var muzzle: MeshInstance3D
var phase := 0.0
var recoil := 0.0

func _ready() -> void:
    var navy := Kit.material(Color(0.07, 0.2, 0.37))
    var orange := StandardMaterial3D.new()
    orange.albedo_color = Color(0.95, 0.32, 0.055)
    orange.roughness = 0.7
    var dark := Kit.material(Color(0.065, 0.085, 0.12))
    var skin := Kit.material(Color(0.84, 0.57, 0.35))
    var trim := Kit.material(Color(0.33, 0.4, 0.46))
    var cyan := Kit.material(Color(0.06, 0.8, 0.95), true)
    Kit.sphere(self, Vector3(0, 1.0, 0), Vector3(0.74, 0.9, 0.5), navy)
    chest = Kit.box(self, Vector3(0, 1.04, -0.06), Vector3(0.78, 0.66, 0.5), orange)
    for x in [-0.23, 0.23]:
        Kit.box(self, Vector3(x, 0.93, -0.34), Vector3(0.23, 0.25, 0.12), dark)
    Kit.box(self, Vector3(0, 0.72, 0), Vector3(0.7, 0.13, 0.5), dark)
    Kit.box(self, Vector3(0, 0.72, -0.28), Vector3(0.17, 0.13, 0.08), trim)
    Kit.sphere(self, Vector3(0, 1.62, 0), Vector3(0.57, 0.65, 0.55), skin)
    Kit.box(self, Vector3(0, 1.82, 0.02), Vector3(0.61, 0.18, 0.55), navy)
    Kit.box(self, Vector3(0, 1.72, -0.27), Vector3(0.56, 0.16, 0.09), dark)
    Kit.box(self, Vector3(0, 1.73, -0.33), Vector3(0.45, 0.08, 0.04), cyan)
    Kit.box(self, Vector3(0, 1.49, -0.27), Vector3(0.25, 0.05, 0.06), dark)
    Kit.box(self, Vector3(0, 1.04, 0.36), Vector3(0.54, 0.61, 0.27), navy)
    for x in [-0.24, 0.24]:
        var leg := Node3D.new()
        leg.position = Vector3(x, 0.67, 0)
        add_child(leg)
        legs.append(leg)
        Kit.sphere(leg, Vector3(0, -0.2, 0), Vector3(0.32, 0.61, 0.34), navy)
        Kit.box(leg, Vector3(0, -0.38, -0.12), Vector3(0.34, 0.24, 0.19), trim)
        Kit.box(leg, Vector3(0, -0.52, -0.1), Vector3(0.42, 0.28, 0.64), dark)
        var arm := Node3D.new()
        arm.position = Vector3(signf(x) * 0.48, 1.25, 0)
        add_child(arm)
        arms.append(arm)
        Kit.sphere(arm, Vector3(0, -0.12, 0), Vector3(0.32, 0.5, 0.32), navy)
        Kit.box(arm, Vector3(0, -0.01, 0), Vector3(0.36, 0.24, 0.4), orange)
        Kit.sphere(arm, Vector3(0, -0.37, -0.08), Vector3(0.28, 0.3, 0.29), skin)
    Kit.box(self, Vector3(0.4, 1.03, -0.68), Vector3(0.3, 0.32, 0.9), trim)
    Kit.box(self, Vector3(0.4, 1.04, -0.85), Vector3(0.23, 0.18, 0.85), dark)
    Kit.box(self, Vector3(0.4, 1.18, -0.68), Vector3(0.12, 0.07, 0.6), cyan)
    muzzle = Kit.box(self, Vector3(0.4, 1.04, -1.3), Vector3(0.3, 0.26, 0.16), cyan)

func animate(delta: float, speed: float, airborne: bool, firing: bool) -> void:
    phase += delta * (10 if speed > 0.2 else 2)
    var stride := minf(speed / 6.0, 1.0) * 0.55
    for index in range(2):
        legs[index].rotation.x = -0.5 if airborne else sin(phase + index * PI) * stride
        arms[index].rotation.x = -0.85 if firing else sin(phase + (1 - index) * PI) * stride * 0.6
    chest.position.y = 1.04 + absf(sin(phase)) * stride * 0.045
    recoil = maxf(0, recoil - delta * 7)
    muzzle.scale = Vector3.ONE * (1 + recoil * 0.8)

func fire() -> void:
    recoil = 1.0
