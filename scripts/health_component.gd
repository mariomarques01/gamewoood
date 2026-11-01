extends Node
signal changed(current: float, maximum: float)
signal died
@export var maximum := 100.0
var current := 100.0
var invulnerability := 0.0

func _physics_process(delta: float) -> void:
    invulnerability = maxf(0.0, invulnerability - delta)

func damage(amount: float, cooldown: float = 0.0) -> void:
    if current <= 0.0 or invulnerability > 0.0:
        return
    current = maxf(0.0, current - amount)
    invulnerability = cooldown
    changed.emit(current, maximum)
    if current <= 0.0:
        died.emit()
