extends Node
const Audio = preload("res://scripts/audio_api.gd")
const Projectile = preload("res://scripts/projectile.gd")
const WEAPONS := [preload("res://resources/weapons/pistol.tres"), preload("res://resources/weapons/machine_gun.tres")]
signal ammo_changed(remaining: int, reloading: bool)
signal weapon_changed(index: int)
var selected := 1
var magazines: Array[int] = [12, 24]
var reloads: Array[float] = [0.0, 0.0]
var ammo: int:
    get: return magazines[selected]
    set(value): magazines[selected] = clampi(value, 0, capacity)
var reload_time: float:
    get: return reloads[selected]
    set(value): reloads[selected] = maxf(0, value)
var capacity: int:
    get: return WEAPONS[selected].capacity
var cooldown := 0.0
var overdrive_time := 0.0
var direction := Vector3.ZERO
var active := false
var enabled := true
var reported_fire := false
var owner_body: CharacterBody3D
var shot_material: StandardMaterial3D
var materials: Array[StandardMaterial3D] = []
var random := RandomNumberGenerator.new()

func _ready() -> void:
    owner_body = get_parent()
    random.randomize()
    for definition in WEAPONS:
        var material := StandardMaterial3D.new()
        material.albedo_color = definition.tracer_color
        material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        materials.append(material)
    shot_material = materials[selected]

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo or not enabled or not owner_body.active:
        return
    match event.physical_keycode:
        KEY_1: select_weapon(0)
        KEY_2: select_weapon(1)
        KEY_Q: select_weapon(1 - selected)
        KEY_R: reload()

func select_weapon(index: int) -> bool:
    if index < 0 or index >= WEAPONS.size() or index == selected or not enabled or not owner_body.active or get_tree().paused:
        return false
    selected = index
    shot_material = materials[selected]
    cooldown = maxf(cooldown, 0.18)
    owner_body.actor.equip_weapon(selected)
    Audio.play(self, "ui")
    weapon_changed.emit(selected)
    ammo_changed.emit(ammo, reload_time > 0)
    print("DEADLIGHT_WEAPON %s" % ("pistol" if selected == 0 else "machine"))
    return true

func _physics_process(delta: float) -> void:
    if not enabled:
        return
    overdrive_time = maxf(0, overdrive_time - delta)
    cooldown = maxf(0, cooldown - delta)
    for index in range(WEAPONS.size()):
        if reloads[index] > 0:
            reloads[index] = maxf(0, reloads[index] - delta)
            if reloads[index] == 0:
                magazines[index] = WEAPONS[index].capacity
                if index == selected:
                    ammo_changed.emit(ammo, false)
    if reload_time > 0 or not active or direction.length_squared() < 0.1 or cooldown > 0:
        return
    if ammo == 0:
        reload()
        return
    if not reported_fire:
        reported_fire = true
        print("DEADLIGHT_FIRE")
    var definition = WEAPONS[selected]
    var shot = Projectile.new()
    shot.direction = direction.normalized().rotated(Vector3.UP, random.randf_range(-definition.spread, definition.spread))
    shot.damage = definition.damage * (1.5 if overdrive_time > 0 else 1.0)
    shot.shooter = owner_body
    shot.material = shot_material
    owner_body.get_parent().add_child(shot)
    shot.global_position = owner_body.global_position + Vector3.UP * 1.05 + shot.direction * 0.75
    owner_body.actor.fire()
    Audio.play(self, definition.sound, owner_body.global_position)
    cooldown = definition.interval * (0.75 if overdrive_time > 0 else 1.0)
    ammo -= 1
    if ammo == 0:
        reload()
    ammo_changed.emit(ammo, reload_time > 0)

func reload() -> void:
    if not enabled or ammo == capacity or reload_time > 0:
        return
    reload_time = WEAPONS[selected].reload_seconds
    Audio.play(self, "reload", owner_body.global_position)
    ammo_changed.emit(ammo, true)

func resupply(all_weapons: bool = false) -> void:
    for index in range(WEAPONS.size()):
        if index == selected or all_weapons:
            magazines[index] = WEAPONS[index].capacity
            reloads[index] = 0
    ammo_changed.emit(ammo, false)

func stop() -> void:
    enabled = false
    active = false
