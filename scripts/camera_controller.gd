extends Camera3D
var target: Node3D
var offset := Vector3(0, 15, 12)

func _ready() -> void:
    target = get_parent()
    top_level = true
    global_position = target.global_position + offset

func _process(delta: float) -> void:
    if is_instance_valid(target):
        global_position = global_position.lerp(target.global_position + offset, 1.0 - exp(-8.0 * delta))
