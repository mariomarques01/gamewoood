extends Node
signal updated
signal victory
const POSITIONS = preload("res://scripts/neighborhood_layout.gd").OBJECTIVES
const TITLES := ["LIBERE O ARSENAL", "PROTEJA E ATIVE O HELIPONTO", "RESTABELECA A COMUNICACAO"]
var player: CharacterBody3D
var current := 0
var progress := 0.0
var active := true
var contested := false
var ui_timer := 0.0

func _physics_process(delta: float) -> void:
    if not active or current >= 3:
        return
    var nearby := player.global_position.distance_to(POSITIONS[current]) < 3.1
    contested = false
    if nearby:
        for enemy in get_tree().get_nodes_in_group("enemies"):
            if enemy.global_position.distance_to(POSITIONS[current]) < 5.0:
                contested = true
                break
    if nearby and not contested:
        progress = minf(1.0, progress + delta / 3.0)
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
