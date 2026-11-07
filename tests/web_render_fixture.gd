extends Node
const POINTS := [Vector3(0,0,1),Vector3(21,0,0),Vector3(-21,0,0),Vector3(-42,0,-14),Vector3(42,0,-10),Vector3(-16,0,-32),Vector3(-63,0,-48),Vector3(63,0,-48),Vector3(-63,0,48),Vector3(63,0,48),Vector3(0,0,53),Vector3(0,0,-50),Vector3(-21,0,24)]
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
    if index == POINTS.size() - 1:
        # Simulate a transient invalid physics position and a view already poisoned
        # by it; the following rendered case must recover without a scene reload.
        district.player.position.x = NAN
        camera._process(0.1)
        district.player.position = POINTS[index]
        camera.rotation = Vector3(NAN, NAN, NAN)
    camera._process(0.1)
    assert(camera.global_transform.is_finite(), "Camera failed to recover before rendering")
    # Exercise live death particles, blood, drops and power effects at every region.
    var alien = district.spawner.spawn()
    assert(alien != null)
    alien.position = district.player.position + Vector3(2,0,-1)
    alien.receive_damage(999)
    district.player.receive_damage(8)
    print("DEADLIGHT_RENDER_CASE ",index)
func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.keycode == KEY_G and not traveling:
        _guidance_case()
        return
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

# Read-only snapshots and deterministic setup live only in the isolated QA export.
# The real mission rules, map button, HUD and victory handler remain production code.
var guidance_phase := -1
var guidance_enemy: Node3D
var guidance_map: CanvasLayer

func _guidance_case() -> void:
    guidance_phase += 1
    var missions = district.missions
    if guidance_phase == 0:
        district.spawner.active = false
        missions.set_physics_process(false)
        missions.active = true
        district.player.position = Vector3(0, 0, 1)
        district.player.health.invulnerability = 10000
        district.spawner.waves_completed = 3
        for child in district.get_children():
            if child.get_script() == preload("res://scripts/neighborhood_overview.gd"):
                guidance_map = child
        district.player.get_node("Camera3D")._process(1)
    elif guidance_phase == 1:
        assert(guidance_map.open, "Actual map touch failed")
    elif guidance_phase == 2:
        assert(not guidance_map.open, "Actual map close touch failed")
        district.player.position = missions.POSITIONS[0]
        missions._physics_process(0.3)
        district.player.get_node("Camera3D")._process(1)
    elif guidance_phase == 3:
        guidance_enemy = preload("res://scripts/enemy_controller.gd").new()
        guidance_enemy.player = district.player
        district.add_child(guidance_enemy)
        guidance_enemy.position = district.player.position + Vector3(1.4, 0, 0)
        guidance_enemy.set_physics_process(false)
        missions._physics_process(1)
    elif guidance_phase == 4:
        guidance_enemy.receive_damage(1000)
        missions._physics_process(3.1)
    elif guidance_phase == 5:
        for objective_index in range(1, 3):
            district.player.position = missions.POSITIONS[objective_index]
            missions._physics_process(3.1)
    district._update_hud()
    district.hud._process(0.2)
    await get_tree().process_frame
    await RenderingServer.frame_post_draw
    var guide = district.hud.mission_guide
    var area := get_viewport().get_visible_rect().size
    var bounds: Rect2 = guide.get_global_rect()
    var map_bounds: Rect2 = guidance_map.legend.get_global_rect()
    var map_center: Vector2 = guidance_map.map_button.get_global_rect().get_center() / area
    var close_center: Vector2 = guidance_map.close_button.get_global_rect().get_center() / area
    print("DEADLIGHT_GUIDANCE_CASE " + JSON.stringify({"case": guidance_phase, "heading": guide.heading.text,
        "status": guide.status_label.text, "instruction": guide.instruction.text, "visible": guide.is_visible_in_tree(),
        "wave": district.hud.wave_status.text, "progress": missions.progress, "map_open": guidance_map.open,
        "checklist": [guide.checklist[0].text, guide.checklist[1].text, guide.checklist[2].text],
        "rect": [bounds.position.x / area.x, bounds.position.y / area.y, bounds.size.x / area.x, bounds.size.y / area.y],
        "map_rect": [map_bounds.position.x / area.x, map_bounds.position.y / area.y, map_bounds.size.x / area.x, map_bounds.size.y / area.y],
        "map": [map_center.x, map_center.y], "close": [close_center.x, close_center.y],
        "tasks": [guidance_map.task_labels[0].text, guidance_map.task_labels[1].text, guidance_map.task_labels[2].text],
        "won": district.ended and district.last_result.get("won", false)}))
