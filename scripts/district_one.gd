extends Node3D

# Bairro 1: greybox 3D jogavel, inspirado no conceito visual da Base do Capitao.
const SIZE := 58.0
const BLUE := Color(0.12, 0.35, 0.62)
const ASPHALT := Color(0.17, 0.20, 0.25)
const CONCRETE := Color(0.47, 0.51, 0.56)
const GOLD := Color(1.0, 0.68, 0.12)
const GREEN := Color(0.18, 0.86, 0.36)

@onready var player: CharacterBody3D = $Player
var hud: Label
var message: Label
var move_id := -1
var aim_id := -1
var move_start := Vector2.ZERO
var aim_start := Vector2.ZERO
var aim_direction := Vector2.RIGHT
var shoot_cooldown := 0.0
var hp := 100
var enemies: Array[CharacterBody3D] = []
var shots: Array[Node3D] = []
var completed: Array[bool] = [false, false, false]
var objectives := [Vector3(-17, 0, -7), Vector3(17, 0, -9), Vector3(0, 0, -18)]
var labels := ["ARSENAL", "HELIPONTO", "COMUNICACAO"]
var objective_markers: Array[Node3D] = []
var spawn_timer := 0.0
var score := 0

func _ready() -> void:
    player.position = Vector3(0, 0, 5)
    _create_map()
    _create_hud()
    _update_hud()
    print("DEADLIGHT_READY district=1 version=0.2.2 objects=%d" % get_child_count())

func _material(color: Color, glow: bool = false) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.75
    if glow:
        mat.emission_enabled = true
        mat.emission = color
        mat.emission_energy_multiplier = 1.4
    return mat

func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, solid: bool = false) -> Node3D:
    var root: Node3D
    if solid:
        root = StaticBody3D.new()
    else:
        root = Node3D.new()
    parent.add_child(root)
    root.position = pos
    var visual := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    visual.mesh = mesh
    visual.material_override = _material(color)
    root.add_child(visual)
    if solid:
        var shape := CollisionShape3D.new()
        var box := BoxShape3D.new()
        box.size = size
        shape.shape = box
        root.add_child(shape)
    return root

