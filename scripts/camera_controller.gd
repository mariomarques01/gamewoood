extends Camera3D
var target: Node3D
var offset := Vector3(10, 18, 15)

func _ready() -> void:
    target = get_parent()
    keep_aspect = Camera3D.KEEP_WIDTH
    top_level = true
    global_position = Vector3(target.global_position.x, 0, target.global_position.z) + offset
    look_at(Vector3(target.global_position.x, 0.8, target.global_position.z))

func _process(delta: float) -> void:
    if is_instance_valid(target):
        var aspect := get_viewport().get_visible_rect().size.aspect()
        # A narrow display keeps a useful combat view instead of extending it toward the sea.
        fov = 48.0 if aspect < 1.0 else 68.0
        global_position = global_position.lerp(Vector3(target.global_position.x, 0, target.global_position.z) + offset, 1.0 - exp(-8.0 * delta))
