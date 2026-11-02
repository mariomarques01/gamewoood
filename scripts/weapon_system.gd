extends Node
const Audio = preload("res://scripts/audio_api.gd")
signal ammo_changed(remaining: int, reloading: bool)
const Projectile = preload("res://scripts/projectile.gd")
var cooldown := 0.0
var reload_time := 0.0
var ammo := 24
var overdrive_time := 0.0
var direction := Vector3.ZERO
var active := false
var reported_fire := false
var owner_body: CharacterBody3D
var shot_material: StandardMaterial3D

func _ready() -> void:
    owner_body = get_parent()
    shot_material = StandardMaterial3D.new()
    shot_material.albedo_color = Color(1, 0.8, 0.15)
    shot_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

func _physics_process(delta: float) -> void:
    overdrive_time = maxf(0, overdrive_time - delta)
    cooldown = maxf(0.0, cooldown - delta)
    if reload_time > 0.0:
        reload_time -= delta
        if reload_time <= 0.0:
            ammo = 24
            ammo_changed.emit(ammo, false)
        return
    if not active or direction.length_squared() < 0.1 or cooldown > 0.0:
        return
    if not reported_fire:
        reported_fire = true
        print("DEADLIGHT_FIRE")
    var shot = Projectile.new()
    shot.direction = direction.normalized()
    shot.damage = 37.5 if overdrive_time > 0 else 25.0
    shot.shooter = owner_body
    shot.material = shot_material
    owner_body.get_parent().add_child(shot)
    shot.global_position = owner_body.global_position + Vector3.UP * 1.05 + shot.direction * 0.75
    owner_body.actor.fire()
    Audio.play(self, "shot", owner_body.global_position)
    cooldown = 0.12 if overdrive_time > 0 else 0.16
    ammo -= 1
    if ammo == 0:
        reload_time = 1.2
        Audio.play(self, "reload", owner_body.global_position)
    ammo_changed.emit(ammo, reload_time > 0.0)

func resupply() -> void:
    ammo = 24
    reload_time = 0.0
    ammo_changed.emit(ammo, false)
