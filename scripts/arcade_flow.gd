extends Node
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

func _physics_process(delta: float) -> void:
    chain_time = maxf(0, chain_time - delta)
    if chain_time == 0:
        chain = 0

func register_kill(position: Vector3) -> void:
    total_kills += 1
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
        player.weapon.overdrive_time = 4.0
        chain = 0
        notice.emit("TRANCO TOTAL! 4s")
    elif chain >= 2 and total_kills != 12:
        notice.emit("SEQUENCIA x%d" % chain)
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
            notice.emit("TRANCO TOTAL! 4s")
        else:
            notice.emit("+20 VIDA" if type == "health" else "MUNICAO REPOSTA"))
    return supply

func mission_completed(current: int) -> void:
    if current <= last_mission:
        return
    last_mission = current
    var names := ["ARSENAL LIBERADO", "HELIPONTO ATIVADO", "COMUNICACAO ONLINE"]
    notice.emit(names[mini(current - 1, 2)])
    if current < 3:
        player.health.heal(15)
        player.weapon.resupply()
