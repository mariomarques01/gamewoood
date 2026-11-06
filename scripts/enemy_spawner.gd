extends Node
signal eliminated
signal wave_changed
signal wave_cleared(number: int)
const WAVE_SIZES := [8, 12, 16]
const INTERMISSION := 8.0
var wave := 1
var wave_spawned := 0
var wave_kills := 0
var waves_completed := 0
var resting := false
var tracked: Dictionary = {}
const Enemy = preload("res://scripts/enemy_controller.gd")
var player: CharacterBody3D
var active := true
const MAX_ENEMIES := 20
var timer := 1.5
var sequence := 0
var last_elimination_position := Vector3.ZERO
var points = preload("res://scripts/neighborhood_layout.gd").SPAWN_POINTS

func _physics_process(delta: float) -> void:
    if not active:
        return
    timer -= delta
    if resting:
        if timer <= 0:
            resting = false
            wave += 1
            wave_spawned = 0
            wave_kills = 0
            timer = 1.0
            wave_changed.emit()
        return
    if waves_completed >= WAVE_SIZES.size() or timer > 0:
        return
    for enemy in get_tree().get_nodes_in_group("enemies"):
        if enemy.global_position.distance_to(player.global_position) > 55:
            if tracked.erase(enemy.get_instance_id()):
                wave_spawned -= 1 # Replace culled aliens; distance never earns a reward.
            enemy.remove_from_group("enemies")
            enemy.queue_free()
    timer = 3.2 - (wave - 1) * 0.5
    for index in range(wave + 1):
        if wave_spawned >= WAVE_SIZES[wave - 1] or get_tree().get_nodes_in_group("enemies").size() >= MAX_ENEMIES:
            break
        var alien = spawn()
        if alien != null:
            tracked[alien.get_instance_id()] = true
            wave_spawned += 1
    wave_changed.emit()

func _wave_elimination(enemy: Node) -> void:
    if not tracked.erase(enemy.get_instance_id()) or not active:
        return
    wave_kills += 1
    if wave_kills >= WAVE_SIZES[wave - 1] and tracked.is_empty():
        waves_completed = wave
        resting = wave < WAVE_SIZES.size()
        timer = INTERMISSION
        wave_cleared.emit(wave)
    wave_changed.emit()

func spawn() -> CharacterBody3D:
    for offset in range(points.size()):
        var point: Vector3 = points[(sequence + offset) % points.size()]
        if point.distance_to(player.global_position) < 7.0 or point.distance_to(player.global_position) > 34.0:
            continue
        var shape := SphereShape3D.new()
        shape.radius = 0.65
        var query := PhysicsShapeQueryParameters3D.new()
        query.shape = shape
        query.transform = Transform3D(Basis.IDENTITY, point + Vector3.UP * 0.85)
        query.collision_mask = 1 | 2 | 4
        if not player.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
            continue
        var enemy = Enemy.new()
        enemy.player = player
        enemy.ranged = sequence % 4 == 2
        enemy.archetype = "brute" if sequence % 8 == 7 else ("runner" if sequence % 4 == 1 else "grunt")
        get_parent().add_child(enemy)
        enemy.global_position = point
        enemy.eliminated.connect(func():
            last_elimination_position = enemy.global_position
            eliminated.emit()
            _wave_elimination(enemy))
        sequence += 1
        return enemy
    return null
