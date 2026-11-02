extends Node3D
const DistrictMap = preload("res://scripts/district_map.gd")
const Spawner = preload("res://scripts/enemy_spawner.gd")
const Missions = preload("res://scripts/mission_manager.gd")
const HUD = preload("res://scripts/hud.gd")
const Save = preload("res://scripts/save_manager.gd")
@onready var player: CharacterBody3D = $Player
var district_map: Node3D
var spawner: Node
var missions: Node
var hud: CanvasLayer
var save: Node
var score := 0
var ended := false

func _ready() -> void:
    player.position = Vector3(0, 0, 7)
    district_map = DistrictMap.new()
    add_child(district_map)
    district_map.build()
    missions = Missions.new()
    missions.player = player
    add_child(missions)
    missions.updated.connect(_update_hud)
    missions.victory.connect(func(): _finish(true))
    spawner = Spawner.new()
    spawner.player = player
    add_child(spawner)
    spawner.eliminated.connect(func():
        score += 1
        _update_hud())
    save = Save.new()
    add_child(save)
    hud = HUD.new()
    add_child(hud)
    hud.player = player
    hud.mission = missions
    player.controls = hud.controls
    hud.pause_requested.connect(_pause)
    hud.restart_requested.connect(_restart)
    player.health.changed.connect(func(_current, _maximum):
        hud.flash()
        _update_hud())
    player.health.died.connect(func(): _finish(false))
    player.weapon.ammo_changed.connect(func(_ammo, _reloading): _update_hud())
    _update_hud()
    print("DEADLIGHT_READY district=1 version=0.4.0 objects=%d" % district_map.get_child_count())

func _update_hud() -> void:
    if not is_instance_valid(hud):
        return
    hud.update_status(player.health.current, player.weapon.ammo, player.weapon.reload_time > 0, score, missions)
    for index in range(3):
        district_map.objective_markers[index].visible = index == missions.current

func _finish(won: bool) -> void:
    if ended:
        return
    ended = true
    player.active = false
    spawner.active = false
    missions.active = false
    for shot in get_tree().get_nodes_in_group("projectiles"):
        shot.queue_free()
    save.record(score, won)
    hud.show_overlay("BASE PROTEGIDA!\n3 MISSOES CONCLUIDAS" if won else "BASE INVADIDA!\nO CAPITAO VOLTA JA...")
    print("DEADLIGHT_RESULT victory=%s kills=%d" % [won, score])

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        _pause()

func _pause() -> void:
    if ended:
        return
    get_tree().paused = not get_tree().paused
    print("DEADLIGHT_PAUSE %s" % get_tree().paused)
    if get_tree().paused:
        hud.show_overlay("OPERACAO EM PAUSA", true)
    else:
        hud.hide_overlay()

func _restart() -> void:
    get_tree().paused = false
    get_tree().reload_current_scene()
