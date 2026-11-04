extends Node
const POINTS := [Vector3(0,0,1),Vector3(21,0,0),Vector3(-21,0,0),Vector3(-42,0,-14),Vector3(42,0,-10),Vector3(-16,0,-32),Vector3(-63,0,-48),Vector3(63,0,-48),Vector3(-63,0,48),Vector3(63,0,48),Vector3(0,0,53),Vector3(0,0,-50)]
var district: Node3D
var index := 0
func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    district = load("res://scenes/main.tscn").instantiate()
    get_tree().root.add_child.call_deferred(district)
    await get_tree().process_frame
    await get_tree().physics_frame
    district.spawner.active = false
    district.missions.active = false
    district.player.set_physics_process(false)
    _position()
func _position() -> void:
    district.player.position = POINTS[index]
    var camera = district.player.get_node("Camera3D")
    camera._process(0.1)
    # Exercise live death particles, blood, drops and power effects at every region.
    var alien = district.spawner.spawn()
    assert(alien != null)
    alien.position = district.player.position + Vector3(2,0,-1)
    alien.receive_damage(999)
    district.player.receive_damage(8)
    print("DEADLIGHT_RENDER_CASE ",index)
func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.keycode == KEY_N:
        index = (index+1)%POINTS.size()
        _position()
