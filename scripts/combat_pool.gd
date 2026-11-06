extends Node
# Scene-owned pools: inactive entries never participate in physics or group queries.
const LIMITS := {"projectile": 64, "spark": 12}
var entries: Dictionary = {"projectile": [], "spark": []}
var created: Dictionary = {"projectile": 0, "spark": 0}

static func ensure(world: Node) -> Node:
    var pool := world.get_node_or_null("CombatPool")
    if pool == null:
        pool = load("res://scripts/combat_pool.gd").new()
        pool.name = "CombatPool"
        world.add_child(pool)
    return pool

func acquire(kind: String) -> Node3D:
    entries[kind] = entries[kind].filter(func(entry): return is_instance_valid(entry) and not entry.is_queued_for_deletion())
    for entry in entries[kind]:
        if is_instance_valid(entry) and not entry.is_queued_for_deletion() and not entry.in_use:
            return entry
    if entries[kind].size() >= LIMITS[kind]:
        if kind == "projectile":
            return null
        # Replace only the oldest short-lived cosmetic effect.
        var oldest = entries[kind][0]
        for entry in entries[kind]:
            if entry.age > oldest.age:
                oldest = entry
        oldest.release()
        return oldest
    var entry = load("res://scripts/projectile.gd" if kind == "projectile" else "res://scripts/hit_spark.gd").new()
    entry.pooled = true
    get_parent().add_child(entry)
    entries[kind].append(entry)
    created[kind] += 1
    return entry

func warm_up() -> void:
    # Allocate through acquire while marking previous entries occupied.
    for kind in ["projectile", "spark"]:
        for index in range(24 if kind == "projectile" else 8):
            var entry = acquire(kind)
            entry.in_use = true
        for entry in entries[kind]:
            entry.release()

func clear() -> void:
    for kind in entries:
        for entry in entries[kind]:
            if is_instance_valid(entry) and not entry.is_queued_for_deletion():
                entry.release()
