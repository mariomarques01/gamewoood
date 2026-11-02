extends Node
const Audio = preload("res://scripts/audio_api.gd")
signal notice(text: String)
signal credits_changed(value: int)
signal elimination_feedback(chain: int)
var credits := 0
const Supply = preload("res://scripts/supply_pickup.gd")
var player: CharacterBody3D
var chain := 0
var chain_time := 0.0
var total_kills := 0
var last_mission := 0
const XP_PER_KILL := 10
const FRENZY_DURATION := 10.0
var xp := 0
var xp_required := 100
var frenzy_level := 0

func award_xp(amount: int) -> void:
    if amount <= 0 or not is_instance_valid(player) or not player.active:
        return
    xp = mini(xp + amount, xp_required)
    if xp >= xp_required and player.weapon.frenzy_time <= 0:
        xp = 0
        frenzy_level += 1
        xp_required = mini(100 + frenzy_level * 40, 300)
        player.weapon.activate_frenzy(FRENZY_DURATION)
        notice.emit("FÚRIA TRANCO! 10s • PODER MÁXIMO")
        print("DEADLIGHT_FRENZY level=%d" % frenzy_level)

func _physics_process(delta: float) -> void:
    if is_instance_valid(player) and player.active and xp >= xp_required and player.weapon.frenzy_time <= 0:
        award_xp(1)
    chain_time = maxf(0, chain_time - delta)
    if chain_time == 0:
        chain = 0

func register_kill(position: Vector3) -> void:
    if not is_instance_valid(player) or not player.active:
        return
    total_kills += 1
    award_xp(XP_PER_KILL)
    if total_kills == 12:
        credits += 25
        credits_changed.emit(credits)
        notice.emit("DESAFIO 12 ALIENS! +25 CREDITOS")
    chain += 1
    chain_time = 4.0
    elimination_feedback.emit(chain)
    if get_tree().get_nodes_in_group("supplies").size() < 12:
        spawn_supply(position + Vector3(0.45, 0, 0), "credit")
    if chain >= 5:
        chain = 0
        if player.weapon.frenzy_time <= 0:
            player.weapon.activate_overdrive()
            notice.emit("TRANCO TOTAL! 4s")
    if total_kills % 8 == 0 and get_tree().get_nodes_in_group("supplies").size() < 12:
        spawn_supply(position + Vector3(-0.5, 0, 0), "boost")
    if total_kills % 3 == 0 and get_tree().get_nodes_in_group("supplies").size() < 12:
        spawn_supply(position, "health" if player.health.current < 80 else "ammo")

func spawn_supply(position: Vector3, kind: String) -> Node3D:
    var supply = Supply.new()
    supply.player = player
    supply.kind = kind
    get_parent().add_child(supply)
    supply.global_position = Vector3(position.x, 0, position.z)
    supply.collected.connect(func(type: String):
        if type == "credit":
            credits += 5
            credits_changed.emit(credits)
        elif type == "boost":
            if player.weapon.frenzy_time <= 0:
                notice.emit("TRANCO TOTAL! 4s")
        else:
            notice.emit("+20 VIDA" if type == "health" else "MUNICAO REPOSTA"))
    return supply

func mission_completed(current: int) -> void:
    if current <= last_mission:
        return
    last_mission = current
    Audio.play(self, "mission")
    var names := ["ARSENAL LIBERADO", "HELIPONTO ATIVADO", "COMUNICACAO ONLINE"]
    notice.emit(names[mini(current - 1, 2)])
    if current < 3:
        player.health.heal(15)
        player.weapon.resupply(true)
