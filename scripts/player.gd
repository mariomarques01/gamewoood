extends CharacterBody3D

@export var move_speed: float = 6.0
@export var acceleration: float = 20.0

var mobile_direction: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
    var direction := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    if mobile_direction.length() > 0.05:
        direction = mobile_direction.limit_length(1.0)
    var target := Vector3(direction.x, 0.0, direction.y) * move_speed
    velocity.x = move_toward(velocity.x, target.x, acceleration * delta)
    velocity.z = move_toward(velocity.z, target.z, acceleration * delta)
    velocity.y = 0.0
    move_and_slide()

func set_mobile_direction(direction: Vector2) -> void:
    mobile_direction = direction
