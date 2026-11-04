extends Node3D
@onready var audio: Node = get_node("/root/GameAudio")
const DistrictMap = preload("res://scripts/district_map.gd")
const Spawner = preload("res://scripts/enemy_spawner.gd")
const Missions = preload("res://scripts/mission_manager.gd")
const HUD = preload("res://scripts/hud.gd")
const Arcade = preload("res://scripts/arcade_flow.gd")
const Save = preload("res://scripts/save_manager.gd")
@onready var player: CharacterBody3D = $Player
var district_map: Node3D
var spawner: Node
var missions: Node
var hud: CanvasLayer
var save: Node
var score := 0
var ended := false
var arcade: Node
var last_hp := 100.0
var orientation_blocked := false
var manually_paused := false
var map_open := false
var run_seconds := 0.0
var last_result: Dictionary = {}

func _ready() -> void:
    player.position = preload("res://scripts/neighborhood_layout.gd").PLAYER_START
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
        if ended:
            return
        score += 1
        arcade.register_kill(spawner.last_elimination_position)
        _update_hud())
    save = Save.new()
    add_child(save)
    hud = HUD.new()
    add_child(hud)
    var overview = preload("res://scripts/neighborhood_overview.gd").new()
    overview.district = self
    add_child(overview)
    hud.player = player
    player.weapon.power_activated.connect(hud.show_power_activation)
    hud.mission = missions
    player.controls = hud.controls
    arcade = Arcade.new()
    arcade.player = player
    add_child(arcade)
    hud.arcade = arcade
    arcade.notice.connect(hud.notify)
    hud.show_credits(save.credits)
    arcade.credits_changed.connect(func(value: int): hud.show_credits(save.credits + value))
    arcade.elimination_feedback.connect(hud.show_kills)
    hud.orientation_changed.connect(_orientation_changed)
    hud.pause_requested.connect(_pause)
    hud.restart_requested.connect(_restart)
    player.health.changed.connect(func(_current, _maximum):
        if _current < last_hp:
            hud.flash()
            audio.play("hurt")
        last_hp = _current
        _update_hud())
    player.health.died.connect(func(): _finish(false))
    player.weapon.ammo_changed.connect(func(_ammo, _reloading): _update_hud())
    player.weapon.weapon_changed.connect(func(index: int): hud.show_weapon(index))
    hud.show_weapon(player.weapon.selected)
    _update_hud()
    _orientation_changed(hud.portrait_mode)
    hud.notify("RECIPIENTES LARANJA: ATIRE E AFASTE-SE")
    print("DEADLIGHT_READY district=1 version=%s objects=%d" % [ProjectSettings.get_setting("application/config/version"), district_map.get_child_count()])

func _physics_process(delta: float) -> void:
    if not ended:
        run_seconds += delta

func _update_hud() -> void:
    if not is_instance_valid(hud):
        return
    if is_instance_valid(arcade):
        arcade.mission_completed(missions.current)
    hud.update_status(player.health.current, player.weapon.ammo, player.weapon.reload_time > 0, score, missions)
    for index in range(3):
        district_map.objective_markers[index].visible = index == missions.current

func _finish(won: bool) -> void:
    if ended:
        return
    ended = true
    audio.set_game_state(false, false)
    audio.play("victory" if won else "defeat")
    player.active = false
    player.weapon.stop()
    spawner.active = false
    missions.active = false
    for canister in get_tree().get_nodes_in_group("explosives"):
        canister.deactivate()
    for shot in get_tree().get_nodes_in_group("projectiles"):
        shot.queue_free()
    last_result = preload("res://scripts/run_result.gd").calculate(won, score, run_seconds, player.health.current, arcade.credits, missions.current)
    save.record(score, won, last_result.earned, last_result.stars)
    hud.show_result(last_result)
    if won:
        player.get_node("Camera3D").finale = true
        var celebration = preload("res://scripts/stage_finale.gd").new()
        celebration.player = player
        add_child(celebration)
    print("DEADLIGHT_RESULT victory=%s kills=%d" % [won, score])

func _pause() -> void:
    if ended:
        return
    audio.play("ui")
    manually_paused = not manually_paused
    _sync_pause()
    print("DEADLIGHT_PAUSE %s" % manually_paused)
    if manually_paused:
        hud.show_overlay("OPERACAO EM PAUSA", true)
    else:
        hud.hide_overlay()

func _orientation_changed(portrait: bool) -> void:
    orientation_blocked = portrait
    _sync_pause()
    print("DEADLIGHT_ORIENTATION %s" % ("portrait" if portrait else "landscape"))

func _sync_pause() -> void:
    get_tree().paused = orientation_blocked or manually_paused or map_open
    audio.set_game_state(not ended, get_tree().paused, orientation_blocked)

func _restart() -> void:
    get_tree().paused = false
    get_tree().reload_current_scene()
