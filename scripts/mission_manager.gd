extends Node
signal updated
signal victory
const POSITIONS = preload("res://scripts/neighborhood_layout.gd").OBJECTIVES
const NAMES := ["ARSENAL", "HELIPONTO", "COMUNICAÇÃO"]
const TITLES := ["LIBERE O ARSENAL", "ATIVE O HELIPONTO", "RESTABELEÇA A COMUNICAÇÃO"]
const CAPTURE_RADIUS := 3.1
const CONTEST_RADIUS := 5.0
const CAPTURE_SECONDS := 3.0
var player: CharacterBody3D
var current := 0
var progress := 0.0
var active := true
var contested := false
var ui_timer := 0.0

func _physics_process(delta: float) -> void:
    if not active or current >= 3:
        return
    var nearby := player.global_position.distance_to(POSITIONS[current]) < CAPTURE_RADIUS
    contested = false
    if nearby:
        for enemy in get_tree().get_nodes_in_group("enemies"):
            if enemy.global_position.distance_to(POSITIONS[current]) < CONTEST_RADIUS:
                contested = true
                break
    if nearby and not contested:
        progress = minf(1.0, progress + delta / CAPTURE_SECONDS)
        if progress >= 1.0:
            current += 1
            progress = 0.0
            updated.emit()
            if current == 3:
                active = false
                victory.emit()
                return
    ui_timer -= delta
    if ui_timer <= 0.0:
        ui_timer = 0.1
        updated.emit()

func guidance() -> Dictionary:
    if current >= NAMES.size() or not active:
        return {"kind": "complete", "nearby": false, "status": "3/3 MISSÕES CONCLUÍDAS", "instruction": "BASE SEGURA"}
    var distance := player.global_position.distance_to(POSITIONS[current])
    var nearby := distance < CAPTURE_RADIUS
    if nearby and contested:
        return {"kind": "contested", "nearby": true, "status": "ÁREA CONTESTADA • CAPTURA BLOQUEADA", "instruction": "Elimine os inimigos próximos para continuar."}
    if nearby:
        return {"kind": "capturing", "nearby": true, "status": "CAPTURANDO %d%% • FALTAM %.1fs" % [int(progress * 100), (1 - progress) * CAPTURE_SECONDS], "instruction": "Continue na área verde até completar a barra."}
    return {"kind": "travel", "nearby": false, "status": "SIGA A SETA ATÉ A ÁREA VERDE • %dm" % int(ceil(distance)), "instruction": "Entre na área e fique 3s, sem inimigos próximos."}

func remaining_text() -> String:
    var remaining := maxi(0, NAMES.size() - current)
    return "FALTA 1 MISSÃO" if remaining == 1 else "FALTAM %d MISSÕES" % remaining
