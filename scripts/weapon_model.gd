extends Node3D
const Kit = preload("res://scripts/visual_kit.gd")
var weapon_index := 1
var muzzle: MeshInstance3D
var flash: MeshInstance3D
func _ready() -> void:
    var steel := Kit.material(Color(0.38, 0.46, 0.53))
    var dark := Kit.material(Color(0.045, 0.08, 0.12))
    var accent := Kit.material(Color(1, 0.7, 0.15) if weapon_index == 0 else Color(0.07, 0.8, 1), true)
    position = Vector3(0.32, 1.04, -0.45)
    var length := 0.55 if weapon_index == 0 else 0.95
    Kit.box(self, Vector3(0, 0, -length * 0.5), Vector3(0.27, 0.25, length), steel)
    Kit.box(self, Vector3(0, -0.19, -0.12), Vector3(0.19, 0.32, 0.2), dark)
    Kit.box(self, Vector3(0, 0.14, -length * 0.5), Vector3(0.13, 0.07, length * 0.7), accent)
    if weapon_index == 1:
        Kit.box(self, Vector3(0, -0.24, -0.48), Vector3(0.22, 0.38, 0.29), dark)
        Kit.box(self, Vector3(0, 0, 0.2), Vector3(0.32, 0.29, 0.26), dark)
        for z in [-0.35, -0.5, -0.65]:
            Kit.box(self, Vector3(0.145, 0, z), Vector3(0.035, 0.12, 0.055), dark)
    muzzle = Kit.box(self, Vector3(0, 0, -length), Vector3(0.24, 0.23, 0.14), accent)
    flash = Kit.sphere(self, Vector3(0, 0, -length - 0.17), Vector3(0.35, 0.35, 0.6), accent)
    flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    flash.hide()
