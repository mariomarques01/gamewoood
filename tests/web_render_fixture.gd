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
    if event is InputEventKey and event.pressed and event.keycode == KEY_R and not traveling:
        _start_route()
    if event is InputEventKey and event.pressed and event.keycode == KEY_N and not traveling:
        index = (index+1)%POINTS.size()
        _position()

const ROUTE := [Vector3(21,0,1),Vector3(42,0,1),Vector3(42,0,-10),Vector3(42,0,1),Vector3(21,0,1),Vector3(21,0,-24),Vector3(21,0,1),Vector3(0,0,1)]
var traveling := false
var route_index := 0
var laps := 0
var route_seconds := 0.0
var kill_timer := 0.0
var report_timer := 0.0

func _start_route() -> void:
    district.player.position = Vector3(0,0,1)
    district.player.health.heal(100)
    district.player.health.invulnerability = 10000
    district.player.set_physics_process(true)
    district.spawner.active = true
    traveling = true
    print("DEADLIGHT_RENDER_ROUTE_START")

func _physics_process(delta: float) -> void:
    if not traveling:
        return
    route_seconds += delta
    kill_timer -= delta
    report_timer -= delta
    var player: CharacterBody3D = district.player
    var offset: Vector3 = ROUTE[route_index] - player.position
    offset.y = 0
    if offset.length() < 0.8:
        route_index += 1
        if route_index == ROUTE.size():
            route_index = 0
            laps += 1
            print("DEADLIGHT_RENDER_LAP ",laps)
        if laps >= 2:
            traveling = false
            district.spawner.active = false
            player.controls.reset()
            print("DEADLIGHT_RENDER_ROUTE_OK seconds=",route_seconds," kills=",district.score)
            return
    player.controls.movement = Vector2(offset.dot(player.screen_to_world(Vector2.RIGHT)),offset.dot(player.screen_to_world(Vector2.DOWN))).normalized()
    var nearest: CharacterBody3D
    var distance := 30.0
    for enemy in get_tree().get_nodes_in_group("enemies"):
        var d: float = player.position.distance_to(enemy.position)
        if not enemy.dead and d < distance:
            distance = d
            nearest = enemy
    if nearest != null:
        var toward: Vector3 = nearest.position - player.position
        player.controls.aiming = true
        player.controls.aim = Vector2(toward.dot(player.screen_to_world(Vector2.RIGHT)),toward.dot(player.screen_to_world(Vector2.DOWN))).normalized()
        if kill_timer <= 0:
            nearest.receive_damage(999)
            kill_timer = 1.5
    if report_timer <= 0:
        report_timer = 2.0
        assert(district.find_children("*","MultiMeshInstance3D",true,false).is_empty(),"Instancing returned to the live scene")
        print("DEADLIGHT_RENDER_ROUTE_FRAME waypoint=",route_index," seconds=",route_seconds)
