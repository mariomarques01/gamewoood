extends Node
signal eliminated
const Enemy = preload("res://scripts/enemy_controller.gd")
var player: CharacterBody3D
var active := true
const MAX_ENEMIES := 24
var timer := 1.5
var sequence := 0
var last_elimination_position := Vector3.ZERO
var points := [Vector3(-19, 0, -3), Vector3(22, 0, 5), Vector3(-9, 0, 15), Vector3(10, 0, 16), Vector3(0, 0, -22)]

func _physics_process(delta: float) -> void:
    timer -= delta
    if not active or timer > 0.0 or get_tree().get_nodes_in_group("enemies").size() >= MAX_ENEMIES:
        return
    timer = maxf(2.0, 3.2 - sequence * 0.025)
    for index in range(mini(4, 2 + sequence / 16)):
        if get_tree().get_nodes_in_group("enemies").size() < MAX_ENEMIES:
            spawn()

func spawn() -> CharacterBody3D:
    for offset in range(points.size()):
        var point: Vector3 = points[(sequence + offset) % points.size()]
        if point.distance_to(player.global_position) < 7.0:
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
            eliminated.emit())
        sequence += 1
        return enemy
    return null
