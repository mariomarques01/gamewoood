extends Camera3D
var target: Node3D
var offset := Vector3(10, 18, 15)
var follow_position := Vector3.ZERO
var impact_time := 0.0
var impact_strength := 0.0

func _ready() -> void:
    target = get_parent()
    keep_aspect = Camera3D.KEEP_WIDTH
    top_level = true
    global_position = Vector3(target.global_position.x, 0, target.global_position.z) + offset
    follow_position = global_position
    look_at(Vector3(target.global_position.x, 0.8, target.global_position.z))

func _process(delta: float) -> void:
    if is_instance_valid(target):
        var aspect := get_viewport().get_visible_rect().size.aspect()
        # A narrow display keeps a useful combat view instead of extending it toward the sea.
        fov = 48.0 if aspect < 1.0 else 68.0
        follow_position = follow_position.lerp(Vector3(target.global_position.x, 0, target.global_position.z) + offset, 1.0 - exp(-8.0 * delta))
        impact_time = maxf(0, impact_time - delta)
        var shake := Vector3(sin(impact_time * 85), 0, cos(impact_time * 73)) * impact_strength * impact_time / 0.24
        global_position = follow_position + shake

func impact(point: Vector3) -> void:
    if not is_instance_valid(target):
        return
    impact_strength = 0.13 * clampf(1 - target.global_position.distance_to(point) / 15, 0, 1)
    impact_time = 0.24