func _create_map() -> void:
    # Area principal e acesso ao portao sul.
    _box(self, Vector3(0, -0.55, 0), Vector3(SIZE, 1, SIZE), Color(0.24, 0.32, 0.30), true)
    _box(self, Vector3(0, -0.04, 14), Vector3(12, 0.08, 27), ASPHALT)
    _box(self, Vector3(0, -0.03, -7), Vector3(42, 0.08, 16), ASPHALT)
    _box(self, Vector3(0, -0.03, 1), Vector3(12, 0.08, 26), ASPHALT)
    # Muros com passagem no portao sul.
    for z in [-26.0, 26.0]:
        _box(self, Vector3(0, 1.2, z), Vector3(52, 2.4, 1.3), CONCRETE, true)
    for x in [-26.0, 26.0]:
        _box(self, Vector3(x, 1.2, 0), Vector3(1.3, 2.4, 52), CONCRETE, true)
    _box(self, Vector3(-17, 1.2, 20), Vector3(18, 2.4, 1.3), CONCRETE, true)
    _box(self, Vector3(17, 1.2, 20), Vector3(18, 2.4, 1.3), CONCRETE, true)
    # Quartel central, duas alas e telhado azul.
    _box(self, Vector3(0, 3.1, -4), Vector3(12, 6.2, 9), CONCRETE, true)
    _box(self, Vector3(0, 6.3, -4), Vector3(13, 0.5, 10), BLUE)
    _box(self, Vector3(-11, 1.8, -17), Vector3(9, 3.6, 6), Color(0.38, 0.44, 0.50), true)
    _box(self, Vector3(-11, 3.8, -17), Vector3(10, 0.4, 7), BLUE)
    _box(self, Vector3(13, 2.2, -17), Vector3(9, 4.4, 7), Color(0.40, 0.46, 0.52), true)
    _box(self, Vector3(13, 4.6, -17), Vector3(10, 0.4, 8), BLUE)
    # Torres e luzes.
    for x in [-22.0, 22.0]:
        for z in [-22.0, 16.0]:
            _box(self, Vector3(x, 3, z), Vector3(2.2, 6, 2.2), Color(0.32, 0.38, 0.45), true)
            _box(self, Vector3(x, 6.2, z), Vector3(3.2, 0.6, 3.2), BLUE)
            _box(self, Vector3(x, 6.65, z), Vector3(0.6, 0.3, 0.6), GOLD)
    # Heliponto com marcas e heliponto de acesso.
    _box(self, Vector3(17, 0.05, -9), Vector3(10, 0.12, 10), ASPHALT)
    _box(self, Vector3(17, 0.13, -9), Vector3(7, 0.04, 0.6), GOLD)
    _box(self, Vector3(17, 0.14, -9), Vector3(0.6, 0.04, 6), GOLD)
    # Caixas de suprimentos e vegetacao.
    for p in [Vector3(-19, 0.65, 5), Vector3(-16, 0.65, 8), Vector3(19, 0.65, 10), Vector3(22, 0.65, 8)]:
        _box(self, p, Vector3(1.4, 1.3, 1.4), Color(0.22, 0.47, 0.25), true)
    for p in [Vector3(-22, 0, 10), Vector3(22, 0, 1), Vector3(-21, 0, -10)]:
        _box(self, p + Vector3(0, 1, 0), Vector3(0.6, 2, 0.6), Color(0.42, 0.25, 0.12))
        _box(self, p + Vector3(0, 2.5, 0), Vector3(2.7, 2.1, 2.7), Color(0.14, 0.48, 0.24))
    for i in range(3):
        var marker := Node3D.new()
        add_child(marker)
        marker.position = objectives[i]
        _box(marker, Vector3(0, 0.08, 0), Vector3(3.2, 0.15, 3.2), GREEN, false)
        _box(marker, Vector3(0, 2.0, 0), Vector3(0.28, 3.8, 0.28), GREEN, false)
        objective_markers.append(marker)
    # Melhor contraste para identificar o protagonista.
    var visual := player.get_node_or_null("Visual/MeshInstance3D") as MeshInstance3D
    if visual:
        visual.material_override = _material(Color(1.0, 0.44, 0.12))

func _create_hud() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(root)
    hud = Label.new()
    hud.position = Vector2(18, 16)
    hud.add_theme_font_size_override("font_size", 23)
    hud.add_theme_color_override("font_color", Color.WHITE)
    root.add_child(hud)
    message = Label.new()
    message.set_anchors_preset(Control.PRESET_CENTER_TOP)
    message.position = Vector2(-230, 65)
    message.custom_minimum_size = Vector2(460, 50)
    message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    message.add_theme_font_size_override("font_size", 25)
    message.add_theme_color_override("font_color", GOLD)
    root.add_child(message)
    var hint := Label.new()
    hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    hint.offset_top = -62
    hint.offset_bottom = -12
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint.text = "ESQUERDA: MOVER   |   DIREITA: MIRAR / ATIRAR"
    hint.add_theme_font_size_override("font_size", 17)
    root.add_child(hint)

func _update_hud() -> void:
    var count := 0
    for done in completed:
        if done:
            count += 1
    hud.text = "BAIRRO 1 v0.2.2  |  BASE DO CAPITAO\nVIDA: %d   ALIENS: %d   MISSOES: %d/3" % [hp, score, count]
    if count == 3:
        message.text = "BAIRRO 1 CONCLUIDO! BASE PROTEGIDA!"
    else:
        message.text = "ATIVE: " + labels[count] + " (marcador verde)"

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        var half := get_viewport().get_visible_rect().size.x * 0.5
        if touch.pressed:
            if touch.position.x < half and move_id == -1:
                move_id = touch.index
                move_start = touch.position
            elif touch.position.x >= half and aim_id == -1:
                aim_id = touch.index
                aim_start = touch.position
        else:
            if touch.index == move_id:
                move_id = -1
                player.set_mobile_direction(Vector2.ZERO)
            if touch.index == aim_id:
                aim_id = -1
    elif event is InputEventScreenDrag:
        var drag := event as InputEventScreenDrag
        if drag.index == move_id:
            player.set_mobile_direction((drag.position - move_start) / 70.0)
        elif drag.index == aim_id:
            var dir := (drag.position - aim_start).normalized()
            if dir.length() > 0.1:
                aim_direction = dir

