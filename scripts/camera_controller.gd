extends Camera3D
var target: Node3D
var offset := Vector3(10, 18, 15)
var follow_position := Vector3.ZERO
var impact_time := 0.0
var impact_strength := 0.0
var finale := false

func _ready() -> void:
    target = get_parent()
    keep_aspect = Camera3D.KEEP_WIDTH
    top_level = true
    near = 0.5
    far = 240.0
    global_position = Vector3(target.global_position.x, 0, target.global_position.z) + offset
    follow_position = global_position
    look_at(Vector3(target.global_position.x, 0.8, target.global_position.z))

func _process(delta: float) -> void:
    if is_instance_valid(target):
        var aspect := get_viewport().get_visible_rect().size.aspect()
        # A narrow display keeps a useful combat view instead of extending it toward the sea.
        var desired_fov := 48.0 if finale or aspect < 1.0 else 68.0
        fov = lerpf(fov, desired_fov, minf(1, delta * 4)) if finale else desired_fov
        var focus := Vector3(target.global_position.x, 0, target.global_position.z)
        var destination := focus + offset * (0.52 if finale else 1.0)
        # Snap after recovery/teleport instead of tracking through empty space.
        if not follow_position.is_finite() or follow_position.distance_to(destination) > 24.0:
            follow_position = destination
        else:
            follow_position = follow_position.lerp(destination, 1.0 - exp(-(3.0 if finale else 8.0) * delta))
        impact_time = maxf(0, impact_time - delta)
        var shake := Vector3(sin(impact_time * 85), 0, cos(impact_time * 73)) * impact_strength * impact_time / 0.24
        global_position = follow_position + shake
        if finale:
            look_at(focus + Vector3.UP * 0.9 + global_basis.x * 2.2)
        else:
            look_at(focus + Vector3.UP * 0.8)

func impact(point: Vector3) -> void:
    if not is_instance_valid(target):
        return
    impact_strength = 0.13 * clampf(1 - target.global_position.distance_to(point) / 15, 0, 1)
    impact_time = 0.24