func _process(delta: float) -> void:
    if hp <= 0:
        return
    spawn_timer -= delta
    shoot_cooldown -= delta
    if spawn_timer <= 0 and enemies.size() < 9:
        spawn_timer = 3.2
        _spawn_alien()
    var direction := aim_direction
    if aim_id == -1:
        var mouse := get_viewport().get_mouse_position()
        var viewport := get_viewport().get_visible_rect().size
        if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
            direction = (mouse - viewport * 0.5).normalized()
        else:
            direction = Vector2.ZERO
    if direction.length() > 0.1 and shoot_cooldown <= 0:
        shoot_cooldown = 0.24
        _fire(direction)
    for alien in enemies.duplicate():
        if not is_instance_valid(alien):
            enemies.erase(alien)
            continue
        var chase: Vector3 = player.global_position - alien.global_position
        chase.y = 0
        if chase.length() > 1.2:
            alien.velocity = chase.normalized() * 2.4
            alien.move_and_slide()
        else:
            hp = max(0, hp - int(ceil(delta * 12.0)))
            _update_hud()
    for shot in shots.duplicate():
        if not is_instance_valid(shot):
            shots.erase(shot)
            continue
        shot.position += shot.get_meta("direction") * 19.0 * delta
        shot.set_meta("life", float(shot.get_meta("life")) - delta)
        if float(shot.get_meta("life")) <= 0:
            shots.erase(shot)
            shot.queue_free()
            continue
        for alien in enemies.duplicate():
            if is_instance_valid(alien) and shot.position.distance_to(alien.position + Vector3(0, 0.8, 0)) < 1.2:
                enemies.erase(alien)
                alien.queue_free()
                shots.erase(shot)
                shot.queue_free()
                score += 1
                _update_hud()
                break
    for i in range(3):
        if not completed[i] and player.position.distance_to(objectives[i]) < 3.1:
            completed[i] = true
            objective_markers[i].visible = false
            _update_hud()
    if hp == 0:
        message.text = "BASE INVADIDA! RECARREGUE PARA TENTAR NOVAMENTE"

func _fire(direction: Vector2) -> void:
    var shot := Node3D.new()
    add_child(shot)
    shot.position = player.position + Vector3(0, 1.1, 0)
    var dir3 := Vector3(direction.x, 0, direction.y).normalized()
    shot.set_meta("direction", dir3)
    shot.set_meta("life", 1.6)
    var sphere := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 0.25
    mesh.height = 0.5
    sphere.mesh = mesh
    sphere.material_override = _material(GOLD, true)
    shot.add_child(sphere)
    shots.append(shot)

func _spawn_alien() -> void:
    var alien := CharacterBody3D.new()
    alien.collision_layer = 2
    alien.collision_mask = 1
    add_child(alien)
    var angle := randf() * TAU
    alien.position = Vector3(cos(angle) * 19, 0, sin(angle) * 19)
    var shape := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.5
    capsule.height = 1.5
    shape.position.y = 0.75
    shape.shape = capsule
    alien.add_child(shape)
    var mesh := MeshInstance3D.new()
    var capsule_mesh := CapsuleMesh.new()
    capsule_mesh.radius = 0.5
    capsule_mesh.height = 1.5
    mesh.position.y = 0.75
    mesh.mesh = capsule_mesh
    mesh.material_override = _material(GREEN)
    alien.add_child(mesh)
    enemies.append(alien)
